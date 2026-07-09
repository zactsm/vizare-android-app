import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled/welcome_page.dart';
import 'package:untitled/pages/utils/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _logger = Logger();

  // Controllers (Start empty, fill later)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // State
  bool _isLoading = true; // New loading state
  bool _isHomebuyer = false;
  bool _isHomeowner = false;
  String _dateJoined = "...";
  File? _selectedImage;
  String? _networkImage; // To show existing profile pic URL
  bool _isSaving = false;
  bool _avatarMarkedForRemoval = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- 1. FETCH REAL USER DATA ---
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Pre-fill email from local storage immediately
    _emailController.text = email;

    try {
      final response = await ApiService.get('get_user_profile.php', {'email': email});
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // Name
          _nameController.text = data['name'] ?? '';

          // Phone (Leave blank if null)
          _phoneController.text = data['phone'] ?? '';

          // Role Checkboxes
          final userType = data['user_type'];
          _isHomebuyer = userType == 'homebuyer';
          _isHomeowner = userType == 'homeowner';

          // Profile Pic
          if (data['profile_pic'] != null && data['profile_pic'].toString().isNotEmpty) {
            _networkImage = data['profile_pic'];
          }

          // Date Joined (Format: YYYY-MM-DD HH:MM:SS)
          if (data['created_at'] != null) {
            // Simple parsing to get just the date (e.g. 2025-01-05)
            _dateJoined = data['created_at'].toString().split(' ')[0];
          }

          _isLoading = false;
        });
      } else {
        _logger.w("Failed to load profile: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _logger.e("Error fetching profile", error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      await Supabase.instance.client.auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _logger.i('User logged out successfully.');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
            (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _logger.e('Error during logout', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e')),
        );
      }
    }
  }

  Future<String?> _uploadToSupabase(File image) async =>
      ApiService.uploadAvatar(image);

  // --- LOGIC: Save Profile ---
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final previousImageUrl = _networkImage;
    String? finalImageUrl = _avatarMarkedForRemoval ? null : _networkImage;

    // 1. If user picked a NEW image, upload it first
    if (_selectedImage != null) {
      final uploadedUrl = await _uploadToSupabase(_selectedImage!);
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      } else {
        // Upload failed
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image. Please try again.")),
          );
        }
        return;
      }
    }

    // 2. Send Data to PHP
    try {
      // Using the controller text for email ensures we target the right user
      // (Assumes email is read-only or matches the logged-in user)
      final response = await ApiService.post(
        'update_profile.php',
        body: {
          'email': _emailController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'profile_pic': finalImageUrl ?? '', // Send empty string if null
        },
      );

      if (response.statusCode == 200) {
        _logger.i("Profile Updated: ${response.body}");
        if (previousImageUrl != null &&
            previousImageUrl.isNotEmpty &&
            previousImageUrl != finalImageUrl) {
          await ApiService.deleteAvatarByUrl(previousImageUrl);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Return to previous screen
        }
      } else {
        _logger.w("Server Error: ${response.body}");
        throw Exception("Failed to save profile");
      }
    } catch (e) {
      _logger.e("Save Error", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred. Check connection.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- LOGIC: Pick Image ---
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      final selectedPath = result?.files.single.path;
      if (!mounted || selectedPath == null) {
        return;
      }

      if (result != null) {
        setState(() {
          _selectedImage = File(selectedPath);
          _avatarMarkedForRemoval = false;
        });
      }
    } catch (e) {
      _logger.e("Error picking image", error: e);
    }
  }

  // --- LOGIC: Delete Image ---
  void _deleteImage() {
    setState(() {
      _selectedImage = null;
      _avatarMarkedForRemoval = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // LOGOUT button (only shows if user is homeowner)
        actions: [
          if (_isHomeowner)
            IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildGradientTitle("Profile"),
            const SizedBox(height: 30),

            // 2. Profile Picture Logic
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: _getImageProvider() != null
                  ? DecorationImage(
                      image: _getImageProvider()!,
                      fit: BoxFit.cover,
                    )
                    : null,
              ),
              child: (_getImageProvider() == null)
                  ? const Icon(Icons.person, size: 80, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 24),

            // 3. Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Upload",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _deleteImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3D00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. Fields (Now populated)
            _buildCustomTextField(
              label: "Full name",
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            _buildCustomTextField(
              label: "Email address",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // Typically we don't allow changing email easily
            ),
            const SizedBox(height: 16),
            _buildCustomTextField(
              label: "Phone number",
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              hint: "Enter phone number",
            ),
            const SizedBox(height: 20),

            // 5. Checkboxes (Role - Read Only usually, or changeable?)
            // Assuming user can't change role easily, but let's keep them disabled or just visual
            _buildCheckboxRow("Homebuyer", _isHomebuyer, null), // null callback disables it
            _buildCheckboxRow("Homeowner", _isHomeowner, null),
            const SizedBox(height: 20),

            // 6. Date Joined
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date Joined",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: (0.6)),
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateJoined,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 7. Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Discard",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E17EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                      "Save",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper to decide which image to show
  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (!_avatarMarkedForRemoval && _networkImage != null) {
      return NetworkImage(_networkImage!);
    }
    return null; // Will show fallback icon
  }

  Widget _buildGradientTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF5A62F1), Color(0xFF548FEE), Color(0xFF9FD0F6), Color(0xFFD6B3F9), Color(0xFFB191FA)],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(fontSize: 32, fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[300] : Colors.white, // Dim if read-only
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Inter')),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
              contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?>? onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged, // If null, it's disabled (read-only)
            checkColor: Colors.black,
            activeColor: Colors.grey[400],
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (!states.contains(WidgetState.selected)) return Colors.transparent;
              return Colors.grey[400];
            }),
            side: const BorderSide(color: Colors.grey, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16, fontFamily: 'Inter')),
      ],
    );
  }
}
