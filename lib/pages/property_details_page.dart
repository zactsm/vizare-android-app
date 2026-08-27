import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/models/chat_models.dart';
import 'package:untitled/pages/gallery_view_page.dart';
import 'package:untitled/pages/chat/chat_page.dart';
import 'package:untitled/pages/chat/schedule_viewing_dialog.dart';
import 'package:untitled/pages/utils/chat_service.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/ar_view_page.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/pages/utils/property_details_skeleton.dart';
import 'package:intl/intl.dart';

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
  bool _isLoadingGallery = true;
  String? _userEmail;

  List<String> _galleryImages = [];
  late PageController _imageCarouselController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageCarouselController = PageController(initialPage: 0);
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

  @override
  void dispose() {
    _imageCarouselController.dispose();
    super.dispose();
  }

  Future<void> _fetchGalleryImages() async {
    try {
      final response = await ApiService.get(
          'get_property_images.php', {'property_id': widget.property.id})
          .timeout(const Duration(seconds: 5));

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGallery = false;
        });
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isLoadingGallery
                ? const PropertyDetailsSkeleton(key: ValueKey('skeleton'))
                : _buildLoadedContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey('loaded_content'),
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
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 18,
                ),
              ),
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
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Property Title (First, in Yellow / Champagne Gold bold)
                Text(
                  widget.property.name,
                  style: GoogleFonts.poppins(
                    color: VizareColors.champagneGold,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Price (Below title, in white/dark text)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.property.price,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.property.propertyType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: VizareColors.champagneGold
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: VizareColors.champagneGold
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.property.propertyType,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VizareColors.champagneGold,
                          ),
                        ),
                      ),
                  ],
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
                          color: isDark
                              ? VizareColors.textSecondary
                              : const Color(0xFF64748B),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // VisionOS Image Gallery & Carousel Layout
                _buildImageGallery(context, _galleryImages),
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
                  backgroundColor: isDark
                      ? VizareColors.obsidianSurface.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.95),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  child: Text(
                    widget.property.description,
                    style: GoogleFonts.inter(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF334155),
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
    );
  }

  Widget _buildSpecsBentoGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final has3D = widget.property.modelPath.isNotEmpty;
    final nameLower = widget.property.name.toLowerCase();
    final isVilla = nameLower.contains('villa') || nameLower.contains('mansion') || nameLower.contains('estate');
    final isPenthouse = nameLower.contains('penthouse') || nameLower.contains('residence') || nameLower.contains('sky');

    final specs = [
      {
        'label': 'Architecture',
        'value': isVilla ? 'Villa / Estate' : (isPenthouse ? 'Penthouse' : 'Modern Luxury'),
        'icon': Icons.architecture_rounded,
      },
      {
        'label': 'Spatial 3D',
        'value': has3D ? 'Interactive GLB' : 'Standard 2D',
        'icon': has3D ? Icons.view_in_ar_rounded : Icons.photo_library_rounded,
      },
      {
        'label': 'Status',
        'value': widget.property.status.toUpperCase(),
        'icon': Icons.verified_outlined,
      },
      {
        'label': 'Experience',
        'value': widget.property.isFeatured ? 'Curated Premier' : 'Verified Listing',
        'icon': Icons.star_border_rounded,
      },
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
          backgroundColor: isDark
              ? VizareColors.obsidianElevated.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.95),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
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
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? VizareColors.textMuted
                            : const Color(0xFF64748B),
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
    if (galleryImages.isEmpty) return const SizedBox.shrink();

    final bool canCycle = galleryImages.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Carousel with persistent aspect ratio and chevron controls
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            children: [
              // PageView Carousel
              ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: PageView.builder(
                  controller: _imageCarouselController,
                  itemCount: galleryImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imagePath = galleryImages[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GalleryViewPage(
                              imagePaths: galleryImages,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: '$imagePath-$index',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0),
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
                            borderRadius: BorderRadius.circular(23.0),
                            child: Image.network(
                              imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, e, s) => Container(
                                color: VizareColors.obsidianSurface,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: Colors.white24, size: 40),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Left Chevron Arrow Button
              if (canCycle)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: VisionGlassPill(
                      padding: const EdgeInsets.all(8),
                      onTap: () {
                        final target = _currentImageIndex > 0
                            ? _currentImageIndex - 1
                            : galleryImages.length - 1;
                        _imageCarouselController.animateToPage(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

              // Right Chevron Arrow Button
              if (canCycle)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: VisionGlassPill(
                      padding: const EdgeInsets.all(8),
                      onTap: () {
                        final target = _currentImageIndex < galleryImages.length - 1
                            ? _currentImageIndex + 1
                            : 0;
                        _imageCarouselController.animateToPage(
                          target,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

              // Page Count Indicator Pill
              if (canCycle)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${galleryImages.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Persistent Aspect Ratio Thumbnail Strip
        _buildThumbnailList(context, galleryImages),
      ],
    );
  }

  Widget _buildThumbnailList(BuildContext context, List<String> images) {
    if (images.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imagePath = images[index];
          final bool isSelected = index == _currentImageIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _currentImageIndex = index);
                _imageCarouselController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? VizareColors.champagneGold
                        : Colors.white.withValues(alpha: 0.15),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: VizareColors.champagneGold.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isSelected ? 14.0 : 15.0),
                  child: Image.network(
                    imagePath,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      width: 68,
                      height: 68,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white24, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openChat() async {
    final conv = await ChatService.getOrCreateConversation(widget.property.id);
    if (!mounted) return;
    if (conv != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage(conversation: conv)),
      );
    } else {
      final fallbackConv = Conversation(
        id: 0,
        propertyId: widget.property.id,
        buyerId: 0,
        homeownerId: widget.property.homeownerId,
        lastMessage: '',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
        property: widget.property,
        otherUser: const ConversationParticipant(
          id: 0,
          fullName: 'Estate Agent / Homeowner',
          email: '',
          role: 'homeowner',
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage(conversation: fallbackConv)),
      );
    }
  }

  void _openScheduleViewing() {
    ScheduleViewingDialog.show(
      context: context,
      property: widget.property,
      onSchedule: (date, timeSlot, tourMode, note) async {
        final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);
        final modeLabel = tourMode == 'virtual_ar'
            ? 'Virtual 3D AR Walkthrough'
            : 'In-Person On-Site Tour';
        final messageContent = note.isNotEmpty
            ? 'Viewing Request: $modeLabel on $formattedDate at $timeSlot.\nNote: "$note"'
            : 'Viewing Request: $modeLabel on $formattedDate at $timeSlot.';

        final conv = await ChatService.getOrCreateConversation(widget.property.id);
        if (conv != null && mounted) {
          await ChatService.sendMessage(
            conversationId: conv.id,
            messageText: messageContent,
            messageType: 'viewing_request',
            viewingDate: formattedDate,
            viewingTime: timeSlot,
            viewingMode: tourMode,
          );
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage(conversation: conv)),
          );
        }
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasModel = widget.property.modelPath.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          decoration: BoxDecoration(
            color: isDark
                ? VizareColors.obsidianSurface.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isDark ? 24 : 16,
                offset: isDark ? const Offset(0, -6) : const Offset(0, -3),
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
              const SizedBox(width: 10),

              // Schedule Viewing Button
              VisionGlassPill(
                padding: const EdgeInsets.all(13),
                color: isDark
                    ? VizareColors.obsidianElevated
                    : const Color(0xFFF1F5F9),
                borderColor:
                    VizareColors.champagneGold.withValues(alpha: 0.5),
                onTap: _openScheduleViewing,
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: VizareColors.champagneGold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),

              // 2-Way Direct Chat Pill
              VisionGlassPill(
                padding: const EdgeInsets.all(13),
                color: isDark
                    ? VizareColors.obsidianElevated
                    : const Color(0xFFF1F5F9),
                borderColor:
                    VizareColors.champagneGold.withValues(alpha: 0.7),
                onTap: _openChat,
                child: Image.asset(
                  'assets/images/white_chat_icon.png',
                  width: 21,
                  height: 21,
                  color: VizareColors.champagneGold,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: VizareColors.champagneGold,
                    size: 21,
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
