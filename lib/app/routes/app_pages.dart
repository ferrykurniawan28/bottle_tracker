import 'package:get/get.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/user/views/user_nav_view.dart';
import '../modules/user/controllers/user_controller.dart';
import '../modules/admin/views/admin_nav_view.dart';
import '../modules/admin/controllers/admin_controller.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: AppRoutes.userNav,
      page: () => const UserNavView(),
      bindings: [
        BindingsBuilder(() {
          Get.lazyPut(() => AuthController());
          Get.lazyPut(() => UserController());
        }),
      ],
    ),
    GetPage(
      name: AppRoutes.adminNav,
      page: () => const AdminNavView(),
      bindings: [
        BindingsBuilder(() {
          Get.lazyPut(() => AuthController());
          Get.lazyPut(() => AdminController());
        }),
      ],
    ),
  ];
}
