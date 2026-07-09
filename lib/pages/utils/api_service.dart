import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final Logger _logger = Logger();
  static const String avatarsBucket = 'avatars';
  static const String propertyAssetsBucket = 'property-assets';
  static const String supportAttachmentsBucket = 'support-attachments';

  static String get baseUrl {
    if (kIsWeb) {
      return '/api';
    }

    return dotenv.env['API_BASE_URL'] ?? '';
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabasePublishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  static Future<String?> uploadAvatar(File file) =>
      _uploadFile(file, avatarsBucket);

  static Future<String?> uploadPropertyAsset(File file) =>
      _uploadFile(file, propertyAssetsBucket);

  static Future<String?> uploadSupportAttachment(File file) =>
      _uploadFile(file, supportAttachmentsBucket, signedUrl: true);

  static Future<void> deleteAvatarByUrl(String url) =>
      _deleteFileByUrl(url, avatarsBucket);

  static Future<void> deletePropertyAssetByUrl(String url) =>
      _deleteFileByUrl(url, propertyAssetsBucket);

  static Future<String?> _uploadFile(
    File file,
    String bucket, {
    bool signedUrl = false,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('A Supabase session is required to upload files.');
      }
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(fileName, file);

      if (signedUrl) {
        return await Supabase.instance.client.storage
            .from(bucket)
            .createSignedUrl(fileName, 60 * 60 * 24 * 7);
      }
      return Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      _logger.e("Supabase Upload Error", error: e);
      return null;
    }
  }

  static Future<void> _deleteFileByUrl(String url, String bucket) async {
    final objectPath = _extractObjectPath(url, bucket);
    if (objectPath == null) {
      _logger.w('Skipping delete for non-matching or invalid storage URL: $url');
      return;
    }

    try {
      await Supabase.instance.client.storage.from(bucket).remove([objectPath]);
    } catch (e) {
      _logger.e("Supabase Delete Error", error: e);
    }
  }

  static String? _extractObjectPath(String url, String expectedBucket) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final bucketIndex = uri.pathSegments.indexOf(expectedBucket);
    if (bucketIndex == -1 || bucketIndex + 1 >= uri.pathSegments.length) {
      return null;
    }

    final objectPath = uri.pathSegments.sublist(bucketIndex + 1).join('/');
    if (objectPath.isEmpty) {
      return null;
    }

    return objectPath;
  }

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

  static Map<String, String> _authenticatedHeaders(
      [Map<String, String>? headers]) {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      ...?headers,
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  static Future<void> restoreSession(
      String? accessToken, String? refreshToken) async {
    if (accessToken == null || refreshToken == null) return;
    await Supabase.instance.client.auth.setSession(refreshToken);
  }

  static Future<http.Response> post(String script, {Map<String, String>? body, Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$script');
    _logger.d('POST to $url with body: $body');
    try {
      final response = await http.post(
        url,
        body: body,
        headers: _authenticatedHeaders(headers),
      );
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
      final response = await http.get(url, headers: _authenticatedHeaders());
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
