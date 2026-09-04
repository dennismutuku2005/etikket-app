import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/quick_stats_bar.dart';
import '../widgets/scanner_overlay.dart';
import '../widgets/ticket_detail_sheet.dart';
import 'manual_lookup_screen.dart';
import 'settings_screen.dart';

class GateScannerScreen extends StatefulWidget {
  const GateScannerScreen({super.key});

  @override
  State<GateScannerScreen> createState() => _GateScannerScreenState();
}

class _GateScannerScreenState extends State<GateScannerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scannerController = Provider.of<ScannerController>(context, listen: false);
      scannerController.checkAndRequestCameraPermission();
      scannerController.setScanningActive(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final scannerController = Provider.of<ScannerController>(context, listen: false);
    if (state == AppLifecycleState.resumed) {
      scannerController.setScanningActive(true);
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      scannerController.setScanningActive(false);
    }
  }

  void _showTicketSheet() {
    if (!mounted) return;
    final scannerController = Provider.of<ScannerController>(context, listen: false);
    final authController = Provider.of<AuthController>(context, listen: false);
    final ticket = scannerController.selectedTicket;

    if (ticket == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Consumer<ScannerController>(
          builder: (sheetContext, controller, child) {
            final activeTicket = controller.selectedTicket ?? ticket;
            return TicketDetailSheet(
              ticket: activeTicket,
              staffName: authController.currentUser?.name ?? 'Gate Staff',
              isVerifying: controller.isVerifying,
              onVerify: () async {
                final staffId = authController.currentUser?.id ?? 1;
                final staffName = authController.currentUser?.name ?? 'Gate Staff';
                final token = authController.currentUser?.token;

                final success = await controller.verifyCurrentTicket(
                  staffId: staffId,
                  staffName: staffName,
                  token: token,
                );

                if (!modalContext.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(modalContext).showSnackBar(
                    SnackBar(
                      content: Text('✓ Checked in ${activeTicket.attendeeName} successfully!'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              onClose: () {
                Navigator.of(modalContext).pop();
                controller.resetSelectedTicket();
              },
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        scannerController.resetSelectedTicket();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final scannerController = context.watch<ScannerController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview or Permission Request View
          if (scannerController.hasCameraPermission && scannerController.mobileScannerController != null)
            MobileScanner(
              controller: scannerController.mobileScannerController!,
              onDetect: (capture) async {
                final ticket = await scannerController.onBarcodeDetected(
                  capture,
                  token: authController.currentUser?.token,
                );
                if (ticket != null && mounted) {
                  _showTicketSheet();
                }
              },
            )
          else
            _buildNoCameraPermissionView(scannerController),

          // Scan Overlay if permission granted
          if (scannerController.hasCameraPermission)
            ScannerOverlay(
              isTorchOn: scannerController.isTorchOn,
              isFrontCamera: scannerController.isFrontCamera,
              onToggleTorch: () => scannerController.toggleTorch(),
              onSwitchCamera: () => scannerController.switchCamera(),
            ),

          // Top Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 80, // Leaves space for top-right torch icons
            child: QuickStatsBar(
              staffName: authController.currentUser?.name ?? 'Gate Staff',
              staffEmail: authController.currentUser?.email,
              scannedCount: scannerController.scannedCount,
              onManualLookup: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManualLookupScreen()),
                );
              },
              onSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),

          // Lookup in progress indicator
          if (scannerController.isLookingUp)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verifying Ticket...',
                      style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Action Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Manual Lookup',
                      icon: const Icon(Icons.keyboard_rounded, size: 18, color: Colors.white),
                      height: 48,
                      onPressed: () async {
                        final code = await Navigator.of(context).push<String>(
                          MaterialPageRoute(builder: (_) => const ManualLookupScreen()),
                        );
                        if (!mounted) return;
                        if (code != null && code.isNotEmpty) {
                          final ticket = await scannerController.lookupCode(
                            code,
                            token: authController.currentUser?.token,
                          );
                          if (ticket != null && mounted) {
                            _showTicketSheet();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Demo Ticket',
                    child: Material(
                      color: AppColors.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          final ticket = await scannerController.lookupCode(
                            'TKT-1042',
                            token: authController.currentUser?.token,
                          );
                          if (ticket != null && mounted) {
                            _showTicketSheet();
                          }
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.science_outlined, size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Demo',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCameraPermissionView(ScannerController controller) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryTint10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Camera Access Required',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow camera permission so the scanner can read ticket QR codes at the gate entrance.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Grant Camera Permission',
              onPressed: () => controller.checkAndRequestCameraPermission(),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Use Manual Lookup Instead',
              variant: AppButtonVariant.outline,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManualLookupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
