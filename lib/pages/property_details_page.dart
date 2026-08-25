import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/gallery_view_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
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

  Future<void> _fetchGalleryImages() async {
    try {
      final response = await ApiService.get(
          'get_property_images.php', {'property_id': widget.property.id});

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith("<") || body.isEmpty) return;

        final List<dynamic> data = jsonDecode(body);

        if (mounted && data.isNotEmpty) {
          setState(() {
            for (var imgObj in data) {
              String imgUrl = imgObj.toString();
              if (imgUrl != widget.property.imagePath &&
                  !_galleryImages.contains(imgUrl)) {
                _galleryImages.add(imgUrl);
              }
            }
          });
          _logger.i("Gallery updated: ${_galleryImages.length} images");
        }
      }
    } catch (e) {
      _logger.e("Error fetching gallery images", error: e);
    }
  }

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
    final bool hasModel = widget.property.modelPath.isNotEmpty;

    return Scaffold(
      backgroundColor: VizareColors.obsidianBlack,
      body: AbstractBackground(
        child: SafeArea(
          child: Column(
            children: [
              // VisionOS Top Navigation Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VisionGlassPill(
                      padding: const EdgeInsets.all(10),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    Row(
                      children: [
                        if (hasModel)
                          const SpatialBadge(
                            text: '3D AR AVAILABLE',
                            icon: Icons.view_in_ar_rounded,
                            primaryColor: VizareColors.spatialCyan,
                          ),
                        const SizedBox(width: 8),
                        VisionGlassPill(
                          padding: const EdgeInsets.all(10),
                          onTap: _toggleFavorite,
                          child: _isLoadingFavorite
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: VizareColors.champagneGold,
                                  ),
                                )
                              : Icon(
                                  _isFavorited
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: _isFavorited
                                      ? Colors.redAccent
                                      : VizareColors.champagneGold,
                                  size: 18,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Price & Category Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.property.price,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: VizareColors.champagneGold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Property Title
                      Text(
                        widget.property.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location Pin
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: VizareColors.champagneGold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style: GoogleFonts.inter(
                                color: VizareColors.textSecondary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // VisionOS Image Gallery Layout
                      _buildImageGallery(context, _galleryImages),
                      const SizedBox(height: 14),
                      _buildThumbnailList(context, _galleryImages),
                      const SizedBox(height: 24),

                      // Architectural Specifications Bento Grid
                      Text(
                        'ARCHITECTURAL SPECIFICATIONS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: VizareColors.champagneGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSpecsBentoGrid(),
                      const SizedBox(height: 24),

                      // Property Description Card
                      Text(
                        'ABOUT THE ESTATE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: VizareColors.champagneGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      VisionGlassContainer(
                        padding: const EdgeInsets.all(18.0),
                        borderRadius: 20,
                        backgroundColor:
                            VizareColors.obsidianSurface.withValues(alpha: 0.8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                        child: Text(
                          widget.property.description,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.65,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // VisionOS Frosted Glass Bottom Action Bar
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsBentoGrid() {
    final specs = [
      {'label': 'Bedrooms', 'value': '4 Beds', 'icon': Icons.bed_rounded},
      {'label': 'Bathrooms', 'value': '3.5 Baths', 'icon': Icons.bathtub_rounded},
      {'label': 'Living Space', 'value': '3,850 SqFt', 'icon': Icons.square_foot_rounded},
      {'label': 'Parking', 'value': '2 Garage', 'icon': Icons.garage_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        final item = specs[index];
        return VisionGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 16,
          backgroundColor:
              VizareColors.obsidianElevated.withValues(alpha: 0.7),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.0,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VizareColors.champagneGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: VizareColors.champagneGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['value'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: VizareColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageGallery(
      BuildContext context, List<String> galleryImages) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildTappableImage(context, galleryImages, 0),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildTappableImage(context, galleryImages, 1, height: 118),
              const SizedBox(height: 10),
              _buildTappableImage(context, galleryImages, 2, height: 118),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailList(BuildContext context, List<String> images) {
    if (images.length <= 3) return const SizedBox.shrink();

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length - 3,
        itemBuilder: (context, index) {
          final realIndex = index + 3;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: _buildTappableImage(context, images, realIndex,
                width: 64, height: 64),
          );
        },
      ),
    );
  }

  Widget _buildTappableImage(
      BuildContext context, List<String> images, int index,
      {double? width, double height = 246}) {
    if (index >= images.length) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.0),
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
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bool hasModel = widget.property.modelPath.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: VizareColors.obsidianSurface.withValues(alpha: 0.90),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Explore in 3D / AR Luxury Button
              Expanded(
                child: LuxuryGradientButton(
                  text: hasModel ? 'EXPLORE IN 3D / AR' : 'NO 3D MODEL',
                  icon: hasModel
                      ? Icons.view_in_ar_rounded
                      : Icons.block_rounded,
                  gradient: hasModel ? VizareColors.goldGradient : null,
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
                ),
              ),
              const SizedBox(width: 12),

              // Contact Homeowner / Inquire Pill
              VisionGlassPill(
                padding: const EdgeInsets.all(14),
                color: VizareColors.obsidianElevated,
                borderColor:
                    VizareColors.champagneGold.withValues(alpha: 0.4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SendInquiryPage(property: widget.property),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/white_chat_icon.png',
                  width: 22,
                  height: 22,
                  color: VizareColors.champagneGold,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: VizareColors.champagneGold,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
