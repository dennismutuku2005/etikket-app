import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class QuickStatsBar extends StatelessWidget {
  final String staffName;
  final String? staffEmail;
  final int scannedCount;
  final VoidCallback onManualLookup;
  final VoidCallback onSettings;

  const QuickStatsBar({
    super.key,
    required this.staffName,
    this.staffEmail,
    required this.scannedCount,
    required this.onManualLookup,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Staff Profile Info
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryTint10,
            child: Text(
              staffName.isNotEmpty ? staffName[0].toUpperCase() : 'G',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        staffName,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Live',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.successText,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  staffEmail ?? 'Gate Staff',
                  style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Scanned counter chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCANNED',
                  style: AppTextStyles.captionBold.copyWith(
                    fontSize: 8.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$scannedCount',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Settings Button
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
