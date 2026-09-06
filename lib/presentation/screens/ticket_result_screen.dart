import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/feedback_util.dart';
import '../../domain/entities/ticket_entity.dart';
import '../controllers/auth_controller.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/ticket_status_badge.dart';

class TicketResultScreen extends StatefulWidget {
  final TicketEntity? ticket;
  final String? errorMessage;

  const TicketResultScreen({
    super.key,
    this.ticket,
    this.errorMessage,
  });

  @override
  State<TicketResultScreen> createState() => _TicketResultScreenState();
}

class _TicketResultScreenState extends State<TicketResultScreen> {
  bool _isAutoVerifying = false;
  bool _wasAlreadyUsed = false;

  @override
  void initState() {
    super.initState();
    _wasAlreadyUsed = widget.ticket?.isCheckedIn ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoVerify();
    });
  }

  Future<void> _checkAutoVerify() async {
    final ticket = widget.ticket;
    if (ticket == null) return;

    if (ticket.isCheckedIn) {
      // Ticket was already used before this scan
      _wasAlreadyUsed = true;
      await FeedbackUtil.errorAlert();
      if (mounted) setState(() {});
      return;
    }

    setState(() {
      _isAutoVerifying = true;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final scannerController = Provider.of<ScannerController>(context, listen: false);

    final staffId = authController.currentUser?.id ?? 1;
    final staffName = authController.currentUser?.name ?? 'Gate Staff';
    final token = authController.currentUser?.token;

    final success = await scannerController.verifyCurrentTicket(
      staffId: staffId,
      staffName: staffName,
      token: token,
    );

    if (mounted) {
      setState(() {
        _isAutoVerifying = false;
        if (!success && (scannerController.errorMessage?.contains('ALREADY') ?? false)) {
          _wasAlreadyUsed = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerController = context.watch<ScannerController>();
    final authController = context.watch<AuthController>();

    // Use latest ticket entity from controller if updated
    final activeTicket = scannerController.selectedTicket ?? widget.ticket;
    final errorMsg = scannerController.errorMessage ?? widget.errorMessage;

    final isSuccess = activeTicket != null;
    final isDuplicateUsed = _wasAlreadyUsed || (activeTicket != null && activeTicket.isCheckedIn && !_isAutoVerifying && (widget.ticket?.isCheckedIn ?? false));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          !isSuccess
              ? 'Scan Result'
              : (isDuplicateUsed ? '⚠️ Duplicate Scan' : '✓ Ticket Details'),
          style: AppTextStyles.h2.copyWith(
            color: isDuplicateUsed ? AppColors.errorText : AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () async {
            await scannerController.prepareForNextScan();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isSuccess && errorMsg != null) ...[
                _buildErrorCard(errorMsg),
              ] else if (activeTicket != null) ...[
                _buildStatusHeader(
                  isDuplicateUsed: isDuplicateUsed,
                  isAutoVerifying: _isAutoVerifying,
                  scannedAt: activeTicket.scannedAt,
                ),
                const SizedBox(height: 20),
                _buildTicketCard(activeTicket, isDuplicateUsed: isDuplicateUsed),
                const SizedBox(height: 16),
                _buildStaffVerificationInfo(authController, activeTicket, isDuplicateUsed: isDuplicateUsed),
              ],
              const SizedBox(height: 28),
              AppButton(
                text: 'Scan Next Ticket',
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Colors.white),
                onPressed: () async {
                  await scannerController.prepareForNextScan();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Back to Gate Dashboard',
                variant: AppButtonVariant.outline,
                onPressed: () {
                  scannerController.openHome();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader({
    required bool isDuplicateUsed,
    required bool isAutoVerifying,
    String? scannedAt,
  }) {
    if (isAutoVerifying) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryTint10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifying Ticket...',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Checking gate validity & marking as used...',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isDuplicateUsed) {
      final formattedTime = AppDateFormatter.formatScannedAt(scannedAt);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTRY DENIED',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.errorText,
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'TICKET ALREADY USED',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.errorText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ This ticket was ALREADY SCANNED and marked as used. Do NOT admit attendee.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.errorText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (scannedAt != null && scannedAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'First Scanned: $formattedTime',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Fresh Valid Ticket: Entry Granted
    final formattedTime = AppDateFormatter.formatScannedAt(scannedAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENTRY GRANTED',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.successText,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'VALID TICKET · CHECKED IN',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.successText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Marked as used ($formattedTime).',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successText.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketEntity ticket, {required bool isDuplicateUsed}) {
    final formattedScannedAt = AppDateFormatter.formatScannedAt(ticket.scannedAt);
    final formattedEventDateTime = AppDateFormatter.formatEventDateTime(ticket.eventDate, ticket.eventTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDuplicateUsed ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
          width: isDuplicateUsed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TICKET DETAILS',
                style: AppTextStyles.captionBold.copyWith(
                  color: isDuplicateUsed ? AppColors.error : AppColors.primary,
                ),
              ),
              TicketStatusBadge(
                status: isDuplicateUsed ? 'used' : ticket.status,
                isLarge: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.attendeeName,
            style: AppTextStyles.h1.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),

          _buildInfoRow('Event Name', ticket.eventName, icon: Icons.event_rounded),
          const SizedBox(height: 12),
          _buildInfoRow('Ticket Type', ticket.ticketType, icon: Icons.confirmation_number_rounded, isHighlight: true),
          const SizedBox(height: 12),
          _buildInfoRow('Ticket Code', ticket.code, icon: Icons.qr_code_rounded, isCode: true),

          if (ticket.eventDate != null && ticket.eventDate!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Event Date', formattedEventDateTime, icon: Icons.calendar_today_rounded),
          ],

          if (ticket.venue != null && ticket.venue!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Venue', ticket.venue!, icon: Icons.location_on_rounded),
          ],

          if (ticket.scannedAt != null && ticket.scannedAt!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              isDuplicateUsed ? 'First Scanned' : 'Checked In At',
              formattedScannedAt,
              icon: Icons.access_time_rounded,
              isHighlight: isDuplicateUsed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    required IconData icon,
    bool isHighlight = false,
    bool isCode = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: isCode
                ? AppTextStyles.code.copyWith(fontSize: 14)
                : (isHighlight
                    ? AppTextStyles.bodyBold.copyWith(
                        color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                      )
                    : AppTextStyles.bodyBold),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffVerificationInfo(AuthController authController, TicketEntity ticket, {required bool isDuplicateUsed}) {
    final staffName = ticket.scannedBy ?? authController.currentUser?.name ?? 'Gate Staff';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDuplicateUsed ? AppColors.errorLight.withValues(alpha: 0.5) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDuplicateUsed ? AppColors.error.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDuplicateUsed ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
            color: isDuplicateUsed ? AppColors.error : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDuplicateUsed ? 'Previously Verified By' : 'Verified By',
                  style: AppTextStyles.caption.copyWith(
                    color: isDuplicateUsed ? AppColors.errorText : AppColors.textMuted,
                  ),
                ),
                Text(
                  staffName,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 13,
                    color: isDuplicateUsed ? AppColors.errorText : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 52),
          const SizedBox(height: 12),
          Text(
            'Lookup Failed',
            style: AppTextStyles.h2.copyWith(color: AppColors.errorText),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.errorText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
