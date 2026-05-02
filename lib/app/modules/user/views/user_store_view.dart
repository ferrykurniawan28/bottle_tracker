import 'package:bottle_tracker/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottle_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/user_controller.dart';

class UserStoreView extends GetView<UserController> {
  const UserStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: Get.width - 105,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Stored',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Manage your stored items',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            // const Spacer(),

                            // notification icon with badge
                            Obx(
                              () => Stack(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.notification),

                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      size: 28,
                                    ),
                                  ),
                                  if (controller
                                          .unreadNotificationsCount
                                          .value >
                                      0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          controller
                                              .unreadNotificationsCount
                                              .value
                                              .toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(child: _buildBottleList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.scanBottleQR(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildBottleList() {
    return Obx(() {
      final bottles = controller.storedBottles;

      if (bottles.isEmpty) {
        return EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No bottles stored',
          subtitle: 'Go to Bar Bottles to select and store bottles',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: bottles.length,
        itemBuilder: (context, index) => BottleCard(bottle: bottles[index]),
      );
    });
  }
}
