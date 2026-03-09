import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http; // Import http
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _logger = Logger();
  // Add controller for the new field
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State for password visibility
  bool _isCurrentPasswordVisible = false; // Add state for new field
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // State for validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _currentPasswordController.dispose(); // Dispose new controller
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _validatePassword() {
    // ... (this function is unchanged)
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSymbol = password.contains(RegExp(r'[!@#^&*(),.?":{}|<>]'));
    });
  }

  // save function
  Future<void> _savePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // --- Start Client-Side Validation ---
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isPasswordValid = _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSymbol;

    if (!isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure your new password meets all requirements.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // --- End Client-Side Validation ---

    // --- HTTP Logic to talk to PHP ---
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (email == null) {
        _logger.e('User email not found in SharedPreferences.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User session not found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      const url = 'http://formidable-fort-475806-q1.et.r.appspot.com/change_password.php';
      final response = await http.post(
        Uri.parse(url),
        body: {
          'email': email,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (!mounted) return;


      // Decode the JSON response from PHP
      final responseData = jsonDecode(response.body);
      final message = responseData['message'] ?? 'Unknown error';

      if (response.statusCode == 200) {
        // Success
        _logger.i('Password changed successfully: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Handle server-side errors (e.g., "Incorrect current password")
        _logger.w('Failed to change password: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $message'), // Show the specific error from PHP
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error changing password', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        // ... (app bar code is unchanged) ...
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (title text is unchanged) ...
              const SizedBox(height: 16),
              const Text(
                'Change password',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // "Current Password" field
              _buildTextFieldLabel('Current Password'),
              _buildPasswordField(
                controller: _currentPasswordController,
                isVisible: _isCurrentPasswordVisible,
                hintText: 'Enter your current password', // Custom hint
                onToggleVisibility: () {
                  setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible);
                },
              ),
              const SizedBox(height: 24),

              // --- Password Field ---
              _buildTextFieldLabel('New Password'),
              _buildPasswordField(
                controller: _passwordController,
                isVisible: _isPasswordVisible,
                hintText: 'Enter new password', // Custom hint
                onToggleVisibility: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              const SizedBox(height: 24),

              // --- Confirm Password Field ---
              _buildTextFieldLabel('Confirm new password'),
              _buildPasswordField(
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                hintText: 'Confirm new password', // Custom hint
                onToggleVisibility: () {
                  setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                },
              ),
              const SizedBox(height: 24),

              // --- Validation Checklist ---
              // ... (validation checklist is unchanged) ...
              _ValidationChecklistItem(
                label: 'Minimum 8 characters',
                isValid: _hasMinLength,
              ),
              _ValidationChecklistItem(
                label: 'At least one uppercase letter',
                isValid: _hasUppercase,
              ),
              _ValidationChecklistItem(
                label: 'At least one lowercase letter',
                isValid: _hasLowercase,
              ),
              _ValidationChecklistItem(
                label: 'At least one numeral (0-9)',
                isValid: _hasNumber,
              ),
              _ValidationChecklistItem(
                label: 'At least one symbol (!@#^...?)',
                isValid: _hasSymbol,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(26.0, 16.0, 26.0, 26.0),
        child: ElevatedButton(
          onPressed: _savePassword, // calls the async function
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5E17EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String hintText = '************', // Added hintText parameter
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hintText, // Use the parameter
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}


class _ValidationChecklistItem extends StatelessWidget {
  final String label;
  final bool isValid;

  const _ValidationChecklistItem({
    required this.label,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.check_circle_outline,
            color: isValid ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isValid ? Colors.white : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}