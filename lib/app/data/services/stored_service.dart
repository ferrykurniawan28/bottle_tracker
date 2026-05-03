import 'package:dio/dio.dart';
import '../models/stored_model.dart';
import '../models/stored_weight_history_model.dart';
import '../models/api_respon.dart';
import '../../core/constants/app_constants.dart';

class StoredService {
  late final Dio _dio;

  StoredService() {
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

  // Get stored by id
  Future<({bool success, String message, StoredModel? stored})> getStoredById(
    int storedId,
  ) async {
    try {
      final response = await _dio.get('/stored/$storedId');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final stored = StoredModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
          );
          return (
            success: true,
            message: apiResponse.message ?? 'Stored fetched successfully',
            stored: stored,
          );
        }

        return (
          success: false,
          message:
              apiResponse.error ??
              apiResponse.message ??
              'Failed to fetch stored',
          stored: null,
        );
      }

      return (success: false, message: 'Failed to fetch stored', stored: null);
    } on DioException catch (e) {
      String message = 'Failed to fetch stored';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, stored: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', stored: null);
    }
  }

  // Create stored bottle
  Future<({bool success, String message, StoredModel? stored})> createStored({
    required String deviceUid,
    required String ownerUid,
    required String bottleName,
    required String brand,
    required String category,
    double? weight,
  }) async {
    try {
      final response = await _dio.post(
        '/stored/create',
        queryParameters: {
          'device_uid': deviceUid,
          'owner_uid': ownerUid,
          'bottle_name': bottleName,
          'brand': brand,
          'category': category,
          if (weight != null) 'weight': weight.toString(),
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
          final stored = StoredModel.fromJson(
            apiResponse.data as Map<String, dynamic>,
          );
          return (
            success: true,
            message: apiResponse.message ?? 'Stored created successfully',
            stored: stored,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to create stored',
            stored: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to create stored',
          stored: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to create stored';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, stored: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', stored: null);
    }
  }

  // Get stored weight history by stored id
  Future<
    ({
      bool success,
      String message,
      StoredModel? stored,
      List<StoredWeightHistoryModel>? history,
    })
  >
  getWeightHistoryByStoredId(int storedId) async {
    try {
      final response = await _dio.get(
        '/stored/$storedId/weight-history/details',
      );

      print('Response data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          // Extract stored and history from data
          final storedData =
              apiResponse.data['stored'] as Map<String, dynamic>?;
          final historyListData = apiResponse.data['history'] as List?;

          StoredModel? stored;
          if (storedData != null) {
            stored = StoredModel.fromJson(storedData);
          }

          List<StoredWeightHistoryModel>? history;
          if (historyListData != null) {
            history = historyListData
                .map(
                  (item) => StoredWeightHistoryModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }

          return (
            success: true,
            message:
                apiResponse.message ??
                'Stored weight history with details fetched successfully',
            stored: stored,
            history: history,
          );
        }

        return (
          success: false,
          message:
              apiResponse.error ??
              apiResponse.message ??
              'Failed to fetch stored weight history',
          stored: null,
          history: null,
        );
      }

      return (
        success: false,
        message: 'Failed to fetch stored weight history',
        stored: null,
        history: null,
      );
    } on DioException catch (e) {
      String message = 'Failed to fetch stored weight history';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, stored: null, history: null);
    } catch (e) {
      return (
        success: false,
        message: 'Error: ${e.toString()}',
        stored: null,
        history: null,
      );
    }
  }

  // Get stored by owner
  Future<({bool success, String message, List<StoredModel>? stored})>
  getStoredByOwner(String ownerId) async {
    try {
      final response = await _dio.get('/stored/list/$ownerId');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final storedList = (apiResponse.data as List)
              .map((item) => StoredModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return (
            success: true,
            message: apiResponse.message ?? 'Stored items fetched successfully',
            stored: storedList,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch stored items',
            stored: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to fetch stored items',
          stored: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch stored items';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, stored: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', stored: null);
    }
  }

  // Get all stored
  Future<({bool success, String message, List<StoredModel>? stored})>
  getAllStored() async {
    try {
      final response = await _dio.get('/stored/all');

      if (response.statusCode == 200) {
        final apiResponse = ApiRespon(
          success: response.data['success'] ?? true,
          message: response.data['message'],
          data: response.data['data'],
          error: response.data['error'],
        );

        if (apiResponse.success && apiResponse.data != null) {
          final storedList = (apiResponse.data as List)
              .map((item) => StoredModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return (
            success: true,
            message:
                apiResponse.message ?? 'All stored items fetched successfully',
            stored: storedList,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to fetch stored items',
            stored: null,
          );
        }
      } else {
        return (
          success: false,
          message: 'Failed to fetch stored items',
          stored: null,
        );
      }
    } on DioException catch (e) {
      String message = 'Failed to fetch stored items';
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          message = errorData['message'];
        }
      } else {
        message = 'Network error: ${e.message}';
      }
      return (success: false, message: message, stored: null);
    } catch (e) {
      return (success: false, message: 'Error: ${e.toString()}', stored: null);
    }
  }

  // Update stored
  Future<({bool success, String message})> updateStored({
    required int storedId,
    String? bottleName,
    String? brand,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (bottleName != null) queryParams['bottle_name'] = bottleName;
      if (brand != null) queryParams['brand'] = brand;
      if (category != null) queryParams['category'] = category;

      final response = await _dio.put(
        '/stored/update/$storedId',
        queryParameters: queryParams,
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
            message: apiResponse.message ?? 'Stored updated successfully',
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to update stored',
          );
        }
      } else {
        return (success: false, message: 'Failed to update stored');
      }
    } on DioException catch (e) {
      String message = 'Failed to update stored';
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

  // Delete stored
  Future<({bool success, String message})> deleteStored(int storedId) async {
    try {
      final response = await _dio.delete('/stored/delete/$storedId');

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
            message: apiResponse.message ?? 'Stored deleted successfully',
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to delete stored',
          );
        }
      } else {
        return (success: false, message: 'Failed to delete stored');
      }
    } on DioException catch (e) {
      String message = 'Failed to delete stored';
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

  // Count stored by owner
  Future<({bool success, String message, int? count})> countStoredByOwner(
    int ownerId,
  ) async {
    try {
      final response = await _dio.get('/stored/count/$ownerId');

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
            message: apiResponse.message ?? 'Count fetched successfully',
            count: count,
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to count stored',
            count: null,
          );
        }
      } else {
        return (success: false, message: 'Failed to count stored', count: null);
      }
    } on DioException catch (e) {
      String message = 'Failed to count stored';
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

  // Finish stored
  Future<({bool success, String message})> finishStored(int storedId) async {
    try {
      final response = await _dio.put('/stored/finish/$storedId');

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
            message: apiResponse.message ?? 'Stored finished successfully',
          );
        } else {
          return (
            success: false,
            message:
                apiResponse.error ??
                apiResponse.message ??
                'Failed to finish stored',
          );
        }
      } else {
        return (success: false, message: 'Failed to finish stored');
      }
    } on DioException catch (e) {
      String message = 'Failed to finish stored';
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
}
