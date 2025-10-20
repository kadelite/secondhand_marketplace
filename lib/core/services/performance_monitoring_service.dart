import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum EventType {
  screenView,
  userAction,
  error,
  performance,
  business,
  crash,
  conversion,
}

enum PerformanceMetricType {
  appStartup,
  screenLoad,
  apiCall,
  database,
  imageLoad,
  networkRequest,
  customTimer,
}

enum CrashSeverity {
  low,
  medium,
  high,
  critical,
}

enum UserSegment {
  newUser,
  returningUser,
  activeUser,
  premiumUser,
  powerSeller,
  frequentBuyer,
}

class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  final Uuid _uuid = const Uuid();
  
  // Analytics Data
  final List<AnalyticsEvent> _eventQueue = [];
  final Map<String, int> _screenViews = {};
  final Map<String, Duration> _sessionDurations = {};
  
  // Performance Data
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  final List<CrashReport> _crashReports = [];
  final Map<String, AppUsageStats> _usageStats = {};
  
  // Session Management
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  DateTime? _appStartTime;
  
  // Device Information
  DeviceInfo? _deviceInfo;
  PackageInfo? _packageInfo;
  
  // Configuration
  bool _isEnabled = true;
  bool _crashReportingEnabled = true;
  bool _performanceTrackingEnabled = true;
  int _maxEventQueueSize = 1000;
  Duration _flushInterval = const Duration(minutes: 5);
  
  Timer? _flushTimer;

  // Initialize the service
  Future<void> initialize({
    bool enabled = true,
    bool crashReporting = true,
    bool performanceTracking = true,
    int maxEventQueueSize = 1000,
    Duration flushInterval = const Duration(minutes: 5),
  }) async {
    _isEnabled = enabled;
    _crashReportingEnabled = crashReporting;
    _performanceTrackingEnabled = performanceTracking;
    _maxEventQueueSize = maxEventQueueSize;
    _flushInterval = flushInterval;
    
    if (!_isEnabled) return;

    await _loadDeviceInfo();
    await _loadPackageInfo();
    await _startNewSession();
    
    _setupCrashHandling();
    _startPeriodicFlush();
    
    _appStartTime = DateTime.now();
    await trackEvent('app_started', EventType.performance, {
      'app_version': _packageInfo?.version,
      'build_number': _packageInfo?.buildNumber,
      'platform': Platform.operatingSystem,
    });
  }

  // Session Management
  Future<void> _startNewSession() async {
    _currentSessionId = _uuid.v4();
    _sessionStartTime = DateTime.now();
    
    await trackEvent('session_started', EventType.userAction, {
      'session_id': _currentSessionId,
    });
  }

  Future<void> endSession() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;
    
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    _sessionDurations[_currentSessionId!] = sessionDuration;
    
    await trackEvent('session_ended', EventType.userAction, {
      'session_id': _currentSessionId,
      'duration_ms': sessionDuration.inMilliseconds,
    });
    
    _currentSessionId = null;
    _sessionStartTime = null;
  }

  // Analytics Event Tracking
  Future<void> trackEvent(
    String eventName,
    EventType type, [
    Map<String, dynamic>? parameters,
  ]) async {
    if (!_isEnabled) return;

    final event = AnalyticsEvent(
      id: _uuid.v4(),
      name: eventName,
      type: type,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
      sessionId: _currentSessionId,
      userId: await _getCurrentUserId(),
    );

    _eventQueue.add(event);
    
    if (_eventQueue.length >= _maxEventQueueSize) {
      await _flushEvents();
    }
  }

  Future<void> trackScreenView(String screenName, [Map<String, dynamic>? parameters]) async {
    _screenViews[screenName] = (_screenViews[screenName] ?? 0) + 1;
    
    await trackEvent('screen_view', EventType.screenView, {
      'screen_name': screenName,
      'view_count': _screenViews[screenName],
      ...?parameters,
    });
  }

  Future<void> trackUserAction(String action, [Map<String, dynamic>? parameters]) async {
    await trackEvent(action, EventType.userAction, parameters);
  }

  Future<void> trackBusinessEvent(String event, [Map<String, dynamic>? parameters]) async {
    await trackEvent(event, EventType.business, parameters);
  }

  Future<void> trackConversion(String conversionType, double value, [Map<String, dynamic>? parameters]) async {
    await trackEvent('conversion', EventType.conversion, {
      'conversion_type': conversionType,
      'value': value,
      'currency': 'USD',
      ...?parameters,
    });
  }

  // Performance Monitoring
  Future<void> startPerformanceTimer(String timerName, PerformanceMetricType type) async {
    if (!_performanceTrackingEnabled) return;

    final metric = PerformanceMetric(
      id: _uuid.v4(),
      name: timerName,
      type: type,
      startTime: DateTime.now(),
      sessionId: _currentSessionId,
    );

    _performanceMetrics[timerName] = metric;
  }

  Future<void> endPerformanceTimer(String timerName, [Map<String, dynamic>? additionalData]) async {
    if (!_performanceTrackingEnabled) return;

    final metric = _performanceMetrics[timerName];
    if (metric == null) return;

    metric.endTime = DateTime.now();
    metric.duration = metric.endTime!.difference(metric.startTime);
    metric.additionalData = additionalData ?? {};

    await trackEvent('performance_metric', EventType.performance, {
      'metric_name': timerName,
      'metric_type': metric.type.name,
      'duration_ms': metric.duration!.inMilliseconds,
      'additional_data': metric.additionalData,
    });

    _performanceMetrics.remove(timerName);
  }

  Future<void> trackApiCall(String endpoint, String method, int statusCode, Duration duration) async {
    await trackEvent('api_call', EventType.performance, {
      'endpoint': endpoint,
      'method': method,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'success': statusCode >= 200 && statusCode < 300,
    });
  }

  Future<void> trackMemoryUsage() async {
    // Note: Memory tracking would require platform channels or specific plugins
    await trackEvent('memory_usage', EventType.performance, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Error and Crash Reporting
  Future<void> trackError(dynamic error, StackTrace? stackTrace, [Map<String, dynamic>? context]) async {
    final errorEvent = ErrorEvent(
      id: _uuid.v4(),
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context ?? {},
      timestamp: DateTime.now(),
      sessionId: _currentSessionId,
      userId: await _getCurrentUserId(),
    );

    await trackEvent('error', EventType.error, {
      'error_message': errorEvent.message,
      'has_stack_trace': stackTrace != null,
      'context': errorEvent.context,
    });
  }

  Future<void> trackCrash(dynamic error, StackTrace stackTrace, CrashSeverity severity, [Map<String, dynamic>? context]) async {
    if (!_crashReportingEnabled) return;

    final crashReport = CrashReport(
      id: _uuid.v4(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      severity: severity,
      context: context ?? {},
      timestamp: DateTime.now(),
      sessionId: _currentSessionId,
      userId: await _getCurrentUserId(),
      deviceInfo: _deviceInfo,
      appInfo: _packageInfo,
    );

    _crashReports.add(crashReport);

    await trackEvent('crash', EventType.crash, {
      'crash_id': crashReport.id,
      'severity': severity.name,
      'error_message': error.toString(),
      'context': context,
    });

    // Immediately flush crash reports
    await _flushCrashReports();
  }

  void _setupCrashHandling() {
    if (!_crashReportingEnabled) return;

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) async {
      await trackCrash(
        details.exception,
        details.stack ?? StackTrace.current,
        CrashSeverity.high,
        {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };

    // Set up Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      trackCrash(error, stack, CrashSeverity.critical);
      return true;
    };
  }

  // User Analytics
  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_user_id', userId);
    
    await trackEvent('user_identified', EventType.userAction, {
      'user_id': userId,
    });
  }

  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await trackEvent('user_properties_updated', EventType.userAction, properties);
  }

  Future<void> trackUserSegment(UserSegment segment) async {
    await trackEvent('user_segment', EventType.userAction, {
      'segment': segment.name,
    });
  }

  // App Usage Statistics
  Future<void> updateUsageStats(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (!_usageStats.containsKey(userId)) {
      _usageStats[userId] = AppUsageStats(
        userId: userId,
        dailyUsage: {},
        totalSessions: 0,
        totalTimeSpent: Duration.zero,
        lastActiveDate: DateTime.now(),
      );
    }

    final stats = _usageStats[userId]!;
    stats.dailyUsage[today] = (stats.dailyUsage[today] ?? 0) + 1;
    stats.totalSessions++;
    stats.lastActiveDate = DateTime.now();
    
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      stats.totalTimeSpent = stats.totalTimeSpent + sessionDuration;
    }
  }

  Future<AppUsageStats?> getUserStats(String userId) async {
    return _usageStats[userId];
  }

  // Custom Metrics
  Future<void> trackCustomMetric(String metricName, double value, [Map<String, dynamic>? attributes]) async {
    await trackEvent('custom_metric', EventType.performance, {
      'metric_name': metricName,
      'value': value,
      'attributes': attributes ?? {},
    });
  }

  // A/B Testing Support
  Future<void> trackExperiment(String experimentName, String variant, [Map<String, dynamic>? parameters]) async {
    await trackEvent('experiment_exposure', EventType.userAction, {
      'experiment_name': experimentName,
      'variant': variant,
      ...?parameters,
    });
  }

  // Funnel Analysis
  Future<void> trackFunnelStep(String funnelName, String stepName, [Map<String, dynamic>? parameters]) async {
    await trackEvent('funnel_step', EventType.business, {
      'funnel_name': funnelName,
      'step_name': stepName,
      ...?parameters,
    });
  }

  // Revenue Tracking
  Future<void> trackRevenue(double amount, String currency, String source, [Map<String, dynamic>? parameters]) async {
    await trackEvent('revenue', EventType.business, {
      'amount': amount,
      'currency': currency,
      'source': source,
      ...?parameters,
    });
  }

  // Data Export and Reporting
  Future<Map<String, dynamic>> getAnalyticsReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final relevantEvents = _eventQueue.where((event) {
      return event.timestamp.isAfter(start) && event.timestamp.isBefore(end);
    }).toList();

    return {
      'period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
      'total_events': relevantEvents.length,
      'events_by_type': _groupEventsByType(relevantEvents),
      'screen_views': Map.from(_screenViews),
      'session_data': _getSessionAnalytics(),
      'crash_count': _crashReports.length,
      'performance_summary': _getPerformanceSummary(),
    };
  }

  Future<List<AnalyticsEvent>> getEvents({
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    var events = List<AnalyticsEvent>.from(_eventQueue);

    if (type != null) {
      events = events.where((e) => e.type == type).toList();
    }

    if (startDate != null) {
      events = events.where((e) => e.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      events = events.where((e) => e.timestamp.isBefore(endDate)).toList();
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && events.length > limit) {
      events = events.take(limit).toList();
    }

    return events;
  }

  // Data Persistence and Sync
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    // In a real implementation, this would send data to your analytics backend
    final eventsToFlush = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    await _persistEvents(eventsToFlush);
  }

  Future<void> _flushCrashReports() async {
    if (_crashReports.isEmpty) return;

    // In a real implementation, this would send crash reports to your backend
    await _persistCrashReports(List<CrashReport>.from(_crashReports));
    _crashReports.clear();
  }

  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) async {
      await _flushEvents();
    });
  }

  // Private Helper Methods
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('analytics_user_id');
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      _deviceInfo = DeviceInfo(
        platform: 'Android',
        model: androidInfo.model,
        version: androidInfo.version.release,
        manufacturer: androidInfo.manufacturer,
        isPhysicalDevice: androidInfo.isPhysicalDevice,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      _deviceInfo = DeviceInfo(
        platform: 'iOS',
        model: iosInfo.model,
        version: iosInfo.systemVersion,
        manufacturer: 'Apple',
        isPhysicalDevice: iosInfo.isPhysicalDevice,
      );
    }
  }

  Future<void> _loadPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  Map<String, int> _groupEventsByType(List<AnalyticsEvent> events) {
    final Map<String, int> grouped = {};
    for (final event in events) {
      grouped[event.type.name] = (grouped[event.type.name] ?? 0) + 1;
    }
    return grouped;
  }

  Map<String, dynamic> _getSessionAnalytics() {
    return {
      'total_sessions': _sessionDurations.length,
      'average_session_duration': _sessionDurations.values.isEmpty
          ? 0
          : _sessionDurations.values
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a + b) / _sessionDurations.length,
      'current_session_id': _currentSessionId,
    };
  }

  Map<String, dynamic> _getPerformanceSummary() {
    // This would include aggregated performance metrics
    return {
      'active_timers': _performanceMetrics.length,
      'app_uptime_ms': _appStartTime != null 
          ? DateTime.now().difference(_appStartTime!).inMilliseconds
          : 0,
    };
  }

  Future<void> _persistEvents(List<AnalyticsEvent> events) async {
    // Implementation would save events to local storage or send to backend
  }

  Future<void> _persistCrashReports(List<CrashReport> reports) async {
    // Implementation would save crash reports or send to crash reporting service
  }

  // Cleanup
  void dispose() {
    _flushTimer?.cancel();
    endSession();
    _flushEvents();
    _flushCrashReports();
  }
}

