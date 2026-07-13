import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // For logging
import 'package:shared_preferences/shared_preferences.dart'; // For user email
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/floating_bottom_nav_bar.dart';
import 'utils/abstract_background.dart';

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

  // Function to fetch favorites ---
  Future<void> _fetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      _logger.w('User email not found. Cannot fetch favorites.');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final response = await ApiService.get('get_favorites.php', {'email': email});
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties = data.map((json) => Property.fromJson(json)).toList();
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);

    final innerContent = Stack(
      fit: StackFit.expand, // Make stack fill the screen
      children: [
        // 1. Scrollable Content (padded internally to scroll behind header)
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: pastelPurple))
            : _buildFavoritesList(),

        // 2. Custom Wise-Style Header Overhaul (Solid high-contrast container)
        Positioned(
          top: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121214), // Solid dark block
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pastelPurple, width: 2.0), // High-contrast border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Favorites',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 34, // Massive expressive Wise-style font
                    fontWeight: FontWeight.w900, // Ultra bold
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your bookmarked properties of interest.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Bottom Nav Bar (only if not embedded)
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
        backgroundColor: const Color(0xFF000000), // Pitch Black background
        body: AbstractBackground(
          child: SafeArea(
            child: innerContent,
          ),
        ),
      ),
    );
  }

  // --- Helper to build the list view of chunky cards ---
  Widget _buildFavoritesList() {
    const Color pastelPurple = Color(0xFFD4B2FF);
    if (_favorites.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t favorited any properties yet.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 140, bottom: 170),
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
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121214), // Solid dark grey card block
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    property.imagePath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.white24, size: 70),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  property.price,
                  style: const TextStyle(
                    color: pastelPurple,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}