import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VizareColors {
  // Canvases & Surfaces (Dark)
  static const Color obsidianBlack = Color(0xFF050608);
  static const Color obsidianSurface = Color(0xFF0E1118);
  static const Color obsidianElevated = Color(0xFF161A24);
  static const Color obsidianBorder = Color(0xFF1F2432);

  // Canvases & Surfaces (Light)
  static const Color alabasterWhite = Color(0xFFF6F8FA);
  static const Color alabasterSurface = Color(0xFFFFFFFF);
  static const Color alabasterElevated = Color(0xFFF1F5F9);
  static const Color alabasterBorder = Color(0xFFE2E8F0);

  // Luxury Champagne Gold Palette
  static const Color champagneGold = Color(0xFFD4AF37);
  static const Color champagneGoldAccessible = Color(0xFF8A6500); // 4.58:1 contrast on white (WCAG AA)
  static const Color goldLight = Color(0xFFF6E7B0);
  static const Color goldDark = Color(0xFFAA7C11);
  static const Color goldOchre = Color(0xFFE5C07B);

  static Color adaptiveGold(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? champagneGold
        : champagneGoldAccessible;
  }

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
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isDark ? 20 : 16,
                offset: isDark ? const Offset(0, 10) : const Offset(0, 4),
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
              color: backgroundColor ??
                  (isDark
                      ? VizareColors.glassFill
                      : Colors.white.withValues(alpha: 0.9)),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFE2E8F0),
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
  final String? semanticLabel;

  const VisionGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.color,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: color ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: borderColor ??
                      (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFCBD5E1)),
                  width: 1.0,
                ),
              ),
              child: child,
            ),
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

/// Standardized Accessible Glass Dialog Modal
class VizareDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color confirmColor;

  const VizareDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.confirmColor = VizareColors.champagneGold,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? VizareColors.obsidianElevated : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? VizareColors.glassBorderSpecular : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? VizareColors.textPrimary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelText != null) ...[
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: onCancel ?? () => Navigator.pop(context),
                      child: Text(
                        cancelText!,
                        style: GoogleFonts.poppins(
                          color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.poppins(
                        color: confirmColor == VizareColors.champagneGold || confirmColor == VizareColors.goldLight
                            ? VizareColors.obsidianBlack
                            : (isDark ? VizareColors.textPrimary : Colors.white),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// VisionOS Circle Button Widget (100% Perfect Circle for Back Buttons & Icon Actions)
class VisionGlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  const VisionGlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48.0,
    this.iconColor,
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor =
        iconColor ?? (isDark ? VizareColors.textPrimary : const Color(0xFF0F172A));

    return Semantics(
      button: true,
      label: semanticLabel ?? 'Button',
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.9)),
                border: Border.all(
                  color: borderColor ??
                      (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFCBD5E1)),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized Top App Bar Component
class VizareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const VizareAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: VisionGlassCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBackPressed ?? () => Navigator.pop(context),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isDark ? VizareColors.textPrimary : const Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}

/// Animated Luxury Shimmer Sweep
class VizareShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const VizareShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0x22FFFFFF),
    this.highlightColor = const Color(0x55E5C07B),
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<VizareShimmer> createState() => _VizareShimmerState();
}

