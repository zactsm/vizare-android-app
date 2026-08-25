import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';
import 'package:untitled/pages/login_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';

enum GuardState { checking, authorized, unauthorized, unauthenticated }

class RoleGuard extends StatefulWidget {
  final List<String> allowedRoles;
  final Widget child;
  final String routeName;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.routeName = '',
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  GuardState _guardState = GuardState.checking;
  String _userRole = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_type')?.toLowerCase() ?? '';

    if (email == null || email.isEmpty) {
      if (mounted) {
        setState(() {
          _guardState = GuardState.unauthenticated;
        });
      }
      return;
    }

    _userEmail = email;
    _userRole = role;

    final normalizedAllowed =
        widget.allowedRoles.map((r) => r.toLowerCase()).toSet();

    // 'admin' role has universal access to all portals
    final isAuthorized =
        role == 'admin' || normalizedAllowed.contains(role);

    if (mounted) {
      setState(() {
        _guardState =
            isAuthorized ? GuardState.authorized : GuardState.unauthorized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_guardState) {
      case GuardState.checking:
        return const PremiumBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(
                color: VizareColors.champagneGold,
              ),
            ),
          ),
        );

      case GuardState.authorized:
        return widget.child;

      case GuardState.unauthenticated:
        return PremiumBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: VisionGlassContainer(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VizareColors.champagneGold
                                .withValues(alpha: 0.15),
                            border: Border.all(
                              color: VizareColors.champagneGold
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            size: 40,
                            color: VizareColors.champagneGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Authentication Required',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Please log in with a verified account to access this terminal.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: VizareColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        LuxuryGradientButton(
                          text: 'Sign In Now',
                          icon: Icons.login_rounded,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case GuardState.unauthorized:
        return PremiumBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: VisionGlassContainer(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VizareColors.crimsonRed
                                .withValues(alpha: 0.15),
                            border: Border.all(
                              color: VizareColors.crimsonRed
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.gpp_bad_rounded,
                            size: 40,
                            color: VizareColors.crimsonRed,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Access Restricted',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your account ($_userEmail, Role: $_userRole) does not have authorization to access this portal.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: VizareColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        LuxuryGradientButton(
                          text: 'Return to Discovery',
                          icon: Icons.arrow_back_rounded,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeBuyerPage(),
                              ),
                            );
                          },
                        ),
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
}
