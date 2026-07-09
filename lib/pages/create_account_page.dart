import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  // --- Controllers & Logger ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _logger = Logger();

  // --- State Variables ---
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isHomeBuyer = true;
  bool _agreedToPolicy = false;

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
    // Dispose all controllers
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Authentication Logic ---

  Future<void> signInWithGoogle() async {
    try {
      final result = await GoogleAuthService.signIn(
        requestedRole: _isHomeBuyer ? 'homebuyer' : 'homeowner',
      );
      if (result == null || !mounted) return;
      final userType = result.userType;

      if (userType == 'homeowner') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/homeowner', (Route<dynamic> route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/homebuyer', (Route<dynamic> route) => false);
      }

    } catch (e) {
      _logger.e("Google Sign-In failed", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In failed. Please try again. Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createAccount() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final bool isHomeBuyer = _isHomeBuyer;

    // --- Start Validation ---
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // --- End Validation ---

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

      if (response.statusCode == 200) {
        _logger.i('Account created: ${response.body}');

        final responseData = jsonDecode(response.body);
        if (responseData['requires_email_confirmation'] == true) {
          if (!mounted) return;
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
        await prefs.setString('user_type', isHomeBuyer ? 'homebuyer' : 'homeowner');
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
        _logger.w(
          'Failed to create account: ${response.statusCode} ${response.body}',
        );
        if (mounted) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error occurred while creating account', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Gradient for Title ---
  Shader _buildGradientShader(Rect bounds) {
    return const LinearGradient(
      begin: Alignment(-1.0, 0.0),
      end: Alignment(1.0, -0.2),
      colors: [
        Color(0xFF5E17EB),
        Color(0xFFD6B3F9),
        Color(0xFF4AE4FF),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(bounds);
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withAlpha(153), // The dark overlay
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: const Offset(-14, 0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  ShaderMask(
                    shaderCallback: (bounds) => _buildGradientShader(bounds),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 45,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        color: Colors.white, // Color is masked by shader
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // Increased spacing

                  // --- Full Name ---
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Name',
                  ),
                  const SizedBox(height: 16),

                  // --- Email ---
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // --- Password ---
                  _buildPasswordField(
                    controller: _passwordController,
                    hintText: 'Password',
                    isVisible: _isPasswordVisible,
                    onToggleVisibility: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Confirm Password ---
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm password',
                    isVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: () {
                      setState(() =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Homebuyer Checkbox ---
                  _buildCheckbox(
                    label: 'I am a homebuyer',
                    value: _isHomeBuyer,
                    onChanged: (val) {
                      setState(() => _isHomeBuyer = val ?? false);
                    },
                  ),

                  // --- Policy Checkbox ---
                  _buildCheckbox(
                    richLabel: _buildPolicyLink(),
                    value: _agreedToPolicy,
                    onChanged: (val) {
                      setState(() => _agreedToPolicy = val ?? false);
                    },
                  ),

                  const SizedBox(height: 24),

                  // --- Register Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _agreedToPolicy ? _createAccount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E17EB),
                        disabledBackgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 18), // Taller
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded
                        ),
                      ),
                      child: const Text(
                        'Register',

                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSeparator(),
                  const SizedBox(height: 24),

                  // --- Sign in with Google Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: signInWithGoogle,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18), // Taller
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Rounded
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",

                        style: TextStyle(
                            color: Colors.white70, fontFamily: 'Poppins'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          'Log in',

                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  /// Builds a standardized text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'Inter'),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5E17EB), width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  /// Built a standardized password field with visibility toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.black, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'Inter'),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5E17EB), width: 2),
          borderRadius: BorderRadius.circular(30),
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

  /// Builds the "or" separator line
  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: (0.3))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'or',
            style: TextStyle(color: Colors.white.withValues(alpha: (0.7))),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: (0.3))),
        ),
      ],
    );
  }

  /// Builds the "I agree to terms & policy" RichText
  Widget _buildPolicyLink() {
    return RichText(
      text: TextSpan(

        style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            letterSpacing: 0.1,
            fontSize: 14.0,
        ),
        children: [
          const TextSpan(text: 'I agree to the '),
          TextSpan(
            text: 'terms & policy',
            style: const TextStyle(

              color: Color(0xFF5E17EB),
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _logger.i('Navigating to Terms & Policy...');
                Navigator.pushNamed(context, '/tos');
              },
          ),
        ],
      ),
    );
  }

  /// Builds a standardized checkbox
  Widget _buildCheckbox({
    String? label,
    Widget? richLabel,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(Colors.white),
          checkColor: WidgetStateProperty.all(Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: richLabel ??
            Text(
              label ?? '',

              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  letterSpacing: 0.1,
                  fontSize: 14.0,
              ),
            ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
