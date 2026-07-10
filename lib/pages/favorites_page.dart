import 'dart:ui';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // For logging
import 'package:shared_preferences/shared_preferences.dart'; // For user email
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/floating_bottom_nav_bar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Pitch Black background
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand, // Make stack fill the screen
            children: [
              // 1. Scrollable Content (starts from top to scroll behind bars)
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: pastelPurple))
                  : _buildFavoritesList(),

              // 2. Liquid Glass Top Header Bar
              _buildTopHeader(context),

              // 3. Floating Bottom Nav Bar
              const FloatingBottomNavBar(activeIndex: NavPageIndex.favorites),
            ],
          ),
        ),
      ),
    );
  }

  // --- Glassmorphic Top Header Bar ---
  Widget _buildTopHeader(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 80,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.only(left: 18, bottom: 12),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: pastelPurple.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'MY ', style: TextStyle(fontWeight: FontWeight.w300)),
                  TextSpan(text: 'FAVORITES', style: TextStyle(fontWeight: FontWeight.w900, color: pastelPurple)),
                ],
              ),
            ),
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
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 96, bottom: 110),
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
              // Re-fetch favorites when user returns from the details page
              setState(() => _isLoading = true);
              _fetchFavorites();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121214), // Solid dark grey container
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Poppins',
                          fontSize: 12,
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
                    color: pastelPurple, // Pastel purple price tag
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