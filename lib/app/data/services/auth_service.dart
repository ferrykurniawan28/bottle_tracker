import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'notification_service.dart';
import '../models/user_model.dart';
import '../models/api_respon.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final _storage = GetStorage();
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: URLs.apiBaseUrl,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  UserModel? getCurrentUser() {
    final data = _storage.read<String>(AppConstants.currentUserKey);
    if (data == null) return null;
    return UserModel.fromJsonString(data);
  }

  void setCurrentUser(UserModel? user) {
    if (user == null) {
      _storage.remove(AppConstants.currentUserKey);
    } else {
      _storage.write(AppConstants.currentUserKey, user.toJsonString());
    }
  }

  Future<void> _updateFCMTokenOnBackend(String userId) async {
    try {
      developer.log('Fetching FCM token from Firebase...', name: 'AuthService');
      final fcmToken = await FirebaseMessaging.instance.getToken();
      developer.log(
        'Firebase returned token: ${fcmToken ?? 'NULL'}',
        name: 'AuthService',
      );
      if (fcmToken != null && fcmToken.isNotEmpty) {
        developer.log(
          'Sending token to backend for user: $userId',
          name: 'AuthService',
        );
        final response = await _dio.post(
          '/users/$userId/fcm-token',
          data: {'fcm_token': fcmToken},
        );
        developer.log(
          '✓ Backend response: ${response.statusCode}',
          name: 'AuthService',
        );
        // Cache FCM token locally
        _storage.write('${AppConstants.currentUserKey}_fcm_token', fcmToken);
      } else {
        developer.log('⚠ FCM token is empty/null', name: 'AuthService');
      }
    } catch (e) {
      // Log but don't fail - FCM is non-critical
      developer.log(
        '✗ Could not update FCM token: $e',
        name: 'AuthService',
        error: e,
      );
    }
  }

  Future<void> _subscribeToUserTopic(String userId) async {
    try {
      developer.log(
        'Subscribing user $userId to topic...',
        name: 'AuthService',
      );
      await NotificationService().subscribeToUserTopic(int.parse(userId));
      developer.log('✓ User topic subscription complete', name: 'AuthService');
    } catch (e) {
      developer.log(
        '✗ Could not subscribe to user topic: $e',
        name: 'AuthService',
        error: e,
      );
    }
  }

  Future<({bool success, String message, UserModel? user})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        URLs.registerEndpoint,
        queryParameters: {
          'username': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final user = UserModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
            null,
          );
          setCurrentUser(user);
          // Update FCM token on backend after successful registration
          await _updateFCMTokenOnBackend(user.id.toString());
          await _subscribeToUserTopic(user.id.toString());
          return (
            success: true,
            message: apiResponse.message ?? 'Registration successful',
            user: user,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Registration failed',
            user: null,
          );
        }
      } else {
        return (success: false, message: 'Registration failed', user: null);
      }
    } on DioException catch (e) {
      String message = 'Registration failed';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, user: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', user: null);
    }
  }

  Future<({bool success, String message, UserModel? user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        URLs.loginEndpoint,
        queryParameters: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final user = UserModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
            null,
          );
          // Update FCM token on backend after successful login
          await _updateFCMTokenOnBackend(user.id.toString());
          await _subscribeToUserTopic(user.id.toString());

          setCurrentUser(user);
          return (
            success: true,
            message: apiResponse.message ?? 'Login successful',
            user: user,
          );
        } else {
          return (
            success: false,
            message: apiResponse.error ?? apiResponse.message ?? 'Login failed',
            user: null,
          );
        }
      } else {
        return (success: false, message: 'Login failed', user: null);
      }
    } on DioException catch (e) {
      String message = 'Login failed';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, user: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', user: null);
    }
  }

  // get all users (for admin)
  Future<({bool success, String message, List<UserModel>? users})>
  getAllUsers() async {
    try {
      final response = await _dio.get(URLs.usersEndpoint);

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final usersList = (apiResponse.data as List)
              .map(
                (user) =>
                    UserModel.fromJson(user as Map<String, dynamic>, null),
              )
              .toList();
          return (
            success: true,
            message: apiResponse.message ?? 'Users fetched successfully',
            users: usersList,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch users',
            users: null,
          );
        }
      } else {
        return (success: false, message: 'Failed to fetch users', users: null);
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch users';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, users: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', users: null);
    }
  }

  // delete user by id (for admin)
  Future<({bool success, String message})> deleteUser(String userId) async {
    try {
      final response = await _dio.delete(
        URLs.deleteUserEndpoint.replaceAll('{id}', userId),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success) {
          return (
            success: true,
            message: apiResponse.message ?? 'User deleted successfully',
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to delete user',
          );
        }
      } else {
        return (success: false, message: 'Failed to delete user');
      }
    } on DioException catch (e) {
      String message = 'Failed to delete user';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}');
    }
  }

  void logout() {
    final user = getCurrentUser();
    if (user != null) {
      // Delete FCM token from backend
      try {
        _dio.delete('/users/${user.id}/fcm-token');
      } catch (e) {
        // print('Warning: Could not delete FCM token from backend: $e');
      }

      // Unsubscribe from Firebase topic
      try {
        FirebaseMessaging.instance.unsubscribeFromTopic('user_${user.id}');
      } catch (e) {
        // print('Warning: Could not unsubscribe from FCM topic: $e');
      }
    }

    // Clear local user data
    setCurrentUser(null);
    _storage.remove('${AppConstants.currentUserKey}_fcm_token');
  }
}