class _VizareShimmerState extends State<VizareShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// Clean rounded skeleton placeholder block
class VizareSkeletonBlock extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const VizareSkeletonBlock({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ??
            (isDark
                ? VizareColors.glassFillElevated
                : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer Skeleton Loading Card for Property Grid/List
class VizareCardSkeleton extends StatelessWidget {
  final double height;
  final double width;

  const VizareCardSkeleton({
    super.key,
    this.height = 240,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VizareShimmer(
      baseColor: isDark ? const Color(0x22FFFFFF) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0x55E5C07B) : const Color(0xFFF8FAFC),
      child: VisionGlassContainer(
        height: height,
        width: width,
        margin: const EdgeInsets.only(bottom: 16),
        borderRadius: 24,
        backgroundColor: isDark
            ? VizareColors.obsidianSurface.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? VizareColors.glassFillElevated
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: isDark
                    ? VizareColors.glassFill
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: isDark
                    ? VizareColors.glassFill
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Curated Luxury Obsidian & Champagne Gold Google Maps Style
const String kVizareDarkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#0d1017"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8c96a8"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0d1017"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d4af37"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#758092"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#111822"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5e6c7d"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#1c2230"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#141923"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a95a5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#2a3449"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#181f2c"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d4af37"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#19202c"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d4af37"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#06080d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3d4b60"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#06080d"}]
  }
]
''';

/// Theme Controller managing System, Dark Obsidian, and Alabaster Light modes
class AppThemeController extends ChangeNotifier {
  static final AppThemeController instance = AppThemeController._internal();
  AppThemeController._internal();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Obsidian Dark';
      case ThemeMode.light:
        return 'Alabaster Light';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  /// Loads theme mode. If unauthenticated, strictly enforces ThemeMode.dark.
  /// If authenticated, loads cached preference and syncs from Supabase database.
  Future<void> loadThemeMode({bool isAuthenticated = false}) async {
    if (!isAuthenticated) {
      _themeMode = ThemeMode.dark;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('app_theme_mode');
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }
      notifyListeners();

      // Attempt background refresh from Supabase profile if session is active
      fetchUserThemeFromDatabase();
    } catch (_) {}
  }

  /// Fetches the authenticated user's theme preference from Supabase and applies it
  Future<void> fetchUserThemeFromDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('theme_preference')
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (profile != null && profile['theme_preference'] != null) {
          final prefStr = profile['theme_preference'].toString().toLowerCase();
          applyUserThemePreference(prefStr, syncToDb: false);
        }
      }
    } catch (_) {}
  }

  /// Applies theme from a string preference ('dark' | 'light' | 'system')
  Future<void> applyUserThemePreference(String? preference,
      {bool syncToDb = false}) async {
    ThemeMode mode = ThemeMode.dark;
    if (preference == 'light') {
      mode = ThemeMode.light;
    } else if (preference == 'system') {
      mode = ThemeMode.system;
    }

    await setThemeMode(mode, syncToDb: syncToDb);
  }

  /// Updates current theme mode, saves to local cache, and optionally syncs to DB
  Future<void> setThemeMode(ThemeMode mode, {bool syncToDb = true}) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'dark';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.system) modeStr = 'system';
      await prefs.setString('app_theme_mode', modeStr);

      if (syncToDb) {
        syncThemeToDatabase(mode);
      }
    } catch (_) {}
  }

  /// Persists theme preference into Supabase profiles table
  Future<void> syncThemeToDatabase(ThemeMode mode) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        String modeStr = 'dark';
        if (mode == ThemeMode.light) modeStr = 'light';
        if (mode == ThemeMode.system) modeStr = 'system';

        await Supabase.instance.client
            .from('profiles')
            .update({'theme_preference': modeStr})
            .eq('auth_user_id', user.id);
      }
    } catch (_) {}
  }

  /// Resets theme to Obsidian Dark and cleans local cached preferences upon sign out
  Future<void> resetToDefaultDark() async {
    _themeMode = ThemeMode.dark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_theme_mode');
    } catch (_) {}
  }
}

/// Global Theme Definitions for Vizare
class VizareTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050608),
      primaryColor: VizareColors.champagneGold,
      colorScheme: const ColorScheme.dark(
        primary: VizareColors.champagneGold,
        secondary: Color(0xFFF3E5AB),
        surface: Color(0xFF0E1118),
        error: Color(0xFFEF4444),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: const Color(0xFFFFFFFF),
          displayColor: const Color(0xFFFFFFFF),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: VizareColors.champagneGold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VizareColors.champagneGold,
          foregroundColor: const Color(0xFF050608),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 8,
          shadowColor: VizareColors.champagneGold.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VizareColors.champagneGold,
          side: const BorderSide(color: VizareColors.champagneGold, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VizareColors.champagneGold,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 14,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        labelStyle: const TextStyle(
          color: VizareColors.champagneGold,
          fontSize: 14,
        ),
        prefixIconColor: VizareColors.champagneGold,
        suffixIconColor: Colors.white60,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: VizareColors.champagneGold,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      primaryColor: VizareColors.champagneGold,
      colorScheme: const ColorScheme.light(
        primary: VizareColors.champagneGold,
        secondary: Color(0xFFAA7C11),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFEF4444),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: VizareColors.champagneGold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VizareColors.champagneGold,
          foregroundColor: const Color(0xFF050608),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 4,
          shadowColor: VizareColors.champagneGold.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VizareColors.champagneGold,
          side: const BorderSide(color: VizareColors.champagneGold, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VizareColors.champagneGold,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        labelStyle: const TextStyle(
          color: VizareColors.champagneGold,
          fontSize: 14,
        ),
        prefixIconColor: VizareColors.champagneGold,
        suffixIconColor: const Color(0xFF64748B),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFCBD5E1),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFCBD5E1),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: VizareColors.champagneGold,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}



