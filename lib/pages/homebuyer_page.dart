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
import 'utils/top_bar_gradient_blur.dart';
import 'favorites_page.dart';
import 'settings_page.dart';
import 'chat/conversations_inbox_page.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != NavPageIndex.home) {
          setState(() {
            _currentIndex = NavPageIndex.home;
          });
          _pageController.animateToPage(
            NavPageIndex.home.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
        body: AbstractBackground(
          child: SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
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

  String? _errorMessage;

  List<Property> _sortWithPreferences(
      List<Property> list, SharedPreferences prefs) {
    final List<Property> preferred = [];
    final List<Property> others = [];

    for (final p in list) {
      final bool isPref =
          prefs.getBool('propertyType_${p.propertyType}') ?? true;
      if (isPref) {
        preferred.add(p);
      } else {
        others.add(p);
      }
    }
    return [...preferred, ...others];
  }

  Future<void> _fetchProperties() async {
    setState(() => _errorMessage = null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await ApiService.get('get_all_listings.php');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Property> properties = [];
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              properties.add(Property.fromJson(item));
            } else if (item is Map) {
              properties.add(Property.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (itemErr) {
            _logger.w('Skipping malformed property item', error: itemErr);
          }
        }

        final sortedFeatured = _sortWithPreferences(
            properties.where((p) => p.isFeatured).toList(), prefs);
        final sortedNearby = _sortWithPreferences(
            properties.where((p) => !p.isFeatured).toList(), prefs);
        final sortedPopular = _sortWithPreferences(
            List.from(properties)..shuffle(), prefs);

        setState(() {
          _featuredProperties = sortedFeatured;
          _nearbyProperties = sortedNearby;
          _popularProperties = sortedPopular;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        _logger.w('Failed to load properties: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load real estate catalog (HTTP ${response.statusCode}).';
        });
      }
    } catch (e) {
      _logger.e('Error fetching properties', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Network connection interrupted. Please verify connection and retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        _isLoading
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 68),
                    const VizareCardSkeleton(height: 260),
                    const VizareCardSkeleton(height: 200),
                  ],
                ),
              )
            : RefreshIndicator(
                color: VizareColors.champagneGold,
                backgroundColor:
                    isDark ? VizareColors.obsidianElevated : Colors.white,
                onRefresh: _fetchProperties,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 68), // Spacer for top floating bar

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
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
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
                              color: isDark
                                  ? VizareColors.textSecondary
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: VisionGlassContainer(
                          padding: const EdgeInsets.all(24),
                          border: Border.all(color: VizareColors.crimsonRed.withValues(alpha: 0.4)),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: VizareColors.crimsonRed, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Connection Notice',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? VizareColors.textSecondary
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 18),
                              LuxuryGradientButton(
                                text: 'Retry Connection',
                                icon: Icons.refresh_rounded,
                                onPressed: _fetchProperties,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 1. Featured Architectural Showcase
                    if (_featuredProperties.isNotEmpty) ...[
                      _buildSectionHeader('Exclusive', 'Showcase'),
                      const SizedBox(height: 14),
                      _buildFeaturedCarousel(context, _featuredProperties),
                      const SizedBox(height: 32),
                    ],

                    // 2. Discover Nearby Section
                    if (_nearbyProperties.isNotEmpty) ...[
                      _buildSectionHeader('Nearby', 'Properties'),
                      const SizedBox(height: 14),
                      _buildNearbyCarousel(context, _nearbyProperties),
                      const SizedBox(height: 32),
                    ],

                    // 3. Spatial Real Estate Picks
                    if (_popularProperties.isNotEmpty) ...[
                      _buildSectionHeader('Curated', 'Portfolio'),
                      const SizedBox(height: 14),
                      _buildPopularFeed(context, _popularProperties),
                    ],
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ),

        // Smooth Gradient Blur behind top bar
        const TopBarGradientBlur(height: 90.0),

        // Floating VisionOS Top Search Capsule
        _buildTopSearchCapsule(context),
      ],
    );
  }

  Widget _buildSectionHeader(String boldText, String accentText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 21,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                backgroundColor: isDark
                    ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border.all(
                  color: isDark
                      ? VizareColors.champagneGold.withValues(alpha: 0.35)
                      : const Color(0xFFE2E8F0),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: isDark
                                    ? VizareColors.textMuted
                                    : const Color(0xFF94A3B8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.location,
                                  style: GoogleFonts.inter(
                                    color: isDark
                                        ? VizareColors.textSecondary
                                        : const Color(0xFF64748B),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                backgroundColor: isDark
                    ? VizareColors.obsidianElevated.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
  Widget _buildPopularFeed(BuildContext context, List<Property> properties) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: List.generate(
          properties.length,
          (index) {
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
                  backgroundColor: isDark
                      ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.95),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFE2E8F0),
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
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
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
                                      color: isDark
                                          ? VizareColors.textSecondary
                                          : const Color(0xFF64748B),
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
                                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                foregroundColor: VizareColors.obsidianBlack,
                                disabledForegroundColor: isDark ? Colors.white24 : const Color(0xFF94A3B8),
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
      ),
    );
  }

  Widget _buildTopSearchCapsule(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 10.0,
      left: 20.0,
      right: 20.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: App Logo
          Image.asset(
            'assets/images/logo.png',
            width: 38,
            height: 38,
            color: isDark ? null : VizareColors.champagneGold,
            errorBuilder: (context, e, s) =>
                const SizedBox(width: 38, height: 38),
          ),
          // Right: Search Icon + Profile Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onSearchTap(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VizareColors.champagneGold.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.search_rounded,
                      color: VizareColors.champagneGold,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Messages Action Button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConversationsInboxPage(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VizareColors.champagneGold.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: VizareColors.champagneGold,
                      size: 19,
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
                  ).then((_) => _fetchUserProfile());
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VizareColors.champagneGold.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
        ],
      ),
    );
  }
}
