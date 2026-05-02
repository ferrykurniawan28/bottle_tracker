import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final Dio _dio;
  final String _baseUrl;

  NotificationRepository(this._dio, {required String baseUrl})
    : _baseUrl = baseUrl;

  /// Get all notifications for user
  Future<List<NotificationModel>> getNotifications(
    int userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users/$userId/notifications',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data['data'] as List;
      return data
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications(
    int userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users/$userId/notifications/unread',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data['data'] as List;
      return data
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(int userId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users/$userId/notifications/unread/count',
      );
      return response.data['data']['unread_count'] ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _dio.put('$_baseUrl/notifications/$notificationId/read');
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(int userId) async {
    try {
      await _dio.put('$_baseUrl/users/$userId/notifications/read-all');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _dio.delete('$_baseUrl/notifications/$notificationId');
    } catch (e) {
      rethrow;
    }
  }

  /// Confirm pickup (YES/NO)
  Future<void> confirmPickup(int notificationId, bool confirmed) async {
    try {
      await _dio.post(
        '$_baseUrl/notifications/$notificationId/confirm-pickup',
        data: {'confirmed': confirmed},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Confirm usage (still using/done)
  Future<void> confirmUsage(int notificationId, bool stillUsing) async {
    try {
      await _dio.post(
        '$_baseUrl/notifications/$notificationId/confirm-usage',
        data: {'still_using': stillUsing},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update FCM token
  Future<void> updateFCMToken(int userId, String fcmToken) async {
    try {
      await _dio.post(
        '$_baseUrl/users/$userId/fcm-token',
        data: {'fcm_token': fcmToken},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete FCM token (logout)
  Future<void> deleteFCMToken(int userId) async {
    try {
      await _dio.delete('$_baseUrl/users/$userId/fcm-token');
    } catch (e) {
      rethrow;
    }
  }
}
