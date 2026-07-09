import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';

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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 1. Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 2. "Find or Create" user in your MySQL database ---
      final response = await ApiService.post(
        'google_login.php',
        body: {
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Google User', // Use Google name
        },
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        // Failed to create user in your backend
        throw Exception('Failed to sign in with your server: ${response.body}');
      }

      // 3. Get user_type from your server's response
      final responseData = jsonDecode(response.body);
      final userType = responseData['user_type'] as String?;
      final hasPassword = responseData['has_password'] as bool?;

      // 4. Save session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', googleUser.email);
      if (userType != null) {
        await prefs.setString('user_type', userType);
      }
      if (hasPassword != null){
        await prefs.setBool('has_password', hasPassword);
      }

      if (!mounted) return;

      // 5. Navigate
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
        _logger.w('Failed to create account: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create account. Please try again.'),
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
      colors: [
        Colors.white,
        Color(0xFFD6B3F9),
      ],
    ).createShader(bounds);
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final Color pastelPurple = const Color(0xFFD6B3F9);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => _buildGradientShader(bounds),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 36,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to explore properties in AR.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // --- Full Name ---
              _buildTextField(
                controller: _nameController,
                hintText: 'Full Name',
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
              const SizedBox(height: 12),

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
                    backgroundColor: pastelPurple,
                    foregroundColor: const Color(0xFF121212),
                    disabledBackgroundColor: Colors.grey.shade800,
                    disabledForegroundColor: Colors.white30,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildSeparator(),
              const SizedBox(height: 16),

              // --- Sign in with Google Button ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 20,
                    width: 20,
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontFamily: 'Poppins'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Log in',
                      style: TextStyle(
                        color: pastelPurple,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
            size: 20,
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
          child: Divider(color: Colors.white.withOpacity(0.15)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'or',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.15)),
        ),
      ],
    );
  }

  /// Builds the "I agree to terms & policy" RichText
  Widget _buildPolicyLink() {
    final Color pastelPurple = const Color(0xFFD6B3F9);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontFamily: 'Poppins',
          fontSize: 14.0,
        ),
        children: [
          const TextSpan(text: 'I agree to the '),
          TextSpan(
            text: 'terms & policy',
            style: TextStyle(
              color: pastelPurple,
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
    final Color pastelPurple = const Color(0xFFD6B3F9);
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return pastelPurple;
            }
            return Colors.white.withOpacity(0.1);
          }),
          checkColor: WidgetStateProperty.all(const Color(0xFF121212)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: richLabel ??
            Text(
              label ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Poppins',
                fontSize: 14.0,
              ),
            ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}