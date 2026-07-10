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
        statusBarColor: Colors.transparent, // Changed to transparent
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand, // Make stack fill the screen
            children: [
              // -----------------------------------------------------------------
              // REPLACED "Search" TITLE WITH A FUNCTIONAL SEARCH BAR
              // -----------------------------------------------------------------
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: TextField(
                  controller: _searchController,
                  autofocus: true, // Automatically open the keyboard
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: (0.5)), fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: (0.1)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  ),
                  onSubmitted: (query) => _searchProperties(query),
                ),
              ),

              // -----------------------------------------------------------------
              // THE RESULTS LIST
              // -----------------------------------------------------------------
              Padding(
                // Add padding to avoid the search bar (top) and nav bar (bottom)
                padding: const EdgeInsets.only(top: 80, bottom: 100),
                child: _buildResults(),
              ),

              // -----------------------------------------------------------------
              // BOTTOM NAV BAR
              // -----------------------------------------------------------------
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Start typing to search for properties.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No properties found.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Inter'),
        ),
      );
    }

    // Display the results in a list
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final property = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              property.imagePath, // image imported from Cloudinary
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
            style: const TextStyle(
              color: Color(0xFFDF00FF),
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsPage(property: property),
              ),
            );
          },
        );
      },
    );
  }
}