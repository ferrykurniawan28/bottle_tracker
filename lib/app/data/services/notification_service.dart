import 'package:bottle_tracker/app/core/theme/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
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
  late final Dio _dio;
  bool _initialized = false;

  static const String _fcmTokenKey = 'fcm_token';
  static const String _channelId = 'bottly_channel';
  static const String _channelName = 'Bottly Notifications';

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize Dio HTTP client
    _dio = Dio(
      BaseOptions(
        baseUrl: URLs.apiBaseUrl,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

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

    _localNotifications.resolvePlatformSpecificImplementation;
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
        _showPickupConfirmationDialog(data);
        break;
      case 'usage_check':
        developer.log('Handling usage check', name: 'NotificationService');
        _showUsageCheckDialog(data);
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

  /// Confirm pickup (user tapped "Yes" or "No" on notification)
  /// Set [confirmed] to true if user picked it up, false if unauthorized
  Future<({dynamic message, dynamic success})> confirmPickup({
    required int notificationId,
    required bool confirmed,
  }) async {
    try {
      developer.log(
        'Confirming pickup for notification $notificationId: $confirmed',
        name: 'NotificationService',
      );

      final response = await _dio.post(
        '/notifications/$notificationId/confirm-pickup',
        data: {'confirmed': confirmed},
      );

      if (response.statusCode == 200) {
        final success = response.data['success'] ?? true;
        final message = response.data['message'] ?? 'Confirmed';

        developer.log(
          'Pickup confirmation sent: $message',
          name: 'NotificationService',
        );

        return (success: success, message: message);
      }

      return (success: false, message: 'Failed to confirm pickup');
    } catch (e) {
      developer.log(
        'Error confirming pickup: $e',
        name: 'NotificationService',
        error: e,
      );
      return (success: false, message: 'Error: $e');
    }
  }

  /// Confirm usage (user responded to 30-min usage check)
  /// Set [stillUsing] to true if still using bottle, false if done
  Future<({dynamic message, dynamic success})> confirmUsage({
    required int notificationId,
    required bool stillUsing,
  }) async {
    try {
      developer.log(
        'Confirming usage for notification $notificationId: still_using=$stillUsing',
        name: 'NotificationService',
      );

      final response = await _dio.post(
        '/notifications/$notificationId/confirm-usage',
        data: {'still_using': stillUsing},
      );

      if (response.statusCode == 200) {
        final success = response.data['success'] ?? true;
        final message = response.data['message'] ?? 'Confirmed';

        developer.log(
          'Usage confirmation sent: $message',
          name: 'NotificationService',
        );

        return (success: success, message: message);
      }

      return (success: false, message: 'Failed to confirm usage');
    } catch (e) {
      developer.log(
        'Error confirming usage: $e',
        name: 'NotificationService',
        error: e,
      );
      return (success: false, message: 'Error: $e');
    }
  }

  /// Show pickup confirmation dialog (called when notification is tapped)
  void _showPickupConfirmationDialog(Map<String, dynamic> data) {
    try {
      final notificationId = int.tryParse(data['notification_id'] ?? '');
      final bottleName = data.containsKey('data')
          ? _extractFromJsonData(data['data'], 'bottle_name')
          : 'your bottle';

      if (notificationId == null) {
        developer.log(
          'Could not extract notification ID from data',
          name: 'NotificationService',
        );
        return;
      }

      Get.dialog(
        AlertDialog(
          title: const Text('Pickup Confirmation'),
          content: Text('Did you pick up $bottleName?'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _confirmPickupAndClose(notificationId, false);
              },
              child: const Text('No', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _confirmPickupAndClose(notificationId, true);
              },
              child: const Text('Yes', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      developer.log(
        'Error showing pickup confirmation dialog: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Show usage check dialog (called when notification is tapped)
  void _showUsageCheckDialog(Map<String, dynamic> data) {
    try {
      final notificationId = int.tryParse(data['notification_id'] ?? '');
      final bottleName = data.containsKey('data')
          ? _extractFromJsonData(data['data'], 'bottle_name')
          : 'your bottle';

      if (notificationId == null) {
        developer.log(
          'Could not extract notification ID from data',
          name: 'NotificationService',
        );
        return;
      }

      Get.dialog(
        AlertDialog(
          title: const Text('Still Using?'),
          content: Text('Are you still using $bottleName?'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _confirmUsageAndClose(notificationId, false);
              },
              child: const Text('Done', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _confirmUsageAndClose(notificationId, true);
              },
              child: Text(
                'Still Using',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      developer.log(
        'Error showing usage check dialog: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Extract value from JSON string data
  String _extractFromJsonData(String jsonStr, String key) {
    try {
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        (jsonStr as dynamic),
      );
      return map[key]?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Confirm pickup and close dialog
  Future<void> _confirmPickupAndClose(
    int notificationId,
    bool confirmed,
  ) async {
    try {
      developer.log(
        'User responded to pickup confirmation: $confirmed',
        name: 'NotificationService',
      );
      final result = await confirmPickup(
        notificationId: notificationId,
        confirmed: confirmed,
      );

      Get.snackbar(
        'Success',
        result.message as String,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      developer.log(
        'Error in pickup confirmation: $e',
        name: 'NotificationService',
        error: e,
      );
      Get.snackbar('Error', 'Failed to confirm pickup');
    }
  }

  /// Confirm usage and close dialog
  Future<void> _confirmUsageAndClose(
    int notificationId,
    bool stillUsing,
  ) async {
    try {
      developer.log(
        'User responded to usage check: $stillUsing',
        name: 'NotificationService',
      );
      final result = await confirmUsage(
        notificationId: notificationId,
        stillUsing: stillUsing,
      );

      Get.snackbar(
        'Success',
        result.message as String,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      developer.log(
        'Error in usage confirmation: $e',
        name: 'NotificationService',
        error: e,
      );
      Get.snackbar('Error', 'Failed to confirm usage');
    }
  }
}
