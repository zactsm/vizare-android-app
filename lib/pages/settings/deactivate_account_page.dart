import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

import '/welcome_page.dart';

class DeactivateAccountPage extends StatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  final _logger = Logger();
  final _otherReasonController = TextEditingController();
  final _passwordController = TextEditingController();

  // State Management
  bool _isPasswordStep = false; // Toggles between the two views
  String? _selectedReason;
  bool _isPasswordVisible = false;

  final Map<String, bool> _reasons = {
    'I found a property': false,
    'I\'m taking a break': false,
    'I had a bad experience': false,
    'I\'m concerned about privacy': false,
    'Other': false,
  };

  @override
  void dispose() {
    _otherReasonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _handleReasonSelection(String reason) {
    setState(() {
      // Unselect all reasons
      _reasons.updateAll((key, value) => false);
      // Select the new reason
      _reasons[reason] = true;
      _selectedReason = reason;
    });
  }

  void _handlePrimaryDeactivation() {
    if (_selectedReason == null) {
      // Optional: Show a snackbar if no reason is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for deactivation.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _logger.i('Deactivation reason: $_selectedReason');
    if (_selectedReason == 'Other') {
      _logger.d('Other reason details: ${_otherReasonController.text}');
    }

    // Move to the password confirmation step
    setState(() {
      _isPasswordStep = true;
    });
  }


  Future<void> _handleFinalDeactivation() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password to confirm.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 1. Get user email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (!context.mounted) return;
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User session not found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Call the PHP script
      // (This script now performs a DELETE as we discussed)
      final response = await ApiService.post(
        'deactivate_account.php',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (!context.mounted) return;

      final responseData = jsonDecode(response.body);
      final message = responseData['message'] ?? 'Unknown error';

      if (response.statusCode == 200) {
        // 3. Deletion Successful: Log the user out completely
        _logger.i('Account deleted successfully.');

        // Sign out from Firebase & Google (if they were used)
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();

        // Clear saved email
        await prefs.remove('user_email');

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        // 4. Deletion Failed (e.g., wrong password)
        _logger.w('Deletion failed: $message');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error during deactivation', error: e);
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
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // If on password step, go back to reasons. Otherwise, pop the page.
            if (_isPasswordStep) {
              setState(() {
                _isPasswordStep = false;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isPasswordStep
                ? _buildPasswordView()
                : _buildReasonsView(),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        // Copied from contact_support_page for consistent positioning
        padding: const EdgeInsets.fromLTRB(26.0, 16.0, 26.0, 26.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // The button's action changes based on the current step
            onPressed: _isPasswordStep
                ? _handleFinalDeactivation
                : _handlePrimaryDeactivation,
            style: ElevatedButton.styleFrom(
              // Red gradient from the design
              backgroundColor: Colors.transparent, // Required for gradient
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              minimumSize: const Size(200, 60), // Matched size
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.zero, // Remove padding to allow gradient to fill
            ).copyWith(
              elevation: WidgetStateProperty.all(0),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                height: 60, // Constrain the button height
                alignment: Alignment.center,
                child: const Text(
                  'Deactivate',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Widgets for each step ---

  Widget _buildReasonsView() {
    return Column(
      key: const ValueKey('reasonsView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Deactivate account',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Deactivating your account will hide your profile and listings. You will no longer receive messages or notifications. You can reactivate your account by logging in again.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Reason for Deactivation:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        ..._reasons.keys.map((reason) {
          return CheckboxListTile(
            title: Text(reason,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
            value: _reasons[reason],
            onChanged: (bool? value) => _handleReasonSelection(reason),
            activeColor: Colors.white,
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
        if (_reasons['Other'] == true)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: TextField(
              controller: _otherReasonController,
              style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us why...',
                hintStyle:
                TextStyle(color: Colors.grey[600], fontFamily: 'Inter'),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordView() {
    return Column(
      key: const ValueKey('passwordView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Deactivate account',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Deactivating your account will hide your profile and listings. You will no longer receive messages or notifications. You can reactivate your account by logging in again.',
          style: TextStyle(
            fontFamily:'Poppins',
            fontSize: 14,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enter your password to confirm:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: '************',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}