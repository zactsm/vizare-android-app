import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/settings_page.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/page_transitions.dart';

enum NavPageIndex { home, search, favorites, settings }

class FloatingBottomNavBar extends StatefulWidget {
  final NavPageIndex activeIndex;
  final PageController? pageController;
  final ValueChanged<NavPageIndex>? onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.activeIndex,
    this.pageController,
    this.onTap,
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

    final double pageProgress = widget.pageController != null
        ? (widget.pageController!.hasClients
            ? (widget.pageController!.page ??
                widget.activeIndex.index.toDouble())
            : widget.activeIndex.index.toDouble())
        : _animController.value;

    final labelStyle = GoogleFonts.poppins(
      fontSize: 10.5,
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
    const double gapWidth = 6.0;
    const double ovalPaddingH = 12.0;

    final Map<int, double> textWidths = {};
    final Map<int, double> targetOvalWidths = {};

    for (int i = 0; i < labels.length; i++) {
      final double tw = _getTextWidth(labels[i], labelStyle) + 2.0;
      textWidths[i] = tw;
      targetOvalWidths[i] = iconWidth + gapWidth + tw + (2 * ovalPaddingH);
    }

    final double maxBarWidth = screenWidth > 480 ? 480 : screenWidth;
    final double barWidth = maxBarWidth - 32;
    const double containerPaddingH = 8.0;
    final double innerWidth = barWidth - (2 * containerPaddingH);

    const double safetyMargin = 12.0;
    final double halfWidth0 = (targetOvalWidths[0] ?? 90.0) / 2.0;
    final double halfWidth3 = (targetOvalWidths[3] ?? 90.0) / 2.0;

    final double defaultCenter0 = innerWidth * 0.125;
    final double defaultCenter3 = innerWidth * 0.875;

    final double minCenter0 = halfWidth0 + safetyMargin;
    final double maxCenter3 = innerWidth - halfWidth3 - safetyMargin;

    final double center0 =
        minCenter0 > defaultCenter0 ? minCenter0 : defaultCenter0;
    final double center3 =
        maxCenter3 < defaultCenter3 ? maxCenter3 : defaultCenter3;

    final double step = (center3 - center0) / 3.0;
    final List<double> tabCenters = [
      center0,
      center0 + step,
      center0 + 2 * step,
      center3,
    ];

    final int activeIndexInt = pageProgress.round().clamp(0, 3);
    final double closeness =
        (1.0 - (pageProgress - activeIndexInt).abs() * 2).clamp(0.0, 1.0);

    final double activeTargetWidth = targetOvalWidths[activeIndexInt] ?? 90.0;
    const double collapsedWidth = 44.0;
    final double activeOvalWidth =
        collapsedWidth + (activeTargetWidth - collapsedWidth) * closeness;

    final int prevIndex = pageProgress.floor().clamp(0, 3);
    final int nextIndex = pageProgress.ceil().clamp(0, 3);
    final double fraction = pageProgress - prevIndex;

    final double prevCenter = tabCenters[prevIndex];
    final double nextCenter = tabCenters[nextIndex];
    final double activeCenter =
        prevCenter + (nextCenter - prevCenter) * fraction;

    final double ovalLeftRaw = activeCenter - (activeOvalWidth / 2);
    final double ovalLeft =
        ovalLeftRaw.clamp(0.0, innerWidth - activeOvalWidth);
    final double itemTouchWidth = innerWidth / 4.0;

    Widget buildNavItem(int index, String inactiveIcon) {
      final double closenessAtTab =
          (1.0 - (pageProgress - index).abs()).clamp(0.0, 1.0);
      final double opacity = (1.0 - closenessAtTab).clamp(0.0, 1.0);
      final double centerPos = tabCenters[index];

      return Positioned(
        left: centerPos - (itemTouchWidth / 2.0),
        top: 0,
        bottom: 0,
        width: itemTouchWidth,
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
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                inactiveIcon,
                width: 20,
                height: 20,
                color: VizareColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(
                horizontal: containerPaddingH,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: VizareColors.obsidianSurface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(36),
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
                  // Sliding and morphing VisionOS Champagne Gold & Neon pill
                  Positioned(
                    left: ovalLeft,
                    top: 6,
                    bottom: 6,
                    width: activeOvalWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: VizareColors.goldGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: VizareColors.champagneGold.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              activeIcons[activeIndexInt],
                              width: iconWidth,
                              height: iconWidth,
                              color: VizareColors.obsidianBlack,
                            ),
                            ClipRect(
                              child: Opacity(
                                opacity: closeness,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: gapWidth * closeness,
                                  ),
                                  child: SizedBox(
                                    height: 16,
                                    width: (textWidths[activeIndexInt] ?? 50.0) *
                                        closeness,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        labels[activeIndexInt],
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
                  ),
                  // Inactive items positioned centered on each tab center
                  buildNavItem(0, inactiveIcons[0]),
                  buildNavItem(1, inactiveIcons[1]),
                  buildNavItem(2, inactiveIcons[2]),
                  buildNavItem(3, inactiveIcons[3]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
