import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/location_geocoder.dart';

class PreferredLocationPage extends StatefulWidget {
  const PreferredLocationPage({super.key});

  @override
  State<PreferredLocationPage> createState() => _PreferredLocationPageState();
}

class _PreferredLocationPageState extends State<PreferredLocationPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final _logger = Logger();

  // Default to Shah Alam (used if nothing is saved)
  String _selectedLocationName = 'Shah Alam, Selangor';
  LatLng _selectedLocationCoords = const LatLng(3.0689, 101.5183);
  bool _showConfirmation = true;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Load saved settings instead of just using default
    _loadPreferences();
  }

  // --- Logic ---

  // 1. LOAD SAVED DATA
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final double? lat = prefs.getDouble('pref_lat');
    final double? lng = prefs.getDouble('pref_lng');
    final String? name = prefs.getString('pref_name');

    if (lat != null && lng != null && name != null) {
      // Found saved data, update UI
      setState(() {
        _selectedLocationCoords = LatLng(lat, lng);
        _selectedLocationName = name;
        _showConfirmation = true;
        _updateMarker();
      });

      // Wait a bit for map to initialize, then move camera
      Future.delayed(const Duration(milliseconds: 500), () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocationCoords, 14.0),
        );
      });
    } else {
      // No saved data, just show default marker
      _updateMarker();
    }
  }

  // 2. SAVE DATA
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('pref_lat', _selectedLocationCoords.latitude);
    await prefs.setDouble('pref_lng', _selectedLocationCoords.longitude);
    await prefs.setString('pref_name', _selectedLocationName);

    _logger.i('Saved location: $_selectedLocationName ($_selectedLocationCoords)');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location preference saved!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    Navigator.of(context).pop(true);
  }

  void _updateMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selectedLocation'),
          position: _selectedLocationCoords,
          infoWindow: InfoWindow(title: _selectedLocationName),
        ),
      );
    });
  }

  // Handle tapping on the map
  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocationCoords = position;
      _updateMarker(); // Move the red pin immediately
    });

    // Animate camera to the tapped spot
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));

    try {
      final formattedName = await reverseGeocode(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _selectedLocationName = formattedName;
        _updateMarker();
      });
    } catch (e) {
      _logger.e('Error finding address for tapped location', error: e);
      setState(() {
        _selectedLocationName = "Custom Location";
      });
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    try {
      final location = await geocodeAddress(query);
      final coords = LatLng(
        location['latitude'] as double,
        location['longitude'] as double,
      );

      setState(() {
        _selectedLocationCoords = coords;
        _selectedLocationName = location['name'] as String;
        _showConfirmation = true;
        _updateMarker();
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: coords, zoom: 14.0),
        ),
      );
    } catch (e) {
      _logger.e('Error searching location', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not find location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferred location',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _searchController,
                onSubmitted: (_) => _searchLocation(),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_showConfirmation) ...[
                const Text(
                  'Is this correct?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedLocationName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocationCoords,
                        zoom: 14.0,
                      ),
                      markers: _markers,
                      onTap: _onMapTapped,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: true,
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Tap anywhere on the map to pinpoint exact location.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(26.0, 16.0, 26.0, 26.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _savePreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6B3F9),
              foregroundColor: const Color(0xFF121212),
              minimumSize: const Size(200, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
