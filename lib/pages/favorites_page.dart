import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // For logging
import 'package:shared_preferences/shared_preferences.dart'; // For user email
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/floating_bottom_nav_bar.dart';

// --- CONVERTED TO STATEFULWIDGET ---
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
        statusBarColor: Colors.transparent, // Set to transparent
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand, // Make stack fill the screen
            children: [
              // scrollable content ---
              Padding(
                // Pad to avoid top and bottom bars
                padding: const EdgeInsets.only(top: 80.0, bottom: 100.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildFavoritesList(), // Show list or empty message
              ),

              // --- "Favorites" Title ---
              Positioned(
                top: 16,
                left: 16,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF5A62F1),
                      Color(0xFF548FEE),
                      Color(0xFF9FD0F6),
                      Color(0xFFD6B3F9),
                      Color(0xFFB191FA),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // --- Bottom Nav Bar ---
              const FloatingBottomNavBar(activeIndex: NavPageIndex.favorites),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper to build the list view ---
  Widget _buildFavoritesList() {
    if (_favorites.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t favorited any properties yet.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
        ),
      );
    }

    // This is the same list style from search_page.dart
    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final property = _favorites[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              property.imagePath, // Uses Cloudinary URL
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.white24, size: 60),
            ),
          ),
          title: Text(
            property.name,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            property.location,
            style: TextStyle(color: Colors.grey[400], fontFamily: 'Inter'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            property.price,
            style: const TextStyle(color: Color(0xFF5E17EB), fontFamily: 'Poppins', fontSize: 12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsPage(property: property),
              ),
            ).then((_) {
              // This re-fetches favorites when user returns from the details page,
              // in case user unfavorited the item.
              setState(() => _isLoading = true);
              _fetchFavorites();
            });
          },
        );
      },
    );
  }
}