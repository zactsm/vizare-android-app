import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/models/user_profile_model.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/widgets/admin_drawer.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Logger _logger = Logger();

  AdminView _currentView = AdminView.moderation;
  String? _adminEmail;

  // 1. Moderation Queue state
  List<Property> _pendingProperties = [];
  bool _isLoadingPending = true;

  // 2. All Listings state
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoadingListings = false;
  String _listingStatusFilter = 'all';
  final TextEditingController _listingSearchController = TextEditingController();

  // 3. User Management state
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoadingUsers = false;
  String _userRoleFilter = 'all';
  final TextEditingController _userSearchController = TextEditingController();

  // 4. Analytics state
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = false;

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
    _loadAdminInfo();
    _fetchPendingProperties();
    _listingSearchController.addListener(_filterListings);
    _userSearchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _listingSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_type')?.toLowerCase();
    final email = prefs.getString('user_email');
    if (email == null || role != 'admin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Access restricted to Platform Administrators.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
        Navigator.pushReplacementNamed(context, '/homebuyer');
      }
    } else {
      if (mounted) {
        setState(() => _adminEmail = email);
      }
    }
  }

  void _onViewSelected(AdminView view) {
    setState(() => _currentView = view);
    if (view == AdminView.moderation && _pendingProperties.isEmpty) {
      _fetchPendingProperties();
    } else if (view == AdminView.listings && _allProperties.isEmpty) {
      _fetchAllProperties();
    } else if (view == AdminView.users && _allUsers.isEmpty) {
      _fetchAllUsers();
    } else if (view == AdminView.analytics && _stats.isEmpty) {
      _fetchStats();
    }
  }

  // ==========================================
  // DATA FETCHING & MUTATION METHODS
  // ==========================================

  Future<void> _fetchPendingProperties() async {
    setState(() => _isLoadingPending = true);
    try {
      final response = await ApiService.get('get_pending_properties.php');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _pendingProperties =
                data.map((json) => Property.fromJson(json)).toList();
            _isLoadingPending = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPending = false);
      }
    } catch (e) {
      _logger.e("Error fetching pending properties", error: e);
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _fetchAllProperties() async {
    setState(() => _isLoadingListings = true);
    try {
      final response = await ApiService.get('get_all_properties_admin.php');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allProperties =
                data.map((json) => Property.fromJson(json)).toList();
            _filterListings();
            _isLoadingListings = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingListings = false);
      }
    } catch (e) {
      _logger.e("Error fetching all properties", error: e);
      if (mounted) setState(() => _isLoadingListings = false);
    }
  }

  Future<void> _fetchAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await ApiService.get('get_admin_users.php');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allUsers =
                data.map((json) => UserProfile.fromJson(json)).toList();
            _filterUsers();
            _isLoadingUsers = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingUsers = false);
      }
    } catch (e) {
      _logger.e("Error fetching users", error: e);
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final response = await ApiService.get('get_admin_stats.php');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _stats = data;
            _isLoadingStats = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      _logger.e("Error fetching stats", error: e);
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _updatePropertyStatus(int propertyId, String newStatus) async {
    setState(() {
      _pendingProperties.removeWhere((p) => p.id == propertyId);
      final index = _allProperties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        final current = _allProperties[index];
        _allProperties[index] = Property(
          id: current.id,
          homeownerId: current.homeownerId,
          name: current.name,
          location: current.location,
          price: current.price,
          description: current.description,
          imagePath: current.imagePath,
          modelPath: current.modelPath,
          isFeatured: current.isFeatured,
          createdAt: current.createdAt,
          status: newStatus,
        );
        _filterListings();
      }
    });

    try {
      await ApiService.post(
        'update_property_status.php',
        body: {
          'property_id': propertyId.toString(),
          'status': newStatus,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Property listing marked as $newStatus',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: newStatus == 'approved'
              ? VizareColors.emeraldGreen
              : newStatus == 'rejected'
                  ? VizareColors.crimsonRed
                  : VizareColors.champagneGold,
          duration: const Duration(milliseconds: 900),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
        _fetchPendingProperties();
      }
    }
  }

  Future<void> _toggleFeatured(int propertyId, bool currentVal) async {
    final newVal = !currentVal;
    setState(() {
      final index = _allProperties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        final current = _allProperties[index];
        _allProperties[index] = Property(
          id: current.id,
          homeownerId: current.homeownerId,
          name: current.name,
          location: current.location,
          price: current.price,
          description: current.description,
          imagePath: current.imagePath,
          modelPath: current.modelPath,
          isFeatured: newVal,
          createdAt: current.createdAt,
          status: current.status,
        );
        _filterListings();
      }
    });

    try {
      await ApiService.post(
        'toggle_property_featured.php',
        body: {
          'property_id': propertyId.toString(),
          'is_featured': newVal.toString(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newVal ? 'Property featured' : 'Property unfeatured'),
          duration: const Duration(milliseconds: 700),
        ),
      );
    } catch (e) {
      _logger.e("Error toggling featured", error: e);
    }
  }

  Future<void> _updateUserRole(UserProfile user, String newRole) async {
    final String oldRole = user.role;
    setState(() {
      final index = _allUsers.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _allUsers[index] = user.copyWith(role: newRole);
        _filterUsers();
      }
    });

    try {
      final res = await ApiService.post(
        'update_user_role.php',
        body: {
          'user_id': user.id,
          'role': newRole,
        },
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} role updated to ${newRole.toUpperCase()}'),
            backgroundColor: VizareColors.emeraldGreen,
            duration: const Duration(milliseconds: 900),
          ),
        );
      } else {
        setState(() {
          final index = _allUsers.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _allUsers[index] = user.copyWith(role: oldRole);
            _filterUsers();
          }
        });
      }
    } catch (e) {
      _logger.e("Error updating user role", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update role')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      try {
        await GoogleAuthService.signOut();
      } catch (_) {}
      await AppThemeController.instance.resetToDefaultDark();
    } catch (_) {}
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // ==========================================
  // FILTERING LOGIC
  // ==========================================

  void _filterListings() {
    final query = _listingSearchController.text.toLowerCase();
    setState(() {
      _filteredProperties = _allProperties.where((prop) {
        final matchesQuery = prop.name.toLowerCase().contains(query) ||
            prop.location.toLowerCase().contains(query) ||
            prop.price.toLowerCase().contains(query);
        final matchesStatus = _listingStatusFilter == 'all' ||
            prop.status.toLowerCase() == _listingStatusFilter;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _filterUsers() {
    final query = _userSearchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final matchesQuery = u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.phoneNumber.toLowerCase().contains(query);
        final matchesRole = _userRoleFilter == 'all' ||
            u.role.toLowerCase() == _userRoleFilter;
        return matchesQuery && matchesRole;
      }).toList();
    });
  }

  // ==========================================
  // MAIN BUILD & VIEW ROUTING
  // ==========================================

  String get _viewTitle {
    switch (_currentView) {
      case AdminView.moderation:
        return 'Moderation Queue';
      case AdminView.listings:
        return 'Listings Management';
      case AdminView.users:
        return 'User Management';
      case AdminView.analytics:
        return 'Platform Overview';
    }
  }

  String get _viewSubtitle {
    switch (_currentView) {
      case AdminView.moderation:
        return 'Review & approve submitted property listings.';
      case AdminView.listings:
        return 'Manage and monitor all platform real estate listings.';
      case AdminView.users:
        return 'Manage buyer, homeowner, and administrator profiles.';
      case AdminView.analytics:
        return 'High-level metrics and platform operations.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      drawer: AdminDrawer(
        currentView: _currentView,
        pendingCount: _pendingProperties.length,
        adminEmail: _adminEmail,
        onViewSelected: _onViewSelected,
        onSignOut: _signOut,
      ),
      body: AbstractBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Hamburger Button & Section Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        VisionGlassPill(
                          padding: const EdgeInsets.all(10),
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Icon(
                            Icons.menu_rounded,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _viewTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    VisionGlassPill(
                      padding: const EdgeInsets.all(10),
                      onTap: () {
                        if (_currentView == AdminView.moderation) {
                          _fetchPendingProperties();
                        } else if (_currentView == AdminView.listings) {
                          _fetchAllProperties();
                        } else if (_currentView == AdminView.users) {
                          _fetchAllUsers();
                        } else if (_currentView == AdminView.analytics) {
                          _fetchStats();
                        }
                      },
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: VizareColors.champagneGold,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    _viewSubtitle,
                    style: GoogleFonts.inter(
                      color: isDark
                          ? VizareColors.textSecondary
                          : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // View Body Content
                Expanded(
                  child: _buildCurrentViewBody(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentViewBody(bool isDark) {
    switch (_currentView) {
      case AdminView.moderation:
        return _buildModerationQueueView(isDark);
      case AdminView.listings:
        return _buildListingsManagementView(isDark);
      case AdminView.users:
        return _buildUserManagementView(isDark);
      case AdminView.analytics:
        return _buildPlatformOverviewView(isDark);
    }
  }

  // ==========================================
  // VIEW 1: MODERATION QUEUE
  // ==========================================

  Widget _buildModerationQueueView(bool isDark) {
    if (_isLoadingPending) {
      return const Center(
        child: CircularProgressIndicator(color: VizareColors.champagneGold),
      );
    }

    if (_pendingProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VizareColors.emeraldGreen.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 48,
                color: VizareColors.emeraldGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Moderation Queue Clean",
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "All submitted property listings have been reviewed.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingProperties.length,
      itemBuilder: (context, index) {
        final property = _pendingProperties[index];
        final bool hasModel = property.modelPath.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: VisionGlassContainer(
            padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        property.imagePath,
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 78,
                          height: 78,
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
                              fontSize: 15.5,
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property.location,
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? VizareColors.textSecondary
                                  : const Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasModel)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: const SpatialBadge(
                      text: 'INCLUDES 3D AR MODEL',
                      icon: Icons.view_in_ar_rounded,
                      primaryColor: VizareColors.spatialCyan,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded,
                              size: 18, color: VizareColors.textPrimary),
                          label: Text(
                            'Approve',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: VizareColors.textPrimary,
                            ),
                          ),
                          onPressed: () =>
                              _updatePropertyStatus(property.id, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VizareColors.emeraldGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_rounded,
                              size: 18, color: VizareColors.crimsonRed),
                          label: Text(
                            'Reject',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: VizareColors.crimsonRed,
                            ),
                          ),
                          onPressed: () =>
                              _updatePropertyStatus(property.id, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: VizareColors.crimsonRed, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // VIEW 2: LISTINGS MANAGEMENT
  // ==========================================

  Widget _buildListingsManagementView(bool isDark) {
    if (_isLoadingListings) {
      return const Center(
        child: CircularProgressIndicator(color: VizareColors.champagneGold),
      );
    }

    return Column(
      children: [
        // Search & Filter row
        VisionGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          borderRadius: 18,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFCBD5E1),
          ),
          child: TextField(
            controller: _listingSearchController,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              icon: const Icon(Icons.search_rounded, color: VizareColors.champagneGold, size: 20),
              hintText: 'Search listings by name, city, price...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 'all', _listingStatusFilter, (v) {
                setState(() => _listingStatusFilter = v);
                _filterListings();
              }, isDark),
              _buildFilterChip('Approved', 'approved', _listingStatusFilter, (v) {
                setState(() => _listingStatusFilter = v);
                _filterListings();
              }, isDark),
              _buildFilterChip('Pending', 'pending', _listingStatusFilter, (v) {
                setState(() => _listingStatusFilter = v);
                _filterListings();
              }, isDark),
              _buildFilterChip('Sold', 'sold', _listingStatusFilter, (v) {
                setState(() => _listingStatusFilter = v);
                _filterListings();
              }, isDark),
              _buildFilterChip('Rejected', 'rejected', _listingStatusFilter, (v) {
                setState(() => _listingStatusFilter = v);
                _filterListings();
              }, isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Listings List
        Expanded(
          child: _filteredProperties.isEmpty
              ? Center(
                  child: Text(
                    'No listings matching filter criteria.',
                    style: GoogleFonts.inter(
                      color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredProperties.length,
                  itemBuilder: (context, index) {
                    final p = _filteredProperties[index];
                    return _buildAllListingCard(p, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllListingCard(Property p, bool isDark) {
    Color statusColor;
    switch (p.status.toLowerCase()) {
      case 'approved':
        statusColor = VizareColors.emeraldGreen;
        break;
      case 'pending':
        statusColor = VizareColors.champagneGold;
        break;
      case 'sold':
        statusColor = VizareColors.spatialCyan;
        break;
      case 'rejected':
        statusColor = VizareColors.crimsonRed;
        break;
      default:
        statusColor = VizareColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: VisionGlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 20,
        backgroundColor: isDark
            ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
            : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                p.imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 72,
                  height: 72,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.broken_image,
                    color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          p.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.price,
                    style: GoogleFonts.poppins(
                      color: VizareColors.champagneGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    p.location,
                    style: GoogleFonts.inter(
                      color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Featured Toggle Button
                      InkWell(
                        onTap: () => _toggleFeatured(p.id, p.isFeatured),
                        child: Row(
                          children: [
                            Icon(
                              p.isFeatured ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: p.isFeatured ? VizareColors.champagneGold : (isDark ? VizareColors.textMuted : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.isFeatured ? 'Featured' : 'Feature',
                              style: GoogleFonts.inter(
                                color: p.isFeatured ? VizareColors.champagneGold : (isDark ? VizareColors.textMuted : const Color(0xFF64748B)),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Status Change Menu
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz_rounded,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B), size: 20),
                        color: isDark ? VizareColors.obsidianElevated : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        onSelected: (newStatus) => _updatePropertyStatus(p.id, newStatus),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'approved',
                            child: Text(
                              'Mark as Approved',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pending',
                            child: Text(
                              'Mark as Pending',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'sold',
                            child: Text(
                              'Mark as Sold',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rejected',
                            child: Text(
                              'Mark as Rejected',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 3: USER MANAGEMENT
  // ==========================================

  Widget _buildUserManagementView(bool isDark) {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: VizareColors.champagneGold),
      );
    }

    return Column(
      children: [
        // User Search Bar
        VisionGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          borderRadius: 18,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFCBD5E1),
          ),
          child: TextField(
            controller: _userSearchController,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              icon: const Icon(Icons.search_rounded, color: VizareColors.champagneGold, size: 20),
              hintText: 'Search users by name, email, role...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Role Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Users', 'all', _userRoleFilter, (v) {
                setState(() => _userRoleFilter = v);
                _filterUsers();
              }, isDark),
              _buildFilterChip('Homebuyers', 'homebuyer', _userRoleFilter, (v) {
                setState(() => _userRoleFilter = v);
                _filterUsers();
              }, isDark),
              _buildFilterChip('Homeowners', 'homeowner', _userRoleFilter, (v) {
                setState(() => _userRoleFilter = v);
                _filterUsers();
              }, isDark),
              _buildFilterChip('Admins', 'admin', _userRoleFilter, (v) {
                setState(() => _userRoleFilter = v);
                _filterUsers();
              }, isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Users List
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No user profiles found.',
                    style: GoogleFonts.inter(
                      color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final u = _filteredUsers[index];
                    return _buildUserCard(u, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserProfile u, bool isDark) {
    Color roleColor;
    switch (u.role.toLowerCase()) {
      case 'admin':
        roleColor = VizareColors.crimsonRed;
        break;
      case 'homeowner':
        roleColor = VizareColors.champagneGold;
        break;
      default:
        roleColor = VizareColors.spatialCyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: VisionGlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 20,
        backgroundColor: isDark
            ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
            : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: roleColor.withValues(alpha: 0.15),
                border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 1.0),
              ),
              child: Center(
                child: Text(
                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                    color: roleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          u.fullName,
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          u.role.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    u.email,
                    style: GoogleFonts.inter(
                      color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (u.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      u.phoneNumber,
                      style: GoogleFonts.inter(
                        color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Change Role Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.shield_outlined,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B), size: 20),
              color: isDark ? VizareColors.obsidianElevated : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              tooltip: 'Change user role',
              onSelected: (newRole) => _updateUserRole(u, newRole),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'homebuyer',
                  child: Text(
                    'Role: Homebuyer',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'homeowner',
                  child: Text(
                    'Role: Homeowner',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'admin',
                  child: Text(
                    'Role: Administrator',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 4: PLATFORM OVERVIEW & ANALYTICS
  // ==========================================

  Widget _buildPlatformOverviewView(bool isDark) {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: VizareColors.champagneGold),
      );
    }

    final totalUsers = _stats['total_users'] ?? _allUsers.length;
    final totalProperties = _stats['total_properties'] ?? _allProperties.length;
    final pendingMod = _stats['pending_moderation'] ?? _pendingProperties.length;
    final totalInquiries = _stats['total_inquiries'] ?? 0;
    final totalFavorites = _stats['total_favorites'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Metrics',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Users',
                  value: totalUsers.toString(),
                  icon: Icons.people_alt_rounded,
                  color: VizareColors.spatialCyan,
                  onTap: () => _onViewSelected(AdminView.users),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Listings',
                  value: totalProperties.toString(),
                  icon: Icons.home_work_rounded,
                  color: VizareColors.champagneGold,
                  onTap: () => _onViewSelected(AdminView.listings),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Pending Review',
                  value: pendingMod.toString(),
                  icon: Icons.pending_actions_rounded,
                  color: VizareColors.crimsonRed,
                  onTap: () => _onViewSelected(AdminView.moderation),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Inquiries Sent',
                  value: totalInquiries.toString(),
                  icon: Icons.mark_chat_read_rounded,
                  color: VizareColors.emeraldGreen,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            title: 'Buyer Saved Favorites',
            value: totalFavorites.toString(),
            icon: Icons.favorite_rounded,
            color: VizareColors.pastelPurple,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Operations',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          VisionGlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            backgroundColor: isDark
                ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
                : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
            child: Column(
              children: [
                _buildQuickActionTile(
                  icon: Icons.verified_user_rounded,
                  title: 'Review Pending Submissions',
                  subtitle: '$pendingMod listings waiting for review',
                  color: VizareColors.champagneGold,
                  onTap: () => _onViewSelected(AdminView.moderation),
                  isDark: isDark,
                ),
                Divider(
                  color: isDark ? VizareColors.obsidianBorder : const Color(0xFFE2E8F0),
                  height: 20,
                ),
                _buildQuickActionTile(
                  icon: Icons.group_add_rounded,
                  title: 'Manage System Users',
                  subtitle: 'Inspect user roles and permissions',
                  color: VizareColors.spatialCyan,
                  onTap: () => _onViewSelected(AdminView.users),
                  isDark: isDark,
                ),
                Divider(
                  color: isDark ? VizareColors.obsidianBorder : const Color(0xFFE2E8F0),
                  height: 20,
                ),
                _buildQuickActionTile(
                  icon: Icons.real_estate_agent_rounded,
                  title: 'Manage All Listings',
                  subtitle: 'Search and update live properties',
                  color: VizareColors.emeraldGreen,
                  onTap: () => _onViewSelected(AdminView.listings),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isDark = true,
  }) {
    return VisionGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: isDark
          ? VizareColors.obsidianSurface.withValues(alpha: 0.85)
          : Colors.white,
      border: Border.all(
        color: color.withValues(alpha: isDark ? 0.25 : 0.4),
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDark = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected,
    bool isDark,
  ) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? VizareColors.champagneGold
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? VizareColors.champagneGold
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected
                  ? VizareColors.obsidianBlack
                  : (isDark ? Colors.white : const Color(0xFF334155)),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
