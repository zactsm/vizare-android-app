import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _logger = Logger();

  bool _isHomeBuyer = true;
  bool _agreedToPolicy = false;
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VizareColors.obsidianElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: VizareColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                color: VizareColors.champagneGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await GoogleAuthService.signIn(
        requestedRole: _isHomeBuyer ? 'homebuyer' : 'homeowner',
      );
      if (result == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }
      final userType = result.userType;

      if (userType == 'homeowner') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/homeowner', (Route<dynamic> route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/homebuyer', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _logger.e("Google Sign-In failed", error: e);
      _showErrorDialog("Authentication Error", "Google Sign-In failed. Please try again.");
    }
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final bool isHomeBuyer = _isHomeBuyer;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorDialog("Required Fields", "Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog("Password Mismatch", "Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        'create_account.php',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'isHomeBuyer': isHomeBuyer.toString(),
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _logger.i('Account created: ${response.body}');

        final responseData = jsonDecode(response.body);
        if (responseData['requires_email_confirmation'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        await ApiService.restoreSession(
          responseData['access_token'] as String?,
          responseData['refresh_token'] as String?,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString(
            'user_type', isHomeBuyer ? 'homebuyer' : 'homeowner');
        await prefs.setBool('has_password', true);

        if (!mounted) return;

        if (isHomeBuyer) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/homebuyer', (Route<dynamic> route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, '/homeowner', (Route<dynamic> route) => false);
        }
      } else {
        var message = 'Failed to create account. Please try again.';
        try {
          final responseData = jsonDecode(response.body);
          message = responseData['message'] as String? ?? message;
        } catch (_) {
          if (response.statusCode == 503) {
            message =
                'Registration service is temporarily unavailable. Please try again later.';
          }
        }
        _showErrorDialog("Registration Failed", message);
      }
    } on TimeoutException {
      _logger.e("🚨 Create account request timed out");
      _showErrorDialog("Connection Timeout", "The server took too long to respond. Please check your connection and try again.");
    } catch (e) {
      _logger.e('Error occurred while creating account', error: e);
      _showErrorDialog("Connection Error", "An error occurred. Check your connection.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/logo.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (c, e, s) =>
                      const SizedBox(width: 48, height: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'Join Vizare',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore and showcase luxury properties in interactive 3D.',
                  style: GoogleFonts.inter(
                    color: VizareColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Container
                VisionGlassContainer(
                  padding: const EdgeInsets.all(22.0),
                  borderRadius: 24,
                  backgroundColor:
                      VizareColors.obsidianSurface.withValues(alpha: 0.85),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FULL NAME',
                        style: GoogleFonts.inter(
                          color: VizareColors.champagneGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 14.5),
                        decoration: const InputDecoration(
                          hintText: 'Sarah Jenkins',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
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
                            color: Colors.white, fontSize: 14.5),
                        decoration: const InputDecoration(
                          hintText: 'yourname@luxury.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'PASSWORD',
                        style: GoogleFonts.inter(
                          color: VizareColors.champagneGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white60,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'CONFIRM PASSWORD',
                        style: GoogleFonts.inter(
                          color: VizareColors.champagneGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white60,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Account Role Selection
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isHomeBuyer = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isHomeBuyer
                                      ? VizareColors.champagneGold
                                          .withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isHomeBuyer
                                        ? VizareColors.champagneGold
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.explore_rounded,
                                      size: 16,
                                      color: _isHomeBuyer
                                          ? VizareColors.champagneGold
                                          : VizareColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Homebuyer',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isHomeBuyer
                                            ? Colors.white
                                            : VizareColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isHomeBuyer = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isHomeBuyer
                                      ? VizareColors.champagneGold
                                      .withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: !_isHomeBuyer
                                        ? VizareColors.champagneGold
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.home_work_rounded,
                                      size: 16,
                                      color: !_isHomeBuyer
                                          ? VizareColors.champagneGold
                                          : VizareColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Homeowner',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: !_isHomeBuyer
                                            ? Colors.white
                                            : VizareColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Policy Agreement Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToPolicy,
                            activeColor: VizareColors.champagneGold,
                            checkColor: VizareColors.obsidianBlack,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() => _agreedToPolicy = val ?? false);
                            },
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  color: VizareColors.textSecondary,
                                  fontSize: 13.0,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'terms & privacy policy',
                                    style: const TextStyle(
                                      color: VizareColors.champagneGold,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushNamed(context, '/tos');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Register Button
                LuxuryGradientButton(
                  text: 'Register Account',
                  icon: Icons.person_add_rounded,
                  isLoading: _isLoading,
                  onPressed: _agreedToPolicy ? _createAccount : null,
                ),
                const SizedBox(height: 14),

                // Google Sign-In Glass Button
                VisionGlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: 30,
                  onTap: _isLoading ? null : signInWithGoogle,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 18,
                          width: 18,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Existing account login
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.inter(
                          color: VizareColors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/login'),
                        child: Text(
                          'Log in',
                          style: GoogleFonts.poppins(
                            color: VizareColors.champagneGold,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
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
    );
  }
}
