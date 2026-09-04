import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsController>(context, listen: false);
    _urlController.text = settings.currentBaseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveUrl() async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await settings.updateBaseUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server URL updated.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final settingsController = context.watch<SettingsController>();
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gate Settings', style: AppTextStyles.h2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Staff Profile Card (if authenticated)
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryTint10,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: AppTextStyles.h3),
                                const SizedBox(height: 2),
                                Text(user.email, style: AppTextStyles.caption),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: AppTextStyles.captionBold.copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Log Out of Gate Session',
                        variant: AppButtonVariant.outline,
                        height: 44,
                        icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                        onPressed: () async {
                          await authController.logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Server Configuration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Backend API Server', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure backend server endpoint used for ticket validation and authentication.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _urlController,
                      label: 'Base URL',
                      hintText: 'http://10.0.2.2:5000',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSaveUrl(),
                    ),
                    const SizedBox(height: 12),

                    // Quick URL Presets
                    Text('Presets:', style: AppTextStyles.captionBold),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Android Emulator (10.0.2.2:5000)'),
                          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                          backgroundColor: AppColors.surfaceAlt,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          onPressed: () {
                            _urlController.text = ApiEndpoints.defaultBaseUrl;
                            _handleSaveUrl();
                          },
                        ),
                        ActionChip(
                          label: const Text('Localhost (127.0.0.1:5000)'),
                          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                          backgroundColor: AppColors.surfaceAlt,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          onPressed: () {
                            _urlController.text = 'http://127.0.0.1:5000';
                            _handleSaveUrl();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Save Server URL',
                            height: 46,
                            onPressed: _handleSaveUrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'Test Connection',
                            variant: AppButtonVariant.secondary,
                            height: 46,
                            isLoading: settingsController.isTestingConnection,
                            onPressed: () => settingsController.testConnection(),
                          ),
                        ),
                      ],
                    ),

                    // Connection test result indicator
                    if (settingsController.connectionSuccess != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settingsController.connectionSuccess == true
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: settingsController.connectionSuccess == true
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              settingsController.connectionSuccess == true
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              size: 18,
                              color: settingsController.connectionSuccess == true
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                settingsController.connectionMessage ?? '',
                                style: AppTextStyles.caption.copyWith(
                                  color: settingsController.connectionSuccess == true
                                      ? AppColors.successText
                                      : AppColors.errorText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Scanner Preferences Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vibration_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Scanner Preferences', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.primary,
                      title: Text('Haptic Vibration Feedback', style: AppTextStyles.bodyBold),
                      subtitle: Text('Vibrate phone upon successful scan', style: AppTextStyles.caption),
                      value: settingsController.vibrationEnabled,
                      onChanged: (val) => settingsController.setVibrationEnabled(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // App Version Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'eTikket Gate Scanner · v1.0.0',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Built for Android Gate Staff Check-In',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
