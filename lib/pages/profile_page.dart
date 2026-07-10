import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/welcome_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _logger = Logger();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isHomebuyer = false;
  bool _isHomeowner = false;
  String _dateJoined = "...";
  PlatformFile? _selectedImage;
  String? _networkImage;
  bool _isSaving = false;
  bool _avatarMarkedForRemoval = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- FETCH USER DATA ---
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');

    if (email == null) {
      setState(() => _isLoading = false);
      return;
    }

    _emailController.text = email;

    try {
      final response = await ApiService.get('get_user_profile.php', {'email': email});
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';

          final userType = data['user_type'];
          _isHomebuyer = userType == 'homebuyer';
          _isHomeowner = userType == 'homeowner';

          if (data['profile_pic'] != null && data['profile_pic'].toString().isNotEmpty) {
            _networkImage = data['profile_pic'];
          }

          if (data['created_at'] != null) {
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
      await Supabase.instance.client.auth.signOut(
        scope: SignOutScope.local,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      try {
        await GoogleAuthService.signOut();
      } catch (error) {
        _logger.d('Google session was not active during logout: $error');
      }
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

  Future<String?> _uploadToSupabase(PlatformFile image) async =>
      ApiService.uploadAvatar(image);

  // --- Save Profile ---
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final previousImageUrl = _networkImage;
    String? finalImageUrl = _avatarMarkedForRemoval ? null : _networkImage;

    if (_selectedImage != null) {
      final uploadedUrl = await _uploadToSupabase(_selectedImage!);
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      } else {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image. Please try again.")),
          );
        }
        return;
      }
    }

    try {
      final response = await ApiService.post(
        'update_profile.php',
        body: {
          'email': _emailController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
          'profile_pic': finalImageUrl ?? '',
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
          Navigator.pop(context);
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

  // --- Pick Image ---
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final selectedFile = result?.files.single;
      if (!mounted || selectedFile == null) {
        return;
      }

      setState(() {
        _selectedImage = selectedFile;
        _avatarMarkedForRemoval = false;
      });
    } catch (e) {
      _logger.e("Error picking image", error: e);
    }
  }

  // --- Delete Image ---
  void _deleteImage() {
    setState(() {
      _selectedImage = null;
      _avatarMarkedForRemoval = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pitch Black background
      body: AbstractBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Custom top section instead of standard AppBar (Back Navigation & Destructive action)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (_isHomeowner)
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: pastelPurple))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Expressive typographic header
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PROFILE',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: pastelPurple,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your profile',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900, // Extra bold title
                                      letterSpacing: -1.0,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Profile Avatar
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF121214),
                                border: Border.all(color: pastelPurple, width: 2.0),
                                image: _getImageProvider() != null
                                    ? DecorationImage(
                                        image: _getImageProvider()!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (_getImageProvider() == null)
                                  ? const Icon(Icons.person_rounded, size: 80, color: Colors.white24)
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Photo Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: _pickImage,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: pastelPurple,
                                    side: const BorderSide(color: pastelPurple, width: 1.5),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    "Upload Photo",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: _deleteImage,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF3D00),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Form Fields (Chunky Wise App inputs)
                            _buildCustomTextField(
                              label: "Full Name",
                              controller: _nameController,
                              pastelPurple: pastelPurple,
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              label: "Email Address",
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              pastelPurple: pastelPurple,
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              label: "Phone Number",
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              hint: "Enter phone number",
                              pastelPurple: pastelPurple,
                            ),
                            const SizedBox(height: 24),

                            // Read-only Roles (Chunky checkboxes)
                            _buildCheckboxRow("Homebuyer Dashboard Active", _isHomebuyer, pastelPurple),
                            const SizedBox(height: 8),
                            _buildCheckboxRow("Homeowner Dashboard Active", _isHomeowner, pastelPurple),
                            const SizedBox(height: 28),

                            // Date Joined Info Container (Chunky Block)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121214), // Solid dark grey card block
                                border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Date Joined",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _dateJoined,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Discard & Save Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white30, width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      "Discard",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: pastelPurple,
                                      foregroundColor: const Color(0xFF000000),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Color(0xFF000000), strokeWidth: 2),
                                          )
                                        : const Text(
                                            "Save Profile",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to decide which image to show
  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      final selected = _selectedImage!;
      return selected.bytes != null
          ? MemoryImage(selected.bytes!)
          : FileImage(File(selected.path!));
    } else if (!_avatarMarkedForRemoval && _networkImage != null) {
      return NetworkImage(_networkImage!);
    }
    return null;
  }

  // Chunky solid inputs with Poppins font
  Widget _buildCustomTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hint,
    required Color pastelPurple,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFF09090A) : const Color(0xFF121214), // Solid blocks
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: readOnly ? const Color(0xFF1E1E22) : const Color(0xFF1E1E22),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              color: readOnly ? Colors.white38 : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontWeight: FontWeight.normal),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  // Custom checkbox row
  Widget _buildCheckboxRow(String label, bool value, Color pastelPurple) {
    return Row(
      children: [
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Colors.white24,
          ),
          child: Checkbox(
            value: value,
            onChanged: null, // Disabled / visual representation of active role
            checkColor: Colors.black,
            activeColor: pastelPurple,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (value) return pastelPurple;
              return const Color(0xFF121214);
            }),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
