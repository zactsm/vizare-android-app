import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:untitled/pages/utils/app_theme.dart';

class GalleryViewPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const GalleryViewPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<GalleryViewPage> createState() => _GalleryViewPageState();
}

class _GalleryViewPageState extends State<GalleryViewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            onPageChanged: onPageChanged,
            itemCount: widget.imagePaths.length,
            builder: (context, index) {
              final imagePath = widget.imagePaths[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imagePath),
                heroAttributes:
                    PhotoViewHeroAttributes(tag: '$imagePath-$index'),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.5,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, color: VizareColors.textMuted, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Image unavailable',
                        style: GoogleFonts.inter(color: VizareColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(
                color: VizareColors.champagneGold,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: VisionGlassPill(
              padding: const EdgeInsets.all(10),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            right: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imagePaths.length}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
