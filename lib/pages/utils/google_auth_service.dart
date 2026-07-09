import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.email,
    required this.userType,
    required this.hasPassword,
  });

  final String email;
  final String userType;
  final bool hasPassword;
}

class GoogleAuthService {
  static GoogleSignIn? _googleSignIn;

  static Future<GoogleAuthResult?> signIn({String? requestedRole}) async {
    final googleSignIn = await _client();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token.');
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    final response = await ApiService.post(
      'google_login.php',
      body: {
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'Google User',
        if (requestedRole != null) 'role': requestedRole,
      },
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AuthException(
        payload['message']?.toString() ?? 'Google sign-in failed.',
      );
    }

    final userType = payload['user_type']?.toString() ?? 'homebuyer';
    final hasPassword = payload['has_password'] == true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', googleUser.email);
    await prefs.setString('user_type', userType);
    await prefs.setBool('has_password', hasPassword);

    return GoogleAuthResult(
      email: googleUser.email,
      userType: userType,
      hasPassword: hasPassword,
    );
  }

  static Future<void> signOut() async {
    try {
      await (await _client()).signOut();
    } catch (_) {
      // Google cleanup is optional after the Supabase session is removed.
    }
  }

  static Future<GoogleSignIn> _client() async {
    if (_googleSignIn != null) return _googleSignIn!;

    String? clientId = dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ??
        dotenv.env['GOOGLE_CLIENT_ID'];
    if (kIsWeb && (clientId == null || clientId.trim().isEmpty)) {
      final response = await ApiService.get('client_config.php');
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        clientId = payload['google_oauth_client_id']?.toString();
      }
    }

    if (kIsWeb && (clientId == null || clientId.trim().isEmpty)) {
      throw StateError(
        'GOOGLE_OAUTH_CLIENT_ID is not configured in Vercel.',
      );
    }

    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? clientId!.trim() : null,
      scopes: const ['email', 'profile'],
    );
    return _googleSignIn!;
  }
}
