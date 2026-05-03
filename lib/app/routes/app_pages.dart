import 'package:bottle_tracker/app/core/constants/app_constants.dart';
import 'package:bottle_tracker/app/modules/admin/views/admin_devices_list.dart';
import 'package:bottle_tracker/app/presentation/screens/notifications_screen.dart';
import 'package:bottle_tracker/app/presentation/screens/stored_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/user/views/user_nav_view.dart';
import '../modules/user/controllers/user_controller.dart';
import '../modules/admin/views/admin_nav_view.dart';
import '../modules/admin/controllers/admin_controller.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/device_repository.dart';
import '../presentation/controllers/notification_controller.dart';
import '../presentation/controllers/device_controller.dart';
import '../data/models/stored_model.dart';
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
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(
      name: AppRoutes.userNav,
      page: () => const UserNavView(),
      bindings: [
        BindingsBuilder(() {
          Get.lazyPut(() => AuthController());
          Get.lazyPut(() => UserController());
          Get.lazyPut(
            () => NotificationRepository(Get.find(), baseUrl: URLs.apiBaseUrl),
          );
          Get.lazyPut(() => NotificationController(Get.find()));
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
          Get.lazyPut(() => Dio());
          Get.lazyPut(
            () => NotificationRepository(Get.find(), baseUrl: URLs.apiBaseUrl),
          );
          Get.lazyPut(() => NotificationController(Get.find()));
          Get.lazyPut(
            () => DeviceRepository(Get.find(), baseUrl: URLs.apiBaseUrl),
          );
          Get.lazyPut(() => DeviceController(Get.find()));
        }),
      ],
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => const NotificationsScreen(),
      bindings: [
        BindingsBuilder(() {
          Get.lazyPut(() => AuthController());
          Get.lazyPut(() => UserController());
          Get.lazyPut(() => Dio());
          Get.lazyPut(
            () => NotificationRepository(Get.find(), baseUrl: URLs.apiBaseUrl),
          );
          Get.lazyPut(() => NotificationController(Get.find()));
        }),
      ],
    ),
    GetPage(
      name: AppRoutes.adminDevices,
      page: () => const AdminDevicesListScreen(),
      bindings: [
        BindingsBuilder(() {
          // Get.lazyPut(() => AuthController());
          Get.lazyPut(() => AdminController());
          // Get.lazyPut(() => Dio());
          Get.lazyPut(() => DeviceRepository(Get.find()));
          Get.lazyPut(() => DeviceController(Get.find()));
        }),
      ],
    ),
    GetPage(
      name: AppRoutes.storedDetail,
      page: () {
        final stored = Get.arguments;
        return StoredDetailScreen(
          stored: stored is StoredModel ? stored : null,
        );
      },
    ),
  ];
}
