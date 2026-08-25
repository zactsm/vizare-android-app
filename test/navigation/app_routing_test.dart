import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      await tester.pumpWidget(const MyApp(initialRoute: '/'));
      await tester.pump();

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('initialRoute "/create-account" renders CreateAccountPage',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/create-account'));
      await tester.pump();

      expect(find.byType(CreateAccountPage), findsOneWidget);
    });

    testWidgets('initialRoute "/login" renders LoginPage', (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/login'));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('initialRoute "/home" renders HomeBuyerPage', (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/home'));
      await tester.pump();

      expect(find.byType(HomeBuyerPage), findsOneWidget);
    });

    testWidgets('initialRoute "/homebuyer" renders HomeBuyerPage',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/homebuyer'));
      await tester.pump();

      expect(find.byType(HomeBuyerPage), findsOneWidget);
    });

    testWidgets('initialRoute "/favorites" renders FavoritesPage',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/favorites'));
      await tester.pump();

      expect(find.byType(FavoritesPage), findsOneWidget);
    });

    testWidgets('initialRoute "/settings" renders SettingsPage',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/settings'));
      await tester.pump();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('initialRoute "/search" renders SearchPage', (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/search'));
      await tester.pump();

      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('initialRoute "/homeowner" renders HomeownerPage',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/homeowner'));
      await tester.pump();

      expect(find.byType(HomeownerPage), findsOneWidget);
    });

    testWidgets('initialRoute "/admin" renders AdminPage', (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/admin'));
      await tester.pump();

      expect(find.byType(AdminPage), findsOneWidget);
    });

    testWidgets('Theme configures dark mode and luxury champagne gold accents',
        (tester) async {
      await tester.pumpWidget(const MyApp(initialRoute: '/'));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, Brightness.dark);
      expect(materialApp.theme?.primaryColor, VizareColors.champagneGold);
      expect(materialApp.theme?.scaffoldBackgroundColor,
          VizareColors.obsidianBlack);
    });
  });
}
