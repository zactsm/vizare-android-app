import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/settings_page.dart';
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

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> with SingleTickerProviderStateMixin {
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
    const Color pastelPurple = Color(0xFFD4B2FF);

    final double pageProgress = widget.pageController != null
        ? (widget.pageController!.hasClients
            ? (widget.pageController!.page ?? widget.activeIndex.index.toDouble())
            : widget.activeIndex.index.toDouble())
        : _animController.value;

    final double maxBarWidth = screenWidth > 480 ? 480 : screenWidth;
    final double barWidth = maxBarWidth - 32; // Fixed margins (16px left/right) for consistency
    final double innerWidth = barWidth - 10; // padding horizontal 5 * 2
    final double segmentWidth = innerWidth / 4;

    final Map<int, double> ovalWidths = {
      0: 110.0, // Home (EXPLORE)
      1: 103.0, // Search (SEARCH)
      2: 121.0, // Favorites (FAVORITES)
      3: 113.0, // Settings (SETTINGS)
    };

    final Map<int, double> textWidths = {
      0: 64.0, // EXPLORE
      1: 56.0, // SEARCH
      2: 78.0, // FAVORITES
      3: 67.0, // SETTINGS
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

    // Determine the closest index to anchor the active label and icon inside the sliding oval
    final int activeIndexInt = pageProgress.round().clamp(0, 3);
    final double closeness = (1.0 - (pageProgress - activeIndexInt).abs() * 2).clamp(0.0, 1.0);

    // Compute size and position of sliding background oval
    final double maxWidthForActive = ovalWidths[activeIndexInt] ?? 110.0;
    // Shrinks to a circular badge (width 48) when swiping in-between tabs
    final double activeOvalWidth = 48.0 + (maxWidthForActive - 48.0) * closeness;

    final int prevIndex = pageProgress.floor().clamp(0, 3);
    final int nextIndex = pageProgress.ceil().clamp(0, 3);
    final double fraction = pageProgress - pageProgress.floor();

    final double prevCenter = segmentWidth * (prevIndex + 0.5);
    final double nextCenter = segmentWidth * (nextIndex + 0.5);
    final double activeCenter = prevCenter + (nextCenter - prevCenter) * fraction;

    // Clamp the position so the oval stays perfectly inside the navigation bar boundaries with a 4px safety padding
    final double ovalLeft = (activeCenter - (activeOvalWidth / 2)).clamp(4.0, innerWidth - activeOvalWidth - 4.0);

    Widget buildNavItem(int index, String inactiveIcon) {
      final double closenessAtTab = (1.0 - (pageProgress - index).abs()).clamp(0.0, 1.0);
      final double opacity = (1.0 - closenessAtTab).clamp(0.0, 1.0);

      return Expanded(
        child: GestureDetector(
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
              // Fallback to pushReplacement if no pageController or onTap is provided
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
          child: Container(
            color: Colors.transparent, // expand hit test area
            height: double.infinity,
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  inactiveIcon,
                  width: 20,
                  height: 20,
                  color: const Color(0xFF8E8E93),
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
          borderRadius: BorderRadius.circular(38),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF121214).withValues(alpha: 0.65), // Glassy dark grey background
                borderRadius: BorderRadius.circular(38),
                border: Border.all(color: pastelPurple.withValues(alpha: 0.7), width: 2.0), // High contrast border
              ),
              child: Stack(
                children: [
                  // Sliding and expanding purple oval background
                  Positioned(
                    left: ovalLeft,
                    top: 4,
                    bottom: 4,
                    width: activeOvalWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: pastelPurple,
                        borderRadius: BorderRadius.circular(29),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              activeIcons[activeIndexInt],
                              width: 20,
                              height: 20,
                              color: const Color(0xFF000000),
                            ),
                            ClipRect(
                              child: Opacity(
                                opacity: closeness,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.0 * closeness),
                                  child: SizedBox(
                                    height: 20,
                                    width: (textWidths[activeIndexInt] ?? 60.0) * closeness,
                                    child: Text(
                                      labels[activeIndexInt],
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.5,
                                        color: Color(0xFF000000),
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
                  // Inactive background icons in the foreground stack
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