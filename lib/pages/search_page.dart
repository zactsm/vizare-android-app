import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'utils/floating_bottom_nav_bar.dart';
import 'utils/abstract_background.dart';
import 'utils/top_bar_gradient_blur.dart';

class SearchPage extends StatefulWidget {
  final bool isEmbedded;
  const SearchPage({super.key, this.isEmbedded = false});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _logger = Logger();

  List<Property> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProperties(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response =
          await ApiService.get('search_properties.php', {'term': query});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties =
            data.map((json) => Property.fromJson(json)).toList();

        setState(() {
          _results = properties;
          _isLoading = false;
        });
      } else {
        _logger.w('Failed to search properties: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e('Error searching properties', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final innerContent = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Search Results List / Empty State / Loading
        _buildResults(),

        // Smooth Gradient Blur behind top search bar
        const TopBarGradientBlur(height: 110.0),

        // VisionOS Floating Search Bar Capsule
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: VisionGlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: 28.0,
            backgroundColor: isDark
                ? VizareColors.obsidianSurface.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.95),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: !widget.isEmbedded,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
              ),
              decoration: InputDecoration(
                hintText: 'Search by estate, city, or architect...',
                hintStyle: GoogleFonts.inter(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : const Color(0xFF94A3B8),
                  fontSize: 13.5,
                ),
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: VizareColors.champagneGold,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchProperties('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (query) => _searchProperties(query),
            ),
          ),
        ),

        if (!widget.isEmbedded)
          const FloatingBottomNavBar(activeIndex: NavPageIndex.search),
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

  Widget _buildResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VizareColors.champagneGold),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VizareColors.champagneGold.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                color: VizareColors.champagneGold,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Explore the Luxury Catalog',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search by property name, location, or architectural features.',
              style: GoogleFonts.inter(
                color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No luxury properties match your query.',
          style: GoogleFonts.inter(
            color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 96, bottom: 120),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final property = _results[index];
        final bool hasModel = property.modelPath.isNotEmpty;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsPage(property: property),
              ),
            );
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
                        if (hasModel) ...[
                          const SizedBox(height: 6),
                          const SpatialBadge(
                            text: '3D AR READY',
                            icon: Icons.view_in_ar_rounded,
                            primaryColor: VizareColors.spatialCyan,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
