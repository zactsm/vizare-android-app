import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

import 'package:untitled/pages/utils/app_theme.dart';
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
  bool _hasPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPassword = prefs.getBool('has_password') ?? false;
    });
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut(
        scope: SignOutScope.local,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await GoogleAuthService.signOut();

      _logger.i('User logged out successfully.');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _logger.e('Error during logout', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final innerContent = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Scrollable List grouped into VisionOS glass containers
        ListView(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 100, bottom: 120),
          children: [
            _buildSectionHeader('Account Preferences'),
            _buildSettingsGroup([
              _buildSettingsItem(
                'Preferred property types',
                Icons.holiday_village_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const PreferredPropertyTypesPage()),
                  );
                },
              ),
              _buildSettingsItem(
                'Preferred locations',
                Icons.map_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PreferredLocationPage()),
                  );
                },
              ),
              if (_hasPassword)
                _buildSettingsItem(
                  'Change password',
                  Icons.password_rounded,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage()),
                    );
                  },
                ),
              _buildSettingsItem(
                'Notification preferences',
                Icons.notifications_active_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const NotificationPreferencesPage()),
                  );
                },
                showDivider: false,
              ),
            ]),
            _buildSectionHeader('Support & Legal'),
            _buildSettingsGroup([
              _buildSettingsItem(
                'FAQs & Guidance',
                Icons.help_outline_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FAQPage()),
                  );
                },
              ),
              _buildSettingsItem(
                'Concierge & Support',
                Icons.support_agent_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ContactSupportPage()),
                  );
                },
              ),
              _buildSettingsItem(
                'Terms of service',
                Icons.article_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TOSPage()),
                  );
                },
              ),
              _buildSettingsItem(
                'Privacy policy',
                Icons.privacy_tip_outlined,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage()),
                  );
                },
                showDivider: false,
              ),
            ]),
            _buildSectionHeader('Account Actions'),
            _buildSettingsGroup([
              _buildSettingsItem(
                'Log out',
                Icons.logout_rounded,
                _logout,
                iconColor: VizareColors.goldLight,
              ),
              _buildSettingsItem(
                'Deactivate account',
                Icons.delete_outline_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const DeactivateAccountPage()),
                  );
                },
                showDivider: false,
                iconColor: VizareColors.crimsonRed,
                textColor: VizareColors.crimsonRed,
              ),
            ]),
            const SizedBox(height: 36),
            Center(
              child: Text(
                'VIZARE SPATIAL PLATFORM v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.2),
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),

        // VisionOS Top Header Capsule
        // Top Header Texts
        Positioned(
          top: 16,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account, notifications, and security.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: VizareColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        if (!widget.isEmbedded)
          const FloatingBottomNavBar(activeIndex: NavPageIndex.settings),
      ],
    );

    if (widget.isEmbedded) {
      return innerContent;
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: VizareColors.obsidianBlack,
        body: AbstractBackground(
          child: SafeArea(
            bottom: true,
            child: innerContent,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 22, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: VizareColors.champagneGold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return VisionGlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 22,
      backgroundColor: VizareColors.obsidianSurface.withValues(alpha: 0.8),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.10),
        width: 1.0,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool showDivider = true,
    Color? iconColor,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? VizareColors.champagneGold)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? VizareColors.champagneGold,
                size: 18,
              ),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                color: textColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: VizareColors.champagneGold,
              size: 13,
            ),
            onTap: onTap,
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.06),
              indent: 58,
              endIndent: 18,
            ),
        ],
      ),
    );
  }
}
