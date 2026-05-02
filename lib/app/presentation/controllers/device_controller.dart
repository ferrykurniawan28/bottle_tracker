import 'package:get/get.dart';
import '../../data/models/device_model.dart';
import '../../data/repositories/device_repository.dart';

class DeviceController extends GetxController {
  final DeviceRepository _repository;

  DeviceController(this._repository);

  final devices = RxList<DeviceModel>();
  final isLoading = RxBool(false);
  final error = RxString('');
  final deviceCount = RxInt(0);
  final unusedDeviceCount = RxInt(0);

  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    getDevices(refresh: true);
    print('DeviceController initialized');
    getDeviceCount();
  }

  Future<void> getDevices({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      devices.clear();
    }

    if (!_hasMore || isLoading.value) return;

    try {
      isLoading.value = true;
      error.value = '';

      final newDevices = await _repository.getDevices(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (newDevices.isEmpty) {
        _hasMore = false;
      } else {
        devices.addAll(newDevices);
        _currentPage++;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreDevices() async {
    await getDevices();
  }

  Future<void> toggleDevice(DeviceModel device) async {
    try {
      final updated = await _repository.toggleDevice(device.id);
      final index = devices.indexWhere((d) => d.id == device.id);
      if (index >= 0) {
        devices[index] = updated;
      }
      Get.snackbar('Success', 'Device toggled successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to toggle device: $e');
    }
  }

  Future<void> deleteDevice(DeviceModel device) async {
    try {
      await _repository.deleteDevice(device.id);
      devices.removeWhere((d) => d.id == device.id);
      Get.snackbar('Success', 'Device deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete device: $e');
    }
  }

  Future<void> getDeviceCount() async {
    try {
      final count = await _repository.getDeviceCount();
      deviceCount.value = count;

      final unusedCount = await _repository.getUnusedDeviceCount();
      unusedDeviceCount.value = unusedCount;
    } catch (e) {
      error.value = e.toString();
    }
  }
}
