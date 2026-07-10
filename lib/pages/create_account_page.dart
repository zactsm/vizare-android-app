import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/google_auth_service.dart';
import 'package:untitled/pages/utils/premium_background.dart';

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
  final _phoneController = TextEditingController();
  final _logger = Logger();

  // --- Registration States ---
  String _userRole = 'homebuyer'; // Default role
  bool _agreedToPolicy = false;
  bool _isUploading = false;

  // --- Password Validation States ---
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSymbol = false;

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
      colors: [
        Colors.white,
        Color(0xFFDF00FF),
      ],
    ).createShader(bounds);
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final Color neonPurple = const Color(0xFFDF00FF);
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    backgroundColor: neonPurple,
                    foregroundColor: const Color(0xFF0D0D0D),
                    disabledBackgroundColor: Colors.grey.shade800,
                    disabledForegroundColor: Colors.white30,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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
                        color: neonPurple,
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
    ),);
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
    final Color neonPurple = const Color(0xFFDF00FF);
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
              color: neonPurple,
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
    final Color neonPurple = const Color(0xFFDF00FF);
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return neonPurple;
            }
            return Colors.white.withOpacity(0.1);
          }),
          checkColor: WidgetStateProperty.all(const Color(0xFF0D0D0D)),
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
