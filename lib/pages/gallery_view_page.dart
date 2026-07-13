import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

    // Set status bar to light for this full-screen view
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
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
          // --- The Swipable, Zoomable Gallery ---
          PhotoViewGallery.builder(
            pageController: _pageController,
            onPageChanged: onPageChanged,
            itemCount: widget.imagePaths.length,
            builder: (context, index) {
              final imagePath = widget.imagePaths[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imagePath),
                // This Hero tag MUST match the one on the details page
                heroAttributes: PhotoViewHeroAttributes(tag: '$imagePath-$index'),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // --- Back Button ---
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),

          // --- Page Counter (e.g., "3 / 5") ---
          Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              '${_currentIndex + 1} / ${widget.imagePaths.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}