import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/settings_page.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/page_transitions.dart';

enum NavPageIndex { home, search, favorites, settings }

class NavBarConfig {
  final double height;
  final double barWidth;
  final double pillInsetH;
  final double pillInsetV;
  final double ovalPaddingH;
  final double gapWidth;
  final double collapsedWidth;
  final double bottomMargin;

  const NavBarConfig({
    this.height = 66.0,
    this.barWidth = 348.0,
    this.pillInsetH = 4.0,
    this.pillInsetV = 6.0,
    this.ovalPaddingH = 10.0,
    this.gapWidth = 5.0,
    this.collapsedWidth = 32.0,
    this.bottomMargin = 24.0,
  });

  /// Automatically picks the tuned preset for Web (Vercel), iOS, or Android
  static NavBarConfig get platformDefault {
    if (kIsWeb) {
      return const NavBarConfig(
        height: 70.0,
        barWidth: 400.0,
        pillInsetV: 6.0,
        pillInsetH: 5.0,
        ovalPaddingH: 18.0,
        gapWidth: 9.0,
        collapsedWidth: 36.0,
        bottomMargin: 24.0,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const NavBarConfig(
        height: 66.0,
        barWidth: 348.0,
        pillInsetV: 6.0,
        pillInsetH: 4.0,
        ovalPaddingH: 10.0,
        gapWidth: 5.0,
        collapsedWidth: 32.0,
        bottomMargin: 24.0,
      );
    } else {
      // Android / other platforms default
      return const NavBarConfig(
        height: 66.0,
        barWidth: 348.0,
        pillInsetV: 6.0,
        pillInsetH: 4.0,
        ovalPaddingH: 10.0,
        gapWidth: 5.0,
        collapsedWidth: 32.0,
        bottomMargin: 24.0,
      );
    }
  }

  NavBarConfig copyWith({
    double? height,
    double? barWidth,
    double? pillInsetH,
    double? pillInsetV,
    double? ovalPaddingH,
    double? gapWidth,
    double? collapsedWidth,
    double? bottomMargin,
  }) {
    return NavBarConfig(
      height: height ?? this.height,
      barWidth: barWidth ?? this.barWidth,
      pillInsetH: pillInsetH ?? this.pillInsetH,
      pillInsetV: pillInsetV ?? this.pillInsetV,
      ovalPaddingH: ovalPaddingH ?? this.ovalPaddingH,
      gapWidth: gapWidth ?? this.gapWidth,
      collapsedWidth: collapsedWidth ?? this.collapsedWidth,
      bottomMargin: bottomMargin ?? this.bottomMargin,
    );
  }
}

class FloatingBottomNavBar extends StatefulWidget {
  final NavPageIndex activeIndex;
  final PageController? pageController;
  final ValueChanged<NavPageIndex>? onTap;
  final NavBarConfig? customConfig;

  const FloatingBottomNavBar({
    super.key,
    required this.activeIndex,
    this.pageController,
    this.onTap,
    this.customConfig,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 3.0,
      value: widget.activeIndex.index.toDouble(),
    );

    if (widget.pageController != null) {
      widget.pageController!.addListener(_onPageScroll);
    }
  }

  void _onPageScroll() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant FloatingBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController?.removeListener(_onPageScroll);
      widget.pageController?.addListener(_onPageScroll);
    }

