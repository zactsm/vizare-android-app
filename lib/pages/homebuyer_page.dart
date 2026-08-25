import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/profile_page.dart';
import 'package:untitled/pages/ar_view_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'utils/floating_bottom_nav_bar.dart';
import 'utils/abstract_background.dart';
import 'favorites_page.dart';
import 'settings_page.dart';

class HomeBuyerPage extends StatefulWidget {
  const HomeBuyerPage({super.key});

  @override
  State<HomeBuyerPage> createState() => _HomeBuyerPageState();
}

class _HomeBuyerPageState extends State<HomeBuyerPage> {
  late PageController _pageController;
  NavPageIndex _currentIndex = NavPageIndex.home;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex.index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: VizareColors.obsidianBlack,
        body: AbstractBackground(
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = NavPageIndex.values[index];
                    });
                  },
                  children: [
                    HomeBuyerHomeBody(
                      onSearchTap: () {
                        _pageController.animateToPage(
                          NavPageIndex.search.index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SearchPage(isEmbedded: true),
                    const FavoritesPage(isEmbedded: true),
                    const SettingsPage(isEmbedded: true),
                  ],
                ),
                FloatingBottomNavBar(
                  activeIndex: _currentIndex,
                  pageController: _pageController,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    _pageController.animateToPage(
                      index.index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeBuyerHomeBody extends StatefulWidget {
  final VoidCallback onSearchTap;
  const HomeBuyerHomeBody({super.key, required this.onSearchTap});

  @override
  State<HomeBuyerHomeBody> createState() => _HomeBuyerHomeBodyState();
}

class _HomeBuyerHomeBodyState extends State<HomeBuyerHomeBody> {
  bool _isLoading = true;
  List<Property> _featuredProperties = [];
  List<Property> _nearbyProperties = [];
  List<Property> _popularProperties = [];
  String? _profilePicUrl;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _fetchProperties();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email != null) {
      try {
        final response =
            await ApiService.get('get_user_profile.php', {'email': email});
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

  Future<void> _fetchProperties() async {
    try {
      final response = await ApiService.get('get_all_listings.php');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties =
            data.map((json) => Property.fromJson(json)).toList();

        setState(() {
          _featuredProperties =
              properties.where((p) => p.isFeatured).toList();
          _nearbyProperties =
              properties.where((p) => !p.isFeatured).toList();
          _popularProperties = List.from(properties)..shuffle();
          _isLoading = false;
        });
      } else {
        _logger.w('Failed to load properties: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e('Error fetching properties', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _isLoading
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 104),
                    const VizareCardSkeleton(height: 260),
                    const VizareCardSkeleton(height: 200),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 96), // Spacer for top floating bar

                    // Luxury Expressive Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.0,
                                height: 1.15,
                              ),
                              children: const [
                                TextSpan(text: 'Discover your\n'),
                                TextSpan(
                                  text: 'Architectural ',
                                  style: TextStyle(
                                    color: VizareColors.champagneGold,
                                  ),
                                ),
                                TextSpan(text: 'Sanctuary.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Step inside luxury properties with real-time 3D spatial models.',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: VizareColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Featured Architectural Showcase
                    if (_featuredProperties.isNotEmpty) ...[
                      _buildSectionHeader('Exclusive', 'Showcase'),
                      const SizedBox(height: 14),
                      _buildFeaturedCarousel(context, _featuredProperties),
                      const SizedBox(height: 32),
                    ],

                    // 2. Nearby Properties
                    if (_nearbyProperties.isNotEmpty) ...[
                      _buildSectionHeader('Nearby', 'Residences'),
                      const SizedBox(height: 14),
                      _buildNearbyCarousel(context, _nearbyProperties),
                      const SizedBox(height: 32),
                    ],

                    // 3. Popular Property Bento Feed
                    if (_popularProperties.isNotEmpty) ...[
                      _buildSectionHeader('Curated', 'Portfolio'),
                      const SizedBox(height: 14),
                      _buildPopularFeed(context, _popularProperties),
                    ],
                    const SizedBox(height: 130),
                  ],
                ),
              ),

        // Floating VisionOS Top Search Capsule
        _buildTopSearchCapsule(context),
      ],
    );
  }

  Widget _buildSectionHeader(String boldText, String accentText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 21,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
              children: [
                TextSpan(
                  text: '$boldText ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: accentText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    color: VizareColors.champagneGold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onSearchTap,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                'VIEW ALL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: VizareColors.champagneGold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel(
      BuildContext context, List<Property> properties) {
    return SizedBox(
      height: 290,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          final bool hasModel = property.modelPath.isNotEmpty;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PropertyDetailsPage(property: property),
                ),
              );
            },
            child: Container(
              width: 300,
              margin: EdgeInsets.only(
                left: index == 0 ? 20.0 : 12.0,
                right: index == properties.length - 1 ? 20.0 : 12.0,
              ),
              child: VisionGlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 26,
                backgroundColor:
                    VizareColors.obsidianSurface.withValues(alpha: 0.85),
                border: Border.all(
                  color: VizareColors.champagneGold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            property.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white24),
                            ),
                          ),
                          // Top Gradient Overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.45),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Price Pill Top-Right
                          Positioned(
                            top: 12,
                            right: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: VizareColors.champagneGold
                                          .withValues(alpha: 0.6),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    property.price,
                                    style: GoogleFonts.poppins(
                                      color: VizareColors.champagneGold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 3D Model indicator pill top-left
                          if (hasModel)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: SpatialBadge(
                                text: '3D TOUR',
                                icon: Icons.view_in_ar_rounded,
                                primaryColor: VizareColors.spatialCyan,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: VizareColors.textMuted,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.location,
                                  style: GoogleFonts.inter(
                                    color: VizareColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyCarousel(
      BuildContext context, List<Property> properties) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PropertyDetailsPage(property: property),
                ),
              );
            },
            child: Container(
              width: 210,
              margin: EdgeInsets.only(
                left: index == 0 ? 20.0 : 12.0,
                right: index == properties.length - 1 ? 20.0 : 12.0,
              ),
              child: VisionGlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 22,
                backgroundColor:
                    VizareColors.obsidianElevated.withValues(alpha: 0.6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        property.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, e, s) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white24),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            property.price,
                            style: GoogleFonts.poppins(
                              color: VizareColors.champagneGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularFeed(
      BuildContext context, List<Property> properties) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          final bool hasModel = property.modelPath.isNotEmpty;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PropertyDetailsPage(property: property),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: VisionGlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 26,
                backgroundColor:
                    VizareColors.obsidianSurface.withValues(alpha: 0.85),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            property.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white24, size: 44),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: VizareColors.champagneGold
                                          .withValues(alpha: 0.6),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    property.price,
                                    style: GoogleFonts.poppins(
                                      color: VizareColors.champagneGold,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  property.location,
                                  style: GoogleFonts.inter(
                                    color: VizareColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // View in AR Button
                          ElevatedButton(
                            onPressed: hasModel
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArViewPage(
                                          modelUrl: property.modelPath,
                                          propertyName: property.name,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasModel
                                  ? VizareColors.champagneGold
                                  : Colors.white10,
                              foregroundColor: VizareColors.obsidianBlack,
                              disabledForegroundColor: Colors.white24,
                              elevation: hasModel ? 8 : 0,
                              shadowColor: VizareColors.champagneGold
                                  .withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasModel) ...[
                                  const Icon(Icons.view_in_ar_rounded,
                                      size: 16, color: VizareColors.obsidianBlack),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  hasModel ? 'VIEW AR' : 'NO AR',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSearchCapsule(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topInset + 8.0,
      left: 16.0,
      right: 16.0,
      child: VisionGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        borderRadius: 30.0,
        backgroundColor: VizareColors.obsidianSurface.withValues(alpha: 0.85),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 38,
              height: 38,
              errorBuilder: (context, e, s) =>
                  const SizedBox(width: 38, height: 38),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onSearchTap();
                },
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: VizareColors.champagneGold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search luxury properties...',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VizareColors.champagneGold.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  image: _profilePicUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_profilePicUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePicUrl == null
                    ? const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: VizareColors.champagneGold,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
