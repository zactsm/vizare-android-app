import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.html) 'google_maps_loader_web.dart';
import 'welcome_page.dart';
import 'pages/create_account_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
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
      title: 'AR Real Estate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      // Use the calculated route
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const WelcomePage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
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
