import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VizareColors {
  // Canvases & Surfaces
  static const Color obsidianBlack = Color(0xFF050608);
  static const Color obsidianSurface = Color(0xFF0E1118);
  static const Color obsidianElevated = Color(0xFF161A24);
  static const Color obsidianBorder = Color(0xFF1F2432);

  // Luxury Champagne Gold Palette
  static const Color champagneGold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF6E7B0);
  static const Color goldDark = Color(0xFFAA7C11);
  static const Color goldOchre = Color(0xFFE5C07B);

  // Neon & Spatial Accents
  static const Color neonPurple = Color(0xFFDF00FF);
  static const Color pastelPurple = Color(0xFFD4B2FF);
  static const Color spatialCyan = Color(0xFF00E5FF);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color crimsonRed = Color(0xFFEF4444);

  // VisionOS Acrylic Materials
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassFillElevated = Color(0x22FFFFFF);
  static const Color glassBorderSpecular = Color(0x38FFFFFF);
  static const Color glassBorderSubtle = Color(0x10FFFFFF);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E7B0), Color(0xFFD4AF37), Color(0xFFAA7C11)],
  );

  static const LinearGradient purpleNeonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF55FF), Color(0xFFDF00FF), Color(0xFF8B00FF)],
  );

  static const LinearGradient goldPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFDF00FF)],
  );

  static const LinearGradient glassSpecularBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x55FFFFFF),
      Color(0x15FFFFFF),
      Color(0x05FFFFFF),
      Color(0x25D4AF37),
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );
}

/// High-fidelity VisionOS Frosted Glass Container with specular borders and backdrop blur
class VisionGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Gradient? borderGradient;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const VisionGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.backgroundColor,
    this.borderGradient,
    this.border,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundColor ?? VizareColors.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

/// VisionOS Pill / Capsule Widget with dynamic glow
class VisionGlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const VisionGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Luxury Champagne Gold & Neon Gradient CTA Button
class LuxuryGradientButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const LuxuryGradientButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.gradient,
    this.textColor,
    this.height = 54.0,
    this.borderRadius = 30.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? VizareColors.goldGradient;
    final effectiveTextColor = textColor ?? VizareColors.obsidianBlack;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (effectiveGradient.colors.first).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: effectiveTextColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          color: effectiveTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Spatial 3D / AR Status Badge
class SpatialBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color primaryColor;

  const SpatialBadge({
    super.key,
    required this.text,
    this.icon,
    this.primaryColor = VizareColors.champagneGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: primaryColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
