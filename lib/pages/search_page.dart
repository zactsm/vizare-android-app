import 'dart:convert'; // for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // for logging
import 'package:untitled/models/property_model.dart'; // Property model
import 'package:untitled/pages/property_details_page.dart'; // details page
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/floating_bottom_nav_bar.dart';
import 'utils/abstract_background.dart';

class SearchPage extends StatefulWidget {
  final bool isEmbedded;
  const SearchPage({super.key, this.isEmbedded = false});

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

    final innerContent = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Scrollable Results List (scrolls under the top search bar)
        _buildResults(),

        // 2. Search Bar Input Capsule (Wise Style: Solid, Outlined, High-Contrast)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121214), // Solid card block
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(color: pastelPurple, width: 2.0), // High contrast border
            ),
            child: TextField(
              controller: _searchController,
              autofocus: !widget.isEmbedded,
              style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search by name or location...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: pastelPurple),
              ),
              onSubmitted: (query) => _searchProperties(query),
            ),
          ),
        ),

        // 3. Floating Bottom Nav Bar (only if not embedded)
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
        backgroundColor: const Color(0xFF000000), // Pitch Black background
        body: AbstractBackground(
          child: SafeArea(
            child: innerContent,
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
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No properties found.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 100, bottom: 120),
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
                          fontWeight: FontWeight.w900, // Wise bold
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