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
  List<Property> _allProperties = [];
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
          _allProperties = properties;
          // Filter properties into different lists (you can change this logic)
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          // bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. YOUR MAIN PAGE CONTENT (SCROLLABLE)
              _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100), // Spacer for top bar

                    if (_featuredProperties.isNotEmpty) ...[
                      _buildSectionHeader('Featured'),
                      const SizedBox(height: 16),
                      _buildFeaturedCard(context, _featuredProperties[0]),
                      const _Divider(),
                    ],
                    if (_nearbyProperties.isNotEmpty) ...[
                      _buildSectionHeader('Nearby'),
                      const SizedBox(height: 16),
                      _buildHorizontalList(_nearbyProperties),
                      const _Divider(),
                    ],
                    if (_popularProperties.isNotEmpty) ...[
                      _buildSectionHeader('Popular'),
                      const SizedBox(height: 16),
                      _buildHorizontalList(_popularProperties),
                    ],
                    const SizedBox(height: 120), // Spacer for bottom nav
                  ],
                ),
              ),

              // 2. THE FLOATING TOP BAR
              _buildTopBar(context),

              // -------------------------------------------------
              // REPLACED BOTTOM NAV BAR WITH NEW WIDGET
              // -------------------------------------------------
              const FloatingBottomNavBar(activeIndex: NavPageIndex.home),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------
  // WIDGET FOR THE "FEATURED" CARD
  // -------------------------------------------------
  Widget _buildFeaturedCard(BuildContext context, Property property) {
    // Check if model exists to decide button state
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                property.imagePath,
                width: 160,
                height: 177,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : Container(
                    width: 160,
                    height: 177,
                    color: Colors.white10,
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 160,
                    height: 177,
                    color: Colors.white10,
                    child: const Icon(Icons.broken_image, color: Colors.white24),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: SizedBox(
                height: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Text Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          property.location,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // "View in AR" Button
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
                          : null, // Disables button if no model exists
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E17EB),
                        disabledBackgroundColor: Colors.white.withValues(alpha: (0.1)), // Grey style when disabled
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        hasModel ? 'View in AR' : 'No AR', // Changes text if unavailable
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: hasModel ? Colors.white : Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------
  // WIDGET FOR HORIZONTAL LISTS
  // -------------------------------------------------
  Widget _buildHorizontalList(List<Property> properties) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          final double leftPadding = index == 0 ? 16.0 : 8.0;
          final double rightPadding = index == properties.length - 1 ? 16.0 : 0.0;

          return Padding(
            padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailsPage(property: property),
                  ),
                );
              },
              child: SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network( // Changed to Image.network
                        property.imagePath,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        // Add error and loading builders
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : Container(
                            width: 140,
                            height: 140,
                            color: Colors.white10,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 140,
                            height: 140,
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image, color: Colors.white24),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      property.price, // Use real data
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Inter',
                        fontSize: 12,
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

  // -------------------------------------------------
  // ALL OTHER HELPER WIDGETS
  // -------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          ).createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          )),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 16.0,
      left: 16.0,
      right: 16.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: (0.1)),
              borderRadius: BorderRadius.circular(40.0),
              border: Border.all(color: Colors.white.withValues(alpha: (0.2))),
            ),
            child: Row(
              children: [
                // --- 1. Logo ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                      ),
                    ],
                  ),
                ),
                // --- 2. Search Bar ---
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(fadeRoute(const SearchPage()));
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        enabled: false,
                        style: const TextStyle(color: Colors.black, fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          hintText: 'Search properties...',
                          hintStyle: TextStyle(color: Colors.grey[800], fontFamily: 'Inter'),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[800]),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // --- Profile Icon ---
                GestureDetector( // Wrapped in GestureDetector
                  onTap: () {
                    // Navigate to ProfilePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 49,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          padding: const EdgeInsets.all(10.0),
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

// Reusable Divider
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Divider(
        color: Colors.white10,
        height: 1.0,
        thickness: 1.0,
      ),
    );
  }
}