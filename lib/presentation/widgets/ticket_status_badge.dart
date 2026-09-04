import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TicketStatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const TicketStatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (lower == 'checked_in' || lower == 'verified' || lower == 'used') {
      bg = AppColors.successLight;
      fg = AppColors.successText;
      label = 'Checked-in / Verified';
      icon = Icons.check_circle_rounded;
    } else if (lower == 'unused' || lower == 'pending' || lower == 'valid') {
      bg = AppColors.warningLight;
      fg = AppColors.warningText;
      label = 'Valid / Ready to Scan';
      icon = Icons.access_time_rounded;
    } else {
      bg = AppColors.errorLight;
      fg = AppColors.errorText;
      label = status;
      icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLarge ? 16 : 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: isLarge ? 13 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
