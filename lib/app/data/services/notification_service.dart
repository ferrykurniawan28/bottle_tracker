import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final GetStorage _storage = GetStorage();
  bool _initialized = false;

  static const String _fcmTokenKey = 'fcm_token';
  static const String _channelId = 'bottly_channel';
  static const String _channelName = 'Bottly Notifications';

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log(
          'Local notification tapped: ${response.payload}',
          name: 'NotificationService',
        );
        _handleNotificationPayload(response.payload);
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Bottly app notifications',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications.resolvePlatformSpecificImplementation;
    AndroidFlutterLocalNotificationsPlugin()?.createNotificationChannel(
      androidChannel,
    );

    developer.log(
      '✓ Local notifications initialized',
      name: 'NotificationService',
    );

    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    developer.log(
      'User granted permission: ${settings.authorizationStatus}',
      name: 'NotificationService',
    );

    // Show notifications while app is in foreground (iOS)
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '✓ RECEIVED FOREGROUND NOTIFICATION',
        name: 'NotificationService',
      );
      developer.log(
        'Title: ${message.notification?.title}',
        name: 'NotificationService',
      );
      developer.log(
        'Body: ${message.notification?.body}',
        name: 'NotificationService',
      );
      developer.log('Data: ${message.data}', name: 'NotificationService');

      // Show local notification popup (required for Android foreground)
      _showLocalNotification(message);
      _handleMessage(message);
    });

    // App was in background and user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '✓ Notification opened from background',
        name: 'NotificationService',
      );
      _handleMessage(message);
    });

    // App was fully killed and opened via notification
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        '✓ App launched from terminated state via notification',
        name: 'NotificationService',
      );
      _handleMessage(initialMessage);
    }

    // Listen for token refresh and update backend
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      developer.log('FCM token refreshed', name: 'NotificationService');
      await _storage.write(_fcmTokenKey, newToken);
      // Notify listeners so AuthService can push the new token to backend
      onTokenRefresh?.call(newToken);
    });

    await _subscribeToTopics();

    _initialized = true;
    developer.log(
      '✓ NotificationService fully initialized',
      name: 'NotificationService',
    );
  }

  /// Optional callback when FCM token refreshes — set this from AuthService
  Function(String token)? onTokenRefresh;

  /// Show a visible local notification (required for Android foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Bottly app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use DateTime milliseconds instead of hashCode to avoid null int error
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      id: notificationId,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Get FCM token (from cache first, then Firebase)
  Future<String?> getFCMToken() async {
    try {
      String? cachedToken = _storage.read(_fcmTokenKey);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        developer.log('Got cached FCM token', name: 'NotificationService');
        return cachedToken;
      }

      developer.log(
        'Fetching FCM token from Firebase...',
        name: 'NotificationService',
      );
      String? token = await _firebaseMessaging.getToken();

      developer.log(
        'Firebase returned token: ${token != null ? 'OK' : 'NULL'}',
        name: 'NotificationService',
      );

      if (token != null && token.isNotEmpty) {
        await _storage.write(_fcmTokenKey, token);
        developer.log('✓ FCM token cached', name: 'NotificationService');
      } else {
        developer.log(
          '⚠ Firebase returned empty/null token',
          name: 'NotificationService',
        );
      }

      return token;
    } catch (e) {
      developer.log(
        '✗ Error getting FCM token: $e',
        name: 'NotificationService',
        error: e,
      );
      return null;
    }
  }

  /// Clear FCM token (call on logout)
  Future<void> clearFCMToken() async {
    try {
      await _storage.remove(_fcmTokenKey);
      developer.log('FCM token cleared', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error clearing FCM token',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Subscribe to default topics
  Future<void> _subscribeToTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      developer.log(
        '✓ Subscribed to all_users topic',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error subscribing to topic',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Subscribe to user-specific topic
  Future<void> subscribeToUserTopic(int userId) async {
    try {
      String topic = 'user_$userId';
      developer.log(
        'Subscribing to topic: $topic',
        name: 'NotificationService',
      );
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('✓ Subscribed to $topic', name: 'NotificationService');
    } catch (e) {
      developer.log(
        '✗ Error subscribing to user topic: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Unsubscribe from user-specific topic
  Future<void> unsubscribeFromUserTopic(int userId) async {
    try {
      String topic = 'user_$userId';
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from $topic', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error unsubscribing from user topic',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Handle incoming FCM messages
  void _handleMessage(RemoteMessage message) {
    developer.log(
      'Handling message: ${message.notification?.title}',
      name: 'NotificationService',
    );

    String? actionType = message.data['action_type'];
    String? notificationId = message.data['notification_id'];

    developer.log(
      'Action: $actionType, ID: $notificationId',
      name: 'NotificationService',
    );

    _handleNotificationAction(actionType, message.data);
  }

  /// Handle local notification tap payload
  void _handleNotificationPayload(String? payload) {
    if (payload == null) return;
    developer.log(
      'Notification payload tapped: $payload',
      name: 'NotificationService',
    );
    // Add navigation logic here if needed
  }

  /// Handle notification based on action type
  void _handleNotificationAction(
    String? actionType,
    Map<String, dynamic> data,
  ) {
    switch (actionType) {
      case 'pickup_confirmation':
        developer.log(
          'Handling pickup confirmation',
          name: 'NotificationService',
        );
        break;
      case 'usage_check':
        developer.log('Handling usage check', name: 'NotificationService');
        break;
      case 'admin_alert':
        developer.log('Handling admin alert', name: 'NotificationService');
        break;
      default:
        developer.log(
          'Unknown action type: $actionType',
          name: 'NotificationService',
        );
    }
  }
}
