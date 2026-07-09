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
                            fontSize: 42,
                            height: 1.1,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.0,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFFFF200),
                                ],
                              ).createShader(const Rect.fromLTWH(0, 0, 350, 150)),
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
                          backgroundColor: const Color(0xFFFFF200),
                          foregroundColor: const Color(0xFF0D0D0D),
                          minimumSize: const Size(200, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFF200), width: 1.5),
                          foregroundColor: const Color(0xFFFFF200),
                          minimumSize: const Size(200, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
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
