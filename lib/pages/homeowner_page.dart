import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/pages/utils/top_bar_gradient_blur.dart';

import 'package:untitled/pages/profile_page.dart';
import 'package:untitled/pages/add_property_page.dart';
import 'package:untitled/pages/edit_property_page.dart';
import 'package:untitled/pages/chat/conversations_inbox_page.dart';

class HomeownerPage extends StatefulWidget {
  const HomeownerPage({super.key});

  @override
  State<HomeownerPage> createState() => _HomeownerPageState();
}

class _HomeownerPageState extends State<HomeownerPage> {
  final _logger = Logger();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearchExpanded = false;
  List<Property> _myProperties = [];
  List<Property> _filteredProperties = [];
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
    _verifyHomeownerRole();
    _searchController.addListener(_filterProperties);
    _fetchMyProperties();
    _fetchUserProfile();
  }

  Future<void> _verifyHomeownerRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_type')?.toLowerCase();
    final email = prefs.getString('user_email');
    if (email == null || (role != 'homeowner' && role != 'admin')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Access restricted to verified Homeowners & Administrators.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
        Navigator.pushReplacementNamed(context, '/homebuyer');
      }
    }
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

  Future<void> _deleteProperty(int propertyId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => VizareDialog(
        title: "Delete Listing",
        message: "Are you sure you want to permanently remove this property listing?",
        confirmText: "Delete",
        cancelText: "Cancel",
        confirmColor: VizareColors.crimsonRed,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) return;

    try {
      final response = await ApiService.post(
        'delete_property.php',
        body: {
          'property_id': propertyId.toString(),
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _myProperties.removeWhere((p) => p.id == propertyId);
          _filterProperties();
        });
      }
    } catch (e) {
      _logger.e("Error deleting property", error: e);
    }
  }

  Future<void> _fetchMyProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response =
          await ApiService.get('get_my_properties.php', {'email': email});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final properties =
            data.map((json) => Property.fromJson(json)).toList();

        if (mounted) {
          setState(() {
            _myProperties = properties;
            _filterProperties();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e("Error fetching my properties", error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProperties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProperties = List.from(_myProperties);
      } else {
        _filteredProperties = _myProperties.where((property) {
          final nameMatch = property.name.toLowerCase().contains(query);
          final locationMatch =
              property.location.toLowerCase().contains(query);
          return nameMatch || locationMatch;
        }).toList();
      }
    });
  }

  void _navigateToAddProperty() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyPage()),
    ).then((result) {
      if (result == true) {
        if (!mounted) return;
        setState(() => _isLoading = true);
        _fetchMyProperties();
      }
    });
  }

  void _navigateToEditProperty(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPropertyPage(property: property),
      ),
    ).then((result) {
      if (result == true) {
        if (!mounted) return;
        setState(() => _isLoading = true);
        _fetchMyProperties();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
        child: SafeArea(
          child: Stack(
            children: [
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: VizareColors.champagneGold),
                    )
                  : _buildBody(isDark),
              const TopBarGradientBlur(height: 90.0),
              _buildTopBar(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Positioned(
      top: 10.0,
      left: 20.0,
      right: 20.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: App Logo
              Image.asset(
                'assets/images/logo.png',
                width: 38,
                height: 38,
                color: isDark ? null : VizareColors.champagneGold,
                errorBuilder: (c, e, s) =>
                    const SizedBox(width: 38, height: 38),
              ),
              // Right: Search Icon + Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded) {
                          _searchController.clear();
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isSearchExpanded
                            ? VizareColors.champagneGold.withValues(alpha: 0.2)
                            : (isDark
                                ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.95)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSearchExpanded
                              ? VizareColors.champagneGold
                              : VizareColors.champagneGold.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isSearchExpanded
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          color: VizareColors.champagneGold,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
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
                                : Colors.black.withValues(alpha: 0.05),
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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isSearchExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: VisionGlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                borderRadius: 22.0,
                backgroundColor: isDark
                    ? VizareColors.obsidianSurface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border.all(
                  color: isDark
                      ? VizareColors.champagneGold.withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: VizareColors.champagneGold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filter your portfolio...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.45)
                                : const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Icon(
                          Icons.clear_rounded,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 72),
          Text(
            'Estate Manager',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create, monitor, and manage your 3D architectural listings.',
            style: GoogleFonts.inter(
              color: isDark
                  ? VizareColors.textSecondary
                  : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          _buildButtonRow(isDark),
          const SizedBox(height: 24),
          _buildMyPropertiesList(isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildButtonRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: LuxuryGradientButton(
            text: '+ Add Property',
            icon: Icons.add_business_rounded,
            height: 48,
            onPressed: _navigateToAddProperty,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: VisionGlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: 28,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConversationsInboxPage()),
              );
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: VizareColors.champagneGold.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mark_chat_unread_rounded,
                    color: VizareColors.champagneGold,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Inquiries',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyPropertiesList(bool isDark) {
    if (_filteredProperties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0),
          child: Text(
            _searchController.text.isNotEmpty
                ? 'No properties match "${_searchController.text}".'
                : 'You have not added any properties yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredProperties.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final property = _filteredProperties[index];
        return _buildPropertyCard(property, isDark);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return VizareColors.emeraldGreen;
      case 'rejected':
        return VizareColors.crimsonRed;
      case 'pending':
      default:
        return VizareColors.champagneGold;
    }
  }

  Widget _buildPropertyCard(Property property, bool isDark) {
    final statusColor = _getStatusColor(property.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: VisionGlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 22,
        backgroundColor: isDark
            ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
            : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Image.network(
                property.imagePath,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 76,
                  height: 76,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.broken_image,
                    color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    property.price,
                    style: GoogleFonts.poppins(
                      color: VizareColors.champagneGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      property.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B), size: 20),
              color: isDark ? VizareColors.obsidianElevated : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditProperty(property);
                } else if (value == 'delete') {
                  _deleteProperty(property.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: VizareColors.champagneGold, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: VizareColors.crimsonRed, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                            color: VizareColors.crimsonRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
