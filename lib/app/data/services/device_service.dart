import 'package:dio/dio.dart';
import '../models/device_model.dart';
import '../models/api_respon.dart';
import '../../core/constants/app_constants.dart';

class DeviceService {
  late final Dio _dio;

  DeviceService() {
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

  // Get all devices
  Future<({bool success, String message, List<DeviceModel>? devices})>
  getAllDevices() async {
    try {
      final response = await _dio.get('/devices');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final devicesList = (apiResponse.data as List)
              .map(
                (device) =>
                    DeviceModel.fromJson(device as Map<String, dynamic>),
              )
              .toList();
          return (
            success: true,
            message: apiResponse.message ?? 'Devices fetched successfully',
            devices: devicesList,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch devices',
            devices: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to fetch devices',
          devices: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch devices';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, devices: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', devices: null);
    }
  }

  // Create device
  Future<({bool success, String message, DeviceModel? device})>
  createDevice() async {
    try {
      final response = await _dio.post('/device/create');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final device = DeviceModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
          );
          return (
            success: true,
            message: apiResponse.message ?? 'Device created successfully',
            device: device,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to create device',
            device: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to create device',
          device: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to create device';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, device: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', device: null);
    }
  }

  // Get device by UID
  Future<({bool success, String message, DeviceModel? device})> getDeviceByUID(
    String uid,
  ) async {
    try {
      final response = await _dio.get('/device/$uid');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final device = DeviceModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
          );
          return (
            success: true,
            message: apiResponse.message ?? 'Device fetched successfully',
            device: device,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch device',
            device: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to fetch device',
          device: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch device';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, device: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', device: null);
    }
  }

  // Update device usage (toggle is_used)
  Future<({bool success, String message, bool? isUsed})> updateDeviceUsage(
    int deviceId,
  ) async {
    try {
      final response = await _dio.put('/device/$deviceId');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final isUsed = apiResponse.data['is_used'] as bool;
          return (
            success: true,
            message: apiResponse.message ?? 'Device usage updated successfully',
            isUsed: isUsed,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to update device',
            isUsed: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to update device',
          isUsed: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to update device';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, isUsed: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', isUsed: null);
    }
  }

  // Delete device by ID
  Future<({bool success, String message})> deleteDevice(int deviceId) async {
    try {
      final response = await _dio.delete('/device/$deviceId');

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
            message: apiResponse.message ?? 'Device deleted successfully',
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to delete device',
          );
        }
      } else {
        return (success: false, message: 'Failed to delete device');
      }
    } on DioException catch (e) {
      String message = 'Failed to delete device';
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

  // get count of devices
  Future<({bool success, String message, int? count})> getDeviceCount() async {
    try {
      final response = await _dio.get('/devices/count');
      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final count = apiResponse.data['count'] as int;
          return (
            success: true,
            message: apiResponse.message ?? 'Device count fetched successfully',
            count: count,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch device count',
            count: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to fetch device count',
          count: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch device count';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, count: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', count: null);
    }
  }

  // get count unused devices
  Future<({bool success, String message, int? count})>
  getUnusedDeviceCount() async {
    try {
      final response = await _dio.get('/devices/count/unused');
      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );
        if (apiResponse.success && apiResponse.data != null) {
          final count = apiResponse.data['count'] as int;
          return (
            success: true,
            message:
                apiResponse.message ??
                'Unused device count fetched successfully',
            count: count,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch unused device count',
            count: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to fetch unused device count',
          count: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch unused device count';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, count: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', count: null);
    }
  }
}
