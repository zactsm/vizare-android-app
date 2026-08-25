import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/admin_page.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _logger = Logger();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => VizareDialog(
        title: title,
        message: message,
        confirmText: "OK",
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await GoogleAuthService.signIn(
        requestedRole: 'homebuyer',
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Google sign-in timed out. Please try again.'),
      );
      if (result == null || !mounted) {
        return;
      }
      final userType = result.userType;

      if (userType == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminPage()),
          (route) => false,
        );
      } else if (userType == 'homeowner') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/homeowner', (Route<dynamic> route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/homebuyer', (Route<dynamic> route) => false);
      }
    } catch (e) {
      _showErrorDialog("Google Sign-In Notice", "Sign-in could not be completed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _showErrorDialog("Required Fields", "Please enter your email and password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        'login.php',
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        _logger.i("✅ Login successful");

        final responseData = jsonDecode(response.body);
        await ApiService.restoreSession(
          responseData['access_token'] as String?,
          responseData['refresh_token'] as String?,
        );
        final userType = responseData['user_type'] as String?;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email.trim());
        if (userType != null) {
          await prefs.setString('user_type', userType);
        }

        if (!mounted) return;

        if (userType == 'admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
            (route) => false,
          );
        } else if (userType == 'homeowner') {
          Navigator.pushNamedAndRemoveUntil(
              context, '/homeowner', (Route<dynamic> route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, '/homebuyer', (Route<dynamic> route) => false);
        }
      } else {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Invalid email or password.';
        _showErrorDialog("Login Failed", errorMessage);
      }
    } on TimeoutException {
      _logger.e("🚨 Login request timed out");
      _showErrorDialog("Connection Timeout", "The server took too long to respond. Please check your connection and try again.");
    } catch (e) {
      _logger.e("🚨 Login error: $e");
      _showErrorDialog("Connection Error", "Could not reach the server. Please verify your connection.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to access your saved tours and luxury properties.',
                  style: GoogleFonts.inter(
                    color: VizareColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 32),

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
                      const SizedBox(height: 20),
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
                        obscureText: _obscurePassword,
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
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white60,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Login CTA Button
                LuxuryGradientButton(
                  text: 'Log In',
                  icon: Icons.login_rounded,
                  isLoading: _isLoading,
                  onPressed: () {
                    login(_emailController.text, _passwordController.text);
                  },
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
                const SizedBox(height: 28),

                // Sign up prompt
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          color: VizareColors.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/create-account'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.poppins(
                              color: VizareColors.champagneGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
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
