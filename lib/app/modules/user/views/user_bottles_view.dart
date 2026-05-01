import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/models/device_model.dart';
import '../controllers/user_controller.dart';

class UserBottlesView extends GetView<UserController> {
  const UserBottlesView({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'whiskey':
        return Icons.local_bar_rounded;
      case 'vodka':
        return Icons.liquor_rounded;
      case 'wine':
        return Icons.wine_bar_rounded;
      case 'beer':
        return Icons.sports_bar_rounded;
      case 'rum':
        return Icons.local_drink_rounded;
      case 'tequila':
        return Icons.nightlife_rounded;
      default:
        return Icons.local_bar_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final catalog = controller.catalogBottles;
          final selectedCount = controller.selectedCatalogIds.length;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.local_bar_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bar Bottles',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Select bottles to store',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: controller.scanBottleQR,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SectionHeader(title: 'Available (${catalog.length})'),
                        ],
                      ),
                    ),
                  ),
                  if (catalog.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.local_bar_rounded,
                        title: 'No bottles available',
                        subtitle: 'The bar hasn\'t added any bottles yet',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final bottle = catalog[index];
                          final isSelected = controller.isSelected(bottle.id);

                          return _CatalogCard(
                            bottle: bottle,
                            isSelected: isSelected,
                            categoryIcon: _getCategoryIcon(bottle.category),
                            onTap: () => controller.toggleSelection(bottle.id),
                          );
                        }, childCount: catalog.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              // Store button
              if (selectedCount > 0)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: () => _showWeightDialog(context),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'Store $selectedCount bottle${selectedCount > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
      // floatingActionButton: selectedCount == 0
      //     ? FloatingActionButton(
      //         onPressed: controller.scanBottleQR,
      //         backgroundColor: AppColors.primary,
      //         child: const Icon(
      //           Icons.qr_code_scanner_rounded,
      //           color: Colors.white,
      //         ),
      //       )
      //     : null,
      // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showWeightDialog(BuildContext context) {
    final weightControllers = <String, TextEditingController>{};
    for (final id in controller.selectedCatalogIds) {
      weightControllers[id] = TextEditingController();
    }
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Weight',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set the weight for each bottle (grams)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ...controller.selectedCatalogIds.map((id) {
                  final bottle = controller.catalogBottles.firstWhereOrNull(
                    (b) => b.id == id,
                  );
                  if (bottle == null) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bottle.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: weightControllers[id],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Weight in grams',
                            hintStyle: const TextStyle(
                              color: AppColors.textHint,
                            ),
                            suffixText: 'g',
                            suffixStyle: const TextStyle(
                              color: AppColors.textHint,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF25253D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;

                          final weights = <String, double>{};
                          for (final entry in weightControllers.entries) {
                            weights[entry.key] = double.parse(
                              entry.value.text.trim(),
                            );
                          }

                          Get.back();
                          controller.storeSelectedBottles(weights);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('Store', style: GoogleFonts.poppins()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final CatalogBottle bottle;
  final bool isSelected;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.bottle,
    required this.isSelected,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.divider.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(categoryIcon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bottle.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bottle.brand} · ${bottle.category}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
