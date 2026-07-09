import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/gallery_view_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/send_inquiry_page.dart';
import 'package:untitled/pages/ar_view_page.dart';

class PropertyDetailsPage extends StatefulWidget {
  final Property property;
  const PropertyDetailsPage({super.key, required this.property});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  // --- STATE VARIABLES ---
  final _logger = Logger();
  bool _isFavorited = false;
  bool _isLoadingFavorite = true;
  bool _isUpdatingFavorite = false;
  String? _userEmail;

  // List to store real images from server
  List<String> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // 1. Initialize with the cover image so the screen isn't empty
    _galleryImages = [widget.property.imagePath];

    // 2. Fetch the rest of the images
    _fetchGalleryImages();

    _checkIfFavorited();
  }

  // --- LOGIC: Fetch Gallery Images ---
  Future<void> _fetchGalleryImages() async {
    try {
      final response = await ApiService.get('get_property_images.php', {'property_id': widget.property.id});

      print("Server Response: ${response.body}");

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith("<") || body.isEmpty) {
          print("ERROR: Server returned HTML or empty response instead of JSON.");
          return;
        }

        final List<dynamic> data = jsonDecode(body);

        if (mounted && data.isNotEmpty) {
          setState(() {
            // Add new images to our list (avoiding duplicates if necessary)
            for (var imgObj in data) {
              String imgUrl = imgObj.toString();

              // Only add if it's not already the cover image
              if (imgUrl != widget.property.imagePath && !_galleryImages.contains(imgUrl)) {
                _galleryImages.add(imgUrl);
              }
            }
          });
          _logger.i("Gallery updated. Total images: ${_galleryImages.length}");
        }
      } else {
        _logger.w("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _logger.e("Error fetching gallery images", error: e);
      // We don't show an error to user, just stick with the cover image
    }
  }

  // --- LOGIC: Check if already favorited ---
  Future<void> _checkIfFavorited() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('user_email');

    if (_userEmail == null) {
      _logger.w("Cannot check favorite: User not logged in.");
      setState(() => _isLoadingFavorite = false);
      return;
    }

    try {
      final response = await ApiService.get('check_favorite.php', {
        'email': _userEmail,
        'property_id': widget.property.id,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isFavorited = data['isFavorited'];
            _isLoadingFavorite = false;
          });
        }
      }
    } catch (e) {
      _logger.e("Error checking favorite status", error: e);
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  // --- LOGIC: Add or Remove Favorite ---
  Future<void> _toggleFavorite() async {
    if (_userEmail == null || _isUpdatingFavorite) return;

    setState(() => _isUpdatingFavorite = true);

    final bool originalState = _isFavorited;
    setState(() => _isFavorited = !_isFavorited);

    final script = _isFavorited ? 'add_favorite.php' : 'remove_favorite.php';

    try {
      final response = await ApiService.post(
        script,
        body: {
          'email': _userEmail!,
          'property_id': widget.property.id.toString(),
        },
      );

      if (response.statusCode != 200) {
        _logger.w("Failed to update favorite: ${response.body}");
        setState(() => _isFavorited = originalState);
      } else {
        _logger.i("Favorite status updated: ${response.body}");
      }
    } catch (e) {
      _logger.e("Error toggling favorite", error: e);
      setState(() => _isFavorited = originalState);
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFavorite = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGradientTitle("Property Details"),
                  const SizedBox(height: 44),
                  Text(
                    widget.property.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.property.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Updated to use _galleryImages
                  _buildImageGallery(context, _galleryImages),
                  const SizedBox(height: 16),

                  // Updated to use _galleryImages
                  _buildThumbnailList(context, _galleryImages),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildGradientTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Colors.white,
          Color(0xFFFFF200),
        ],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, List<String> galleryImages) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main large image (Index 0)
        Expanded(
          flex: 2,
          child: _buildTappableImage(context, galleryImages, 0),
        ),
        const SizedBox(width: 12),
        // Side column images (Index 1 and 2)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildTappableImage(context, galleryImages, 1, height: 119),
              const SizedBox(height: 12),
              _buildTappableImage(context, galleryImages, 2, height: 119),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailList(BuildContext context, List<String> images) {
    // If we only have fewer than 4 images, no need to show the horizontal scroll list
    // because they are already visible in the main gallery view above.
    if (images.length <= 3) return const SizedBox.shrink();

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Start from index 3 because 0,1,2 are shown above
        itemCount: images.length - 3,
        itemBuilder: (context, index) {
          // Adjust index to point to correct image
          final realIndex = index + 3;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildTappableImage(context, images, realIndex, width: 70, height: 70),
          );
        },
      ),
    );
  }

  Widget _buildTappableImage(BuildContext context, List<String> images, int index, {double? width, double height = 250}) {
    // Safety check for index out of bounds (handles cases where fetching isn't done yet)
    if (index >= images.length) {
      // If specific index is missing (e.g. index 1 or 2 while loading), show a placeholder or empty box
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    final imagePath = images[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GalleryViewPage(
              imagePaths: images,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Hero(
        tag: '$imagePath-$index',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Image.network(
            imagePath,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, e, s) => Container(
              width: width,
              height: height,
              color: Colors.white10,
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the bottom bar with the "View in AR" button and icons
  Widget _buildBottomBar(BuildContext context) {
    // Check if AR model is available
    final bool hasModel = widget.property.modelPath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: (0.1)), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // --- "View in AR" Button ---
          Expanded(
            child: ElevatedButton(
              onPressed: hasModel
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArViewPage(
                      modelUrl: widget.property.modelPath,
                      propertyName: widget.property.name,
                    ),
                  ),
                );
              }
                  : null, // Disable button if no model
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF200),
                disabledBackgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: const Color(0xFF0D0D0D),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      hasModel ? Icons.view_in_ar : Icons.block,
                      color: hasModel ? const Color(0xFF0D0D0D) : Colors.white30,
                      size: 20
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasModel ? 'View in AR' : 'No AR Model',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: hasModel ? const Color(0xFF0D0D0D) : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // --- Chat Icon Button ---
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFF200), width: 1.5),
            ),
            child: IconButton(
              icon: Image.asset(
                'assets/images/white_chat_icon.png',
                width: 20,
                color: const Color(0xFFFFF200),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SendInquiryPage(property: widget.property),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // --- Favorite Icon Button ---
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFF200), width: 1.5),
            ),
            child: _isLoadingFavorite
                ? const Padding(
              padding: EdgeInsets.all(14.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFF200)),
            )
                : IconButton(
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : const Color(0xFFFFF200),
                size: 24,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}