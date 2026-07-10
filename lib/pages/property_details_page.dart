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
import 'package:untitled/pages/utils/abstract_background.dart';

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

    _galleryImages = [widget.property.imagePath];
    _fetchGalleryImages();
    _checkIfFavorited();
  }

  // --- LOGIC: Fetch Gallery Images ---
  Future<void> _fetchGalleryImages() async {
    try {
      final response = await ApiService.get('get_property_images.php', {'property_id': widget.property.id});

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith("<") || body.isEmpty) {
          return;
        }

        final List<dynamic> data = jsonDecode(body);

        if (mounted && data.isNotEmpty) {
          setState(() {
            for (var imgObj in data) {
              String imgUrl = imgObj.toString();
              if (imgUrl != widget.property.imagePath && !_galleryImages.contains(imgUrl)) {
                _galleryImages.add(imgUrl);
              }
            }
          });
          _logger.i("Gallery updated. Total images: ${_galleryImages.length}");
        }
      }
    } catch (e) {
      _logger.e("Error fetching gallery images", error: e);
    }
  }

  // --- LOGIC: Check if already favorited ---
  Future<void> _checkIfFavorited() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('user_email');

    if (_userEmail == null) {
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
    const Color pastelPurple = Color(0xFFD4B2FF);

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pitch Black background
      body: AbstractBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom top section instead of standard AppBar (Back Navigation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROPERTY DETAILS',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: pastelPurple,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.property.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900, // Wise bold typographic style
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.property.description,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Image Gallery with chunky rounded containers
                      _buildImageGallery(context, _galleryImages),
                      const SizedBox(height: 16),

                      _buildThumbnailList(context, _galleryImages),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // Bottom action bar (Chunky solid containers)
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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
    if (images.length <= 3) return const SizedBox.shrink();

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length - 3,
        itemBuilder: (context, index) {
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
    if (index >= images.length) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(24), // Chunky corners
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
          borderRadius: BorderRadius.circular(24.0), // Chunky corners
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

  /// Builds the bottom bar with the "View in AR" button and icons (Wise Style)
  Widget _buildBottomBar(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    final bool hasModel = widget.property.modelPath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF121214), // Solid dark block
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
      ),
      child: Row(
        children: [
          // View in AR Button: Solid filled shape, black text
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
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: pastelPurple,
                foregroundColor: const Color(0xFF000000),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                disabledForegroundColor: Colors.white24,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasModel ? Icons.view_in_ar_rounded : Icons.block_rounded,
                    color: hasModel ? const Color(0xFF000000) : Colors.white30,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasModel ? 'VIEW IN AR' : 'NO AR MODEL',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Chat Icon Button: Chunky outlined container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: pastelPurple, width: 2.0),
            ),
            child: IconButton(
              icon: Image.asset(
                'assets/images/white_chat_icon.png',
                width: 22,
                color: pastelPurple,
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

          // Favorite Icon Button: Chunky outlined container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: pastelPurple, width: 2.0),
            ),
            child: _isLoadingFavorite
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2, color: pastelPurple),
                  )
                : IconButton(
                    icon: Icon(
                      _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorited ? Colors.red : pastelPurple,
                      size: 26,
                    ),
                    onPressed: _toggleFavorite,
                  ),
          ),
        ],
      ),
    );
  }
}