import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Pinned top bar background with smooth multi-stop gradient fade.
/// Content scrolling underneath dissolves smoothly into the top bar with no hard edges.
class TopBarGradientBlur extends StatelessWidget {
  final double height;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final double blurSigma;
  final bool enableBackdropBlur;

  const TopBarGradientBlur({
    super.key,
    this.height = 90.0,
    this.gradientColors,
    this.gradientStops,
    this.blurSigma = 0.0,
    this.enableBackdropBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite;
    final colors = gradientColors ??
        [
          baseColor,
          baseColor.withValues(alpha: 0.92),
          baseColor.withValues(alpha: 0.60),
          baseColor.withValues(alpha: 0.20),
          baseColor.withValues(alpha: 0.0),
        ];

    final stops = gradientStops ?? const [0.0, 0.40, 0.70, 0.88, 1.0];

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ),
      ),
    );

    if (enableBackdropBlur && blurSigma > 0) {
      content = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: content,
      ),
    );
  }
}
