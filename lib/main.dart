import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.html) 'google_maps_loader_web.dart';
import 'welcome_page.dart';
import 'pages/create_account_page.dart';
import 'pages/login_page.dart';
import 'pages/homebuyer_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';
import 'pages/homeowner_page.dart';
import 'pages/admin_page.dart';
import 'pages/utils/role_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load local .env asset if bundled
  try {
    await dotenv.load(fileName: ".env");
  } catch (error) {
    debugPrint('Note: .env asset not bundled locally: $error');
  }

  // 2. Extract configuration or fetch dynamically on Web
  String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  String? supabaseAnonKey =
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
  String? googleMapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  String? googleOAuthId =
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? dotenv.env['GOOGLE_CLIENT_ID'];

  if ((supabaseUrl == null || supabaseAnonKey == null) && kIsWeb) {
    try {
      final response = await http
          .get(Uri.parse('/api/client_config.php'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        supabaseUrl ??= data['supabase_url']?.toString();
        supabaseAnonKey ??= data['supabase_publishable_key']?.toString();
        googleMapsKey ??= data['google_maps_api_key']?.toString();
        googleOAuthId ??= data['google_oauth_client_id']?.toString();

        if (supabaseUrl != null && supabaseUrl.isNotEmpty) {
          dotenv.env['SUPABASE_URL'] = supabaseUrl;
        }
        if (supabaseAnonKey != null && supabaseAnonKey.isNotEmpty) {
          dotenv.env['SUPABASE_PUBLISHABLE_KEY'] = supabaseAnonKey;
        }
        if (googleMapsKey != null && googleMapsKey.isNotEmpty) {
          dotenv.env['GOOGLE_MAPS_API_KEY'] = googleMapsKey;
        }
        if (googleOAuthId != null && googleOAuthId.isNotEmpty) {
          dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] = googleOAuthId;
        }
      }
    } catch (e) {
      debugPrint('Dynamic client config fetch note: $e');
    }
  }

  // 3. Initialize Google Maps non-blockingly
  try {
    loadGoogleMapsApi(
      fallbackApiKey: googleMapsKey,
    ).catchError((err) {
      debugPrint('Google Maps loader note: $err');
    });
  } catch (error) {
    debugPrint('Google Maps initialization note: $error');
  }

  // 4. Initialize Supabase safely
  bool supabaseReady = false;
  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      supabaseReady = true;
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  } else {
    debugPrint('Supabase credentials not yet available; proceeding to UI.');
  }

  // 5. Check for existing session safely
  String startRoute = '/';
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? userEmail = prefs.getString('user_email');
    final String? userType = prefs.getString('user_type');

    bool hasSupabaseSession = false;
    if (supabaseReady) {
      try {
        hasSupabaseSession =
            Supabase.instance.client.auth.currentSession != null;
      } catch (_) {
        hasSupabaseSession = false;
      }
    }

    if (userEmail != null && (hasSupabaseSession || !supabaseReady)) {
      if (userType == 'admin') {
        startRoute = '/admin';
      } else if (userType == 'homeowner') {
        startRoute = '/homeowner';
      } else {
        startRoute = '/';
      }
    }
  } catch (e) {
    debugPrint('Session check note: $e');
  }

  // 6. Launch App
  runApp(MyApp(initialRoute: startRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute; // Receive the route here

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizare AR Real Estate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050608),
        primaryColor: const Color(0xFFD4AF37), // Champagne Gold
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFF3E5AB),
          surface: Color(0xFF0E1118),
          error: Color(0xFFEF4444),
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme.apply(
            bodyColor: const Color(0xFFFFFFFF),
            displayColor: const Color(0xFFFFFFFF),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF050608),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 8,
            shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD4AF37),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD4AF37),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0E1118).withValues(alpha: 0.7),
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          labelStyle: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFFD4AF37),
              width: 1.5,
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF050608),
          body: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth < 480 ? constraints.maxWidth : 480.0;
                final maxH = maxW * (19.5 / 9.0);
                final actualH = constraints.maxHeight < maxH ? constraints.maxHeight : maxH;

                return SizedBox(
                  width: maxW,
                  height: actualH,
                  child: AspectRatio(
                    aspectRatio: 9.0 / 19.5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(constraints.maxWidth > 500 ? 32 : 0),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      // Use the calculated route
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const WelcomePage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const RoleGuard(
              allowedRoles: ['homebuyer', 'homeowner', 'admin'],
              routeName: '/home',
              child: HomeBuyerPage(),
            ),
        '/homebuyer': (context) => const RoleGuard(
              allowedRoles: ['homebuyer', 'homeowner', 'admin'],
              routeName: '/homebuyer',
              child: HomeBuyerPage(),
            ),
        '/favorites': (context) => const RoleGuard(
              allowedRoles: ['homebuyer', 'homeowner', 'admin'],
              routeName: '/favorites',
              child: FavoritesPage(),
            ),
        '/settings': (context) => const RoleGuard(
              allowedRoles: ['homebuyer', 'homeowner', 'admin'],
              routeName: '/settings',
              child: SettingsPage(),
            ),
        '/search': (context) => const RoleGuard(
              allowedRoles: ['homebuyer', 'homeowner', 'admin'],
              routeName: '/search',
              child: SearchPage(),
            ),
        '/homeowner': (context) => const RoleGuard(
              allowedRoles: ['homeowner', 'admin'],
              routeName: '/homeowner',
              child: HomeownerPage(),
            ),
        '/admin': (context) => const RoleGuard(
              allowedRoles: ['admin'],
              routeName: '/admin',
              child: AdminPage(),
            ),
      },
    );
  }
}
