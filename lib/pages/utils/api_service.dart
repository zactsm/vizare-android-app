import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  static final Logger _logger = Logger();

  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? '';

  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryUploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  static Uri getUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final base = baseUrl.replaceFirst(RegExp(r'https?://'), '');
    final isHttps = baseUrl.startsWith('https');

    if (isHttps) {
      return Uri.https(base, cleanPath, queryParameters);
    } else {
      return Uri.http(base, cleanPath, queryParameters);
    }
  }

  static Future<http.Response> post(String script, {Map<String, String>? body, Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$script');
    _logger.d('POST to $url with body: $body');
    try {
      final response = await http.post(url, body: body, headers: headers);
      _logResponse(response);
      return response;
    } catch (e) {
      _logger.e('Error during POST to $url', error: e);
      rethrow;
    }
  }

  static Future<http.Response> get(String script, [Map<String, dynamic>? queryParameters]) async {
    final baseUri = Uri.parse('$baseUrl/$script');
    final url = baseUri.replace(queryParameters: {
      ...baseUri.queryParameters,
      ...?queryParameters?.map((key, value) => MapEntry(key, value.toString())),
    });
    
    _logger.d('GET to $url');
    try {
      final response = await http.get(url);
      _logResponse(response);
      return response;
    } catch (e) {
      _logger.e('Error during GET to $url', error: e);
      rethrow;
    }
  }

  static void _logResponse(http.Response response) {
    if (response.statusCode == 200) {
      _logger.i('Response 200 from ${response.request?.url}');
    } else {
      _logger.w('Response ${response.statusCode} from ${response.request?.url}: ${response.body}');
    }
  }
}
