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
    const double gapWidth = 6.0;
    const double ovalPaddingH = 11.0;

    final Map<int, double> textWidths = {};
    final Map<int, double> targetOvalWidths = {};

    for (int i = 0; i < labels.length; i++) {
      final double tw = _getTextWidth(labels[i], labelStyle) + 1.5;
      textWidths[i] = tw;
      targetOvalWidths[i] = iconWidth + gapWidth + tw + (2 * ovalPaddingH);
    }

    final double maxBarWidth = screenWidth > 400 ? 330 : (screenWidth - 48);
    final double barWidth = maxBarWidth.clamp(280.0, 330.0);
    const double pillInsetH = 5.0;
    const double pillInsetV = 6.0;
    final double innerWidth = barWidth - (2 * pillInsetH);

    // Dynamic space allocation:
    // When a tab is active (closeness = 1.0), it expands to its target active width.
    // Inactive tabs compress down to collapsedWidth, freeing up space for the active pill.
    const double collapsedWidth = 36.0;
    final List<double> tabCloseness = [];
    final List<double> tabWidths = [];

    for (int i = 0; i < 4; i++) {
      final double c = (1.0 - (pageProgress - i).abs()).clamp(0.0, 1.0);
      tabCloseness.add(c);
      final double targetW = targetOvalWidths[i] ?? 92.0;
      tabWidths.add(collapsedWidth + (targetW - collapsedWidth) * c);
    }

    final double totalTabWidths = tabWidths.reduce((a, b) => a + b);
    final double availableSpace = innerWidth - totalTabWidths;
    final double dynamicGap = (availableSpace / 3.0).clamp(0.0, 40.0);

    // Compute continuous left coordinates for each item
    final List<double> tabLefts = [];
    double currentX = (availableSpace - (dynamicGap * 3.0)) / 2.0;
    if (currentX < 0) currentX = 0;

    for (int i = 0; i < 4; i++) {
      tabLefts.add(currentX);
      currentX += tabWidths[i] + dynamicGap;
    }

    // Determine the active morphing pill frame (sliding and morphing continuously)
    final int prevIndex = pageProgress.floor().clamp(0, 3);
    final int nextIndex = pageProgress.ceil().clamp(0, 3);
    final double fraction = pageProgress - prevIndex;

    final double activePillLeft =
        tabLefts[prevIndex] + (tabLefts[nextIndex] - tabLefts[prevIndex]) * fraction;
    final double activePillWidth =
        tabWidths[prevIndex] + (tabWidths[nextIndex] - tabWidths[prevIndex]) * fraction;

    Widget buildNavItem(int index) {
      final double closeness = tabCloseness[index];
      final double width = tabWidths[index];
      final double left = tabLefts[index];

      return Positioned(
        left: left,
        top: 0,
        bottom: 0,
        width: width,
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
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
            child: Container(
              width: barWidth,
              height: 70,
              padding: const EdgeInsets.symmetric(
                horizontal: pillInsetH,
                vertical: pillInsetV,
              ),
              decoration: BoxDecoration(
                color: VizareColors.obsidianSurface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(35),
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
                    top: 0,
                    bottom: 0,
                    width: activePillWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: VizareColors.goldGradient,
                        borderRadius: BorderRadius.circular(29),
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
