import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/premium_background.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final Map<String, bool> generalNotifications = {
    'Property Recommendations': false,
    'Price Drops & Property Updates': false,
    'Inquiry Responses': false,
    'Saved Property Updates': false,
    'Promotions & Architectural News': false,
  };

  final Map<String, bool> deliveryMethods = {
    'Push notifications': false,
    'Email notifications': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    for (var key in generalNotifications.keys) {
      if (prefs.containsKey(key)) {
        generalNotifications[key] = prefs.getBool(key)!;
      }
    }

    for (var key in deliveryMethods.keys) {
      if (prefs.containsKey(key)) {
        deliveryMethods[key] = prefs.getBool(key)!;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const VizareAppBar(
          title: 'Notification Preferences',
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Text(
                'Notification preferences',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the notifications and delivery channels you want to receive.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: VizareColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ALERT CATEGORIES',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: VizareColors.champagneGold,
                ),
              ),
              const SizedBox(height: 12),
              VisionGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: generalNotifications.keys.map((key) {
                    final subtitle = _getSubtitle(key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Switch.adaptive(
                            value: generalNotifications[key] ?? false,
                            activeThumbColor: VizareColors.champagneGold,
                            activeTrackColor:
                                VizareColors.champagneGold.withValues(alpha: 0.3),
                            inactiveThumbColor: Colors.white60,
                            inactiveTrackColor: Colors.white12,
                            onChanged: (val) async {
                              setState(() {
                                generalNotifications[key] = val;
                              });
                              await _savePreference(key, val);
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  key,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.inter(
                                      color: VizareColors.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'DELIVERY CHANNELS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: VizareColors.champagneGold,
                ),
              ),
              const SizedBox(height: 12),
              VisionGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: deliveryMethods.keys.map((key) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Switch.adaptive(
                            value: deliveryMethods[key] ?? false,
                            activeThumbColor: VizareColors.champagneGold,
                            activeTrackColor:
                                VizareColors.champagneGold.withValues(alpha: 0.3),
                            inactiveThumbColor: Colors.white60,
                            inactiveTrackColor: Colors.white12,
                            onChanged: (val) async {
                              setState(() {
                                deliveryMethods[key] = val;
                              });
                              await _savePreference(key, val);
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              key,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String? _getSubtitle(String key) {
    switch (key) {
      case 'Property Recommendations':
        return 'Tailored luxury architectural listings matching your saved criteria.';
      case 'Price Drops & Property Updates':
        return 'Instant notifications when monitored estates update pricing or availability.';
      case 'Inquiry Responses':
        return 'Direct communications from estate owners and concierge advisors.';
      case 'Saved Property Updates':
        return 'Status adjustments for homes bookmarked in your portfolio.';
      case 'Promotions & Architectural News':
        return 'Curated updates on spatial 3D releases and architectural insights.';
      default:
        return null;
    }
  }
}
