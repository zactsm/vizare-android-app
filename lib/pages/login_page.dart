import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/admin_page.dart';
import 'package:untitled/pages/forgot_password_page.dart';
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

  void _showUnverifiedEmailDialog(String email) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => VizareDialog(
        title: "Email Not Verified",
        message:
            "Your email address ($email) has not been verified yet.\n\nPlease check your inbox (and spam folder) for the verification link, or tap 'Resend Email' to receive a new link.",
        confirmText: "Resend Email",
        cancelText: "Cancel",
        onCancel: () => Navigator.pop(dialogCtx),
        onConfirm: () {
          Navigator.pop(dialogCtx);
          _resendVerificationEmail(email);
        },
      ),
    );
  }

  Future<void> _resendVerificationEmail(String email) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        'resend_verification.php',
        body: {'email': email},
      );
      if (!mounted) return;
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'Verification email resent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorDialog(
          "Resend Failed",
          responseData['message'] ??
              'Could not resend verification email. Please try again.',
        );
      }
    } on TimeoutException {
      if (mounted) {
        _showErrorDialog("Connection Timeout",
            "The server took too long to respond. Please check your connection.");
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Connection Error",
            "Could not reach the server. Please verify your connection.");
      }
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
        if (responseData.containsKey('has_password')) {
          await prefs.setBool('has_password', responseData['has_password'] == true);
        }

        // Load and apply authenticated user's theme preference
        await AppThemeController.instance.loadThemeMode(isAuthenticated: true);

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
        final bool isUnverified =
            responseData['requires_email_confirmation'] == true ||
            (response.statusCode == 403 &&
                (responseData['message']?.toString().toLowerCase().contains('verif') == true ||
                 responseData['message']?.toString().toLowerCase().contains('confirm') == true));

        if (isUnverified) {
          _showUnverifiedEmailDialog(email.trim());
        } else {
          final errorMessage = responseData['message'] ?? 'Invalid email or password.';
          _showErrorDialog("Login Failed", errorMessage);
        }
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
    return Theme(
      data: VizareTheme.darkTheme,
      child: Scaffold(
        backgroundColor: VizareColors.obsidianBlack,
        body: PremiumBackground(
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
                        cursorColor: VizareColors.champagneGold,
                        decoration: InputDecoration(
                          hintText: 'yourname@luxury.com',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14.5,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
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
                        cursorColor: VizareColors.champagneGold,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14.5,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white60,
                              size: 18,
                              semanticLabel: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
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
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              color: VizareColors.champagneGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

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
    ),
  ),
);
  }
}
