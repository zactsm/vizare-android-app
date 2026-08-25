import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (error) {
    debugPrint('Unable to load .env asset: $error');
  }

  try {
    await loadGoogleMapsApi(
      fallbackApiKey: dotenv.env['GOOGLE_MAPS_API_KEY'],
    );
  } catch (error) {
    debugPrint('Google Maps initialization failed: $error');
  }

  // Safely extract the variables
  final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  final String? supabaseAnonKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  // Initialize Supabase only when the credentials are available.
  if (supabaseUrl == null || supabaseAnonKey == null) {
    debugPrint('Supabase credentials are missing; continuing without backend initialization.');
  } else {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }

  // Check for existing session
  final prefs = await SharedPreferences.getInstance();
  final String? userEmail = prefs.getString('user_email');
  final String? userType = prefs.getString('user_type');

  // Decide where to start
  String startRoute = '/'; // Default to Welcome Page

  final hasSupabaseSession =
      Supabase.instance.client.auth.currentSession != null;
  if (userEmail != null && hasSupabaseSession) {
    // User is logged in, check type
    if (userType == 'admin'){
      startRoute = '/admin';
    } else if (userType == 'homeowner') {
      startRoute = '/homeowner';
    } else {
      // Default to homebuyer if type is missing or homebuyer
      startRoute = '/';
    }
  }

  // Pass the route to the app
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
          secondary: Color(0xFFDF00FF),
          surface: Color(0xFF0E1118),
          error: Color(0xFFEF4444),
        ),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
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
        '/home': (context) => const HomeBuyerPage(),
        '/homebuyer': (context) => const HomeBuyerPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/settings': (context) => const SettingsPage(),
        '/search': (context) => const SearchPage(),
        '/homeowner': (context) => const HomeownerPage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}
