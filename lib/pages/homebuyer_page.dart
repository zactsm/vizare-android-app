import 'dart:ui';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // For logging
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/profile_page.dart';
import 'package:untitled/pages/ar_view_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/page_transitions.dart';
import 'utils/floating_bottom_nav_bar.dart';

class HomeBuyerPage extends StatefulWidget {
  const HomeBuyerPage({super.key});

  @override
  State<HomeBuyerPage> createState() => _HomeBuyerPageState();
}

class _HomeBuyerPageState extends State<HomeBuyerPage> {
  // State variables for loading and storing properties
  bool _isLoading = true;
  List<Property> _featuredProperties = [];
  List<Property> _nearbyProperties = [];
  List<Property> _popularProperties = [];
  String? _profilePicUrl;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    // Set status bar style
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    // Fetch data when the page loads
    _fetchProperties();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email != null) {
      try {
        final response = await ApiService.get('get_user_profile.php', {'email': email});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              // Save the URL if it exists and is not empty
              if (data['profile_pic'] != null && data['profile_pic'].toString().isNotEmpty) {
                _profilePicUrl = data['profile_pic'];
              } else {
                _profilePicUrl = null;
              }
            });
          }
        }
      } catch (e) {
        _logger.e("Error fetching profile pic", error: e);
      }
    }
  }

  // --- Data Fetching Logic ---
  Future<void> _fetchProperties() async {
    try {
      final response = await ApiService.get('get_all_listings.php');

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Decode the JSON response
        final List<dynamic> data = jsonDecode(response.body);

        // Convert JSON maps to Property objects
        final properties = data.map((json) => Property.fromJson(json)).toList();

        // Update the state
        setState(() {
          // Filter properties into different lists
          _featuredProperties = properties.where((p) => p.isFeatured).toList();
          _nearbyProperties = properties.where((p) => !p.isFeatured).toList();
          _popularProperties = List.from(properties)..shuffle(); // Just shuffle all for now

          _isLoading = false;
        });
      } else {
        _logger.w('Failed to load properties: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e('Error fetching properties', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load properties. Check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Pitch Black background
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: pastelPurple),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 100), // Spacer for top floating bar

                          // Advanced Poppins Typography Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 32,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(text: 'EXPLORE\n', style: TextStyle(fontWeight: FontWeight.w300)),
                                  TextSpan(text: 'PROPERTIES', style: TextStyle(fontWeight: FontWeight.w900, color: pastelPurple)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 1. Featured Carousel
                          if (_featuredProperties.isNotEmpty) ...[
                            _buildSectionHeader('FEATURED', 'UNITS'),
                            const SizedBox(height: 14),
                            _buildFeaturedCarousel(context, _featuredProperties),
                            const SizedBox(height: 32),
                          ],

                          // 2. Nearby Carousel
                          if (_nearbyProperties.isNotEmpty) ...[
                            _buildSectionHeader('NEARBY', 'HOMES'),
                            const SizedBox(height: 14),
                            _buildNearbyCarousel(context, _nearbyProperties),
                            const SizedBox(height: 32),
                          ],

                          // 3. Popular Property Feed (Massive chunky card blocks)
                          if (_popularProperties.isNotEmpty) ...[
                            _buildSectionHeader('POPULAR', 'FEED'),
                            const SizedBox(height: 14),
                            _buildPopularFeed(context, _popularProperties),
                          ],
                          const SizedBox(height: 120), // Spacer for bottom nav
                        ],
                      ),
                    ),

              // The Floating Top Search Capsule
              _buildTopSearchCapsule(context),

              // Floating Bottom Nav Bar
              const FloatingBottomNavBar(activeIndex: NavPageIndex.home),
            ],
          ),
        ),
      ),
    );
  }

  // --- Typography Section Header Helper ---
  Widget _buildSectionHeader(String thinText, String boldText) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          children: [
            TextSpan(text: '$thinText ', style: const TextStyle(fontWeight: FontWeight.w300)),
            TextSpan(text: boldText, style: const TextStyle(fontWeight: FontWeight.w900, color: pastelPurple)),
          ],
        ),
      ),
    );
  }

  // --- Featured Carousel (Flat solid cards with solid dark gray background) ---
  Widget _buildFeaturedCarousel(BuildContext context, List<Property> properties) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
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
              width: 280,
              margin: EdgeInsets.only(
                left: index == 0 ? 18.0 : 8.0,
                right: index == properties.length - 1 ? 18.0 : 8.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF121214), // Flat solid dark container
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            property.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image, color: Colors.white24),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                property.price,
                                style: const TextStyle(
                                  color: pastelPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Nearby Carousel (Transparent background outlined secondary card blocks) ---
  Widget _buildNearbyCarousel(BuildContext context, List<Property> properties) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
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
              width: 190,
              margin: EdgeInsets.only(
                left: index == 0 ? 18.0 : 8.0,
                right: index == properties.length - 1 ? 18.0 : 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent, // Transparent background
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: pastelPurple, width: 1.5), // Crisp thin border
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        property.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, e, s) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image, color: Colors.white24),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            property.price,
                            style: const TextStyle(
                              color: pastelPurple,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Popular Property Feed (Massive chunky card blocks with pastel purple View in AR button) ---
  Widget _buildPopularFeed(BuildContext context, List<Property> properties) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
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
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF121214), // Flat solid dark container
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Massive full-width image
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            property.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image, color: Colors.white24, size: 48),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                property.price,
                                style: const TextStyle(
                                  color: pastelPurple,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                          const SizedBox(width: 12),
                          // View in AR Button: solid vibrant pastel purple block shapes
                          ElevatedButton(
                            onPressed: hasModel
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArViewPage(
                                          modelUrl: property.modelPath,
                                          propertyName: property.name,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pastelPurple,
                              foregroundColor: const Color(0xFF000000),
                              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                              disabledForegroundColor: Colors.white24,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              hasModel ? 'VIEW AR' : 'NO AR',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                color: hasModel ? const Color(0xFF000000) : Colors.white30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Top Persistent Floating Search Capsule ---
  Widget _buildTopSearchCapsule(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return Positioned(
      top: 16.0,
      left: 16.0,
      right: 16.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32.0),
              border: Border.all(
                color: pastelPurple.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 44,
                  height: 44,
                ),
                const SizedBox(width: 8),
                // Capsule Search Field
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(fadeRoute(const SearchPage()));
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF1E1E22), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white54, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Search properties...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Profile Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      image: _profilePicUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_profilePicUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profilePicUrl == null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/images/profile_icon.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}