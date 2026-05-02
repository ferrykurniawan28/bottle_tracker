import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/stored_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/stored_service.dart';
import '../../../data/services/auth_service.dart';

class AdminController extends GetxController {
  final DeviceService _deviceService = DeviceService();
  final StoredService _storedService = StoredService();
  final AuthService _authService = AuthService();

  final allDevices = <DeviceModel>[].obs;
  final allStoredBottles = <StoredModel>[].obs;
  final searchResults = <StoredModel>[].obs;
  final searchedUser = Rx<UserModel?>(null);
  final allUsers = <UserModel>[].obs;
  final currentIndex = 0.obs;

  final searchController = TextEditingController();
  final userSearchController = TextEditingController();
  final filteredUsers = <UserModel>[].obs;
  final currentPage = 0.obs;
  final pageSize = 10;
  final hasSearched = false.obs;
  final allDevicesCount = 0.obs;
  final unusedDevicesCount = 0.obs;

  final categories = [
    'Whiskey',
    'Vodka',
    'Wine',
    'Beer',
    'Rum',
    'Tequila',
    'Gin',
    'Brandy',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    loadData();
    getAllDevicesCount();
    getUnusedDevicesCount();
  }

  void loadData() async {
    final devicesResult = await _deviceService.getAllDevices();
    allDevices.value = devicesResult.devices ?? [];

    final storedResult = await _storedService.getAllStored();
    allStoredBottles.value = storedResult.stored ?? [];

    final usersResult = await _authService.getAllUsers();
    allUsers.value = usersResult.users ?? [];
    filteredUsers.value = usersResult.users ?? [];
    currentPage.value = 0;
  }

  // ── Search ──

  void searchByUserId() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    hasSearched.value = true;
    final result = await _authService.getAllUsers();
    final users = result.users ?? [];
    final matchedUsers = users.where(
      (u) =>
          u.uniqueCode.toLowerCase().contains(query.toLowerCase()) ||
          u.name.toLowerCase().contains(query.toLowerCase()) ||
          u.email.toLowerCase().contains(query.toLowerCase()),
    );

    if (matchedUsers.isNotEmpty) {
      searchedUser.value = matchedUsers.first;
      searchResults.value = [];
      final storedResult = await _storedService.getAllStored();
      final allStored = storedResult.stored ?? [];
      for (final user in matchedUsers) {
        final userBottles = allStored
            .where((b) => b.ownerId.toString() == user.id)
            .toList();
        searchResults.addAll(userBottles);
      }
    } else {
      searchedUser.value = null;
      searchResults.value = [];
    }
  }

  void clearSearch() {
    searchController.clear();
    searchResults.clear();
    searchedUser.value = null;
    hasSearched.value = false;
  }

  // ── Users ──

  void deleteUser(String userId) async {
    await _authService.deleteUser(userId);
    final storedResult = await _storedService.getAllStored();
    final userStored =
        storedResult.stored
            ?.where((b) => b.ownerId.toString() == userId)
            .toList() ??
        [];
    for (final stored in userStored) {
      await _storedService.deleteStored(stored.id);
    }
    loadData();
    searchUsers();
  }

  void searchUsers() {
    final query = userSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredUsers.value = allUsers;
    } else {
      filteredUsers.value = allUsers
          .where(
            (u) =>
                u.email.toLowerCase().contains(query) ||
                u.name.toLowerCase().contains(query),
          )
          .toList();
    }
    currentPage.value = 0;
  }

  List<UserModel> get usersPage {
    int start = currentPage.value * pageSize;
    int end = (start + pageSize) > filteredUsers.length
        ? filteredUsers.length
        : (start + pageSize);
    if (start >= filteredUsers.length) return [];
    return filteredUsers.sublist(start, end);
  }

  void nextPage() {
    if ((currentPage.value + 1) * pageSize < filteredUsers.length) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
    }
  }

  int get totalPages => (filteredUsers.length / pageSize).ceil();

  void changeTab(int index) => currentIndex.value = index;

  @override
  void onClose() {
    searchController.dispose();
    userSearchController.dispose();
    super.onClose();
  }

  // ── Devices ──
  Future<void> deleteDevice(int deviceId) async {
    await _deviceService.deleteDevice(deviceId);
    loadData();
  }

  // get all devices count
  Future<void> getAllDevicesCount() async {
    final devicesResult = await _deviceService.getDeviceCount();
    allDevicesCount.value = devicesResult.count ?? 0;
  }

  // get unused devices count
  Future<void> getUnusedDevicesCount() async {
    final devicesResult = await _deviceService.getUnusedDeviceCount();
    unusedDevicesCount.value = devicesResult.count ?? 0;
  }

  // ── Stored ──
  Future<void> deleteStored(int storedId) async {
    await _storedService.deleteStored(storedId);
    loadData();
  }
}
