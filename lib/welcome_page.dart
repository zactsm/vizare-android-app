import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final List<String> _messages = [
    'Your dream home, now in augmented reality.',
    'Bringing properties into view, right in your hands.',
    'Step inside your future home - without stepping outside.',
    'Explore spaces like never before with AR tours.',
    'Walk through before you walk in.',
  ];
  int _currentIndex = 0;
  late Timer _timer;

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

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg.png', // Make sure the image exists and is declared in pubspec.yaml
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 Dark overlay for readability
          Container(
            color: Colors.black.withValues(alpha: (0.6)),
          ),

          // 🔹 Foreground content
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 54.0, right: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Align(
                      alignment: Alignment.topLeft,
                      child: Transform.translate(
                        offset: const Offset(-16, 0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 250),
                    Padding(
                      padding: const EdgeInsets.only(right: 24.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _messages[_currentIndex],
                          key: ValueKey(_messages[_currentIndex]),
                          style: TextStyle(
                            fontSize: 45,
                            height: 1.0,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                begin: Alignment(-1.0, 0.0),
                                end: Alignment(1.0, -0.2),
                                colors: [
                                  Color(0xFF5E17EB),
                                  Color(0xFFD6B3F9),
                                  Color(0xFF4AE4FF),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-account');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E17EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
