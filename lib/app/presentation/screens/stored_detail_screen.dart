import 'package:bottle_tracker/app/core/theme/app_colors.dart';
import 'package:bottle_tracker/app/data/models/stored_model.dart';
import 'package:bottle_tracker/app/data/models/stored_weight_history_model.dart';
import 'package:bottle_tracker/app/data/services/stored_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StoredDetailScreen extends StatefulWidget {
  final StoredModel? stored;

  const StoredDetailScreen({super.key, this.stored});

  @override
  State<StoredDetailScreen> createState() => _StoredDetailScreenState();
}

class _StoredDetailScreenState extends State<StoredDetailScreen> {
  final StoredService _storedService = StoredService();

  StoredModel? _stored;
  late Future<List<StoredWeightHistoryModel>> _historyFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stored = widget.stored ?? Get.arguments as StoredModel?;
    _historyFuture = _loadHistory();
  }

  Future<List<StoredWeightHistoryModel>> _loadHistory() async {
    final stored = _stored;
    if (stored == null) {
      _errorMessage = 'Stored item not found.';
      return [];
    }

    final result = await _storedService.getWeightHistoryByStoredId(stored.id);
    if (!result.success) {
      _errorMessage = result.message;
      return [];
    }

    _errorMessage = null;
    return result.history ?? [];
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _loadHistory();
    });
    await _historyFuture;
  }

  @override
  Widget build(BuildContext context) {
    final stored = _stored;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Stored Detail'),
        actions: [
          // if user want to finish the stored, they can tap this button to mark it as finished
          if (stored != null && stored.isActive)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              onPressed: () {
                Get.defaultDialog(
                  title: 'Finish Stored',
                  middleText:
                      'Are you sure you want to mark this stored as finished? This action cannot be undone.',
                  textCancel: 'Cancel',
                  textConfirm: 'Finish',
                  confirmTextColor: Colors.white,
                  buttonColor: AppColors.primary,
                  cancelTextColor: Colors.white,
                  onConfirm: () async {
                    final result = await _storedService.finishStored(stored.id);
                    if (result.success) {
                      Get.back();
                      setState(() {
                        _stored = _stored!.copyWith(isActive: false);
                      });
                    } else {
                      Get.snackbar('Error', result.message);
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: stored == null
          ? Center(
              child: Text(
                'Stored item not available',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<StoredWeightHistoryModel>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.hasData == false) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      _DetailHeaderCard(stored: stored),
                      const SizedBox(height: 20),
                      // _InfoSectionCard(stored: stored),
                      // const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Weight History',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${history.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage != null)
                        _EmptyHistoryState(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load history',
                          subtitle: _errorMessage!,
                        )
                      else if (history.isEmpty)
                        _EmptyHistoryState(
                          icon: Icons.query_stats_rounded,
                          title: 'No weight history yet',
                          subtitle:
                              'Weight changes will appear here after new records are added.',
                        )
                      else
                        ...history.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HistoryTile(entry: entry),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _DetailHeaderCard extends StatelessWidget {
  final StoredModel stored;

  const _DetailHeaderCard({required this.stored});

  IconData _getCategoryIcon() {
    switch (stored.category?.toLowerCase()) {
      case 'whiskey':
        return Icons.local_bar_rounded;
      case 'vodka':
        return Icons.liquor_rounded;
      case 'wine':
        return Icons.wine_bar_rounded;
      case 'tequila':
        return Icons.nightlife_rounded;
      default:
        return Icons.local_bar_rounded;
    }
  }

  Color _getStatusColor() {
    return stored.weight != null ? AppColors.success : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_getCategoryIcon(), color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stored.bottleName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stored.brand} · ${stored.category ?? 'Uncategorized'}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // _Badge(
                    //   label: stored.weight != null
                    //       ? '${stored.weight!.toStringAsFixed(0)} g'
                    //       : 'No weight',
                    //   color: statusColor,
                    // ),
                    _Badge(
                      label: stored.isActive ? 'Active' : 'Inactive',
                      color: stored.isActive
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            stored.createdAt != null
                ? DateFormat('dd MMM yyyy').format(stored.createdAt!)
                : 'Unknown date',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final StoredModel stored;

  const _InfoSectionCard({required this.stored});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bottle Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Bottle ID', value: stored.id.toString()),
          _InfoRow(label: 'Device ID', value: stored.deviceId.toString()),
          _InfoRow(label: 'Owner ID', value: stored.ownerId.toString()),
          _InfoRow(
            label: 'Created At',
            value: stored.createdAt != null
                ? DateFormat('dd MMM yyyy, HH:mm').format(stored.createdAt!)
                : 'Unknown',
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final StoredWeightHistoryModel entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.monitor_weight_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${entry.weight.toStringAsFixed(0)} ml',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.recordedAt != null
                          ? DateFormat('dd MMM yyyy').format(entry.recordedAt!)
                          : 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.recordedAt != null
                      ? DateFormat('HH:mm').format(entry.recordedAt!)
                      : 'No time',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                // if (entry.note != null && entry.note!.trim().isNotEmpty) ...[
                //   const SizedBox(height: 8),
                //   Text(
                //     entry.note!,
                //     style: GoogleFonts.poppins(
                //       fontSize: 12,
                //       color: AppColors.textSecondary,
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyHistoryState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textHint, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
