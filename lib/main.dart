import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/utils/api_service.dart';

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
  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: ApiService.supabaseUrl,
    anonKey: ApiService.supabaseAnonKey,
  );

  // Check for existing session
  final prefs = await SharedPreferences.getInstance();
  final String? userEmail = prefs.getString('user_email');
  final String? userType = prefs.getString('user_type');

  // Decide where to start
  String startRoute = '/'; // Default to Welcome Page

  if (userEmail != null) {
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