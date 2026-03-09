import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  // Checkbox states
  final Map<String, bool> generalNotifications = {
    'Property Recommendations': false,
    'Price Drops & Property Updates': false,
    'Inquiry Responses': false,
    'Saved Property Updates': false,
    'Promotions or News': false,
  };

  final Map<String, bool> deliveryMethods = {
    'Push notifications': false,
    'Email notifications': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved checkbox states
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load general notifications
    for (var key in generalNotifications.keys) {
      if (prefs.containsKey(key)) {
        generalNotifications[key] = prefs.getBool(key)!;
      }
    }

    // Load delivery methods
    for (var key in deliveryMethods.keys) {
      if (prefs.containsKey(key)) {
        deliveryMethods[key] = prefs.getBool(key)!;
      }
    }

    setState(() {}); // Refresh UI after loading
  }


  @override
  Widget build(BuildContext context) {
    // Set system overlay for dark mode
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Notification preferences',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'General',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // General notifications checkboxes
            ...generalNotifications.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _CheckboxTile(
                  title: entry.key,
                  subtitle: _getSubtitle(entry.key),
                  value: entry.value,
                  onChanged: (value) async {
                    setState(() {
                      generalNotifications[entry.key] = value!;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool(entry.key, value!);
                  },
                ),
              );
            }),

            const SizedBox(height: 24),
            Divider(color: Colors.white.withValues(alpha: (0.1)), thickness: 1),
            const SizedBox(height: 24),

            const Text(
              'Delivery Methods',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),

            // Delivery method checkboxes
            ...deliveryMethods.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _CheckboxTile(
                  title: entry.key,
                  value: entry.value,
                  onChanged: (value) async {
                    setState(() {
                      deliveryMethods[entry.key] = value!;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool(entry.key, value!);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Optional subtitles for General section
  String? _getSubtitle(String key) {
    switch (key) {
      case 'Property Recommendations':
        return 'Get notified about new listings that match your preferences.';
      case 'Price Drops & Property Updates':
        return 'Alerts when prices change or listings are updated.';
      case 'Inquiry Responses':
        return 'Get notified when an agent or homeowner replies to your inquiry.';
      case 'Saved Property Updates':
        return "Changes to properties you've favorited.";
      case 'Promotions or News':
        return 'Receive updates on new app features or real estate trends.';
      default:
        return null;
    }
  }
}

// Custom reusable checkbox list tile
class _CheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
      children: [
        Transform.translate(
          offset: const Offset(0, -2), // Slight downward shift to align with text
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            side: const BorderSide(color: Colors.white, width: 1.5),
            activeColor: Colors.white,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, // Keeps text aligned better
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

