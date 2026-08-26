import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Pinned top bar background with frosted blur and smooth gradient fade.
/// Content scrolling underneath dissolves smoothly into the top bar.
class TopBarGradientBlur extends StatelessWidget {
  final double height;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final double blurSigma;

  const TopBarGradientBlur({
    super.key,
    this.height = 80.0,
    this.gradientColors,
    this.gradientStops,
    this.blurSigma = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          VizareColors.obsidianBlack.withValues(alpha: 0.95),
          VizareColors.obsidianBlack.withValues(alpha: 0.75),
          VizareColors.obsidianBlack.withValues(alpha: 0.35),
          VizareColors.obsidianBlack.withValues(alpha: 0.0),
        ];

    final stops = gradientStops ?? const [0.0, 0.50, 0.80, 1.0];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                  stops: stops,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
