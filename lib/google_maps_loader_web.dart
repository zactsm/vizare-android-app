import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<void> loadGoogleMapsApi({String? fallbackApiKey}) async {
  if (html.document.querySelector('script[data-vizare-google-maps]') != null) {
    return;
  }

  var apiKey = fallbackApiKey?.trim() ?? '';
  if (apiKey.isEmpty) {
    final response = await html.HttpRequest.request(
      '/api/client_config.php',
      method: 'GET',
    );
    if (response.status != 200) {
      throw StateError('Unable to load the Google Maps configuration.');
    }
    final payload = jsonDecode(response.responseText ?? '{}');
    apiKey = payload['google_maps_api_key']?.toString().trim() ?? '';
  }

  if (apiKey.isEmpty) {
    throw StateError('The Google Maps API key is not configured.');
  }

  final completer = Completer<void>();
  final script = html.ScriptElement();
  script.dataset['vizareGoogleMaps'] = 'true';
  script.async = true;
  script.defer = true;
  script.src =
      'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey)}';
  script.onLoad.first.then((_) => completer.complete());
  script.onError.first.then(
    (_) => completer.completeError(
      StateError('The Google Maps JavaScript API failed to load.'),
    ),
  );

  html.document.head!.append(script);
  await completer.future.timeout(const Duration(seconds: 15));
}
