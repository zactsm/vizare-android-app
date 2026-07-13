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
import 'utils/abstract_background.dart';

class SettingsPage extends StatefulWidget {
  final bool isEmbedded;
  const SettingsPage({super.key, this.isEmbedded = false});

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

    final innerContent = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Scrollable List grouped into card blocks (full screen stack child)
        ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 140, bottom: 120),
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
              if (_hasPassword)
                _buildSettingsItem('Change password', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                }),
              _buildSettingsItem('Notification preferences', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPreferencesPage()),
                );
              }),
            ]),
            _buildSectionHeader('Support & Legal'),
            _buildSettingsGroup([
              _buildSettingsItem('FAQs', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQPage()),
                );
              }),
              _buildSettingsItem('Contact support', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactSupportPage()),
                );
              }),
              _buildSettingsItem('Terms of service', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TOSPage()),
                );
              }),
              _buildSettingsItem('Privacy policy', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                );
              }),
            ]),
            _buildSectionHeader('Account Actions'),
            _buildSettingsGroup([
              _buildSettingsItem('Log out', () => _logout(context)),
              _buildSettingsItem('Deactivate account', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeactivateAccountPage()),
                );
              }, showDivider: false),
            ]),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'VIZARE v1.0.0',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.15),
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),

        // 2. Custom Wise-Style Header Overhaul (Solid high-contrast container)
        Positioned(
          top: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121214), // Solid dark grey card block
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pastelPurple, width: 2.0), // High-contrast border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 34, // Ultra bold
                    fontWeight: FontWeight.w900, // Ultra bold
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your preferences and profile details.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Bottom Nav Bar (only if not embedded)
        if (!widget.isEmbedded)
          const FloatingBottomNavBar(activeIndex: NavPageIndex.settings),
      ],
    );

    if (widget.isEmbedded) {
      return innerContent;
    }

    return PopScope(
      canPop: false, // Prevents back swipe
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Pitch Black background
        body: AbstractBackground(
          child: SafeArea(
            bottom: true,
            child: innerContent,
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
          fontSize: 11,
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
