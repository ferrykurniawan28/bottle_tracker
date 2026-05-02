import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GetStorage _storage = GetStorage();

  static const String _fcmTokenKey = 'fcm_token';

  /// Initialize Firebase Messaging and request permissions
  Future<void> initialize() async {
    // Request notification permissions
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

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'Received foreground notification',
        name: 'NotificationService',
        error: message.notification?.toMap(),
      );
      _handleMessage(message);
    });

    // Handle notification when app is in background and user taps it
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Notification opened', name: 'NotificationService');
      _handleMessage(message);
    });

    // Get initial message if app was launched from notification
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Subscribe to default topics
    await _subscribeToTopics();
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      // Try to get from storage first (cache)
      String? cachedToken = _storage.read(_fcmTokenKey);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        return cachedToken;
      }

      // Get from Firebase
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        // Cache the token
        await _storage.write(_fcmTokenKey, token);
        developer.log('FCM Token: $token', name: 'NotificationService');
      }

      return token;
    } catch (e) {
      developer.log(
        'Error getting FCM token',
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

  /// Subscribe to topics
  Future<void> _subscribeToTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      developer.log(
        'Subscribed to all_users topic',
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

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    developer.log(
      'Message: ${message.notification?.title} - ${message.notification?.body}',
      name: 'NotificationService',
    );

    // Parse the notification data
    String? actionType = message.data['action_type'];
    String? notificationId = message.data['notification_id'];

    developer.log(
      'Action Type: $actionType, Notification ID: $notificationId',
      name: 'NotificationService',
    );

    // Handle based on action type
    _handleNotificationAction(actionType, message.data);
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
        // Will be handled by UI layer
        break;
      case 'usage_check':
        developer.log('Handling usage check', name: 'NotificationService');
        // Will be handled by UI layer
        break;
      case 'admin_alert':
        developer.log('Handling admin alert', name: 'NotificationService');
        // Will be handled by UI layer
        break;
      default:
        developer.log(
          'Unknown action type: $actionType',
          name: 'NotificationService',
        );
    }
  }

  /// Subscribe to user-specific topic
  Future<void> subscribeToUserTopic(int userId) async {
    try {
      String topic = 'user_$userId';
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to $topic', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error subscribing to user topic',
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
}
