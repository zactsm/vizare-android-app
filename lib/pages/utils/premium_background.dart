import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VizareColors.obsidianBlack,
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
                  colors: [
                    VizareColors.champagneGold.withValues(alpha: 0.20),
                    VizareColors.goldDark.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Clean Obsidian Status Bar Shield (Prevents glow bleed into status bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      VizareColors.obsidianBlack,
                      Colors.transparent,
                    ],
                    stops: [0.0, 1.0],
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
                  colors: [
                    VizareColors.neonPurple.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Luxury Ambient Wave Painter
          Positioned.fill(
            child: CustomPaint(
              painter: LuxuryWavePainter(),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Layer 1: Deep obsidian wave
    paint.color = VizareColors.obsidianSurface.withValues(alpha: 0.7);
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

    // Layer 2: Elevated obsidian wave with subtle gold specular sheen
    paint.color = VizareColors.obsidianElevated.withValues(alpha: 0.85);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
