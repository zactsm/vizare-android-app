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
    _searchController.dispose();
    super.dispose();
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

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    try {
      final target = await geocodeAddress(query);

      if (target['latitude'] != null && target['longitude'] != null) {
        final double lat = (target['latitude'] as num).toDouble();
        final double lng = (target['longitude'] as num).toDouble();
        final String name = (target['name'] as String?) ?? query;

        if (mounted) {
          setState(() {
            _selectedLocationCoords = LatLng(lat, lng);
            _selectedLocationName = name;
            _showConfirmation = true;
            _updateMarker();
          });
        }

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocationCoords, 14.0),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Location not found. Please try another query.",
                  style: GoogleFonts.inter()),
              backgroundColor: VizareColors.crimsonRed,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e("Error searching location", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error locating address: $e", style: GoogleFonts.inter()),
            backgroundColor: VizareColors.crimsonRed,
          ),
        );
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
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
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
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? VizareColors.obsidianSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _searchLocation(),
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search city, state, or region...',
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? VizareColors.textMuted : const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: VizareColors.champagneGold,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: VizareColors.champagneGold,
                            size: 18,
                          ),
                          onPressed: _searchLocation,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0, horizontal: 16.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
