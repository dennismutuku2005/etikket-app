import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/ticket_entity.dart';
import '../controllers/auth_controller.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/quick_stats_bar.dart';
import '../widgets/scanner_overlay.dart';
import 'login_screen.dart';
import 'manual_lookup_screen.dart';
import 'settings_screen.dart';
import 'ticket_result_screen.dart';

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
      scannerController.openHome();
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
      if (!scannerController.isHomeScreen) {
        scannerController.setScanningActive(true);
      }
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      scannerController.setScanningActive(false);
    }
  }

  Future<void> _navigateToResultPage(TicketEntity? ticket, {String? errorMessage}) async {
    if (!mounted) return;
    final scannerController = Provider.of<ScannerController>(context, listen: false);
    await scannerController.pauseScanning();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketResultScreen(
          ticket: ticket,
          errorMessage: errorMessage,
        ),
      ),
    );

    if (mounted && !scannerController.isHomeScreen) {
      await scannerController.resumeScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final scannerController = context.watch<ScannerController>();

    if (scannerController.isHomeScreen && !scannerController.isLookingUp && !scannerController.isVerifying) {
      return _buildHomeScreen(authController, scannerController);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (scannerController.hasCameraPermission && scannerController.mobileScannerController != null)
            MobileScanner(
              key: ObjectKey(scannerController.mobileScannerController),
              controller: scannerController.mobileScannerController!,
              onDetect: (capture) async {
                final ticket = await scannerController.onBarcodeDetected(
                  capture,
                  token: authController.currentUser?.token,
                );
                if ((ticket != null || scannerController.errorMessage != null) && mounted) {
                  await _navigateToResultPage(ticket, errorMessage: scannerController.errorMessage);
                }
              },
            )
          else
            _buildNoCameraPermissionView(scannerController),

          if (scannerController.hasCameraPermission)
            ScannerOverlay(
              isTorchOn: scannerController.isTorchOn,
              isFrontCamera: scannerController.isFrontCamera,
              onToggleTorch: () => scannerController.toggleTorch(),
              onSwitchCamera: () => scannerController.switchCamera(),
              onClose: () => scannerController.openHome(),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 70,
            right: 16,
            child: QuickStatsBar(
              staffName: authController.currentUser?.name ?? 'Gate Staff',
              staffEmail: authController.currentUser?.email,
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
              child: AppButton(
                text: 'Manual Code Lookup',
                icon: const Icon(Icons.keyboard_rounded, size: 18, color: Colors.white),
                height: 48,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await scannerController.pauseScanning();
                  if (!mounted) return;
                  final code = await nav.push<String>(
                    MaterialPageRoute(builder: (_) => const ManualLookupScreen()),
                  );
                  if (!mounted) return;
                  if (code != null && code.isNotEmpty) {
                    final ticket = await scannerController.lookupCode(
                      code,
                      token: authController.currentUser?.token,
                    );
                    if (mounted) {
                      await _navigateToResultPage(ticket, errorMessage: scannerController.errorMessage);
                    }
                  } else if (!scannerController.isHomeScreen) {
                    await scannerController.resumeScanning();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(AuthController authController, ScannerController scannerController) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gate Dashboard',
                          style: AppTextStyles.h1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authController.currentUser?.name ?? 'Gate Staff',
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _HomeStatCard(
                      label: 'Scanned',
                      value: '${scannerController.scannedCount}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeStatCard(
                      label: 'Status',
                      value: 'Ready',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan tickets',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open the scanner when you are ready to validate a guest entry.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      text: 'Open Scanner',
                      onPressed: () async {
                        await scannerController.startScanning();
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Manual Code Lookup',
                      variant: AppButtonVariant.outline,
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final code = await nav.push<String>(
                          MaterialPageRoute(builder: (_) => const ManualLookupScreen()),
                        );
                        if (!mounted) return;
                        if (code != null && code.isNotEmpty) {
                          final ticket = await scannerController.lookupCode(
                            code,
                            token: authController.currentUser?.token,
                          );
                          if (mounted) {
                            await _navigateToResultPage(ticket, errorMessage: scannerController.errorMessage);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: AppButton(
                  text: 'Log out',
                  variant: AppButtonVariant.outline,
                  onPressed: () async {
                    await authController.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

class _HomeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HomeStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
