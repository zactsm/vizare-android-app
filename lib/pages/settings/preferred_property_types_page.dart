import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/api_service.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';

class PreferredPropertyTypesPage extends StatefulWidget {
  const PreferredPropertyTypesPage({super.key});

  @override
  State<PreferredPropertyTypesPage> createState() =>
      _PreferredPropertyTypesPageState();
}

class _PreferredPropertyTypesPageState
    extends State<PreferredPropertyTypesPage> {
  final Map<String, bool> propertyTypes = {
    'Apartment / Flat': true,
    'Condominium': true,
    'Luxury Villa': true,
    'Duplex / Penthouse': true,
    'Detached House / Bungalow': true,
    'Terraced House / Townhouse': true,
    'Serviced Residence': true,
    'Loft': true,
    'Studio Unit': true,
    'Commercial Property': true,
    'Modern Luxury': true,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await ApiService.get('get_property_types.php');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final Map<String, bool> fetched = {};
          for (var item in data) {
            final name = item['name']?.toString() ?? '';
            if (name.isNotEmpty) {
              final isEnabled = prefs.containsKey('propertyType_$name')
                  ? prefs.getBool('propertyType_$name')!
                  : true;
              fetched[name] = isEnabled;
            }
          }
          if (mounted) {
            setState(() {
              propertyTypes.clear();
              propertyTypes.addAll(fetched);
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback if network fails
    for (var key in propertyTypes.keys.toList()) {
      if (prefs.containsKey('propertyType_$key')) {
        propertyTypes[key] = prefs.getBool('propertyType_$key')!;
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('propertyType_$key', value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VizareColors.obsidianBlack : VizareColors.alabasterWhite,
      body: AbstractBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const VizareAppBar(
            title: 'Preferred Property Types',
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                    child: Text(
                      'Toggle the architectural categories you want featured in your discovery feeds.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark
                            ? VizareColors.textSecondary
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ),
                  Expanded(
                    child: VisionGlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: VizareColors.champagneGold,
                              ),
                            )
                          : ListView(
                              children: propertyTypes.keys.map((type) {
                          final isSelected = propertyTypes[type] ?? false;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final newVal = !isSelected;
                                  setState(() {
                                    propertyTypes[type] = newVal;
                                  });
                                  await _savePreference(type, newVal);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? VizareColors.champagneGold
                                            .withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? VizareColors.champagneGold
                                              .withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: VizareColors.champagneGold,
                                        checkColor: Colors.black,
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.white38
                                              : const Color(0xFF94A3B8),
                                        ),
                                        onChanged: (val) async {
                                          if (val == null) return;
                                          setState(() {
                                            propertyTypes[type] = val;
                                          });
                                          await _savePreference(type, val);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          type,
                                          style: GoogleFonts.inter(
                                            color: isSelected
                                                ? (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A))
                                                : (isDark
                                                    ? VizareColors.textSecondary
                                                    : const Color(0xFF475569)),
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
