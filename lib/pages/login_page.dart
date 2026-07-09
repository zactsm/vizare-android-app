import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final logger = Logger();

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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

      // 2. "Find or Create" user in MySQL database ---
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
      logger.e("Google Sign-In failed", error: e);
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

  Future<void> login(String rawEmail, String rawPassword) async {
    final email = rawEmail.trim();
    final password = rawPassword.trim();

    if (email.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Missing Fields"),
          content: Text("Please enter both email and password."),
        ),
      );
      return;
    }

    logger.d("📧 Sending email: [$email]");
    logger.d("🔑 Sending password: [$password]");

    try {
      final response = await ApiService.post(
        'login.php',
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'email': email, 'password': password},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        logger.i("✅ Login success: ${response.body}");

        final responseData = jsonDecode(response.body);
        final userType = responseData['user_type'] as String?;
        final hasPassword = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        if (userType != null){
          await prefs.setString('user_type', userType);
        }

        await prefs.setBool('has_password', hasPassword);

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
        logger.w("❌ Login failed: ${response.body}");
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Login failed.';

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Login Failed"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      logger.e("🚨 Login error: $e");
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

  Shader _buildGradientShader(Rect bounds) {
    return const LinearGradient(
      colors: [
        Colors.white,
        Color(0xFFD6B3F9),
      ],
    ).createShader(bounds);
  }

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
                shaderCallback: _buildGradientShader,
                child: const Text(
                  'Log In',
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
                'Welcome back! Enter your details to continue.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Email',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'yourname@example.com',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Password',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    login(_emailController.text, _passwordController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pastelPurple,
                    foregroundColor: const Color(0xFF121212),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Google Sign-In Button
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
                    style: TextStyle(fontWeight: FontWeight.w600),
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
                    "Don't have an account?",
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/create-account'),
                    child: Text(
                      'Sign up',
                      style: TextStyle(color: pastelPurple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
