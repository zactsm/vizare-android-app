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
import 'package:untitled/pages/utils/api_service.dart';
import 'utils/floating_bottom_nav_bar.dart';
import 'utils/google_auth_service.dart';
import 'package:untitled/welcome_page.dart';
import 'utils/abstract_background.dart';
import 'utils/top_bar_gradient_blur.dart';

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
      await AppThemeController.instance.resetToDefaultDark();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            _buildSectionHeader('Appearance'),
            _buildSettingsGroup([
              ListenableBuilder(
                listenable: AppThemeController.instance,
                builder: (context, _) {
                  return _buildSettingsItem(
                    'Theme Mode',
                    Icons.palette_outlined,
                    _showThemeSelectorDialog,
                    trailingText: AppThemeController.instance.themeModeName,
                    showDivider: false,
                  );
                },
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
              ),
              _buildSettingsItem(
                'Download personal data (GDPR)',
                Icons.download_for_offline_outlined,
                _downloadPersonalData,
                showDivider: false,
              ),
            ]),
            _buildSectionHeader('Account Actions'),
            _buildSettingsGroup([
              _buildSettingsItem(
                'Log out',
                Icons.logout_rounded,
                _logout,
                iconColor: isDark ? VizareColors.goldLight : VizareColors.goldDark,
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.25),
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),

        // Smooth Gradient Blur behind top header
        const TopBarGradientBlur(height: 125.0),

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
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account, notifications, and security.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: isDark
                      ? VizareColors.textSecondary
                      : const Color(0xFF64748B),
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
        backgroundColor:
            isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VisionGlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 22,
      backgroundColor: isDark
          ? VizareColors.obsidianSurface.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.9),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFE2E8F0),
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
    String? trailingText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    .withValues(alpha: isDark ? 0.12 : 0.10),
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
                color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null) ...[
                  Text(
                    trailingText,
                    style: GoogleFonts.inter(
                      color: isDark
                          ? VizareColors.textMuted
                          : const Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: VizareColors.champagneGold,
                  size: 13,
                ),
              ],
            ),
            onTap: onTap,
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF1F5F9),
              indent: 58,
              endIndent: 18,
            ),
        ],
      ),
    );
  }

  void _showThemeSelectorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ListenableBuilder(
          listenable: AppThemeController.instance,
          builder: (context, _) {
            final currentMode = AppThemeController.instance.themeMode;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor:
                  isDark ? VizareColors.obsidianSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VizareColors.champagneGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: VizareColors.champagneGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Appearance",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeOption(
                    title: "System Default",
                    subtitle: "Matches device operating system",
                    icon: Icons.brightness_auto_rounded,
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () {
                      AppThemeController.instance.setThemeMode(ThemeMode.system);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildThemeOption(
                    title: "Obsidian Dark",
                    subtitle: "Vizare signature luxury dark aesthetic",
                    icon: Icons.dark_mode_rounded,
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () {
                      AppThemeController.instance.setThemeMode(ThemeMode.dark);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildThemeOption(
                    title: "Alabaster Light",
                    subtitle: "Crisp daylight luxury palette",
                    icon: Icons.light_mode_rounded,
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () {
                      AppThemeController.instance.setThemeMode(ThemeMode.light);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: GoogleFonts.inter(
                      color: VizareColors.champagneGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? VizareColors.champagneGold.withValues(alpha: isDark ? 0.15 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? VizareColors.champagneGold
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? VizareColors.champagneGold
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: isDark
                          ? VizareColors.textMuted
                          : const Color(0xFF64748B),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: VizareColors.champagneGold,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPersonalData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: VizareColors.champagneGold),
      ),
    );

    try {
      final response = await ApiService.get('export_my_data.php');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Personal Data Export',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Text(
                'Your complete GDPR / CCPA personal data archive has been generated successfully.\n\nExported records include:\n• Account Profile & Role\n• Property Listings & Models\n• Saved Favorites\n• Direct Inquiries & Messaging\n• Support Tickets & Attachments\n• Notification & Marketing Preferences',
                style: GoogleFonts.inter(fontSize: 13, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    color: VizareColors.champagneGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to generate export archive. Please try again.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
      );
    }
  }
}

