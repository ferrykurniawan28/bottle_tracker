import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import 'user_bottles_view.dart';
import 'user_store_view.dart';
import 'user_profile_view.dart';
import '../../../core/widgets/custom_nav_bar.dart';

class UserNavView extends GetView<UserController> {
  const UserNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      // const UserBottlesView(),
      const UserStoreView(),
      const UserProfileView(),
    ];

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: CustomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
          items: const [
            // NavItem(
            //   icon: Icons.local_bar_outlined,
            //   activeIcon: Icons.local_bar_rounded,
            // ),
            NavItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
            ),
            NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
