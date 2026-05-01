import 'package:bottle_tracker/app/data/models/user_model.dart';
import 'package:bottle_tracker/app/data/services/auth_service.dart';
import 'package:bottle_tracker/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerNameController = TextEditingController();

  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _authService.getCurrentUser();
  }

  void login() async {
    if (!loginFormKey.currentState!.validate()) return;

    isLoading.value = true;
    final result = await _authService.login(
      email: loginEmailController.text,
      password: loginPasswordController.text,
    );

    isLoading.value = false;

    if (result.success) {
      currentUser.value = result.user;
      _clearLoginFields();
      if (result.user!.role == 'admin') {
        Get.offAllNamed(AppRoutes.adminNav);
      } else {
        Get.offAllNamed(AppRoutes.userNav);
      }
    } else {
      Get.snackbar(
        'Error',
        result.message,
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void register() async {
    if (!registerFormKey.currentState!.validate()) return;

    isLoading.value = true;
    final result = await _authService.register(
      email: registerEmailController.text,
      password: registerPasswordController.text,
      name: registerNameController.text,
    );

    isLoading.value = false;

    if (result.success) {
      currentUser.value = result.user;
      _clearRegisterFields();
      Get.offAllNamed(AppRoutes.userNav);
    } else {
      Get.snackbar(
        'Error',
        result.message,
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        colorText: Colors.red,
        snackPosition: SnackPosition.TOP,
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void logout() {
    _authService.logout();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  void checkAuth() {
    final user = _authService.getCurrentUser();
    if (user != null) {
      currentUser.value = user;
      if (user.role == 'admin') {
        Get.offAllNamed(AppRoutes.adminNav);
      } else {
        Get.offAllNamed(AppRoutes.userNav);
      }
    }
  }

  void _clearLoginFields() {
    loginEmailController.clear();
    loginPasswordController.clear();
  }

  void _clearRegisterFields() {
    registerEmailController.clear();
    registerPasswordController.clear();
    registerNameController.clear();
  }
}
