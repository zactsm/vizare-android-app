import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/utils/api_service.dart';

import 'package:untitled/pages/profile_page.dart';
import 'package:untitled/pages/add_property_page.dart';
import 'package:untitled/pages/edit_property_page.dart';
import 'package:untitled/pages/to_respond_page.dart';

class HomeownerPage extends StatefulWidget {
  const HomeownerPage({super.key});

  @override
  State<HomeownerPage> createState() => _HomeownerPageState();
}

class _HomeownerPageState extends State<HomeownerPage> {
  final _logger = Logger();
  final _searchController = TextEditingController();

  // State lists
  bool _isLoading = true;
  List<Property> _myProperties = []; // Master list
  List<Property> _filteredProperties = []; // List to display
  String? _profilePicUrl;

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
    // Add listener for search
    _searchController.addListener(_filterProperties);
    _fetchMyProperties();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProperties);
    _searchController.dispose();
    super.dispose();
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
              if (data['profile_pic'] != null &&
                  data['profile_pic'].toString().isNotEmpty) {
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

  Future<void> _deleteProperty(int propertyId) async {
    // 1. Show Confirmation Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Delete Property", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this property? This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return; // User cancelled

    // 2. Proceed with Delete
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) throw Exception("User not logged in");

      final response = await ApiService.post(
        'delete_property.php',
        body: {
          'email': email,
          'property_id': propertyId.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Success: Refresh the list to remove the item from UI
        _logger.i("Property deleted successfully");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Property deleted."), backgroundColor: Colors.red),
          );
        }
        _fetchMyProperties(); // Refresh list
      } else {
        throw Exception("Failed to delete: ${response.body}");
      }
    } catch (e) {
      _logger.e("Delete error", error: e);
      if (mounted) {
        setState(() => _isLoading = false); // Stop loading on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting property.")),
        );
      }
    }
  }

  // --- DATA & SEARCH LOGIC ---

  Future<void> _fetchMyProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      _logger.w('User email not found. Cannot fetch properties.');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService.get('get_my_properties.php', {'email': email});
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties = data.map((json) => Property.fromJson(json)).toList();
        setState(() {
          _myProperties = properties;
          _filteredProperties = properties; // Initialize filtered list
          _isLoading = false;
        });
      } else {
        _logger.w('Failed to load properties: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e('Error fetching properties', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProperties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProperties = _myProperties.where((property) {
        final nameMatch = property.name.toLowerCase().contains(query);
        final locationMatch = property.location.toLowerCase().contains(query);
        return nameMatch || locationMatch;
      }).toList();
    });
  }

  // --- NAVIGATION ---
  void _navigateToAddProperty() {
   Navigator.push(
     context,
     MaterialPageRoute(builder: (context) => const AddPropertyPage()),
   ).then((result) {
     // If result is true (meaning we added a property), refresh the list
     if (result == true) {
       _fetchMyProperties();
     }
   });
 }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      // --- MODIFIED: Removed AppBar, added Stack ---
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _buildBody(),
          // This is the new floating bar
          _buildTopBar(context),
        ],
      ),
    );
  }

  // --- _buildTopBar() function (and modified it) ---
  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 52.0,
      left: 16.0,
      right: 16.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.85),
              borderRadius: BorderRadius.circular(40.0),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                // --- 1. Logo ---
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
                // --- 2. Search Bar (MODIFIED) ---
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    enabled: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search your properties...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: const Color(0xFF0D0D0D),
                      isDense: true,
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 10.0),
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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage()), // Goes to profile
                    ).then((_) {
                      _fetchUserProfile(); // Refresh image when back
                    });
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

  // --- _buildBody() to add padding ---
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Added Spacer to clear the floating top bar
          const SizedBox(height: 140),
          _buildGradientTitle('Manage Your\nProperties'),
          const SizedBox(height: 24),
          _buildButtonRow(),
          const SizedBox(height: 24), // Fixed spacing
          _buildMyPropertiesList(),
          // Added spacer for bottom
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGradientTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Colors.white,
          Color(0xFFDF00FF),
        ],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    final Color neonPurple = const Color(0xFFDF00FF);
    return Row(
      children: [
        // "+ Add new property" button (Neon purple)
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _navigateToAddProperty();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: neonPurple,
              foregroundColor: const Color(0xFF0D0D0D),
              minimumSize: const Size(100, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '+ Add property',
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // "To respond" button (Outlined neon purple)
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ToRespondPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: neonPurple,
              side: BorderSide(color: neonPurple, width: 1.5),
              minimumSize: const Size(100, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'To respond',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyPropertiesList() {
    if (_filteredProperties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0),
          child: Text(
            _searchController.text.isNotEmpty
                ? 'No properties found for "${_searchController.text}".'
                : 'You have not posted any properties yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.grey, fontFamily: 'Poppins', fontSize: 16),
          ),
        ),
      );
    }

    // Use ListView.builder for performance
    return ListView.builder(
      itemCount: _filteredProperties.length,
      shrinkWrap: true, // Important inside a SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Let the parent scroll
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return _buildPropertyCard(property);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.orangeAccent;
    }
  }

  // This is the new card widget
  Widget _buildPropertyCard(Property property) {
    final statusColor = _getStatusColor(property.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: (0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              property.imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white24,
                  size: 80),
            ),
          ),
          const SizedBox(width: 16),
          // Title and Description
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
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  property.description,
                  style:
                  TextStyle(color: Colors.grey[400], fontFamily: 'Poppins'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: (0.1)),
                    border: Border.all(color: statusColor.withValues(alpha: (0.5))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Edit and Delete Buttons
          Column(
            children: [
              // Edit Button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPropertyPage(property: property),
                    ),
                  ).then((result){
                    if (result == true) {
                      _fetchMyProperties();
                    }
                  });
                  _logger.i('Edit property ${property.id}');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: (0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              // Delete Button
              InkWell(
                onTap: () {
                  _deleteProperty(property.id);
                  _logger.i('Delete property ${property.id}');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child:
                  const Icon(Icons.delete, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}