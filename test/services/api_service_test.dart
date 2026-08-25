import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/pages/utils/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService Tests', () {
    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        final key = message != null
            ? utf8.decode(message.buffer.asUint8List())
            : '';
        if (key == '.env' || key.contains('.env')) {
          return ByteData.view(
            Uint8List.fromList(utf8.encode('''
API_BASE_URL=https://api.example.com
SUPABASE_URL=https://xyz.supabase.co
SUPABASE_PUBLISHABLE_KEY=mock-anon-key-12345
''')).buffer,
          );
        }
        return null;
      });

      await dotenv.load(fileName: '.env');
    });

    test('baseUrl returns environment configuration correctly', () {
      expect(ApiService.baseUrl, 'https://api.example.com');
      expect(ApiService.supabaseUrl, 'https://xyz.supabase.co');
      expect(ApiService.supabasePublishableKey, 'mock-anon-key-12345');
    });

    test('getUri generates correct Uri with https schema', () {
      final uri = ApiService.getUri('get_all_listings.php');
      expect(uri.toString(), 'https://api.example.com/get_all_listings.php');
      expect(uri.scheme, 'https');
      expect(uri.host, 'api.example.com');
      expect(uri.path, '/get_all_listings.php');
    });

    test('getUri cleans leading slashes from path', () {
      final uri = ApiService.getUri('/search_properties.php');
      expect(uri.path, '/search_properties.php');
    });

    test('getUri appends query parameters properly', () {
      final uri = ApiService.getUri('search_properties.php', {
        'term': 'Villa',
        'limit': '10',
        'page': '1',
      });

      expect(uri.queryParameters['term'], 'Villa');
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['page'], '1');
    });

    test('getUri handles empty query parameters gracefully', () {
      final uri = ApiService.getUri('get_my_properties.php', {});
      expect(uri.toString(), 'https://api.example.com/get_my_properties.php');
    });

    test('getUri supports http fallback when scheme is not https', () {
      dotenv.env['API_BASE_URL'] = 'http://localhost';
      final uri = ApiService.getUri('test_route.php');
      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.path, '/test_route.php');
    });
  });
}
