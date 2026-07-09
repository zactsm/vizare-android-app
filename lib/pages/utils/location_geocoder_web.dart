import 'dart:convert';
import 'dart:js_interop';

@JS('vizareGeocodeAddress')
external JSPromise<JSString> _geocodeAddress(JSString query);

@JS('vizareReverseGeocode')
external JSPromise<JSString> _reverseGeocode(
  JSNumber latitude,
  JSNumber longitude,
);

Future<Map<String, dynamic>> geocodeAddress(String query) async {
  final result = (await _geocodeAddress(query.toJS).toDart).toDart;
  return Map<String, dynamic>.from(jsonDecode(result));
}

Future<String> reverseGeocode(double latitude, double longitude) async {
  final result = (
    await _reverseGeocode(latitude.toJS, longitude.toJS).toDart
  ).toDart;
  final payload = Map<String, dynamic>.from(jsonDecode(result));
  return payload['name']?.toString() ?? 'Custom Location';
}
