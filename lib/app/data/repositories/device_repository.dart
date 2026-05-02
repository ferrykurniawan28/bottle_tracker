import 'package:dio/dio.dart';
import '../models/device_model.dart';
import '../../core/constants/app_constants.dart';

class DeviceRepository {
  final Dio _dio;
  final String _baseUrl;

  DeviceRepository(this._dio, {String? baseUrl})
    : _baseUrl = baseUrl ?? URLs.apiBaseUrl;

  Future<List<DeviceModel>> getDevices({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/devices',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map(
              (device) => DeviceModel.fromJson(device as Map<String, dynamic>),
            )
            .toList();
      }
      throw Exception('Failed to fetch devices');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DeviceModel> getDeviceByUID(String uid) async {
    try {
      final response = await _dio.get('/device/$uid');

      if (response.statusCode == 200) {
        _baseUrl;
        return DeviceModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Device not found');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<DeviceModel> toggleDevice(int deviceId) async {
    try {
      final response = await _dio.put('$_baseUrl/device/$deviceId');

      if (response.statusCode == 200) {
        return DeviceModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to toggle device');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> deleteDevice(int deviceId) async {
    try {
      final response = await _dio.delete('$_baseUrl/device/$deviceId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete device');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<int> getDeviceCount() async {
    try {
      final response = await _dio.get('$_baseUrl/devices/count');

      if (response.statusCode == 200) {
        return response.data['data']['count'] as int;
      }
      throw Exception('Failed to fetch device count');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<int> getUnusedDeviceCount() async {
    try {
      final response = await _dio.get('$_baseUrl/devices/count/unused');

      if (response.statusCode == 200) {
        return response.data['data']['count'] as int;
      }
      throw Exception('Failed to fetch unused device count');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
