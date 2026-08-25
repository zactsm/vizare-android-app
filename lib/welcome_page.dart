import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'pages/utils/premium_background.dart';
import 'pages/utils/app_theme.dart';

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
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % 5;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  List<List<InlineSpan>> _getRichMessages() {
    return [
      [
        const TextSpan(
          text: 'Experience ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'living spaces\n',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: VizareColors.champagneGold,
          ),
        ),
        const TextSpan(
          text: 'in spatial ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: '3D reality.',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: VizareColors.champagneGold,
          ),
        ),
      ],
      [
        const TextSpan(
          text: 'Ultra-luxury ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'properties\n',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: VizareColors.champagneGold,
          ),
        ),
        const TextSpan(
          text: 'crafted for ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'next-gen living.',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: VizareColors.champagneGold,
          ),
        ),
      ],
      [
        const TextSpan(
          text: 'Step inside ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'your future\n',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: VizareColors.champagneGold,
          ),
        ),
        const TextSpan(
          text: 'architectural ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'sanctuary.',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: VizareColors.champagneGold,
          ),
        ),
      ],
      [
        const TextSpan(
          text: 'Explore ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'spaces\n',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: VizareColors.champagneGold,
          ),
        ),
        const TextSpan(
          text: 'with real-time ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'AR tours.',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: VizareColors.champagneGold,
          ),
        ),
      ],
      [
        const TextSpan(
          text: 'Walk through ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'estates\n',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: VizareColors.champagneGold,
          ),
        ),
        const TextSpan(
          text: 'before you ',
          style: TextStyle(fontWeight: FontWeight.w300, color: VizareColors.goldLight),
        ),
        const TextSpan(
          text: 'walk in.',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: VizareColors.champagneGold,
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            // Top Bar with Logo
                            Image.asset(
                              'assets/images/logo.png',
                              width: 54,
                              height: 54,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(width: 54, height: 54),
                            ),
                            const SizedBox(height: 110),
                            // Dynamic Heading Switcher
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  final isEntering =
                                      child.key == ValueKey(_currentIndex);
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: isEntering
                                          ? const Offset(0.15, 0.0)
                                          : const Offset(-0.15, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: RichText(
                                  key: ValueKey(_currentIndex),
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 36,
                                      height: 1.25,
                                      letterSpacing: -0.5,
                                    ),
                                    children: _getRichMessages()[_currentIndex],
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Progress Indicator Dots
                            Row(
                              children: List.generate(5, (index) {
                                final isActive = index == _currentIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 8),
                                  width: isActive ? 28 : 8,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? VizareColors.champagneGold
                                        : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // CTAs
                        Column(
                          children: [
                            LuxuryGradientButton(
                              text: 'Create Account',
                              icon: Icons.person_add_alt_1_rounded,
                              onPressed: () {
                                Navigator.pushNamed(context, '/create-account');
                              },
                            ),
                            const SizedBox(height: 14),
                            VisionGlassPill(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              borderColor: VizareColors.glassBorderSpecular,
                              onTap: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.login_rounded,
                                    color: VizareColors.textPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Log In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: VizareColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
