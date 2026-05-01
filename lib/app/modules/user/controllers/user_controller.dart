import 'package:bottle_tracker/app/core/theme/app_colors.dart';
import 'package:bottle_tracker/app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/stored_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/services/bottle_service.dart';
import '../../../data/services/auth_service.dart';

class UserController extends GetxController {
  final BottleService _bottleService = BottleService();
  final AuthService _authService = AuthService();

  final catalogBottles = <CatalogBottle>[].obs;
  final storedBottles = <BottleModel>[].obs;
  final selectedCatalogIds = <String>{}.obs;
  final currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() {
    catalogBottles.value = _bottleService.getCatalogBottles();
    final user = _authService.getCurrentUser();
    if (user != null) {
      storedBottles.value = _bottleService.getBottlesByUserId(user.id);
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

  void storeSelectedBottles(Map<String, double> weights) {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    for (final catalogId in selectedCatalogIds) {
      final catalog = catalogBottles.firstWhereOrNull((b) => b.id == catalogId);
      if (catalog == null) continue;

      final weight = weights[catalogId];
      if (weight == null || weight <= 0) continue;

      _bottleService.storeBottle(
        userId: user.id,
        catalogBottleId: catalog.id,
        name: catalog.name,
        brand: catalog.brand,
        category: catalog.category,
        weightGrams: weight,
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

  void _handleScannedBottle(String bottleId) {
    final bottle = _bottleService.getAllBottles().firstWhereOrNull(
      (b) => b.id == bottleId,
    );
    if (bottle != null) {
      // Find which user owns this bottle
      final user = _authService.getAllUsers().firstWhereOrNull(
        (u) => u.id == bottle.userId,
      );

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
                  'Bottle Found',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                _buildInfoRow('Name', bottle.name),
                _buildInfoRow('Brand', bottle.brand),
                _buildInfoRow('Owner', user?.name ?? 'Unknown'),
                _buildInfoRow(
                  'Status',
                  bottle.isReturned ? 'Returned' : 'In Storage',
                ),
                const SizedBox(height: 24),
                CustomButton(text: 'Close', onPressed: () => Get.back()),
              ],
            ),
          ),
        ),
      );
    } else {
      Get.snackbar(
        'Not Found',
        'No bottle found with this QR code',
        backgroundColor: Colors.orange.withValues(alpha: 0.2),
        colorText: Colors.orange,
      );
    }
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
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
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
