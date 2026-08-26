import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AbstractBackground extends StatelessWidget {
  final Widget child;
  final bool showSunGlow;
  final double sunPosition; // 0.0 = dawn/morning, 0.5 = zenith gold, 1.0 = twilight violet

  const AbstractBackground({
    super.key,
    required this.child,
    this.showSunGlow = true,
    this.sunPosition = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VizareColors.obsidianBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Sun / Twilight Radiant Glow 1 (Mid-Right Solar Warmth)
          if (showSunGlow)
            Positioned(
              top: 30,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      VizareColors.champagneGold.withValues(alpha: 0.18),
                      VizareColors.goldOchre.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
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

          // Ambient Radiant Violet / Cosmic Mesh Glow (Mid-Left)
          Positioned(
            top: 260,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    VizareColors.neonPurple.withValues(alpha: 0.14),
                    VizareColors.pastelPurple.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Spatial Cyan Glow (Bottom-Right)
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    VizareColors.spatialCyan.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Subtle Noise / Blur diffusion overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox.expand(),
            ),
          ),

          // Foreground Content
          child,
        ],
      ),
    );
  }
}
