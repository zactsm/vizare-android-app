import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final Logger _logger = Logger();
  static const String defaultApiBaseUrl = 'https://vizare-web.vercel.app/api';
  static const String avatarsBucket = 'avatars';
  static const String propertyAssetsBucket = 'property-assets';
  static const String supportAttachmentsBucket = 'support-attachments';

  static String sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final trimmed = url.trim();

    // Normalize Unsplash URLs: remove auto=format and ensure fm=jpg is set
    // (CanvasKit requires a concrete decodable format; webp/avif may not decode)
    String normalized = trimmed;
    if (normalized.contains('images.unsplash.com')) {
      try {
        final uri = Uri.parse(normalized);
        final queryMap = Map<String, String>.from(uri.queryParameters);
        queryMap.remove('auto');
        queryMap['fm'] = 'jpg';
        normalized = uri.replace(queryParameters: queryMap).toString();
      } catch (_) {
        normalized = normalized.replaceAll('auto=format', 'fm=jpg');
        if (!normalized.contains('fm=')) {
          normalized = normalized.contains('?')
              ? '$normalized&fm=jpg'
              : '$normalized?fm=jpg';
        }
      }
    }

    // On Flutter Web, CanvasKit uses fetch() in cors mode to load images.
    // External image servers (Supabase Storage, Unsplash) may not return the
    // Access-Control-Allow-Origin header needed for the browser to accept the
    // response. Route external images through our Vercel proxy which fetches
    // server-side and re-serves with CORS headers.
    if (kIsWeb && _isExternalImageUrl(normalized)) {
      final encoded = Uri.encodeComponent(normalized);
      return '$baseUrl/image-proxy?url=$encoded';
    }

    return normalized;
  }

  /// Returns true for image URLs that require CORS proxying on web.
  static bool _isExternalImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      return host.endsWith('.supabase.co') ||
          host.endsWith('.supabase.com') ||
          host == 'images.unsplash.com' ||
          host == 'cdn.unsplash.com' ||
          host == 'plus.unsplash.com';
    } catch (_) {
      return false;
    }
  }

  static String get baseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin.startsWith('http')) {
          final host = Uri.base.host;
          if (host.endsWith('vercel.app') ||
              host == 'vizare.app' ||
              host.endsWith('.vizare.app')) {
            return '$origin/api';
          }
        }
      } catch (_) {}
    }

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

  static String? _cachedAccessToken;
  static String? get cachedAccessToken => _cachedAccessToken;

  static Future<String?> _uploadFile(
    PlatformFile file,
    String bucket, {
    bool signedUrl = false,
  }) async {
    try {
      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null && file.path!.isNotEmpty) {
        try {
          final ioFile = File(file.path!);
          if (await ioFile.exists()) {
            bytes = await ioFile.readAsBytes();
          }
        } catch (e) {
          _logger.e("Failed to read file from path ${file.path}", error: e);
        }
      }

      if (bytes == null || bytes.isEmpty) {
        _logger.e("Cannot upload file: bytes are null or empty");
        return null;
      }

      final extension = file.name.split('.').last;
      final contentType = _resolveContentType(extension);

      // Strategy 1: Attempt direct upload to Supabase storage if client has active Supabase user session
      String? userId;
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      if (userId != null && userId.isNotEmpty) {
        try {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
          final objectPath = '$userId/$fileName';

          await Supabase.instance.client.storage.from(bucket).uploadBinary(
                objectPath,
                bytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: contentType,
                ),
              );

          if (signedUrl) {
            return await Supabase.instance.client.storage
                .from(bucket)
                .createSignedUrl(objectPath, 900); // 15 minutes validity
          }

          return Supabase.instance.client.storage.from(bucket).getPublicUrl(objectPath);
        } catch (clientErr) {
          _logger.w("Direct Supabase storage upload failed, attempting fallback API upload: $clientErr");
        }
      }

      // Strategy 2: Upload via API gateway (/api/upload_asset.php) using service-role
      try {
        final base64Data = base64Encode(bytes);
        final response = await post(
          'upload_asset.php',
          body: {
            'bucket': bucket,
            'file_name': file.name,
            'file_data': base64Data,
            'content_type': contentType,
            'signed_url': signedUrl.toString(),
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final url = data['url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        } else {
          _logger.e("API upload returned ${response.statusCode}: ${response.body}");
        }
      } catch (apiErr) {
        _logger.e("API upload failed", error: apiErr);
      }

      return null;
    } catch (e) {
      _logger.e("Upload Error", error: e);
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
    accessToken ??= _cachedAccessToken;

    return {
      ...?headers,
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  static Future<void> restoreSession(
      String? accessToken, String? refreshToken) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      _cachedAccessToken = accessToken;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
      } catch (_) {}
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', refreshToken);
        await Supabase.instance.client.auth.setSession(refreshToken);
      } catch (e) {
        _logger.w("Session restore notice: $e");
      }
    }
  }

  static Future<void> clearAuthSession() async {
    _cachedAccessToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (_) {}
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
          .timeout(const Duration(seconds: 30));
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
          .timeout(const Duration(seconds: 30));
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
