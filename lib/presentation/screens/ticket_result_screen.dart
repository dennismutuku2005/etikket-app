import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoVerify();
    });
  }

  Future<void> _checkAutoVerify() async {
    final ticket = widget.ticket;
    if (ticket == null || ticket.isCheckedIn) return;

    setState(() {
      _isAutoVerifying = true;
    });

    final authController = Provider.of<AuthController>(context, listen: false);
    final scannerController = Provider.of<ScannerController>(context, listen: false);

    final staffId = authController.currentUser?.id ?? 1;
    final staffName = authController.currentUser?.name ?? 'Gate Staff';
    final token = authController.currentUser?.token;

    await scannerController.verifyCurrentTicket(
      staffId: staffId,
      staffName: staffName,
      token: token,
    );

    if (mounted) {
      setState(() {
        _isAutoVerifying = false;
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
    final isAlreadyCheckedIn = activeTicket != null && activeTicket.isCheckedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isSuccess ? 'Ticket Details' : 'Scan Result',
          style: AppTextStyles.h2,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            scannerController.resetSelectedTicket();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isSuccess && errorMsg != null) ...[
                _buildErrorCard(errorMsg, scannerController),
              ] else if (activeTicket != null) ...[
                _buildStatusHeader(isAlreadyCheckedIn, _isAutoVerifying),
                const SizedBox(height: 20),
                _buildTicketCard(activeTicket),
                const SizedBox(height: 20),
                _buildStaffVerificationInfo(authController, activeTicket),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: 'Scan Next Ticket',
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Colors.white),
                onPressed: () {
                  scannerController.resetSelectedTicket();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Back to Main Dashboard',
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

  Widget _buildStatusHeader(bool isCheckedIn, bool isAutoVerifying) {
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
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marking Ticket as Used...',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Validating guest pass at gate entrance...',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCheckedIn ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isCheckedIn ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCheckedIn ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckedIn ? Icons.check_rounded : Icons.priority_high_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckedIn ? 'VALID & MARKED AS USED' : 'ALREADY CHECKED IN',
                  style: AppTextStyles.captionBold.copyWith(
                    color: isCheckedIn ? AppColors.successText : AppColors.errorText,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCheckedIn ? 'Entry Granted' : 'Duplicate Scan Warning',
                  style: AppTextStyles.h2.copyWith(
                    color: isCheckedIn ? AppColors.successText : AppColors.errorText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCheckedIn
                      ? 'Ticket has been successfully scanned & marked as used.'
                      : 'This ticket was already scanned previously.',
                  style: AppTextStyles.caption.copyWith(
                    color: (isCheckedIn ? AppColors.successText : AppColors.errorText).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketEntity ticket) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
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
                style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
              ),
              TicketStatusBadge(status: ticket.status),
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

          if (ticket.venue != null && ticket.venue!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Venue', ticket.venue!, icon: Icons.location_on_rounded),
          ],

          if (ticket.scannedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Scanned At', ticket.scannedAt!, icon: Icons.access_time_rounded),
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
        Text(
          value,
          style: isCode
              ? AppTextStyles.code.copyWith(fontSize: 14)
              : (isHighlight
                  ? AppTextStyles.bodyBold.copyWith(color: AppColors.primary)
                  : AppTextStyles.bodyBold),
        ),
      ],
    );
  }

  Widget _buildStaffVerificationInfo(AuthController authController, TicketEntity ticket) {
    final staffName = ticket.scannedBy ?? authController.currentUser?.name ?? 'Gate Staff';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified By',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                Text(
                  staffName,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message, ScannerController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            'Scan / Lookup Failed',
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
