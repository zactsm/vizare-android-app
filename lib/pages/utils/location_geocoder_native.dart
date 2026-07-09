import 'package:geocoding/geocoding.dart';

Future<Map<String, dynamic>> geocodeAddress(String query) async {
  final locations = await locationFromAddress(query);
  if (locations.isEmpty) throw StateError('Location could not be found.');

  final location = locations.first;
  final name = await reverseGeocode(
    location.latitude,
    location.longitude,
  );
  return {
    'latitude': location.latitude,
    'longitude': location.longitude,
    'name': name,
  };
}

Future<String> reverseGeocode(double latitude, double longitude) async {
  final placemarks = await placemarkFromCoordinates(latitude, longitude);
  if (placemarks.isEmpty) return 'Custom Location';

  final address = placemarks.first;
  return [
    address.name,
    address.street,
    address.locality,
    address.administrativeArea,
  ].whereType<String>().where((part) => part.isNotEmpty).toSet().join(', ');
}
