import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import 'admin_bottles_view.dart';
import 'admin_search_view.dart';
import 'admin_users_view.dart';
import '../../../core/widgets/custom_nav_bar.dart';

class AdminNavView extends GetView<AdminController> {
  const AdminNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminBottlesView(),
      const AdminSearchView(),
      const AdminUsersView(),
    ];

    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.currentIndex.value,
            children: pages,
          ),
          bottomNavigationBar: CustomNavBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            items: const [
              NavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
              ),
              NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.manage_search_rounded,
              ),
              NavItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
              ),
            ],
          ),
        ));
  }
}
