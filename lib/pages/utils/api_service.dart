import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final Logger _logger = Logger();
  static const String defaultApiBaseUrl = 'https://vizare-web.vercel.app/api';
  static const String avatarsBucket = 'avatars';
  static const String propertyAssetsBucket = 'property-assets';
  static const String supportAttachmentsBucket = 'support-attachments';

  static String get baseUrl {
    final envBase =
        (dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null)?.trim();
    if (envBase != null && envBase.isNotEmpty) {
      return envBase.endsWith('/')
          ? envBase.substring(0, envBase.length - 1)
          : envBase;
    }

    return defaultApiBaseUrl;
  }

  static String get supabaseUrl =>
      (dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null) ?? '';
  static String get supabasePublishableKey =>
      (dotenv.isInitialized
          ? dotenv.env['SUPABASE_PUBLISHABLE_KEY']
          : null) ??
      '';

  static Future<String?> uploadAvatar(PlatformFile file) =>
      _uploadFile(file, avatarsBucket);

  static Future<String?> uploadPropertyAsset(PlatformFile file) =>
      _uploadFile(file, propertyAssetsBucket);

  static Future<String?> uploadSupportAttachment(PlatformFile file) =>
      _uploadFile(file, supportAttachmentsBucket, signedUrl: true);

  static Future<void> deleteAvatarByUrl(String url) =>
      _deleteFileByUrl(url, avatarsBucket);

  static Future<void> deletePropertyAssetByUrl(String url) =>
      _deleteFileByUrl(url, propertyAssetsBucket);

  static Future<String?> _uploadFile(
    PlatformFile file,
    String bucket, {
    bool signedUrl = false,
  }) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) {
        _logger.e("Cannot upload file: bytes are null");
        return null;
      }

      String? userId;
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      final extension = file.name.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final objectPath =
          userId == null ? fileName : '$userId/$fileName';

      await Supabase.instance.client.storage.from(bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _resolveContentType(extension),
            ),
          );

      if (signedUrl) {
        return await Supabase.instance.client.storage
            .from(bucket)
            .createSignedUrl(objectPath, 900); // 15 minutes validity
      }

      return Supabase.instance.client.storage.from(bucket).getPublicUrl(objectPath);
    } catch (e) {
      _logger.e("Supabase Upload Error", error: e);
      return null;
    }
  }

  static String _resolveContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'glb':
        return 'model/gltf-binary';
      case 'gltf':
        return 'model/gltf+json';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<void> _deleteFileByUrl(String url, String bucket) async {
    final objectPath = _extractObjectPath(url, bucket);
    if (objectPath == null) return;

    // Ensure users can only delete their own uploaded files under their userId folder
    String? currentUserId;
    try {
      currentUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {}

    if (currentUserId != null && !objectPath.startsWith('$currentUserId/')) {
      _logger.w("Denied attempt to delete unauthorized storage object: $objectPath");
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
    final base = baseUrl;
    final fullUrl = base.endsWith('/') ? '$base$cleanPath' : '$base/$cleanPath';
    final parsed = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return parsed.replace(
        queryParameters: {
          ...parsed.queryParameters,
          ...queryParameters
              .map((key, value) => MapEntry(key, value.toString())),
        },
      );
    }
    return parsed;
  }

  static Map<String, String> _authenticatedHeaders(
      [Map<String, String>? headers]) {
    String? accessToken;
    try {
      accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      accessToken = null;
    }
    return {
      ...?headers,
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  static Future<void> restoreSession(
      String? accessToken, String? refreshToken) async {
    if (accessToken == null || refreshToken == null) return;
    try {
      await Supabase.instance.client.auth.setSession(refreshToken);
    } catch (e) {
      _logger.w("Session restore notice: $e");
    }
  }

  static final Map<String, _CachedResponse> _responseCache = {};

  static void clearCache() {
    _responseCache.clear();
  }

  static Future<http.Response> post(String script,
      {Map<String, String>? body, Map<String, String>? headers}) async {
    final base = baseUrl;
    final cleanScript = script.startsWith('/') ? script.substring(1) : script;
    final url = Uri.parse(
        base.endsWith('/') ? '$base$cleanScript' : '$base/$cleanScript');

    if (kDebugMode) {
      final sanitized = Map<String, String>.from(body ?? {});
      for (final key in [
        'password',
        'current_password',
        'new_password',
        'token',
        'access_token',
        'refresh_token'
      ]) {
        if (sanitized.containsKey(key)) sanitized[key] = '******';
      }
      _logger.d('POST to $url with body: $sanitized');
    }
    try {
      final response = await http
          .post(
            url,
            body: body,
            headers: _authenticatedHeaders(headers),
          )
          .timeout(const Duration(seconds: 15));
      _logResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _responseCache.clear(); // Safe invalidation on successful mutation
      }
      return response;
    } catch (e) {
      _logger.e('Error during POST to $url', error: e);
      rethrow;
    }
  }

  static Future<http.Response> get(String script,
      [Map<String, dynamic>? queryParameters]) async {
    final base = baseUrl;
    final cleanScript = script.startsWith('/') ? script.substring(1) : script;
    final baseUri = Uri.parse(
        base.endsWith('/') ? '$base$cleanScript' : '$base/$cleanScript');

    final url = baseUri.replace(queryParameters: {
      ...baseUri.queryParameters,
      ...?queryParameters
          ?.map((key, value) => MapEntry(key, value.toString())),
    });

    final cacheKey = url.toString();
    final now = DateTime.now();
    if (_responseCache.containsKey(cacheKey)) {
      final cached = _responseCache[cacheKey]!;
      if (now.difference(cached.timestamp).inSeconds < 15) {
        _logger.d('Serving cached GET for $url');
        return cached.response;
      }
    }

    _logger.d('GET to $url');
    try {
      final response = await http
          .get(url, headers: _authenticatedHeaders())
          .timeout(const Duration(seconds: 15));
      _logResponse(response);
      if (response.statusCode == 200) {
        _responseCache[cacheKey] = _CachedResponse(response, now);
      }
      return response;
    } catch (e) {
      _logger.e('Error during GET to $url', error: e);
      rethrow;
    }
  }

  static void _logResponse(http.Response response) {
    if (!kDebugMode) return;
    if (response.statusCode == 200) {
      _logger.i('Response 200 from ${response.request?.url}');
    } else {
      _logger.w('Response ${response.statusCode} from ${response.request?.url}');
    }
  }
}

class _CachedResponse {
  final http.Response response;
  final DateTime timestamp;
  _CachedResponse(this.response, this.timestamp);
}
