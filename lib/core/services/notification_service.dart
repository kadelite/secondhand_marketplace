import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';

enum NotificationType {
  message,
  orderUpdate,
  paymentUpdate,
  promotion,
  security,
  system,
  reminder,
  social,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Uuid _uuid = const Uuid();

  // Notification Preferences
  Map<NotificationType, bool> _notificationPreferences = {};
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _badgeEnabled = true;
  String _defaultSound = 'default';

  // Notification History
  final List<NotificationData> _notificationHistory = [];

  // Getters
  String? get fcmToken => _fcmToken;
  List<NotificationData> get notificationHistory => _notificationHistory;
  bool get isInitialized => _isInitialized;

  String? _fcmToken;
  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeFirebaseMessaging();
      await _initializeLocalNotifications();
      await _loadNotificationPreferences();
      await _setupNotificationChannels();
      
      _isInitialized = true;
      AppLogger.info('Notification service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize notification service: $e');
    }
  }

  // Firebase Cloud Messaging Setup
  Future<void> _initializeFirebaseMessaging() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      AppLogger.warning('Push notification permission denied');
      return;
    }

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    AppLogger.info('FCM Token: $_fcmToken');

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _uploadTokenToServer(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message clicks
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Handle app launch from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  // Local Notifications Setup
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationClick,
    );
  }

  // Setup notification channels for Android
  Future<void> _setupNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Chat messages and conversations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'orders',
        'Order Updates',
        description: 'Order status and shipping updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'payments',
        'Payment Updates',
        description: 'Payment confirmations and issues',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'promotions',
        'Promotions',
        description: 'Deals and promotional offers',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'security',
        'Security Alerts',
        description: 'Security and account alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'system',
        'System Notifications',
        description: 'App updates and system messages',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Send Local Notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? payload,
    DateTime? scheduledDate,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_shouldShowNotification(type)) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final channelId = _getChannelId(type);
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      playSound: _soundEnabled && _notificationPreferences[type] != false,
      enableVibration: _vibrationEnabled && _notificationPreferences[type] != false,
      icon: _getNotificationIcon(type),
      largeIcon: type == NotificationType.message 
          ? const DrawableResourceAndroidBitmap('@mipmap/ic_launcher')
          : null,
      styleInformation: _getStyleInformation(type, body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationData = NotificationData(
      id: id.toString(),
      title: title,
      body: body,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
      isRead: false,
    );

    _addToHistory(notificationData);

    if (scheduledDate != null) {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(payload ?? {}),
      );
    } else {
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(payload ?? {}),
      );
    }
  }

  // Send Push Notification (Server-side)
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final payload = {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };

    // This would send to your backend service
    await _sendToBackend(payload);
  }

  // Bulk Notifications
  Future<void> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final payload = {
      'user_ids': userIds,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendBulkToBackend(payload);
  }

  // Schedule Notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      type: type,
      payload: payload,
      scheduledDate: scheduledDate,
      priority: priority,
    );
  }

  // Cancel Scheduled Notification
  Future<void> cancelScheduledNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  // Cancel All Notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Notification Preferences
  Future<void> setNotificationEnabled(NotificationType type, bool enabled) async {
    _notificationPreferences[type] = enabled;
    await _saveNotificationPreferences();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveNotificationPreferences();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveNotificationPreferences();
  }

  Future<void> setBadgeEnabled(bool enabled) async {
    _badgeEnabled = enabled;
    await _saveNotificationPreferences();
  }

  bool isNotificationEnabled(NotificationType type) {
    return _notificationPreferences[type] ?? true;
  }

  // Notification History Management
  void markAsRead(String notificationId) {
    final notification = _notificationHistory
        .where((n) => n.id == notificationId)
        .firstOrNull;
    
    if (notification != null) {
      notification.markAsRead();
      _saveNotificationHistory();
    }
  }

  void markAllAsRead() {
    for (final notification in _notificationHistory) {
      notification.markAsRead();
    }
    _saveNotificationHistory();
  }

  void clearHistory() {
    _notificationHistory.clear();
    _saveNotificationHistory();
  }

  int get unreadCount => _notificationHistory.where((n) => !n.isRead).length;

  // Message Handlers
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = _parseNotificationType(message.data['type']);
    
    await showLocalNotification(
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      type: type,
      payload: message.data,
    );
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    final data = message.data;
    await _processNotificationClick(data);
  }

  Future<void> _handleLocalNotificationClick(NotificationResponse response) async {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      await _processNotificationClick(data);
    }
  }

  Future<void> _processNotificationClick(Map<String, dynamic> data) async {
    final type = _parseNotificationType(data['type']);
    final notificationId = data['notification_id'] as String?;
    
    if (notificationId != null) {
      markAsRead(notificationId);
    }

    // Navigate to appropriate screen based on notification type
    switch (type) {
      case NotificationType.message:
        _navigateToChat(data);
        break;
      case NotificationType.orderUpdate:
        _navigateToOrder(data);
        break;
      case NotificationType.paymentUpdate:
        _navigateToPayment(data);
        break;
      case NotificationType.promotion:
        _navigateToPromotion(data);
        break;
      case NotificationType.security:
        _navigateToSecurity(data);
        break;
      default:
        // Navigate to home or appropriate default screen
        break;
    }
  }

  // Helper Methods
  NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.system;
    
    return NotificationType.values
        .where((type) => type.name == typeString)
        .firstOrNull ?? NotificationType.system;
  }

  bool _shouldShowNotification(NotificationType type) {
    return _notificationPreferences[type] ?? true;
  }

  String _getChannelId(NotificationType type) {
    return switch (type) {
      NotificationType.message => 'messages',
      NotificationType.orderUpdate => 'orders',
      NotificationType.paymentUpdate => 'payments',
      NotificationType.promotion => 'promotions',
      NotificationType.security => 'security',
      _ => 'system',
    };
  }

  String _getChannelName(NotificationType type) {
    return switch (type) {
      NotificationType.message => 'Messages',
      NotificationType.orderUpdate => 'Order Updates',
      NotificationType.paymentUpdate => 'Payment Updates',
      NotificationType.promotion => 'Promotions',
      NotificationType.security => 'Security Alerts',
      _ => 'System Notifications',
    };
  }

  String _getChannelDescription(NotificationType type) {
    return switch (type) {
      NotificationType.message => 'Chat messages and conversations',
      NotificationType.orderUpdate => 'Order status and shipping updates',
      NotificationType.paymentUpdate => 'Payment confirmations and issues',
      NotificationType.promotion => 'Deals and promotional offers',
      NotificationType.security => 'Security and account alerts',
      _ => 'App updates and system messages',
    };
  }

  Importance _getImportance(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.urgent => Importance.max,
      NotificationPriority.high => Importance.high,
      NotificationPriority.normal => Importance.defaultImportance,
      NotificationPriority.low => Importance.low,
    };
  }

  Priority _getPriority(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.urgent => Priority.max,
      NotificationPriority.high => Priority.high,
      NotificationPriority.normal => Priority.defaultPriority,
      NotificationPriority.low => Priority.low,
    };
  }

  String? _getNotificationIcon(NotificationType type) {
    return switch (type) {
      NotificationType.message => '@drawable/ic_message',
      NotificationType.orderUpdate => '@drawable/ic_package',
      NotificationType.paymentUpdate => '@drawable/ic_payment',
      NotificationType.promotion => '@drawable/ic_offer',
      NotificationType.security => '@drawable/ic_security',
      _ => null,
    };
  }

  StyleInformation? _getStyleInformation(NotificationType type, String body) {
    if (type == NotificationType.message) {
      return BigTextStyleInformation(body);
    }
    return null;
  }

  void _addToHistory(NotificationData notification) {
    _notificationHistory.insert(0, notification);
    
    // Keep only last 100 notifications
    if (_notificationHistory.length > 100) {
      _notificationHistory.removeLast();
    }
    
    _saveNotificationHistory();
  }

  // Storage Methods
  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final type in NotificationType.values) {
      _notificationPreferences[type] = prefs.getBool('notification_${type.name}') ?? true;
    }
    
    _soundEnabled = prefs.getBool('notification_sound') ?? true;
    _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
    _badgeEnabled = prefs.getBool('notification_badge') ?? true;
    _defaultSound = prefs.getString('notification_default_sound') ?? 'default';
  }

  Future<void> _saveNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final type in NotificationType.values) {
      await prefs.setBool('notification_${type.name}', _notificationPreferences[type] ?? true);
    }
    
    await prefs.setBool('notification_sound', _soundEnabled);
    await prefs.setBool('notification_vibration', _vibrationEnabled);
    await prefs.setBool('notification_badge', _badgeEnabled);
    await prefs.setString('notification_default_sound', _defaultSound);
  }

  Future<void> _saveNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _notificationHistory
        .map((n) => n.toJson())
        .toList();
    await prefs.setString('notification_history', jsonEncode(historyJson));
  }

  // Placeholder methods for backend integration and navigation
  Future<void> _uploadTokenToServer(String token) async {
    // Upload FCM token to your backend
  }

  Future<void> _sendToBackend(Map<String, dynamic> payload) async {
    // Send notification payload to backend service
  }

  Future<void> _sendBulkToBackend(Map<String, dynamic> payload) async {
    // Send bulk notification payload to backend service
  }

  void _navigateToChat(Map<String, dynamic> data) {
    // Navigate to chat screen
  }

  void _navigateToOrder(Map<String, dynamic> data) {
    // Navigate to order details
  }

  void _navigateToPayment(Map<String, dynamic> data) {
    // Navigate to payment screen
  }

  void _navigateToPromotion(Map<String, dynamic> data) {
    // Navigate to promotion details
  }

  void _navigateToSecurity(Map<String, dynamic> data) {
    // Navigate to security settings
  }

  dynamic _convertToTZDateTime(DateTime dateTime) {
    // Convert DateTime to TZDateTime for scheduling
    return dateTime; // Placeholder - implement with timezone package
  }
}

// Data Classes
class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  bool isRead;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    required this.createdAt,
    this.isRead = false,
  });

  void markAsRead() {
    isRead = true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  static NotificationData fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values
          .where((type) => type.name == json['type'])
          .first,
      payload: json['payload'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }
}

// Placeholder for AppLogger
class AppLogger {
  static void info(String message) => print('INFO: $message');
  static void warning(String message) => print('WARNING: $message');
  static void error(String message) => print('ERROR: $message');
}