import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      const url = 'https://formidable-fort-475806-q1.et.r.appspot.com/google_login.php';
      final response = await http.post(
        Uri.parse(url),
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

    const url = 'http://formidable-fort-475806-q1.et.r.appspot.com/login.php';

    try {
      final response = await http.post(
        Uri.parse(url),
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
          Container(color: Colors.black.withValues(alpha: (0.6))),
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
                    shaderCallback: _buildGradientShader,
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 45,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('  Email',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.purple),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const Text('  Password',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.purple),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        login(_emailController.text, _passwordController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E17EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: const Text('Log in',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Google Sign-In Button
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
                        style: TextStyle(color: Colors.black87),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        elevation: 2,
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/create-account'),
                        child: const Text('Sign up',
                            style: TextStyle(color: Colors.white)),
                      ),
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
}
