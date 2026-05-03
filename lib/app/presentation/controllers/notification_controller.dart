import 'package:bottle_tracker/app/data/services/auth_service.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository;
  final NotificationService _notificationService = NotificationService();

  NotificationController(this._repository);

  // Observable states
  RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  RxList<NotificationModel> unreadNotifications = <NotificationModel>[].obs;
  RxInt unreadCount = 0.obs;
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  // Pagination
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;

  int? _currentUserId() {
    final user = AuthService().getCurrentUser();
    if (user == null) return null;
    return int.tryParse(user.id);
  }

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  /// Initialize FCM and setup listeners
  Future<void> _initializeNotifications() async {
    try {
      developer.log(
        'NotificationController._initializeNotifications() called',
        name: 'NotificationController',
      );

      // Initialize FCM
      await _notificationService.initialize();
      developer.log('✓ FCM initialized', name: 'NotificationController');

      // Get and update FCM token
      String? token = await _notificationService.getFCMToken();
      developer.log(
        'Got FCM token: ${token ?? 'NULL'}',
        name: 'NotificationController',
      );

      if (token != null && token.isNotEmpty) {
        final userId = _currentUserId();
        developer.log(
          'Current user ID: $userId',
          name: 'NotificationController',
        );
        if (userId != null) {
          developer.log(
            'Updating FCM token on backend for user: $userId',
            name: 'NotificationController',
          );
          await _repository.updateFCMToken(userId, token);
          developer.log(
            '✓ Token updated on backend',
            name: 'NotificationController',
          );

          // Subscribe to user-specific topic
          await _notificationService.subscribeToUserTopic(userId);
          developer.log(
            '✓ Subscribed to user topic',
            name: 'NotificationController',
          );
        }
      } else {
        developer.log(
          '⚠ Token is empty, skipping backend update',
          name: 'NotificationController',
        );
      }

      // Load initial notifications
      await getNotifications();
      await getUnreadNotificationsCount();
    } catch (e) {
      developer.log(
        '✗ Error initializing notifications: $e',
        name: 'NotificationController',
        error: e,
      );
      error.value = 'Failed to initialize notifications: $e';
    }
  }

  /// Get notifications with pagination
  Future<void> getNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
        notifications.clear();
      }

      if (!_hasMore || isLoading.value) return;

      isLoading.value = true;
      error.value = '';

      final userId = _currentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final newNotifications = await _repository.getNotifications(
        userId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (newNotifications.isEmpty) {
        _hasMore = false;
      } else {
        notifications.addAll(newNotifications);
        _currentPage++;
      }
    } catch (e) {
      error.value = 'Failed to load notifications: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    await getNotifications();
  }

  /// Get unread notifications
  Future<void> getUnreadNotifications() async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = _currentUserId();
      if (userId == null) throw Exception('User not authenticated');

      unreadNotifications.value = await _repository.getUnreadNotifications(
        userId,
      );
    } catch (e) {
      error.value = 'Failed to load unread notifications: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Get unread notification count
  Future<void> getUnreadNotificationsCount() async {
    try {
      final userId = _currentUserId();
      if (userId == null) throw Exception('User not authenticated');

      unreadCount.value = await _repository.getUnreadNotificationCount(userId);
    } catch (e) {
      error.value = 'Failed to get unread count: $e';
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
      }

      await getUnreadNotificationsCount();
    } catch (e) {
      error.value = 'Failed to mark as read: $e';
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _currentUserId();
      if (userId == null) throw Exception('User not authenticated');

      await _repository.markAllNotificationsAsRead(userId);

      // Update local state
      for (var i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }

      unreadCount.value = 0;
    } catch (e) {
      error.value = 'Failed to mark all as read: $e';
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      notifications.removeWhere((n) => n.id == notificationId);
      await getUnreadNotificationsCount();
    } catch (e) {
      error.value = 'Failed to delete notification: $e';
    }
  }

  /// Confirm pickup (YES)
  Future<void> confirmPickupYes(int notificationId) async {
    try {
      await _repository.confirmPickup(notificationId, true);
      // Update notification status locally
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(
          actionStatus: 'confirmed',
        );
      }
    } catch (e) {
      error.value = 'Failed to confirm pickup: $e';
      rethrow;
    }
  }

  /// Deny pickup (NO)
  Future<void> confirmPickupNo(int notificationId) async {
    try {
      await _repository.confirmPickup(notificationId, false);
      // Update notification status locally
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(
          actionStatus: 'unauthorized',
        );
      }
    } catch (e) {
      error.value = 'Failed to deny pickup: $e';
      rethrow;
    }
  }

  /// Confirm still using
  Future<void> confirmStillUsing(int notificationId) async {
    try {
      await _repository.confirmUsage(notificationId, true);
    } catch (e) {
      error.value = 'Failed to confirm usage: $e';
      rethrow;
    }
  }

  /// Confirm done using
  Future<void> confirmDoneUsing(int notificationId) async {
    try {
      await _repository.confirmUsage(notificationId, false);
      // Update notification status
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(
          actionStatus: 'resolved',
        );
      }
    } catch (e) {
      error.value = 'Failed to confirm done: $e';
      rethrow;
    }
  }

  /// Cleanup on logout
  Future<void> logout() async {
    try {
      final userId = _currentUserId();
      if (userId != null) {
        await _repository.deleteFCMToken(userId);
        await _notificationService.unsubscribeFromUserTopic(userId);
        await _notificationService.clearFCMToken();
      }
      notifications.clear();
      unreadNotifications.clear();
      unreadCount.value = 0;
    } catch (e) {
      error.value = 'Error during logout: $e';
    }
  }
}
