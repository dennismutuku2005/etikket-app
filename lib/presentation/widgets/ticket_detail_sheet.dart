import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/ticket_entity.dart';
import 'app_button.dart';
import 'ticket_status_badge.dart';

class TicketDetailSheet extends StatelessWidget {
  final TicketEntity ticket;
  final String staffName;
  final bool isVerifying;
  final VoidCallback onVerify;
  final VoidCallback onClose;

  const TicketDetailSheet({
    super.key,
    required this.ticket,
    required this.staffName,
    required this.isVerifying,
    required this.onVerify,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlreadyUsed = ticket.isCheckedIn;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TICKET VERIFICATION',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Confirm Check-In',
                    style: AppTextStyles.h2,
                  ),
                ],
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceAlt,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Alert banner if already used
          if (isAlreadyUsed)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This ticket has ALREADY BEEN SCANNED & CHECKED IN.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.errorText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Attendee Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ATTENDEE',
                        style: AppTextStyles.captionBold,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket.attendeeName,
                        style: AppTextStyles.h3.copyWith(fontSize: 17),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TicketStatusBadge(status: ticket.status),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Event & Ticket Type Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EVENT', style: AppTextStyles.captionBold),
                      const SizedBox(height: 2),
                      Text(
                        ticket.eventName,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TICKET TYPE', style: AppTextStyles.captionBold),
                      const SizedBox(height: 2),
                      Text(
                        ticket.ticketType,
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ticket Code & Scanned Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TICKET CODE', style: AppTextStyles.captionBold),
                    const SizedBox(height: 2),
                    Text(
                      ticket.code,
                      style: AppTextStyles.code.copyWith(
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                if (ticket.scannedAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('SCANNED AT', style: AppTextStyles.captionBold),
                      const SizedBox(height: 2),
                      Text(
                        ticket.scannedAt!,
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          if (!isAlreadyUsed)
            AppButton(
              text: 'Mark as Used',
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
              isLoading: isVerifying,
              onPressed: onVerify,
            )
          else
            const AppButton(
              text: 'Already Checked In',
              variant: AppButtonVariant.secondary,
              onPressed: null,
            ),
          const SizedBox(height: 10),
          AppButton(
            text: 'Close',
            variant: AppButtonVariant.outline,
            onPressed: onClose,
            height: 48,
          ),
        ],
      ),
    );
  }
}
