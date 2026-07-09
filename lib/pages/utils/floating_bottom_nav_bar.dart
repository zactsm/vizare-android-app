import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/settings_page.dart';
import 'package:untitled/pages/utils/page_transitions.dart';

// An enum to make it clear which page is active
enum NavPageIndex { home, search, favorites, settings }

class FloatingBottomNavBar extends StatelessWidget {
  final NavPageIndex activeIndex;

  const FloatingBottomNavBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    // Get the screen width for responsive padding
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.bottomCenter,
      // Use Padding for responsive horizontal margins
      child: Padding(
        // ADJUST POSITIONING AND PADDING HERE ----------------------------------------------
        padding: EdgeInsets.only(
          left: screenWidth * 0.1,
          right: screenWidth * 0.1,
          bottom: 10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Home Button
                  if (activeIndex == NavPageIndex.home)
                    const _ActiveFooterIcon(
                      icon: 'assets/images/home_icon.png',
                      label: 'Main Menu',
                    )
                  else
                    _FooterIcon(
                      imagePath: 'assets/images/white_home_icon.png',
                      onTap: () => Navigator.of(context)
                          .pushReplacement(fadeRoute(const HomeBuyerPage())),
                    ),

                  // Search Button
                  if (activeIndex == NavPageIndex.search)
                    const _ActiveFooterIcon(
                      icon: 'assets/images/search_icon.png',
                      label: 'Search',
                    )
                  else
                    _FooterIcon(
                      imagePath: 'assets/images/white_search_icon.png',
                      onTap: () => Navigator.of(context)
                          .pushReplacement(fadeRoute(const SearchPage())),
                    ),

                  // Favorites Button
                  if (activeIndex == NavPageIndex.favorites)
                    const _ActiveFooterIcon(
                      icon: 'assets/images/fav_icon.png',
                      label: 'Favorites',
                    )
                  else
                    _FooterIcon(
                      imagePath: 'assets/images/white_fav_icon.png',
                      onTap: () => Navigator.of(context)
                          .pushReplacement(fadeRoute(const FavoritesPage())),
                    ),

                  // Settings Button
                  if (activeIndex == NavPageIndex.settings)
                    const _ActiveFooterIcon(
                      icon: 'assets/images/settings_icon.png',
                      label: 'Settings',
                    )
                  else
                    _FooterIcon(
                      imagePath: 'assets/images/white_settings_icon.png',
                      onTap: () => Navigator.of(context)
                          .pushReplacement(fadeRoute(const SettingsPage())),
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

class _FooterIcon extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  const _FooterIcon({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          imagePath,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _ActiveFooterIcon extends StatelessWidget {
  final String icon;
  final String label;
  const _ActiveFooterIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isMainMenu = label.contains('Main');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMainMenu ? 16.5 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF200),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: isMainMenu ? 24 : 19.5,
            height: 28,
            color: const Color(0xFF0D0D0D),
          ),
          const SizedBox(width: 8),
          Text(
            label.trim(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Color(0xFF0D0D0D),
            ),
          )
        ],
      ),
    );
  }
}