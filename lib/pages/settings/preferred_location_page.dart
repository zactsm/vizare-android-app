import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
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

  String _selectedLocationName = 'Shah Alam, Selangor';
  LatLng _selectedLocationCoords = const LatLng(3.0689, 101.5183);
  bool _showConfirmation = true;

  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  final List<Map<String, dynamic>> _popularLocations = [
    {'name': 'Mont Kiara, Kuala Lumpur', 'lat': 3.1678, 'lng': 101.6548, 'state': 'Kuala Lumpur'},
    {'name': 'KLCC / City Centre, Kuala Lumpur', 'lat': 3.1578, 'lng': 101.7123, 'state': 'Kuala Lumpur'},
    {'name': 'Bangsar / Bangsar South, Kuala Lumpur', 'lat': 3.1292, 'lng': 101.6710, 'state': 'Kuala Lumpur'},
    {'name': 'Damansara Heights, Kuala Lumpur', 'lat': 3.1510, 'lng': 101.6600, 'state': 'Kuala Lumpur'},
    {'name': 'Bukit Tunku (Kenny Hills), Kuala Lumpur', 'lat': 3.1700, 'lng': 101.6833, 'state': 'Kuala Lumpur'},
    {'name': 'Desa ParkCity, Kuala Lumpur', 'lat': 3.1873, 'lng': 101.6322, 'state': 'Kuala Lumpur'},
    {'name': 'Ampang Hilir / Embassy Row, Kuala Lumpur', 'lat': 3.1583, 'lng': 101.7333, 'state': 'Kuala Lumpur'},
    {'name': 'Petaling Jaya, Selangor', 'lat': 3.1073, 'lng': 101.6067, 'state': 'Selangor'},
    {'name': 'Shah Alam, Selangor', 'lat': 3.0689, 'lng': 101.5183, 'state': 'Selangor'},
    {'name': 'Subang Jaya, Selangor', 'lat': 3.0565, 'lng': 101.5851, 'state': 'Selangor'},
    {'name': 'Cyberjaya / Putrajaya, Selangor', 'lat': 2.9213, 'lng': 101.6559, 'state': 'Selangor'},
    {'name': 'George Town, Penang', 'lat': 5.4141, 'lng': 100.3288, 'state': 'Penang'},
    {'name': 'Tanjung Tokong, Penang', 'lat': 5.4578, 'lng': 100.3060, 'state': 'Penang'},
    {'name': 'Johor Bahru / Iskandar Puteri, Johor', 'lat': 1.4927, 'lng': 103.7414, 'state': 'Johor'},
    {'name': 'Kota Kinabalu, Sabah', 'lat': 5.9804, 'lng': 116.0735, 'state': 'Sabah'},
    {'name': 'Kuching, Sarawak', 'lat': 1.5535, 'lng': 110.3592, 'state': 'Sarawak'},
  ];

  final Set<Marker> _markers = {};
  BitmapDescriptor _goldMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);

  @override
  void initState() {
    super.initState();
    _loadCustomPin();
    _loadPreferences();
  }

  Future<void> _loadCustomPin() async {
    try {
      final ByteData byteData =
          await rootBundle.load('assets/images/gold_map_pin.png');
      final Uint8List bytes = byteData.buffer.asUint8List();
      final icon = BitmapDescriptor.bytes(
        bytes,
        width: 36,
        height: 45,
      );
      if (mounted) {
        setState(() {
          _goldMarkerIcon = icon;
          _updateMarker();
        });
      }
    } catch (e) {
      _logger.w('Using default yellow/gold hue marker', error: e);
      _goldMarkerIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      if (mounted) _updateMarker();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final List<Map<String, dynamic>> results = [];

      // 1. Instant matching from popular luxury Malaysian hubs
      final matchedLocal = _popularLocations.where((loc) {
        final name = loc['name'].toString().toLowerCase();
        final state = loc['state'].toString().toLowerCase();
        final q = cleanQuery.toLowerCase();
        return name.contains(q) || state.contains(q);
      }).toList();

      results.addAll(matchedLocal);

      // 2. Geocoder query if no or few results
      try {
        final target = await geocodeAddress(cleanQuery);
        if (target['latitude'] != null && target['longitude'] != null) {
          final double lat = (target['latitude'] as num).toDouble();
          final double lng = (target['longitude'] as num).toDouble();
          final String name = (target['name'] as String?) ?? cleanQuery;

          // Only add if not duplicate
          final bool exists = results.any(
              (r) => (r['lat'] - lat).abs() < 0.001 && (r['lng'] - lng).abs() < 0.001);
          if (!exists) {
            results.insert(0, {
              'name': name,
              'lat': lat,
              'lng': lng,
              'state': 'Custom Geocoded Match',
            });
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> location) {
    final double lat = (location['lat'] as num).toDouble();
    final double lng = (location['lng'] as num).toDouble();
    final String name = location['name'] as String;

    FocusScope.of(context).unfocus();

    setState(() {
      _selectedLocationCoords = LatLng(lat, lng);
      _selectedLocationName = name;
      _searchController.text = name;
      _searchResults = [];
      _showConfirmation = true;
      _updateMarker();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocationCoords, 14.0),
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final double? lat = prefs.getDouble('pref_lat');
    final double? lng = prefs.getDouble('pref_lng');
    final String? name = prefs.getString('pref_name');

    if (lat != null && lng != null && name != null) {
      if (mounted) {
        setState(() {
          _selectedLocationCoords = LatLng(lat, lng);
          _selectedLocationName = name;
          _showConfirmation = true;
          _updateMarker();
        });
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocationCoords, 14.0),
        );
      });
    } else {
      _updateMarker();
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('pref_lat', _selectedLocationCoords.latitude);
    await prefs.setDouble('pref_lng', _selectedLocationCoords.longitude);
    await prefs.setString('pref_name', _selectedLocationName);

    _logger.i('Saved location: $_selectedLocationName ($_selectedLocationCoords)');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Location preference updated!",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: VizareColors.emeraldGreen,
        duration: const Duration(seconds: 2),
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
          icon: _goldMarkerIcon,
          infoWindow: InfoWindow(title: _selectedLocationName),
        ),
      );
    });
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocationCoords = position;
      _searchResults = [];
      _updateMarker();
    });

    try {
      final name = await reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _selectedLocationName = name.isNotEmpty
              ? name
              : 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          _searchController.text = _selectedLocationName;
          _showConfirmation = true;
        });
      }
    } catch (e) {
      _logger.e("Error getting address from tap", error: e);
      if (mounted) {
        setState(() {
          _selectedLocationName =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          _showConfirmation = true;
        });
      }
    }
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
            title: 'Preferred Location',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                    child: Text(
                      'Search a city or tap anywhere on the map to center your curated recommendations.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isDark
                            ? VizareColors.textSecondary
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ),

                  // Search Bar with Homebuyer SearchPage Glass Aesthetic
                  VisionGlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: 28.0,
                    backgroundColor: isDark
                        ? VizareColors.obsidianSurface.withValues(alpha: 0.88)
                        : Colors.white.withValues(alpha: 0.95),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search city, state, or neighborhood...',
                        hintStyle: GoogleFonts.inter(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : const Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0, horizontal: 8.0),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: VizareColors.champagneGold,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : (_isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: VizareColors.champagneGold,
                                      ),
                                    ),
                                  )
                                : null),
                      ),
                    ),
                  ),

                  // Autocomplete Live Results Dropdown
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    VisionGlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      borderRadius: 18.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _searchResults.map((result) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectSearchResult(result),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 10.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: VizareColors.champagneGold
                                            .withValues(alpha: 0.12),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: VizareColors.champagneGold,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result['name'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (result['state'] != null)
                                            Text(
                                              result['state'] ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: isDark
                                                    ? VizareColors.textMuted
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.north_west_rounded,
                                      size: 16,
                                      color: VizareColors.champagneGold,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  if (_showConfirmation) ...[
                    VisionGlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: VizareColors.champagneGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedLocationName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14.0),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.38,
                              child: GoogleMap(
                                style: isDark ? kVizareDarkMapStyle : null,
                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer(),
                                  ),
                                },
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
                          const SizedBox(height: 10),
                          Text(
                            "Tap anywhere on the spatial map to pinpoint an exact neighborhood.",
                            style: GoogleFonts.inter(
                              color: isDark ? VizareColors.textMuted : const Color(0xFF64748B),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    LuxuryGradientButton(
                      text: 'Save Vicinity Preference',
                      icon: Icons.check_circle_rounded,
                      onPressed: _savePreferences,
                    ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
