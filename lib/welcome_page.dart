import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'pages/utils/premium_background.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
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

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % 5;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  List<List<InlineSpan>> _getRichMessages(Color neonPurple) {
    return [
      [
        const TextSpan(text: 'Your ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        TextSpan(text: 'dream space\n', style: TextStyle(fontWeight: FontWeight.w900, color: neonPurple)),
        const TextSpan(text: 'now in ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        const TextSpan(text: 'augmented reality.', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.white)),
      ],
      [
        const TextSpan(text: 'Bringing ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        TextSpan(text: 'properties\n', style: TextStyle(fontWeight: FontWeight.w900, color: neonPurple)),
        const TextSpan(text: 'directly into ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        const TextSpan(text: 'your hands.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
      [
        const TextSpan(text: 'Step ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        TextSpan(text: 'inside\n', style: TextStyle(fontWeight: FontWeight.w900, color: neonPurple)),
        const TextSpan(text: 'your future home ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        const TextSpan(text: 'virtually.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
      [
        const TextSpan(text: 'Explore ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const TextSpan(text: 'spaces\n', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w300, color: Colors.white)),
        const TextSpan(text: 'like never before with ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        TextSpan(text: 'AR tours.', style: TextStyle(fontWeight: FontWeight.w900, color: neonPurple)),
      ],
      [
        const TextSpan(text: 'Walk ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        TextSpan(text: 'through\n', style: TextStyle(fontWeight: FontWeight.w900, color: neonPurple)),
        const TextSpan(text: 'before you ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white)),
        const TextSpan(text: 'walk in.', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.white)),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Color neonPurple = const Color(0xFFDF00FF);

    return PremiumBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Logo
                Align(
                  alignment: Alignment.topLeft,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                  ),
                ),
                const SizedBox(height: 160),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: RichText(
                      key: ValueKey(_currentIndex),
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 38,
                          height: 1.2,
                          fontFamily: 'Poppins',
                        ),
                        children: _getRichMessages(neonPurple)[_currentIndex],
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
                      backgroundColor: neonPurple,
                      foregroundColor: const Color(0xFF0D0D0D),
                      minimumSize: const Size(200, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
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
                      side: BorderSide(color: neonPurple, width: 1.5),
                      foregroundColor: neonPurple,
                      minimumSize: const Size(200, 56),
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
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
