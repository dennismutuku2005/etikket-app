import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ScannerOverlay extends StatefulWidget {
  final VoidCallback onToggleTorch;
  final VoidCallback onSwitchCamera;
  final VoidCallback? onClose;
  final bool isTorchOn;
  final bool isFrontCamera;

  const ScannerOverlay({
    super.key,
    required this.onToggleTorch,
    required this.onSwitchCamera,
    this.onClose,
    this.isTorchOn = false,
    this.isFrontCamera = false,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.72;

    return Stack(
      children: [
        // Darkened mask with square transparent cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.65),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanSize,
                  height: scanSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scanner Reticle / Corner brackets
        Center(
          child: SizedBox(
            width: scanSize,
            height: scanSize,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(scanSize, scanSize),
                  painter: _ReticleCornerPainter(
                    color: AppColors.primary,
                    strokeWidth: 4.5,
                    cornerLength: 28,
                    borderRadius: 24,
                  ),
                ),

                // Animated Laser Line
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: scanSize * _animation.value,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.0),
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Helper instruction text
        Positioned(
          bottom: (size.height / 2) - (scanSize / 2) - 52,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Point camera at ticket QR code',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Top Left: Back Button
        if (widget.onClose != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _OverlayIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              isActive: false,
              onTap: widget.onClose!,
              tooltip: 'Back to Dashboard',
            ),
          ),

        // Top Controls: Torch & Camera Switch
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: Row(
            children: [
              _OverlayIconButton(
                icon: widget.isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                isActive: widget.isTorchOn,
                onTap: widget.onToggleTorch,
                tooltip: 'Toggle Flashlight',
              ),
              const SizedBox(width: 10),
              _OverlayIconButton(
                icon: Icons.flip_camera_ios_rounded,
                isActive: widget.isFrontCamera,
                onTap: widget.onSwitchCamera,
                tooltip: 'Switch Camera',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _OverlayIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? AppColors.primary : Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white24, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReticleCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double borderRadius;

  _ReticleCornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;
    final cl = cornerLength;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cl)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(cl, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(w - cl, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, cl);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, h - cl)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(cl, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(w - cl, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - cl);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
