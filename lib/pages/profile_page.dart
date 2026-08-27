import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _logger = Logger();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isHomeowner = false;
  bool _isHomebuyer = false;
  String _dateJoined = '';
  String? _networkImage;
  PlatformFile? _selectedImage;
  bool _avatarMarkedForRemoval = false;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('user_email');
    final userType = prefs.getString('user_type');

    if (userType != null && mounted) {
      final roleLower = userType.toLowerCase();
      _isHomeowner = roleLower == 'homeowner';
      _isHomebuyer = roleLower == 'homebuyer';
    }

    if (userEmail == null || userEmail.isEmpty) {
      try {
        userEmail = Supabase.instance.client.auth.currentUser?.email;
      } catch (_) {}
    }

    if (userEmail == null || userEmail.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService.get(
        'get_user_profile.php',
        {'email': userEmail},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _nameController.text = data['full_name'] ?? data['name'] ?? '';
            _emailController.text = data['email'] ?? userEmail!;
            _phoneController.text = data['phone'] ?? '';
            _networkImage = data['profile_pic'];
            if (data['created_at'] != null && data['created_at'].toString().isNotEmpty) {
              _dateJoined = data['created_at'].toString().split('T').first;
            } else {
              _dateJoined = 'Member';
            }
            final fetchedRole = (data['role'] ?? data['user_type'] ?? userType ?? '').toString().toLowerCase();
            _isHomeowner = fetchedRole == 'homeowner';
            _isHomebuyer = fetchedRole == 'homebuyer';
          });
        }
      }
    } catch (e) {
      _logger.e("Error fetching profile", error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImage = result.files.first;
          _avatarMarkedForRemoval = false;
        });
      }
    } catch (e) {
      _logger.e("Error picking image", error: e);
    }
  }

  void _deleteImage() {
    setState(() {
      _selectedImage = null;
      _avatarMarkedForRemoval = true;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await GoogleAuthService.signOut();
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    await AppThemeController.instance.resetToDefaultDark();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name cannot be empty.', style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _networkImage;

      if (_selectedImage != null) {
        final uploaded = await ApiService.uploadAvatar(_selectedImage!);
        if (uploaded != null) avatarUrl = uploaded;
      } else if (_avatarMarkedForRemoval) {
        avatarUrl = null;
      }

      final response = await ApiService.post(
        'update_profile.php',
        body: {
          'email': _emailController.text.trim(),
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'profile_pic': avatarUrl ?? '',
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: VizareColors.emeraldGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile.', style: GoogleFonts.inter()),
              backgroundColor: VizareColors.crimsonRed,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e("Error updating profile", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e', style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      final selected = _selectedImage!;
      return selected.bytes != null
          ? MemoryImage(selected.bytes!)
          : FileImage(File(selected.path!));
    } else if (!_avatarMarkedForRemoval &&
        _networkImage != null &&
        _networkImage!.isNotEmpty) {
      return NetworkImage(_networkImage!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: VisionGlassCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconColor: isDark ? Colors.white : const Color(0xFF0F172A),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: null,
            title: Text(
              'Member Identity',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: VizareColors.champagneGold,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!_isHomeowner) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile & Identity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage your verified architectural credentials and contact settings.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? VizareColors.textSecondary
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ] else ...[
                          const SizedBox(height: 8),
                        ],
                        // Profile Avatar with Luxury Specular Ring
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? VizareColors.obsidianSurface
                                    : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: VizareColors.champagneGold,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: VizareColors.champagneGold
                                        .withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                                image: _getImageProvider() != null
                                    ? DecorationImage(
                                        image: _getImageProvider()!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _getImageProvider() == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 64,
                                      color: VizareColors.champagneGold,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: VizareColors.goldGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: VizareColors.champagneGold
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_getImageProvider() != null)
                          GestureDetector(
                            onTap: _deleteImage,
                            child: Text(
                              'Remove Avatar',
                              style: GoogleFonts.inter(
                                color: VizareColors.crimsonRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 28),
                        // Form Fields
                        VisionGlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Full Name'),
                              _buildInput(
                                controller: _nameController,
                                hintText: 'Your legal or display name',
                                icon: Icons.badge_outlined,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Email Address (Verified)'),
                              _buildInput(
                                controller: _emailController,
                                hintText: 'name@domain.com',
                                icon: Icons.alternate_email_rounded,
                                readOnly: true,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Phone Number'),
                              _buildInput(
                                controller: _phoneController,
                                hintText: '+60 12-345 6789',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Account Role'),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? VizareColors.obsidianSurface
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_rounded,
                                      color: VizareColors.champagneGold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isHomeowner
                                          ? 'Verified Homeowner / Architect'
                                          : (_isHomebuyer
                                              ? 'Curated Homebuyer'
                                              : 'Administrator'),
                                      style: GoogleFonts.inter(
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF334155),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_dateJoined.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Member since $_dateJoined',
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? VizareColors.textMuted
                                      : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        LuxuryGradientButton(
                          text: 'Save Changes',
                          icon: Icons.check_circle_rounded,
                          isLoading: _isSaving,
                          onPressed: _saveProfile,
                        ),
                        const SizedBox(height: 14),
                        VisionGlassPill(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          borderColor: VizareColors.crimsonRed.withValues(alpha: 0.4),
                          onTap: _logout,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: VizareColors.crimsonRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Log Out',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: VizareColors.crimsonRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: VizareColors.champagneGold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    bool isDark = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly
            ? (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF1F5F9))
            : (isDark ? VizareColors.obsidianSurface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: readOnly
              ? (isDark ? Colors.white54 : const Color(0xFF64748B))
              : (isDark ? Colors.white : const Color(0xFF0F172A)),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: readOnly
                ? (isDark ? Colors.white24 : const Color(0xFF94A3B8))
                : VizareColors.champagneGold.withValues(alpha: 0.7),
            size: 20,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
