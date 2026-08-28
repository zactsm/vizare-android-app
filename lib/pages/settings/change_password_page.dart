import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _logger = Logger();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSaving = false;

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
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _savePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
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
        SnackBar(
          content: Text('New password does not meet security criteria.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New passwords do not match.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiService.post(
        'change_password.php',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: VizareColors.emeraldGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password. Check current password.',
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } catch (e) {
      _logger.e("Error changing password", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e', style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          appBar: const VizareAppBar(
            title: 'Security',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                    child: Text(
                      'Ensure your account is protected with a strong, distinct passphrase.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark
                            ? VizareColors.textSecondary
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ),
                  VisionGlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Current Password'),
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          isVisible: _isCurrentPasswordVisible,
                          hintText: 'Enter current password',
                          onToggleVisibility: () {
                            setState(() => _isCurrentPasswordVisible =
                                !_isCurrentPasswordVisible);
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('New Password'),
                        _buildPasswordField(
                          controller: _passwordController,
                          isVisible: _isPasswordVisible,
                          hintText: 'Enter new password',
                          onToggleVisibility: () {
                            setState(
                                () => _isPasswordVisible = !_isPasswordVisible);
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Confirm new password'),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          isVisible: _isConfirmPasswordVisible,
                          hintText: 'Confirm new password',
                          onToggleVisibility: () {
                            setState(() => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible);
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  VisionGlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ValidationChecklistItem(
                          label: 'Minimum 8 characters',
                          isValid: _hasMinLength,
                          isDark: isDark,
                        ),
                        _ValidationChecklistItem(
                          label: 'At least one uppercase letter (A-Z)',
                          isValid: _hasUppercase,
                          isDark: isDark,
                        ),
                        _ValidationChecklistItem(
                          label: 'At least one lowercase letter (a-z)',
                          isValid: _hasLowercase,
                          isDark: isDark,
                        ),
                        _ValidationChecklistItem(
                          label: 'At least one numeral (0-9)',
                          isValid: _hasNumber,
                          isDark: isDark,
                        ),
                        _ValidationChecklistItem(
                          label: 'At least one special symbol (!@#\$%...)',
                          isValid: _hasSymbol,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VizareColors.champagneGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: VizareColors.champagneGold,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String hintText = '••••••••••••',
    bool isDark = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? VizareColors.obsidianSurface : Colors.white,
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
        obscureText: !isVisible,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: VizareColors.champagneGold,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: onToggleVisibility,
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

class _ValidationChecklistItem extends StatelessWidget {
  final String label;
  final bool isValid;
  final bool isDark;

  const _ValidationChecklistItem({
    required this.label,
    required this.isValid,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isValid
                ? VizareColors.emeraldGreen
                : (isDark ? Colors.white24 : const Color(0xFF94A3B8)),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isValid
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? VizareColors.textMuted : const Color(0xFF64748B)),
              fontSize: 12.5,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
