import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/ticket_status_badge.dart';

class ManualLookupScreen extends StatefulWidget {
  const ManualLookupScreen({super.key});

  @override
  State<ManualLookupScreen> createState() => _ManualLookupScreenState();
}

class _ManualLookupScreenState extends State<ManualLookupScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLookup() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a ticket code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final scannerController = Provider.of<ScannerController>(context, listen: false);

    await scannerController.lookupCode(
      code,
      token: authController.currentUser?.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final scannerController = context.watch<ScannerController>();
    final selectedTicket = scannerController.selectedTicket;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manual Lookup', style: AppTextStyles.h2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Ticket Code',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search by ticket code printed on the attendee digital or paper pass.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _codeController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleLookup(),
                      suffixIcon: _codeController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                setState(() {
                                  _codeController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    AppButton(
                      text: 'Lookup Ticket',
                      isLoading: scannerController.isLookingUp,
                      icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                      onPressed: _handleLookup,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error notification if lookup failed
              if (scannerController.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          scannerController.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.errorText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Ticket Result Card
              if (selectedTicket != null) ...[
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TICKET FOUND', style: AppTextStyles.captionBold.copyWith(color: AppColors.primary)),
                              const SizedBox(height: 2),
                              Text(selectedTicket.attendeeName, style: AppTextStyles.h2),
                            ],
                          ),
                          TicketStatusBadge(status: selectedTicket.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),

                      _buildDetailRow('Event', selectedTicket.eventName),
                      const SizedBox(height: 8),
                      _buildDetailRow('Ticket Type', selectedTicket.ticketType),
                      const SizedBox(height: 8),
                      _buildDetailRow('Ticket Code', selectedTicket.code, isMonospace: true),

                      if (selectedTicket.scannedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow('Scanned At', selectedTicket.scannedAt!),
                      ],

                      const SizedBox(height: 20),

                      if (!selectedTicket.isCheckedIn)
                        AppButton(
                          text: 'Mark as Used / Check-in',
                          isLoading: scannerController.isVerifying,
                          icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          onPressed: () async {
                            final staffId = authController.currentUser?.id ?? 1;
                            final staffName = authController.currentUser?.name ?? 'Gate Staff';
                            final token = authController.currentUser?.token;

                            final success = await scannerController.verifyCurrentTicket(
                              staffId: staffId,
                              staffName: staffName,
                              token: token,
                            );

                            if (!context.mounted) return;

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Checked in ${selectedTicket.attendeeName} successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.successText, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Ticket Verified & Checked In',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.successText,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Recent Scans History Section
              if (scannerController.recentScans.isNotEmpty) ...[
                Text('Recent Check-Ins Today', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: scannerController.recentScans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = scannerController.recentScans[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.attendeeName, style: AppTextStyles.bodyBold),
                                Text(
                                  '${item.ticketType} · ${item.code}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Just now',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: isMonospace ? AppTextStyles.code : AppTextStyles.bodyBold,
        ),
      ],
    );
  }
}
