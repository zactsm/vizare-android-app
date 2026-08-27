import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Solar Champagne Gold Glow (Positioned below status bar)
          Positioned(
            top: 30,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          VizareColors.champagneGold.withValues(alpha: 0.20),
                          VizareColors.goldDark.withValues(alpha: 0.06),
                          Colors.transparent,
                        ]
                      : [
                          VizareColors.champagneGold.withValues(alpha: 0.14),
                          VizareColors.goldLight.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // Clean Status Bar Shield (Prevents glow bleed into status bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Cosmic Violet Deep Glow
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          VizareColors.neonPurple.withValues(alpha: 0.18),
                          Colors.transparent,
                        ]
                      : [
                          VizareColors.pastelPurple.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // Luxury Ambient Wave Painter
          Positioned.fill(
            child: CustomPaint(
              painter: LuxuryWavePainter(isDark: isDark),
            ),
          ),

          // Diffusion Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: const SizedBox.expand(),
            ),
          ),

          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class LuxuryWavePainter extends CustomPainter {
  final bool isDark;

  const LuxuryWavePainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Layer 1 wave
    paint.color = isDark
        ? VizareColors.obsidianSurface.withValues(alpha: 0.7)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.5);
    final path1 = Path();
    path1.moveTo(0, size.height * 0.50);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.44,
      size.width * 0.52,
      size.height * 0.52,
    );
    path1.quadraticBezierTo(
      size.width * 0.80,
      size.height * 0.60,
      size.width,
      size.height * 0.50,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // Layer 2 wave
    paint.color = isDark
        ? VizareColors.obsidianElevated.withValues(alpha: 0.85)
        : const Color(0xFFCBD5E1).withValues(alpha: 0.35);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.72,
      size.width * 0.68,
      size.height * 0.62,
    );
    path2.quadraticBezierTo(
      size.width * 0.86,
      size.height * 0.56,
      size.width,
      size.height * 0.66,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant LuxuryWavePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
