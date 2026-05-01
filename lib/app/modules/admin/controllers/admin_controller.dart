import 'package:bottle_tracker/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/stored_model.dart';
import '../../../data/models/device_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/bottle_service.dart';
import '../../../data/services/auth_service.dart';

class AdminController extends GetxController {
  final BottleService _bottleService = BottleService();
  final AuthService _authService = AuthService();

  final catalogBottles = <CatalogBottle>[].obs;
  final allStoredBottles = <BottleModel>[].obs;
  final searchResults = <BottleModel>[].obs;
  final searchedUser = Rx<UserModel?>(null);
  final allUsers = <UserModel>[].obs;
  final currentIndex = 0.obs;

  final searchController = TextEditingController();
  final userSearchController = TextEditingController();
  final filteredUsers = <UserModel>[].obs;
  final currentPage = 0.obs;
  final pageSize = 10;
  final hasSearched = false.obs;

  // Catalog CRUD fields
  final bottleNameController = TextEditingController();
  final bottleBrandController = TextEditingController();
  final bottleFormKey = GlobalKey<FormState>();
  final selectedCategory = 'Whiskey'.obs;
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
  }

  void loadData() async {
    catalogBottles.value = _bottleService.getCatalogBottles();
    allStoredBottles.value = _bottleService.getAllBottles();
    final result = await _authService.getAllUsers();
    allUsers.value = result.users ?? [];
    filteredUsers.value = result.users ?? [];
    currentPage.value = 0;
  }

  // ── Catalog CRUD ──

  void showAddBottleDialog() {
    _clearFields();
    Get.dialog(
      _buildCatalogDialog(
        title: 'Add Bottle',
        onSave: () {
          if (!bottleFormKey.currentState!.validate()) return;
          _bottleService.addCatalogBottle(
            name: bottleNameController.text.trim(),
            brand: bottleBrandController.text.trim(),
            category: selectedCategory.value,
          );
          loadData();
          _clearFields();
          Get.back();
        },
      ),
    );
  }

  void showEditCatalogDialog(CatalogBottle bottle) {
    bottleNameController.text = bottle.name;
    bottleBrandController.text = bottle.brand;
    selectedCategory.value = bottle.category;

    Get.dialog(
      _buildCatalogDialog(
        title: 'Edit Bottle',
        onSave: () {
          if (!bottleFormKey.currentState!.validate()) return;
          _bottleService.updateCatalogBottle(
            bottle.copyWith(
              name: bottleNameController.text.trim(),
              brand: bottleBrandController.text.trim(),
              category: selectedCategory.value,
            ),
          );
          loadData();
          _clearFields();
          Get.back();
        },
      ),
    );
  }

  void deleteCatalogBottle(String id) {
    _bottleService.deleteCatalogBottle(id);
    loadData();
  }

  void showQRCode(CatalogBottle bottle) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Catalog QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bottle.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: bottle.id,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Catalog ID: ${bottle.id}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      for (final user in matchedUsers) {
        final bottles = _bottleService.getBottlesByUserId(user.id);
        // Only show bottles that have NOT been returned
        searchResults.addAll(bottles.where((b) => !b.isReturned));
      }
    } else {
      searchedUser.value = null;
      searchResults.value = [];
    }
  }

  void putBackBottle(BottleModel bottle) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Return Bottle',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to return "${bottle.name}" to the user?',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textHint),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _bottleService.updateBottle(bottle.copyWith(isReturned: true));
              loadData();
              searchByUserId();
              Get.back();
              Get.snackbar(
                'Bottle Returned',
                '${bottle.name} has been put back and moved to user history.',
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                colorText: Colors.green,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Return', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
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
    _bottleService.deleteBottlesByUserId(userId);
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

  // ── Dialog builder ──

  Widget _buildCatalogDialog({
    required String title,
    required VoidCallback onSave,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: bottleFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _dialogField(bottleNameController, 'Bottle Name'),
              const SizedBox(height: 12),
              _dialogField(bottleBrandController, 'Brand'),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: selectedCategory.value,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Color(0xFF9D9DB5)),
                    filled: true,
                    fillColor: const Color(0xFF25253D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF25253D),
                  style: const TextStyle(color: Colors.white),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => selectedCategory.value = v!,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearFields();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF6C5CE7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF6C5CE7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9D9DB5)),
        filled: true,
        fillColor: const Color(0xFF25253D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _clearFields() {
    bottleNameController.clear();
    bottleBrandController.clear();
    selectedCategory.value = 'Whiskey';
  }

  void changeTab(int index) => currentIndex.value = index;

  @override
  void onClose() {
    searchController.dispose();
    userSearchController.dispose();
    bottleNameController.dispose();
    bottleBrandController.dispose();
    super.onClose();
  }
}
