import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottle_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../controllers/user_controller.dart';

class UserStoreView extends GetView<UserController> {
  const UserStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: AppColors.primary,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textHint,
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Current'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBottleList(isHistory: false),
                    _buildBottleList(isHistory: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => controller.scanBottleQR(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBottleList({required bool isHistory}) {
    return Obx(() {
      final bottles = controller.storedBottles
          .where((b) => b.isReturned == isHistory)
          .toList();

      if (bottles.isEmpty) {
        return EmptyState(
          icon: isHistory ? Icons.history_rounded : Icons.inventory_2_outlined,
          title: isHistory ? 'No history yet' : 'No bottles stored',
          subtitle: isHistory
              ? 'Bottles returned by admin will appear here'
              : 'Go to Bar Bottles to select and store bottles',
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
