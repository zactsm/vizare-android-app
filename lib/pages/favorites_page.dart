import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'utils/floating_bottom_nav_bar.dart';
import 'utils/abstract_background.dart';
import 'utils/top_bar_gradient_blur.dart';

class FavoritesPage extends StatefulWidget {
  final bool isEmbedded;
  const FavoritesPage({super.key, this.isEmbedded = false});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _logger = Logger();
  bool _isLoading = true;
  List<Property> _favorites = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      _logger.w('User email not found. Cannot fetch favorites.');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response =
          await ApiService.get('get_favorites.php', {'email': email});
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties =
            data.map((json) => Property.fromJson(json)).toList();
        setState(() {
          _favorites = properties;
          _isLoading = false;
        });
      } else {
        _logger.w('Failed to load favorites: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e('Error fetching favorites', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final innerContent = Stack(
      fit: StackFit.expand,
      children: [
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: VizareColors.champagneGold),
              )
            : _buildFavoritesList(),

        // Smooth Gradient Blur behind top header
        const TopBarGradientBlur(height: 125.0),

        // Top Header Texts
        Positioned(
          top: 16,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Estates',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your curated portfolio of luxury spaces.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: isDark
                      ? VizareColors.textSecondary
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        if (!widget.isEmbedded)
          const FloatingBottomNavBar(activeIndex: NavPageIndex.favorites),
      ],
    );

    if (widget.isEmbedded) {
      return innerContent;
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
        body: AbstractBackground(
          child: SafeArea(
            child: innerContent,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VizareColors.champagneGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: VizareColors.champagneGold.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: VizareColors.champagneGold,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Saved Properties Yet',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Explore the catalog and bookmark properties for quick AR access.',
              style: GoogleFonts.inter(
                color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 100, bottom: 120),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final property = _favorites[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsPage(property: property),
              ),
            ).then((_) {
              setState(() => _isLoading = true);
              _fetchFavorites();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: VisionGlassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 22,
              backgroundColor: isDark
                  ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.95),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      property.imagePath,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              color: Colors.white24, size: 74),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.location,
                          style: GoogleFonts.inter(
                            color: isDark
                                ? VizareColors.textSecondary
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    property.price,
                    style: GoogleFonts.poppins(
                      color: VizareColors.champagneGold,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
