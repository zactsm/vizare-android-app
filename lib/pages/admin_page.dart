import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _logger = Logger();
  List<Property> _pendingProperties = [];
  bool _isLoading = true;

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
    _verifyAdminRole();
    _fetchPendingProperties();
  }

  Future<void> _verifyAdminRole() async {
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
    }
  }

  Future<void> _fetchPendingProperties() async {
    try {
      final response = await ApiService.get('get_pending_properties.php');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pendingProperties =
              data.map((json) => Property.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e("Error fetching pending", error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int propertyId, String newStatus) async {
    setState(() {
      _pendingProperties.removeWhere((p) => p.id == propertyId);
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
            'Property listing $newStatus',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: newStatus == 'approved'
              ? VizareColors.emeraldGreen
              : VizareColors.crimsonRed,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VizareColors.obsidianBlack,
      body: AbstractBackground(
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Admin Terminal Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moderation Queue',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                    VisionGlassPill(
                      padding: const EdgeInsets.all(10),
                      onTap: () async {
                        try {
                          await Supabase.instance.client.auth.signOut(
                            scope: SignOutScope.local,
                          );
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.clear();
                          try {
                            await GoogleAuthService.signOut();
                          } catch (_) {}
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Review submitted 3D property listings before publishing.',
                  style: GoogleFonts.inter(
                    color: VizareColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                // Review Queue List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: VizareColors.champagneGold),
                        )
                      : _pendingProperties.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: _pendingProperties.length,
                              itemBuilder: (context, index) {
                                return _buildAdminCard(
                                    _pendingProperties[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "All submitted property listings have been reviewed.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: VizareColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(Property property) {
    final bool hasModel = property.modelPath.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: VisionGlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 22,
        backgroundColor: VizareColors.obsidianSurface.withValues(alpha: 0.85),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
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
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.broken_image, color: Colors.white24),
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
                          color: Colors.white,
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
                          color: VizareColors.textSecondary,
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
            // Approve / Reject Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded,
                        size: 18, color: Colors.white),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () =>
                        _updateStatus(property.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VizareColors.emeraldGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                        _updateStatus(property.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: VizareColors.crimsonRed, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
