import 'dart:convert'; // for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // for logging
import 'package:untitled/models/property_model.dart'; // Property model
import 'package:untitled/pages/property_details_page.dart'; // details page
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/floating_bottom_nav_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // -----------------------------------------------------------------
  // STATE VARIABLES & CONTROLLERS
  // -----------------------------------------------------------------
  final _searchController = TextEditingController();
  final _logger = Logger();

  List<Property> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false; // To show initial message

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // SEARCH LOGIC
  // -----------------------------------------------------------------
  Future<void> _searchProperties(String query) async {
    if (query.isEmpty) {
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
      final response = await ApiService.get('search_properties.php', {'term': query});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties = data.map((json) => Property.fromJson(json)).toList();

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search failed. Check connection.'),
            backgroundColor: Colors.red,
          ),
        );
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
              // 1. Search Bar Input Capsule
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: TextField(
                  controller: _searchController,
                  autofocus: true, // Automatically open the keyboard
                  style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Poppins'),
                    filled: true,
                    fillColor: const Color(0xFF121214),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: pastelPurple, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: pastelPurple, width: 2.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    prefixIcon: const Icon(Icons.search, color: pastelPurple),
                  ),
                  onSubmitted: (query) => _searchProperties(query),
                ),
              ),

              // 2. The Results List
              Padding(
                padding: const EdgeInsets.only(top: 96, bottom: 100),
                child: _buildResults(),
              ),

              // 3. Floating Bottom Nav Bar
              const FloatingBottomNavBar(activeIndex: NavPageIndex.search),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // HELPER WIDGET TO BUILD THE RESULTS
  // -----------------------------------------------------------------
  Widget _buildResults() {
    const Color pastelPurple = Color(0xFFD4B2FF);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: pastelPurple),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Start typing to search for properties.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No properties found.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
      );
    }

    // Display the results in a custom list of chunky cards
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final property = _results[index];
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