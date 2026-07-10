import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untitled/pages/settings/change_password_page.dart';
import 'package:untitled/pages/settings/contact_support_page.dart';
import 'package:untitled/pages/settings/deactivate_account_page.dart';
import 'package:untitled/pages/settings/faq_page.dart';
import 'package:untitled/pages/settings/notification_preferences_page.dart';
import 'package:untitled/pages/settings/preferred_location_page.dart';
import 'package:untitled/pages/settings/preferred_property_types_page.dart';
import 'package:untitled/pages/settings/privacy_policy_page.dart';
import 'package:untitled/pages/settings/tos_page.dart';

import 'utils/floating_bottom_nav_bar.dart';
import 'utils/google_auth_service.dart';
import 'package:untitled/welcome_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _logger = Logger();
  bool _hasPassword = false; // State variable to hold the flag

  @override
  void initState() {
    super.initState();
    _loadUserPreferences(); // Load the flag when the page opens

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  // Function to read from SharedPreferences ---
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPassword = prefs.getBool('has_password') ?? false;
    });
  }

  // Logout logic ---
  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut(
        scope: SignOutScope.local,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await GoogleAuthService.signOut();

      _logger.i('User logged out successfully.');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _logger.e('Error during logout', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return PopScope(
      canPop: false, // Prevents back swipe
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Pitch Black background
        body: SafeArea(
          bottom: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Scrollable List grouped into card blocks (full screen stack child)
              ListView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 96, bottom: 120),
                children: [
                  _buildSectionHeader('Account Preferences'),
                  _buildSettingsGroup([
                    _buildSettingsItem('Preferred property types', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PreferredPropertyTypesPage()),
                      );
                    }),
                    _buildSettingsItem('Preferred location', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PreferredLocationPage()),
                      );
                    }),
                    _buildSettingsItem('Notification preferences', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationPreferencesPage()),
                      );
                    }, showDivider: false),
                  ]),

                  // Conditional "Security" block ---
                  if (_hasPassword) ...[
                    _buildSectionHeader('Security'),
                    _buildSettingsGroup([
                      _buildSettingsItem('Change password', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                        );
                      }, showDivider: false),
                    ]),
                  ],

                  _buildSectionHeader('Support & Legal'),
                  _buildSettingsGroup([
                    _buildSettingsItem('FAQs', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FAQPage()),
                      );
                    }),
                    _buildSettingsItem('Terms of Service', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TOSPage()),
                      );
                    }),
                    _buildSettingsItem('Privacy Policy', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                      );
                    }),
                    _buildSettingsItem('Contact Support', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ContactSupportPage()),
                      );
                    }),
                    _buildSettingsItem('Deactivate Account', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeactivateAccountPage()),
                      );
                    }, showDivider: false),
                  ]),

                  // Log Out Button: Solid block pastel purple shape with solid black text
                  Center(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 32, bottom: 16),
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pastelPurple,
                          foregroundColor: const Color(0xFF000000),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () => _logout(context),
                        child: const Text(
                          "LOG OUT",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Liquid Glass Top Header Bar
              _buildTopHeader(context),

              // 3. Floating Bottom Nav Bar
              const FloatingBottomNavBar(activeIndex: NavPageIndex.settings),
            ],
          ),
        ),
      ),
    );
  }

  // --- Glassmorphic Top Header Bar ---
  Widget _buildTopHeader(BuildContext context) {
    const Color pastelPurple = Color(0xFFD4B2FF);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 80,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.only(left: 18, bottom: 12),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: pastelPurple.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'APP ', style: TextStyle(fontWeight: FontWeight.w300)),
                  TextSpan(text: 'SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, color: pastelPurple)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Header style: tiny, clean, all-caps muted gray text ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF8E8E93), // Muted gray
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- Group settings items inside a flat solid card container block ---
  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121214), // Solid dark gray block
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E1E22), width: 1.5),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // --- Individual settings list item widget ---
  Widget _buildSettingsItem(String title, VoidCallback onTap, {bool showDivider = true}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFFD4B2FF), // Pastel purple arrow icon
            size: 14,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF1E1E22),
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}