    if (widget.pageController == null) {
      _animController.animateTo(
        widget.activeIndex.index.toDouble(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPageScroll);
    _animController.dispose();
    super.dispose();
  }

  double _getTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final config = widget.customConfig ?? NavBarConfig.platformDefault;

    final double pageProgress = widget.pageController != null
        ? (widget.pageController!.hasClients
            ? (widget.pageController!.page ??
                widget.activeIndex.index.toDouble())
            : widget.activeIndex.index.toDouble())
        : _animController.value;

    final labelStyle = GoogleFonts.poppins(
      fontSize: 11.0,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: VizareColors.obsidianBlack,
    );

    final List<String> labels = [
      'EXPLORE',
      'SEARCH',
      'FAVORITES',
      'SETTINGS',
    ];

    final List<String> activeIcons = [
      'assets/images/home_icon.png',
      'assets/images/search_icon.png',
      'assets/images/fav_icon.png',
      'assets/images/settings_icon.png',
    ];

    final List<String> inactiveIcons = [
      'assets/images/white_home_icon.png',
      'assets/images/white_search_icon.png',
      'assets/images/white_fav_icon.png',
      'assets/images/white_settings_icon.png',
    ];

    const double iconWidth = 18.0;
    final double gapWidth = config.gapWidth;
    final double ovalPaddingH = config.ovalPaddingH;

    final Map<int, double> textWidths = {};
    final Map<int, double> targetOvalWidths = {};

    for (int i = 0; i < labels.length; i++) {
      final double tw = _getTextWidth(labels[i], labelStyle) + 1.5;
      textWidths[i] = tw;
      targetOvalWidths[i] = iconWidth + gapWidth + tw + (2 * ovalPaddingH);
    }

    final double barWidth = widget.customConfig != null
        ? config.barWidth
        : (screenWidth > (config.barWidth + 32)
            ? config.barWidth
            : (screenWidth - 32).clamp(260.0, config.barWidth));

    final double containerRadius = config.height / 2.0;
    final double pillHeight = config.height - (2 * config.pillInsetV);
    final double pillRadius = (pillHeight / 2.0).clamp(8.0, 45.0);

    // Safe boundaries to prevent clipping at rounded ends:
    final double safeInset = config.pillInsetV.clamp(0.0, containerRadius - 4.0);
    final double usableSpan = barWidth - (2.0 * safeInset);

    // Dynamic width for each tab based on its closeness to being active:
    final List<double> tabCloseness = [];
    final List<double> dynamicItemWidths = [];

    for (int i = 0; i < 4; i++) {
      final double c = (1.0 - (pageProgress - i).abs()).clamp(0.0, 1.0);
      tabCloseness.add(c);
      final double targetW = targetOvalWidths[i] ?? 92.0;
      dynamicItemWidths.add(config.collapsedWidth + (targetW - config.collapsedWidth) * c);
    }

    final double totalWidths = dynamicItemWidths.reduce((a, b) => a + b);
    final double availableSpace = (usableSpan - totalWidths).clamp(0.0, double.infinity);
    final double dynamicGap = availableSpace / 3.0;

    // Compute exact left coordinates for each tab:
    final List<double> tabLefts = [];
    double currentX = safeInset;

    for (int i = 0; i < 4; i++) {
      tabLefts.add(currentX);
      currentX += dynamicItemWidths[i] + dynamicGap;
    }

    // Determine the active morphing pill frame (sliding and morphing continuously)
    final int prevIndex = pageProgress.floor().clamp(0, 3);
    final int nextIndex = pageProgress.ceil().clamp(0, 3);
    final double fraction = pageProgress - prevIndex;

    final double activePillLeft =
        tabLefts[prevIndex] + (tabLefts[nextIndex] - tabLefts[prevIndex]) * fraction;
    final double activePillWidth =
        dynamicItemWidths[prevIndex] + (dynamicItemWidths[nextIndex] - dynamicItemWidths[prevIndex]) * fraction;

    Widget buildNavItem(int index) {
      final double closeness = tabCloseness[index];
      final double itemWidth = dynamicItemWidths[index];
      final double left = tabLefts[index];

      return Positioned(
        left: left,
        top: config.pillInsetV,
        bottom: config.pillInsetV,
        width: itemWidth,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!(NavPageIndex.values[index]);
            } else if (widget.pageController != null) {
              widget.pageController!.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              if (widget.activeIndex.index != index) {
                Widget targetPage;
                switch (NavPageIndex.values[index]) {
                  case NavPageIndex.home:
                    targetPage = const HomeBuyerPage();
                    break;
                  case NavPageIndex.search:
                    targetPage = const SearchPage();
                    break;
                  case NavPageIndex.favorites:
                    targetPage = const FavoritesPage();
                    break;
                  case NavPageIndex.settings:
                    targetPage = const SettingsPage();
                    break;
                }
                Navigator.of(context).pushReplacement(fadeRoute(targetPage));
              }
            }
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (1.0 - closeness).clamp(0.0, 1.0),
                        child: Image.asset(
                          inactiveIcons[index],
                          width: 20,
                          height: 20,
                          color: VizareColors.textSecondary,
                        ),
                      ),
                      Opacity(
                        opacity: closeness,
                        child: Image.asset(
                          activeIcons[index],
                          width: iconWidth,
                          height: iconWidth,
                          color: VizareColors.obsidianBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRect(
                  child: Opacity(
                    opacity: closeness,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: gapWidth * closeness,
                      ),
                      child: SizedBox(
                        height: 18,
                        width: (textWidths[index] ?? 50.0) * closeness,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            labels[index],
                            maxLines: 1,
                            softWrap: false,
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: config.bottomMargin,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(containerRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(
              width: barWidth,
              height: config.height,
              decoration: BoxDecoration(
                color: VizareColors.obsidianSurface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(containerRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.03),
                    VizareColors.obsidianSurface.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: VizareColors.champagneGold.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 1. Fluidly morphing VisionOS Champagne Gold pill
                  Positioned(
                    left: activePillLeft,
                    top: config.pillInsetV,
                    bottom: config.pillInsetV,
                    width: activePillWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: VizareColors.goldGradient,
                        borderRadius: BorderRadius.circular(pillRadius),
                        boxShadow: [
                          BoxShadow(
                            color: VizareColors.champagneGold.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2. Interactive Navigation Items positioned dynamically
                  buildNavItem(0),
                  buildNavItem(1),
                  buildNavItem(2),
                  buildNavItem(3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
