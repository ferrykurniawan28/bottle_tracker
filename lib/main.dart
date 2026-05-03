import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'dart:developer' as developer;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('App initializing...', name: 'main');

  await GetStorage.init();
  developer.log('✓ GetStorage initialized', name: 'main');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log('✓ Firebase initialized', name: 'main');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  developer.log('✓ Background message handler registered', name: 'main');

  developer.log('Initializing NotificationService...', name: 'main');
  await NotificationService().initialize();
  developer.log('✓ NotificationService initialized', name: 'main');

  final currentUser = AuthService().getCurrentUser();
  if (currentUser != null) {
    developer.log(
      'Current user found: ${currentUser.email}, ID: ${currentUser.id}',
      name: 'main',
    );
    final userId = int.tryParse(currentUser.id);
    if (userId != null) {
      developer.log('Subscribing user $userId to topic...', name: 'main');
      await NotificationService().subscribeToUserTopic(userId);
      developer.log('✓ User subscribed to topic', name: 'main');
    } else {
      developer.log(
        '⚠ Could not parse user ID: ${currentUser.id}',
        name: 'main',
      );
    }
  } else {
    developer.log('No current user found', name: 'main');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
    ),
  );

  developer.log('Starting app...', name: 'main');
  runApp(const BottlyApp());
}

//
class BottlyApp extends StatelessWidget {
  const BottlyApp({super.key});

  String get _initialRoute {
    final user = AuthService().getCurrentUser();
    if (user == null) return AppRoutes.login;
    return user.role == 'admin' ? AppRoutes.adminNav : AppRoutes.userNav;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bottly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: _initialRoute,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
