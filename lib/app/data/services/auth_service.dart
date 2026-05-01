import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
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
          );
          setCurrentUser(user);
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

        print('Login API Response: ${response.data}');
        print(
          'Parsed ApiRespon: success=${apiResponse.success}, message=${apiResponse.message}, error=${apiResponse.error}',
        );

        if (apiResponse.success && apiResponse.data != null) {
          final user = UserModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
          );
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
      print('DioException: ${e.toString()}');
      return (success: false, message: message, user: null);
    } catch (e) {
      print('Exception: ${e.toString()}');
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
              .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
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
    setCurrentUser(null);
  }
}
