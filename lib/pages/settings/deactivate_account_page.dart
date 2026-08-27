import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/welcome_page.dart';
import '../utils/google_auth_service.dart';

class DeactivateAccountPage extends StatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  final _logger = Logger();
  final _otherReasonController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordStep = false;
  String? _selectedReason;
  bool _isPasswordVisible = false;
  bool _isDeactivating = false;
  bool _isPermanentDeletion = false;

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

  void _handleReasonSelection(String reason) {
    setState(() {
      _reasons.updateAll((key, value) => false);
      _reasons[reason] = true;
      _selectedReason = reason;
    });
  }

  void _handlePrimaryDeactivation() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a reason for deactivation.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }
    setState(() {
      _isPasswordStep = true;
    });
  }

  Future<void> _handleFinalDeactivation() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your password to confirm.',
              style: GoogleFonts.inter()),
          backgroundColor: VizareColors.crimsonRed,
        ),
      );
      return;
    }

    setState(() => _isDeactivating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');

      if (!mounted) return;
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: User session not found. Please log in again.',
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
        return;
      }

      final endpoint = _isPermanentDeletion ? 'delete_account.php' : 'deactivate_account.php';
      final response = await ApiService.post(
        endpoint,
        body: {'email': email, 'password': password},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await prefs.clear();
        try {
          await GoogleAuthService.signOut();
        } catch (_) {}
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
        await AppThemeController.instance.resetToDefaultDark();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPermanentDeletion
                  ? 'Account and personal data permanently erased.'
                  : 'Account deactivated successfully.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: VizareColors.emeraldGreen,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operation failed. Check your password.',
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during deactivation', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Check your connection.',
                style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeactivating = false);
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
          appBar: VizareAppBar(
            title: 'Deactivate Account',
            onBackPressed: () {
              if (_isPasswordStep) {
                setState(() => _isPasswordStep = false);
              } else {
                Navigator.pop(context);
              }
            },
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
                      _isPermanentDeletion
                          ? 'Under GDPR Art. 17 / CCPA, your account, authentication tokens, profile data, and media files will be permanently erased.'
                          : 'Deactivating will archive your profile, spatial favorites, and listing views. You can reactivate anytime by logging in.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark
                            ? VizareColors.textSecondary
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (!_isPasswordStep) ...[
                    VisionGlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPermanentDeletion = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isPermanentDeletion ? VizareColors.champagneGold.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_isPermanentDeletion ? VizareColors.champagneGold.withValues(alpha: 0.5) : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  'Temporary',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: !_isPermanentDeletion
                                        ? VizareColors.champagneGold
                                        : (isDark ? VizareColors.textSecondary : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPermanentDeletion = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isPermanentDeletion ? VizareColors.crimsonRed.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isPermanentDeletion ? VizareColors.crimsonRed.withValues(alpha: 0.5) : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  'Permanent Erasure',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isPermanentDeletion
                                        ? Colors.redAccent
                                        : (isDark ? VizareColors.textSecondary : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Reason for Deactivation:',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                  _isPasswordStep ? _buildPasswordView(isDark) : _buildReasonsView(isDark),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isDeactivating
                          ? null
                          : (_isPasswordStep
                              ? _handleFinalDeactivation
                              : _handlePrimaryDeactivation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VizareColors.crimsonRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: _isDeactivating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isPasswordStep
                                  ? 'Confirm Deactivation'
                                  : 'Deactivate',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildReasonsView(bool isDark) {
    return VisionGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._reasons.keys.map((reason) {
            final isSelected = _reasons[reason] == true;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleReasonSelection(reason),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VizareColors.champagneGold.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? VizareColors.champagneGold.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? VizareColors.champagneGold
                              : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? VizareColors.textSecondary : const Color(0xFF475569)),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (_reasons['Other'] == true) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? VizareColors.obsidianSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: TextField(
                controller: _otherReasonController,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.5,
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us why...',
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordView(bool isDark) {
    return VisionGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm with Password',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please enter your account password to confirm deactivation.',
            style: GoogleFonts.inter(
              color: isDark ? VizareColors.textSecondary : const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: isDark ? VizareColors.obsidianSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
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
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(
                        () => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
                hintText: '••••••••••••',
                hintStyle: GoogleFonts.inter(
                  color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
