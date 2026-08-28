import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.html) 'google_maps_loader_web.dart';
import 'welcome_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/create_account_page.dart';
import 'pages/login_page.dart';
import 'pages/homebuyer_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';
import 'pages/homeowner_page.dart';
import 'pages/admin_page.dart';
import 'pages/settings/tos_page.dart';
import 'pages/settings/privacy_policy_page.dart';
import 'pages/utils/app_theme.dart';
import 'pages/utils/role_guard.dart';
import 'pages/utils/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load local .env asset if bundled
  try {
    await dotenv.load(fileName: ".env");
  } catch (error) {
    debugPrint('Note: .env asset not bundled locally: $error');
  }

  // Ensure dotenv is initialized even if .env file is missing from bundle
  if (!dotenv.isInitialized) {
    await dotenv.load(mergeWith: {'API_BASE_URL': ApiService.defaultApiBaseUrl});
  }

  // 2. Extract configuration or fetch dynamically from Vercel API Gateway
  String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  String? supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
  String? googleMapsKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  String? googleOAuthId =
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID'] ?? dotenv.env['GOOGLE_CLIENT_ID'];

  if (supabaseUrl == null || supabasePublishableKey == null) {
    try {
      final base = ApiService.baseUrl;
      final configUri = Uri.parse(
          base.endsWith('/') ? '${base}client_config.php' : '$base/client_config.php');
      final response = await http
          .get(configUri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        supabaseUrl ??= data['supabase_url']?.toString();
        supabasePublishableKey ??= data['supabase_publishable_key']?.toString();
        googleMapsKey ??= data['google_maps_api_key']?.toString();
        googleOAuthId ??= data['google_oauth_client_id']?.toString();

        if (supabaseUrl != null && supabaseUrl.isNotEmpty) {
          dotenv.env['SUPABASE_URL'] = supabaseUrl;
        }
        if (supabasePublishableKey != null && supabasePublishableKey.isNotEmpty) {
          dotenv.env['SUPABASE_PUBLISHABLE_KEY'] = supabasePublishableKey;
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
      supabasePublishableKey != null &&
      supabasePublishableKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabasePublishableKey,
      );
      supabaseReady = true;
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  } else {
    debugPrint('Supabase credentials not yet available; proceeding to UI.');
  }

  // 5. Check for existing session safely using Hardware-Backed Secure Storage
  String startRoute = '/';
  try {
    // Perform one-time legacy token migration to hardware-backed secure storage
    await ApiService.migrateLegacyTokens();

    final prefs = await SharedPreferences.getInstance();
    final String? userEmail = prefs.getString('user_email');
    final String? userType = prefs.getString('user_type');
    final String? accessToken = await ApiService.getStoredAccessToken();
    final String? refreshToken = await ApiService.getStoredRefreshToken();

    if (accessToken != null || refreshToken != null) {
      await ApiService.restoreSession(accessToken, refreshToken);
    }

    bool hasSupabaseSession = false;
    if (supabaseReady) {
      try {
        hasSupabaseSession =
            Supabase.instance.client.auth.currentSession != null;
      } catch (_) {
        hasSupabaseSession = false;
      }
    }

    bool isAuthenticated = false;
    if (userEmail != null && (hasSupabaseSession || !supabaseReady || accessToken != null)) {
      isAuthenticated = true;
      if (userType == 'admin') {
        startRoute = '/admin';
      } else if (userType == 'homeowner') {
        startRoute = '/homeowner';
      } else {
        startRoute = '/';
      }
    }

    // 6. Load theme mode (defaults to Obsidian Dark for unauthenticated guest users)
    await AppThemeController.instance
        .loadThemeMode(isAuthenticated: isAuthenticated);
  } catch (e) {
    debugPrint('Session check note: $e');
    await AppThemeController.instance.loadThemeMode(isAuthenticated: false);
  }

  // 7. Launch App
  runApp(MyApp(initialRoute: startRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute; // Receive the route here

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'VIZARE',
          debugShowCheckedModeBanner: false,
          themeMode: AppThemeController.instance.themeMode,
          theme: VizareTheme.lightTheme,
          darkTheme: VizareTheme.darkTheme,
          builder: (context, child) {
        if (!kIsWeb) {
          return child ?? const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF050608),
          body: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobileBrowser = constraints.maxWidth <= 500;

                if (isMobileBrowser) {
                  return child ?? const SizedBox.shrink();
                }

                // iPhone 16 / 17 Display Specs (393 x 852 logical points, 19.5:9 ratio)
                const double targetWidth = 393.0;
                const double targetHeight = 852.0;
                const double topSafeArea = 72.0; // Dynamic Island / Status Bar
                const double bottomSafeArea = 34.0; // Home indicator

                // PNG Mockup Dimensions (image aspect ratio: 1300x2642, screen: 1244x2606)
                const double frameWidth = targetWidth * (1300.0 / 1244.0); // ~410.7
                const double frameHeight = targetHeight * (2642.0 / 2606.0); // ~863.8
                const double sideOffset = (frameWidth - targetWidth) / 2.0; // ~8.85
                const double vertOffset = (frameHeight - targetHeight) / 2.0; // ~5.89

                return FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 24.0),
                    width: frameWidth,
                    height: frameHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(55.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.75),
                          blurRadius: 40,
                          spreadRadius: 8,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color:
                              VizareColors.champagneGold.withValues(alpha: 0.08),
                          blurRadius: 30,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Interactive Flutter App Screen (clipped inside mockup bezel)
                        Positioned(
                          top: vertOffset,
                          bottom: vertOffset,
                          left: sideOffset,
                          right: sideOffset,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50.0),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                size: const Size(targetWidth, targetHeight),
                                padding: const EdgeInsets.only(
                                  top: topSafeArea,
                                  bottom: bottomSafeArea,
                                ),
                                viewPadding: const EdgeInsets.only(
                                  top: topSafeArea,
                                  bottom: bottomSafeArea,
                                ),
                                textScaler: (MediaQuery.maybeOf(context)?.textScaler ?? const TextScaler.linear(1.0)).clamp(minScaleFactor: 1.0, maxScaleFactor: 2.0),
                                devicePixelRatio: 3.0,
                              ),
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),

                        // 2. Realistic iPhone 17 Pro Mockup Frame Overlay
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/iphone17pro.png',
                              width: frameWidth,
                              height: frameHeight,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
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
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/tos': (context) => const TOSPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
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
      },
    );
  }
}
