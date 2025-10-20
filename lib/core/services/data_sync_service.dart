import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
  paused,
}

enum SyncOperation {
  create,
  update,
  delete,
  read,
}

enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

enum ConflictResolution {
  serverWins,
  clientWins,
  merge,
  manual,
}

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final Uuid _uuid = const Uuid();
  
  // Sync state management
  SyncStatus _syncStatus = SyncStatus.idle;
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  // Connectivity monitoring
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = false;
  
  // Sync queue management
  final List<SyncOperation> _syncQueue = [];
  final Map<String, SyncItem> _pendingSyncItems = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  
  // Configuration
  bool _autoSyncEnabled = true;
  Duration _syncInterval = const Duration(minutes: 5);
  int _maxRetries = 3;
  Duration _retryDelay = const Duration(seconds: 30);
  bool _syncOnlyOnWifi = false;
  
  Timer? _syncTimer;
  Timer? _retryTimer;

  // Getters
  SyncStatus get syncStatus => _syncStatus;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  bool get isOnline => _isOnline;
  bool get autoSyncEnabled => _autoSyncEnabled;
  List<SyncItem> get pendingSyncItems => _pendingSyncItems.values.toList();

  // Initialize the service
  Future<void> initialize({
    bool autoSync = true,
    Duration syncInterval = const Duration(minutes: 5),
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 30),
    bool syncOnlyOnWifi = false,
  }) async {
    _autoSyncEnabled = autoSync;
    _syncInterval = syncInterval;
    _maxRetries = maxRetries;
    _retryDelay = retryDelay;
    _syncOnlyOnWifi = syncOnlyOnWifi;

    await _loadSyncConfiguration();
    await _loadPendingSyncItems();
    
    _setupConnectivityListener();
    
    if (_autoSyncEnabled) {
      _startAutoSync();
    }

    // Perform initial sync if online
    if (_isOnline) {
      _scheduleSyncWithDelay(const Duration(seconds: 2));
    }
  }

  // Connectivity Management
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (_syncOnlyOnWifi) {
      _isOnline = _isOnline && results.contains(ConnectivityResult.wifi);
    }

    if (!wasOnline && _isOnline) {
      // Just came online, trigger sync
      if (_autoSyncEnabled && _pendingSyncItems.isNotEmpty) {
        _scheduleSyncWithDelay(const Duration(seconds: 1));
      }
    }
  }

  // Sync Operations
  Future<void> addSyncItem({
    required String id,
    required String entity,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
    ConflictResolution conflictResolution = ConflictResolution.serverWins,
  }) async {
    final syncItem = SyncItem(
      id: id,
      entity: entity,
      operation: operation,
      data: data,
      priority: priority,
      conflictResolution: conflictResolution,
      createdAt: DateTime.now(),
      retryCount: 0,
    );

    _pendingSyncItems[id] = syncItem;
    await _savePendingSyncItems();

    if (_autoSyncEnabled && _isOnline) {
      _scheduleSyncWithDelay(const Duration(milliseconds: 500));
    }
  }

  Future<bool> syncNow({bool force = false}) async {
    if (!_isOnline && !force) {
      return false;
    }

    if (_syncStatus == SyncStatus.syncing) {
      return false; // Already syncing
    }

    await _performSync();
    return true;
  }

  Future<void> _performSync() async {
    if (_pendingSyncItems.isEmpty) return;

    _updateSyncStatus(SyncStatus.syncing);

    try {
      // Sort items by priority and creation time
      final sortedItems = _pendingSyncItems.values.toList()
        ..sort((a, b) {
          final priorityComparison = b.priority.index.compareTo(a.priority.index);
          if (priorityComparison != 0) return priorityComparison;
          return a.createdAt.compareTo(b.createdAt);
        });

      final completedItems = <String>[];
      final failedItems = <String>[];

      for (final item in sortedItems) {
        if (_syncStatus != SyncStatus.syncing) break; // Sync was cancelled

        try {
          final success = await _syncItem(item);
          if (success) {
            completedItems.add(item.id);
          } else {
            failedItems.add(item.id);
          }
        } catch (e) {
          failedItems.add(item.id);
          await _handleSyncError(item, e);
        }
      }

      // Remove completed items
      for (final id in completedItems) {
        _pendingSyncItems.remove(id);
      }

      // Update retry counts for failed items
      for (final id in failedItems) {
        final item = _pendingSyncItems[id];
        if (item != null) {
          item.retryCount++;
          item.lastRetryAt = DateTime.now();
          
          if (item.retryCount >= _maxRetries) {
            item.status = SyncItemStatus.failed;
          }
        }
      }

      await _savePendingSyncItems();
      
      _updateSyncStatus(failedItems.isEmpty ? SyncStatus.completed : SyncStatus.failed);
      
      // Schedule retry for failed items
      if (failedItems.isNotEmpty) {
        _scheduleRetry();
      }

    } catch (e) {
      _updateSyncStatus(SyncStatus.failed);
      _scheduleRetry();
    }
  }

  Future<bool> _syncItem(SyncItem item) async {
    try {
      switch (item.operation) {
        case SyncOperation.create:
          return await _syncCreate(item);
        case SyncOperation.update:
          return await _syncUpdate(item);
        case SyncOperation.delete:
          return await _syncDelete(item);
        case SyncOperation.read:
          return await _syncRead(item);
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncCreate(SyncItem item) async {
    // Implementation would make HTTP POST request to create the item
    // This is a mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate network call success/failure
    final success = DateTime.now().millisecond % 10 < 8; // 80% success rate
    
    if (success) {
      _lastSyncTimes[item.entity] = DateTime.now();
    }
    
    return success;
  }

  Future<bool> _syncUpdate(SyncItem item) async {
    // Implementation would make HTTP PUT/PATCH request to update the item
    // Handle conflict resolution here
    await Future.delayed(const Duration(milliseconds: 400));
    
    final success = DateTime.now().millisecond % 10 < 8;
    
    if (success) {
      _lastSyncTimes[item.entity] = DateTime.now();
    }
    
    return success;
  }

  Future<bool> _syncDelete(SyncItem item) async {
    // Implementation would make HTTP DELETE request
    await Future.delayed(const Duration(milliseconds: 300));
    
    final success = DateTime.now().millisecond % 10 < 9; // 90% success rate for deletes
    
    if (success) {
      _lastSyncTimes[item.entity] = DateTime.now();
    }
    
    return success;
  }

  Future<bool> _syncRead(SyncItem item) async {
    // Implementation would make HTTP GET request to fetch latest data
    await Future.delayed(const Duration(milliseconds: 600));
    
    final success = DateTime.now().millisecond % 10 < 9;
    
    if (success) {
      _lastSyncTimes[item.entity] = DateTime.now();
    }
    
    return success;
  }

  // Conflict Resolution
  Future<Map<String, dynamic>?> resolveConflict(
    SyncItem item,
    Map<String, dynamic> serverData,
    Map<String, dynamic> clientData,
  ) async {
    switch (item.conflictResolution) {
      case ConflictResolution.serverWins:
        return serverData;
        
      case ConflictResolution.clientWins:
        return clientData;
        
      case ConflictResolution.merge:
        return _mergeData(serverData, clientData);
        
      case ConflictResolution.manual:
        // This would typically show a UI for manual resolution
        return await _requestManualResolution(item, serverData, clientData);
    }
  }

  Map<String, dynamic> _mergeData(
    Map<String, dynamic> serverData,
    Map<String, dynamic> clientData,
  ) {
    final merged = Map<String, dynamic>.from(serverData);
    
    clientData.forEach((key, value) {
      if (!merged.containsKey(key) || merged[key] != value) {
        // Simple merge strategy - client data overwrites server data
        // In a real implementation, you'd have more sophisticated merge logic
        merged[key] = value;
      }
    });
    
    return merged;
  }

  Future<Map<String, dynamic>?> _requestManualResolution(
    SyncItem item,
    Map<String, dynamic> serverData,
    Map<String, dynamic> clientData,
  ) async {
    // This would show a UI for manual conflict resolution
    // For now, just return client data
    return clientData;
  }

  // Auto Sync Management
  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline && _pendingSyncItems.isNotEmpty) {
        _performSync();
      }
    });
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _scheduleSyncWithDelay(Duration delay) {
    Timer(delay, () {
      if (_isOnline && _pendingSyncItems.isNotEmpty) {
        _performSync();
      }
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (_isOnline) {
        _performSync();
      }
    });
  }

  // Configuration
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    
    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
    
    await _saveSyncConfiguration();
  }

  Future<void> setSyncInterval(Duration interval) async {
    _syncInterval = interval;
    
    if (_autoSyncEnabled) {
      _startAutoSync(); // Restart with new interval
    }
    
    await _saveSyncConfiguration();
  }

  Future<void> setSyncOnlyOnWifi(bool wifiOnly) async {
    _syncOnlyOnWifi = wifiOnly;
    await _saveSyncConfiguration();
  }

  // Manual Control
  Future<void> pauseSync() async {
    _updateSyncStatus(SyncStatus.paused);
    _stopAutoSync();
    _retryTimer?.cancel();
  }

  Future<void> resumeSync() async {
    _updateSyncStatus(SyncStatus.idle);
    
    if (_autoSyncEnabled) {
      _startAutoSync();
    }
    
    if (_isOnline && _pendingSyncItems.isNotEmpty) {
      _scheduleSyncWithDelay(const Duration(seconds: 1));
    }
  }

  Future<void> cancelSync() async {
    _updateSyncStatus(SyncStatus.idle);
  }

  // Data Management
  Future<void> clearSyncQueue() async {
    _pendingSyncItems.clear();
    await _savePendingSyncItems();
  }

  Future<void> removeSyncItem(String id) async {
    _pendingSyncItems.remove(id);
    await _savePendingSyncItems();
  }

  Future<void> retryFailedItems() async {
    final failedItems = _pendingSyncItems.values
        .where((item) => item.status == SyncItemStatus.failed)
        .toList();
    
    for (final item in failedItems) {
      item.status = SyncItemStatus.pending;
      item.retryCount = 0;
      item.lastRetryAt = null;
    }
    
    await _savePendingSyncItems();
    
    if (_isOnline) {
      _scheduleSyncWithDelay(const Duration(seconds: 1));
    }
  }

  // Statistics and Monitoring
  SyncStats getSyncStats() {
    final totalItems = _pendingSyncItems.length;
    final pendingItems = _pendingSyncItems.values
        .where((item) => item.status == SyncItemStatus.pending)
        .length;
    final failedItems = _pendingSyncItems.values
        .where((item) => item.status == SyncItemStatus.failed)
        .length;
    
    return SyncStats(
      totalPendingItems: totalItems,
      pendingItems: pendingItems,
      failedItems: failedItems,
      lastSyncTimes: Map.from(_lastSyncTimes),
      isOnline: _isOnline,
      syncStatus: _syncStatus,
      autoSyncEnabled: _autoSyncEnabled,
    );
  }

  DateTime? getLastSyncTime(String entity) {
    return _lastSyncTimes[entity];
  }

  // Error Handling
  Future<void> _handleSyncError(SyncItem item, dynamic error) async {
    // Log the error and update item status
    item.lastError = error.toString();
    item.lastRetryAt = DateTime.now();
    
    // You could send this to your error tracking service
  }

  // Persistence
  Future<void> _saveSyncConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_auto_enabled', _autoSyncEnabled);
    await prefs.setInt('sync_interval_minutes', _syncInterval.inMinutes);
    await prefs.setBool('sync_wifi_only', _syncOnlyOnWifi);
  }

  Future<void> _loadSyncConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSyncEnabled = prefs.getBool('sync_auto_enabled') ?? true;
    final intervalMinutes = prefs.getInt('sync_interval_minutes') ?? 5;
    _syncInterval = Duration(minutes: intervalMinutes);
    _syncOnlyOnWifi = prefs.getBool('sync_wifi_only') ?? false;
  }

  Future<void> _savePendingSyncItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _pendingSyncItems.values
        .map((item) => item.toJson())
        .toList();
    await prefs.setString('pending_sync_items', json.encode(itemsJson));
  }

  Future<void> _loadPendingSyncItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJsonString = prefs.getString('pending_sync_items');
    
    if (itemsJsonString != null) {
      final itemsJson = json.decode(itemsJsonString) as List;
      for (final itemJson in itemsJson) {
        final item = SyncItem.fromJson(itemJson);
        _pendingSyncItems[item.id] = item;
      }
    }
  }

  // Status Updates
  void _updateSyncStatus(SyncStatus status) {
    if (_syncStatus != status) {
      _syncStatus = status;
      _syncStatusController.add(status);
    }
  }

  // Cleanup
  void dispose() {
    _connectivitySubscription.cancel();
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _syncStatusController.close();
  }
}

