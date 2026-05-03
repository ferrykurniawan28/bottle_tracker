import 'package:bottle_tracker/app/core/theme/app_colors.dart';
import 'package:bottle_tracker/app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/stored_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/device_service.dart';
import '../../../data/services/stored_service.dart';
import '../../../data/services/auth_service.dart';

class UserController extends GetxController {
  final DeviceService _deviceService = DeviceService();
  final StoredService _storedService = StoredService();
  final AuthService _authService = AuthService();

  final allDevices = <DeviceModel>[].obs;
  final storedBottles = <StoredModel>[].obs;
  final selectedCatalogIds = <String>{}.obs;
  final currentIndex = 0.obs;
  final currentUser = Rxn<UserModel>();
  final unreadNotificationsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _authService.getCurrentUser();
    loadData();
  }

  Future<void> loadData() async {
    final devicesResult = await _deviceService.getAllDevices();
    allDevices.value = devicesResult.devices ?? [];

    final storedUser = currentUser.value;
    if (storedUser != null) {
      final storedResult = await _storedService.getStoredByOwner(storedUser.id);
      storedBottles.value = storedResult.stored ?? [];
      return;
    }

    final userResult = await _authService.getAllUsers();
    if (userResult.users != null && userResult.users!.isNotEmpty) {
      currentUser.value = userResult.users!.first;
      final storedResult = await _storedService.getStoredByOwner(
        currentUser.value!.id,
      );
      storedBottles.value = storedResult.stored ?? [];
    }
  }

  void toggleSelection(String catalogId) {
    if (selectedCatalogIds.contains(catalogId)) {
      selectedCatalogIds.remove(catalogId);
    } else {
      selectedCatalogIds.add(catalogId);
    }
  }

  bool isSelected(String catalogId) => selectedCatalogIds.contains(catalogId);

  void storeSelectedBottles(
    Map<String, Map<String, dynamic>> bottleData,
  ) async {
    if (currentUser.value == null) return;

    for (final entry in bottleData.entries) {
      final deviceId = entry.value['deviceId'] as int?;
      final name = entry.value['name'] as String?;
      final brand = entry.value['brand'] as String?;
      final category = entry.value['category'] as String?;
      final weight = entry.value['weight'] as double?;

      if (deviceId == null || name == null || weight == null || weight <= 0) {
        continue;
      }

      await _storedService.createStored(
        deviceUid: deviceId.toString(),
        ownerUid: currentUser.value!.uniqueCode,
        bottleName: name,
        brand: brand ?? '',
        category: category ?? 'Other',
        weight: weight,
      );
    }

    selectedCatalogIds.clear();
    loadData();

    Get.snackbar(
      'Success',
      'Bottles stored successfully!',
      backgroundColor: Colors.green.withValues(alpha: 0.2),
      colorText: Colors.green,
      snackPosition: SnackPosition.TOP,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
    );
  }

  void changeTab(int index) => currentIndex.value = index;

  void scanBottleQR() {
    Get.to(() => const QRScannerView())?.then((qrCode) {
      if (qrCode != null && qrCode is String) {
        _handleScannedBottle(qrCode);
      }
    });
  }

  void _handleScannedBottle(String bottleId) async {
    final deviceResult = await _deviceService.getDeviceByUID(bottleId);
    if (deviceResult.device != null) {
      final device = deviceResult.device!;
      Get.dialog(
        Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Device Found',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                _buildInfoRow('Device UID', device.uid),
                _buildInfoRow('Status', device.isUsed ? 'In Use' : 'Available'),
                _buildInfoRow(
                  'Created',
                  device.createdAt.toString().split(' ')[0],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Use',
                  onPressed: () => _handleUsedDevice(device.uid),
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Close',
                  onPressed: () => Get.back(),
                  color: AppColors.divider,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Get.snackbar(
        'Not Found',
        'No device found with this QR code',
        backgroundColor: Colors.orange.withValues(alpha: 0.2),
        colorText: Colors.orange,
      );
    }
  }

  void _handleUsedDevice(String deviceId) {
    Get.back();

    final nameController = TextEditingController();
    final brandController = TextEditingController();
    StoredCategory? selectedCategory;

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Store Bottle',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Bottle Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ✅ StatefulBuilder so dropdown re-renders on selection
                StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButtonFormField<StoredCategory>(
                      initialValue:
                          selectedCategory, // ✅ 'value' not 'initialValue'
                      isExpanded: true, // ✅ prevents overflow in narrow dialogs
                      items: StoredCategory.values.map((category) {
                        return DropdownMenuItem<StoredCategory>(
                          value: category,
                          child: Text(
                            category.toString().split('.').last.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Category (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Store',
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter a bottle name',
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.2,
                              ),
                              colorText: Colors.red,
                            );
                            return;
                          }

                          if (brandController.text.trim().isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter a brand name',
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.2,
                              ),
                              colorText: Colors.red,
                            );
                            return;
                          }

                          if (selectedCategory == null) {
                            Get.snackbar(
                              'Error',
                              'Please select a category',
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.2,
                              ),
                              colorText: Colors.red,
                            );
                            return;
                          }

                          await _storedService.createStored(
                            deviceUid: deviceId,
                            ownerUid: currentUser.value!.uniqueCode,
                            bottleName: nameController.text.trim(),
                            brand: brandController.text.trim(),
                            category: selectedCategory
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                          );

                          Get.back();
                          loadData();

                          Get.snackbar(
                            'Success',
                            'Bottle stored successfully!',
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.2,
                            ),
                            colorText: Colors.green,
                          );
                        },
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onPressed: () => Get.back(),
                        color: AppColors.divider,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 39),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerView extends StatelessWidget {
  const QRScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Get.back(result: code);
                }
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scan bottle QR code',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
