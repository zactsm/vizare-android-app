import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferredPropertyTypesPage extends StatefulWidget {
  const PreferredPropertyTypesPage({super.key});

  @override
  State<PreferredPropertyTypesPage> createState() => _PreferredPropertyTypesPageState();
}

class _PreferredPropertyTypesPageState extends State<PreferredPropertyTypesPage> {
  final Map<String, bool> propertyTypes = {
    'Apartment/Flat': true,
    'Condominium': true,
    'Terraced House / Townhouse': true,
    'Semi-Detached House': true,
    'Detached House / Bungalow': true,
    'Studio Unit': true,
    'Loft': true,
    'Serviced Residence': true,
    'Duplex / Penthouse': true,
    'Room Rental / Shared Unit': true,
    'Commercial Property': true,
    'Land / Lot for Development': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved states when page opens
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    for (var key in propertyTypes.keys) {
      if (prefs.containsKey('propertyType_$key')) {
        propertyTypes[key] = prefs.getBool('propertyType_$key')!;
      }
    }

    setState(() {}); // Refresh UI after loading
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('propertyType_$key', value); // Save individual toggle
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar for dark theme
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
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Preferred property types',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: propertyTypes.keys.map((type) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: propertyTypes[type],
                          onChanged: (value) async {
                            setState(() {
                              propertyTypes[type] = value!;
                            });
                            await _savePreference(type, value!); // Save persistently
                          },
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