// Data Classes
enum SyncItemStatus {
  pending,
  syncing,
  completed,
  failed,
}

class SyncItem {
  final String id;
  final String entity;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final ConflictResolution conflictResolution;
  final DateTime createdAt;
  
  SyncItemStatus status;
  int retryCount;
  DateTime? lastRetryAt;
  String? lastError;

  SyncItem({
    required this.id,
    required this.entity,
    required this.operation,
    required this.data,
    required this.priority,
    required this.conflictResolution,
    required this.createdAt,
    this.status = SyncItemStatus.pending,
    this.retryCount = 0,
    this.lastRetryAt,
    this.lastError,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity': entity,
      'operation': operation.name,
      'data': data,
      'priority': priority.name,
      'conflict_resolution': conflictResolution.name,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
      'last_error': lastError,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'],
      entity: json['entity'],
      operation: SyncOperation.values.firstWhere(
        (op) => op.name == json['operation'],
      ),
      data: Map<String, dynamic>.from(json['data']),
      priority: SyncPriority.values.firstWhere(
        (p) => p.name == json['priority'],
      ),
      conflictResolution: ConflictResolution.values.firstWhere(
        (cr) => cr.name == json['conflict_resolution'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      status: SyncItemStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      retryCount: json['retry_count'] ?? 0,
      lastRetryAt: json['last_retry_at'] != null
          ? DateTime.parse(json['last_retry_at'])
          : null,
      lastError: json['last_error'],
    );
  }
}

class SyncStats {
  final int totalPendingItems;
  final int pendingItems;
  final int failedItems;
  final Map<String, DateTime> lastSyncTimes;
  final bool isOnline;
  final SyncStatus syncStatus;
  final bool autoSyncEnabled;

  SyncStats({
    required this.totalPendingItems,
    required this.pendingItems,
    required this.failedItems,
    required this.lastSyncTimes,
    required this.isOnline,
    required this.syncStatus,
    required this.autoSyncEnabled,
  });
}

// Extension for easy sync operations
extension SyncExtension on Map<String, dynamic> {
  Future<void> syncCreate(String entity, {SyncPriority priority = SyncPriority.normal}) async {
    await DataSyncService().addSyncItem(
      id: const Uuid().v4(),
      entity: entity,
      operation: SyncOperation.create,
      data: this,
      priority: priority,
    );
  }

  Future<void> syncUpdate(String entity, String id, {SyncPriority priority = SyncPriority.normal}) async {
    await DataSyncService().addSyncItem(
      id: id,
      entity: entity,
      operation: SyncOperation.update,
      data: this,
      priority: priority,
    );
  }

  Future<void> syncDelete(String entity, String id, {SyncPriority priority = SyncPriority.normal}) async {
    await DataSyncService().addSyncItem(
      id: id,
      entity: entity,
      operation: SyncOperation.delete,
      data: this,
      priority: priority,
    );
  }
}