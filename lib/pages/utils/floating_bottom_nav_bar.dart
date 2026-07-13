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
    final double barWidth = maxBarWidth - (maxBarWidth * 0.12);
    final double innerWidth = barWidth - 24; // padding horizontal 12 * 2
    final double segmentWidth = innerWidth / 4;

    final Map<int, double> ovalWidths = {
      0: 110.0, // Home
      1: 110.0, // Search
      2: 125.0, // Favorites
      3: 115.0, // Settings
    };

    final Map<int, double> textWidths = {
      0: 65.0, // EXPLORE
      1: 55.0, // SEARCH
      2: 75.0, // FAVORITES
      3: 65.0, // SETTINGS
    };

    // Calculate interpolated position and width for the purple oval
    final int prevIndex = pageProgress.floor().clamp(0, 3);
    final int nextIndex = pageProgress.ceil().clamp(0, 3);
    final double fraction = pageProgress - pageProgress.floor();

    final double prevWidth = ovalWidths[prevIndex] ?? 110.0;
    final double nextWidth = ovalWidths[nextIndex] ?? 110.0;
    final double activeOvalWidth = prevWidth + (nextWidth - prevWidth) * fraction;

    final double prevCenter = segmentWidth * (prevIndex + 0.5);
    final double nextCenter = segmentWidth * (nextIndex + 0.5);
    final double activeCenter = prevCenter + (nextCenter - prevCenter) * fraction;

    final double ovalLeft = activeCenter - (activeOvalWidth / 2);

    Widget buildNavItem(int index, String activeIcon, String inactiveIcon, String label) {
      final double closeness = (1.0 - (pageProgress - index).abs()).clamp(0.0, 1.0);
      final double textWidth = textWidths[index] ?? 60.0;

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outlined icon when inactive
                      Opacity(
                        opacity: (1.0 - closeness).clamp(0.0, 1.0),
                        child: Image.asset(
                          inactiveIcon,
                          width: 20,
                          height: 20,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                      // Filled black icon when active
                      Opacity(
                        opacity: closeness,
                        child: Image.asset(
                          activeIcon,
                          width: 20,
                          height: 20,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                  ClipRect(
                    child: SizedBox(
                      height: 20,
                      width: textWidth * closeness,
                      child: Opacity(
                        opacity: closeness,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            label,
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
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          bottom: 24,
        ),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121214), // High-contrast solid dark background
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: pastelPurple, width: 2.0), // High-contrast chunky border
          ),
          child: Stack(
            children: [
              // Sliding purple oval background
              Positioned(
                left: ovalLeft,
                top: 0,
                bottom: 0,
                width: activeOvalWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: pastelPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // Nav items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildNavItem(0, 'assets/images/home_icon.png', 'assets/images/white_home_icon.png', 'EXPLORE'),
                  buildNavItem(1, 'assets/images/search_icon.png', 'assets/images/white_search_icon.png', 'SEARCH'),
                  buildNavItem(2, 'assets/images/fav_icon.png', 'assets/images/white_fav_icon.png', 'FAVORITES'),
                  buildNavItem(3, 'assets/images/settings_icon.png', 'assets/images/white_settings_icon.png', 'SETTINGS'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}