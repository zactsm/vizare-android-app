import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _logger = Logger();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: VizareColors.obsidianSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              color: VizareColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.inter(
                  color: VizareColors.champagneGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetSentDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: VizareColors.obsidianSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VizareColors.champagneGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: VizareColors.champagneGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Reset Link Sent",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We have sent a password reset link to:",
                style: GoogleFonts.inter(
                  color: VizareColors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: VizareColors.champagneGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  email,
                  style: GoogleFonts.inter(
                    color: VizareColors.champagneGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Please check your inbox (and spam folder) for the link to set your new password.",
                style: GoogleFonts.inter(
                  color: VizareColors.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss dialog
                Navigator.pop(context); // Go back to login
              },
              child: Text(
                "Back to Login",
                style: GoogleFonts.inter(
                  color: VizareColors.champagneGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog("Email Required", "Please enter your registered email address.");
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog("Invalid Email", "Please enter a valid email address.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        'forgot_password.php',
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'email': email},
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showResetSentDialog(email);
      } else {
        var message = "Could not send reset link. Please try again.";
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
            message = data['message'].toString();
          }
        } catch (_) {}
        _showErrorDialog("Request Failed", message);
      }
    } on TimeoutException {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog("Connection Timeout", "Server took too long to respond. Please try again.");
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _logger.e("Forgot password request failed", error: e);
      _showErrorDialog("Connection Error", "Could not connect to the server. Please check your network.");
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 52,
                      height: 52,
                      color: isDark ? null : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Forgot Password",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter the email associated with your account and we will send you a link to reset your password.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? VizareColors.textSecondary
                          : const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  VisionGlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    borderRadius: 28,
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
                        Text(
                          'EMAIL ADDRESS',
                          style: GoogleFonts.inter(
                            color: VizareColors.champagneGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14.5,
                          ),
                          cursorColor: VizareColors.champagneGold,
                          decoration: InputDecoration(
                            hintText: 'yourname@luxury.com',
                            hintStyle: GoogleFonts.inter(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : const Color(0xFF94A3B8),
                              fontSize: 14.5,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: VizareColors.champagneGold,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: VizareColors.champagneGold,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  LuxuryGradientButton(
                    text: "Send Reset Link",
                    icon: Icons.send_rounded,
                    isLoading: _isLoading,
                    onPressed: _sendResetLink,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Remember your password? Sign In",
                        style: GoogleFonts.inter(
                          color: isDark
                              ? VizareColors.textSecondary
                              : const Color(0xFF64748B),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
