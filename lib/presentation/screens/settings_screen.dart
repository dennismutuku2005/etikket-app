import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final settingsController = context.watch<SettingsController>();
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings & Profile', style: AppTextStyles.h2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Staff Profile Card
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
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
                            radius: 26,
                            backgroundColor: AppColors.primaryTint10,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
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
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    user.role.replaceAll('_', ' ').toUpperCase(),
                                    style: AppTextStyles.captionBold.copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 14),
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
              const SizedBox(height: 20),

              // Help & Support Card
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
                        const Icon(Icons.help_outline_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Help & Support', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Having issues scanning tickets or need account permissions? Contact your event organizer or administrator.',
                      style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

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
                      'Fast & Secure Event Check-In',
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
