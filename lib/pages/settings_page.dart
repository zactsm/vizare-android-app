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

//--- CONVERTED TO STATEFULWIDGET ---
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

    // Set status bar style
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
    // Get the flag, default to 'false' if it's not there
    setState(() {
      _hasPassword = prefs.getBool('has_password') ?? false;
    });
  }

  // Moved logout logic inside the class ---
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
    return PopScope(
      canPop: false, // Prevents back swipe
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: true, // Ensures consistent nav bar position
          child: Stack(
            fit: StackFit.expand, // Ensures Stack fills screen
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
                child: ListView(
                  children: [
                    const _SectionHeader(
                      iconPath: 'assets/images/grey_home_icon.png',
                      title: 'Account Preferences',
                    ),
                    _SettingsItem(
                      title: 'Preferred property types',
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PreferredPropertyTypesPage()),
                        );
                      },
                    ),
                    _SettingsItem(
                        title: 'Preferred location',
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PreferredLocationPage()),
                          );
                        }
                    ),
                    _SettingsItem(
                      title: 'Notification preferences',
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPreferencesPage()),
                        );
                      },
                    ),

                    // Conditional "Change Password" button ---
                    // This will only show if _hasPassword is true
                    if (_hasPassword) ...[
                      const SizedBox(height: 10),
                      const _SectionDivider(),
                      const _SectionHeader(
                        iconPath: 'assets/images/grey_security_icon.png',
                        title: 'Security',
                      ),

                      _SettingsItem(
                        title: 'Change password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ChangePasswordPage()),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 10),
                    const _SectionDivider(),

                    const _SectionHeader(
                      iconPath: 'assets/images/grey_support_icon.png',
                      title: 'Support & Legal',
                    ),
                    _SettingsItem(
                        title: 'FAQs',
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FAQPage()),
                          );
                        }
                    ),
                    _SettingsItem(
                      title: 'Terms of Service',
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TOSPage()),
                        );
                      },
                    ),
                    _SettingsItem(
                      title: 'Privacy Policy',
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                        );
                      },
                    ),
                    _SettingsItem(
                      title: 'Contact Support',
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ContactSupportPage()),
                        );
                      },
                    ),
                    _SettingsItem(
                      title: 'Deactivate Account',
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DeactivateAccountPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Logout Button
                    Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => _logout(context), // Calls the new class method
                          child: const Text(
                            "Log out",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              Positioned(
                top: 16,
                left: 16,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFFF200),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const FloatingBottomNavBar(activeIndex: NavPageIndex.settings),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper widgets for the settings list ---

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 32,
      thickness: 1,
      color: Colors.white.withValues(alpha: (0.1)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String iconPath;
  final String title;
  const _SectionHeader({required this.iconPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4, top: 20),
      child: Row(
        children: [
          Image.asset(iconPath, width: 20, height: 20, errorBuilder: (context, error, stackTrace) => const SizedBox()),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF808080),
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap; // ✅ Allow tapping behavior

  const _SettingsItem({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 0, right: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
        size: 16,
      ),
      onTap: onTap, // ✅ Use the callback you pass in
    );
  }
}