// Data Classes
class AnalyticsEvent {
  final String id;
  final String name;
  final EventType type;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? sessionId;
  final String? userId;

  AnalyticsEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.parameters,
    required this.timestamp,
    this.sessionId,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId,
      'user_id': userId,
    };
  }
}

class PerformanceMetric {
  final String id;
  final String name;
  final PerformanceMetricType type;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  Map<String, dynamic>? additionalData;
  final String? sessionId;

  PerformanceMetric({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    this.endTime,
    this.duration,
    this.additionalData,
    this.sessionId,
  });
}

class ErrorEvent {
  final String id;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic> context;
  final DateTime timestamp;
  final String? sessionId;
  final String? userId;

  ErrorEvent({
    required this.id,
    required this.message,
    this.stackTrace,
    required this.context,
    required this.timestamp,
    this.sessionId,
    this.userId,
  });
}

class CrashReport {
  final String id;
  final String error;
  final String stackTrace;
  final CrashSeverity severity;
  final Map<String, dynamic> context;
  final DateTime timestamp;
  final String? sessionId;
  final String? userId;
  final DeviceInfo? deviceInfo;
  final PackageInfo? appInfo;

  CrashReport({
    required this.id,
    required this.error,
    required this.stackTrace,
    required this.severity,
    required this.context,
    required this.timestamp,
    this.sessionId,
    this.userId,
    this.deviceInfo,
    this.appInfo,
  });
}

class DeviceInfo {
  final String platform;
  final String model;
  final String version;
  final String manufacturer;
  final bool isPhysicalDevice;

  DeviceInfo({
    required this.platform,
    required this.model,
    required this.version,
    required this.manufacturer,
    required this.isPhysicalDevice,
  });
}

class AppUsageStats {
  final String userId;
  final Map<String, int> dailyUsage; // Date -> session count
  int totalSessions;
  Duration totalTimeSpent;
  DateTime lastActiveDate;

  AppUsageStats({
    required this.userId,
    required this.dailyUsage,
    required this.totalSessions,
    required this.totalTimeSpent,
    required this.lastActiveDate,
  });
}