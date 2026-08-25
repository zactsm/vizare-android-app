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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double pageProgress = widget.pageController != null
        ? (widget.pageController!.hasClients
            ? (widget.pageController!.page ??
                widget.activeIndex.index.toDouble())
            : widget.activeIndex.index.toDouble())
        : _animController.value;

    final double maxBarWidth = screenWidth > 480 ? 480 : screenWidth;
    final double barWidth = maxBarWidth - 32;
    final double innerWidth = barWidth - 12;
    final double segmentWidth = innerWidth / 4;

    final Map<int, double> ovalWidths = {
      0: 116.0, // EXPLORE
      1: 108.0, // SEARCH
      2: 126.0, // FAVORITES
      3: 118.0, // SETTINGS
    };

    final Map<int, double> textWidths = {
      0: 68.0,
      1: 60.0,
      2: 82.0,
      3: 72.0,
    };

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

    final List<String> labels = [
      'EXPLORE',
      'SEARCH',
      'FAVORITES',
      'SETTINGS',
    ];

    final int activeIndexInt = pageProgress.round().clamp(0, 3);
    final double closeness =
        (1.0 - (pageProgress - activeIndexInt).abs() * 2).clamp(0.0, 1.0);

    final double maxWidthForActive = ovalWidths[activeIndexInt] ?? 116.0;
    final double activeOvalWidth =
        48.0 + (maxWidthForActive - 48.0) * closeness;

    final int prevIndex = pageProgress.floor().clamp(0, 3);
    final int nextIndex = pageProgress.ceil().clamp(0, 3);
    final double fraction = pageProgress - pageProgress.floor();

    final double prevCenter = segmentWidth * (prevIndex + 0.5);
    final double nextCenter = segmentWidth * (nextIndex + 0.5);
    final double activeCenter =
        prevCenter + (nextCenter - prevCenter) * fraction;

    final double ovalLeft = (activeCenter - (activeOvalWidth / 2))
        .clamp(4.0, innerWidth - activeOvalWidth - 4.0);

    Widget buildNavItem(int index, String inactiveIcon) {
      final double closenessAtTab =
          (1.0 - (pageProgress - index).abs()).clamp(0.0, 1.0);
      final double opacity = (1.0 - closenessAtTab).clamp(0.0, 1.0);

      return Expanded(
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
          child: SizedBox(
            height: double.infinity,
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
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
            child: Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: VizareColors.obsidianSurface.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: VizareColors.champagneGold.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Sliding and morphing VisionOS Champagne Gold & Neon pill
                  Positioned(
                    left: ovalLeft,
                    top: 4,
                    bottom: 4,
                    width: activeOvalWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: VizareColors.goldGradient,
                        borderRadius: BorderRadius.circular(30),
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
                              width: 19,
                              height: 19,
                              color: VizareColors.obsidianBlack,
                            ),
                            ClipRect(
                              child: Opacity(
                                opacity: closeness,
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(left: 7.0 * closeness),
                                  child: SizedBox(
                                    height: 18,
                                    width: (textWidths[activeIndexInt] ?? 64.0) *
                                        closeness,
                                    child: Text(
                                      labels[activeIndexInt],
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: VizareColors.obsidianBlack,
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
                  // Inactive items row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildNavItem(0, inactiveIcons[0]),
                      buildNavItem(1, inactiveIcons[1]),
                      buildNavItem(2, inactiveIcons[2]),
                      buildNavItem(3, inactiveIcons[3]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
