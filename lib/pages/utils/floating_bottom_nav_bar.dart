import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/settings_page.dart';
import 'package:untitled/pages/utils/page_transitions.dart';

enum NavPageIndex { home, search, favorites, settings }

class FloatingBottomNavBar extends StatelessWidget {
  final NavPageIndex activeIndex;

  const FloatingBottomNavBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const Color pastelPurple = Color(0xFFD4B2FF);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.08,
          right: screenWidth * 0.08,
          bottom: 20,
        ),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home Button
              if (activeIndex == NavPageIndex.home)
                const _ActiveFooterIcon(
                  icon: 'assets/images/home_icon.png',
                  label: 'EXPLORE',
                  pastelPurple: pastelPurple,
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
                  label: 'SEARCH',
                  pastelPurple: pastelPurple,
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
                  label: 'FAVORITES',
                  pastelPurple: pastelPurple,
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
                  label: 'SETTINGS',
                  pastelPurple: pastelPurple,
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
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          imagePath,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          color: const Color(0xFF8E8E93),
        ),
      ),
    );
  }
}

class _ActiveFooterIcon extends StatelessWidget {
  final String icon;
  final String label;
  final Color pastelPurple;
  const _ActiveFooterIcon({
    required this.icon,
    required this.label,
    required this.pastelPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pastelPurple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            width: 20,
            height: 20,
            color: const Color(0xFF000000),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
              letterSpacing: 0.8,
              color: Color(0xFF000000),
            ),
          )
        ],
      ),
    );
  }
}