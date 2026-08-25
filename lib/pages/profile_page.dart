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
import 'package:untitled/pages/utils/premium_background.dart';
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
    final userEmail = prefs.getString('user_email');
    final userType = prefs.getString('user_type');

    if (userEmail == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService.post(
        'get_profile.php',
        body: {'email': userEmail},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _nameController.text = data['full_name'] ?? '';
            _emailController.text = data['email'] ?? userEmail;
            _phoneController.text = data['phone'] ?? '';
            _networkImage = data['profile_pic'];
            _dateJoined = data['created_at'] != null
                ? data['created_at'].toString().split('T').first
                : 'Unknown';
            _isHomeowner = (data['role'] == 'homeowner') || (userType == 'homeowner');
            _isHomebuyer = (data['role'] == 'homebuyer') || (userType == 'homebuyer');
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
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: VisionGlassPill(
              padding: const EdgeInsets.all(8),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          actions: [
            if (_isHomeowner)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: VizareColors.crimsonRed,
                    size: 22,
                  ),
                ),
              ),
          ],
          title: Text(
            'Member Identity',
            style: GoogleFonts.poppins(
              color: Colors.white,
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
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your verified architectural credentials and contact settings.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: VizareColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Profile Avatar with Luxury Specular Ring
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: VizareColors.obsidianSurface,
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
                                    color: Colors.white24,
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
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Email Address (Verified)'),
                            _buildInput(
                              controller: _emailController,
                              hintText: 'name@domain.com',
                              icon: Icons.alternate_email_rounded,
                              readOnly: true,
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Phone Number'),
                            _buildInput(
                              controller: _phoneController,
                              hintText: '+60 12-345 6789',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 18),
                            _buildLabel('Account Role'),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: VizareColors.obsidianSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
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
                                      color: Colors.white70,
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
                                color: VizareColors.textMuted,
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
                      const SizedBox(height: 32),
                    ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly
            ? Colors.white.withValues(alpha: 0.03)
            : VizareColors.obsidianSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: readOnly ? Colors.white54 : Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: readOnly
                ? Colors.white24
                : VizareColors.champagneGold.withValues(alpha: 0.7),
            size: 20,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: VizareColors.textMuted,
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
