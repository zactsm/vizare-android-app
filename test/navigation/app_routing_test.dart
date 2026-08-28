import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/main.dart';
import 'package:untitled/welcome_page.dart';
import 'package:untitled/pages/create_account_page.dart';
import 'package:untitled/pages/login_page.dart';
import 'package:untitled/pages/homebuyer_page.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/settings_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/homeowner_page.dart';
import 'package:untitled/pages/admin_page.dart';
import 'package:untitled/pages/utils/app_theme.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  group('App Routing and Theme Tests', () {
    testWidgets('initialRoute "/" renders WelcomePage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MyApp(initialRoute: '/'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('initialRoute "/create-account" renders CreateAccountPage',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MyApp(initialRoute: '/create-account'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAccountPage), findsOneWidget);
    });

    testWidgets('initialRoute "/login" renders LoginPage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MyApp(initialRoute: '/login'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('initialRoute "/home" renders HomeBuyerPage for authenticated user',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'buyer@example.com',
        'user_type': 'homebuyer',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeBuyerPage), findsOneWidget);
    });

    testWidgets('initialRoute "/homebuyer" renders HomeBuyerPage for authenticated user',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'buyer@example.com',
        'user_type': 'homebuyer',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/homebuyer'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeBuyerPage), findsOneWidget);
    });

    testWidgets('initialRoute "/favorites" renders FavoritesPage for authenticated user',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'buyer@example.com',
        'user_type': 'homebuyer',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/favorites'));
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesPage), findsOneWidget);
    });

    testWidgets('initialRoute "/settings" renders SettingsPage for authenticated user',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'buyer@example.com',
        'user_type': 'homebuyer',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('initialRoute "/search" renders SearchPage for authenticated user',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'buyer@example.com',
        'user_type': 'homebuyer',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/search'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('initialRoute "/homeowner" renders HomeownerPage for homeowner role',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'owner@example.com',
        'user_type': 'homeowner',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/homeowner'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeownerPage), findsOneWidget);
    });

    testWidgets('initialRoute "/admin" renders AdminPage for admin role',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'admin@example.com',
        'user_type': 'admin',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/admin'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPage), findsOneWidget);
    });

    testWidgets('unauthenticated URL manipulation is intercepted by RoleGuard',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MyApp(initialRoute: '/homeowner'));
      await tester.pumpAndSettle();

      expect(find.text('Authentication Required'), findsOneWidget);
      expect(find.byType(HomeownerPage), findsNothing);
    });

    testWidgets('homebuyer role attempting /admin is blocked by RoleGuard',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'buyer@example.com',
        'user_type': 'homebuyer',
      });
      await tester.pumpWidget(const MyApp(initialRoute: '/admin'));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byType(AdminPage), findsNothing);
    });

    testWidgets('initialRoute "/forgot_password" renders ForgotPasswordPage',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/forgot_password'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsWidgets);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('Theme configures dark mode and luxury champagne gold accents',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MyApp(initialRoute: '/'));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.darkTheme?.brightness, Brightness.dark);
      expect(materialApp.darkTheme?.primaryColor, VizareColors.champagneGold);
      expect(materialApp.darkTheme?.scaffoldBackgroundColor,
          VizareColors.obsidianBlack);
      expect(materialApp.theme?.brightness, Brightness.light);
      expect(materialApp.theme?.primaryColor, VizareColors.champagneGoldAccessible);
    });
  });
}
