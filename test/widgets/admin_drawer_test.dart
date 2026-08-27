import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/admin_page.dart';
import 'package:untitled/widgets/admin_drawer.dart';
import '../test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_email': 'admin@vizare.com',
      'user_type': 'admin',
      'user_name': 'System Administrator',
    });
  });

  group('AdminDrawer Unit & Widget Tests', () {
    testWidgets('renders all navigation items and branding header', (tester) async {
      AdminView selectedView = AdminView.moderation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AdminDrawer(
              currentView: selectedView,
              pendingCount: 5,
              adminEmail: 'admin@vizare.com',
              onViewSelected: (view) => selectedView = view,
              onSignOut: () {},
            ),
            body: const SizedBox(),
          ),
        ),
      );

      // Open the drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify Console branding
      expect(find.text('VIZARE CONSOLE'), findsOneWidget);
      expect(find.text('SUPER ADMIN'), findsOneWidget);
      expect(find.text('admin@vizare.com'), findsOneWidget);

      // Verify Nav Items
      expect(find.text('Platform Overview'), findsOneWidget);
      expect(find.text('Moderation Queue'), findsOneWidget);
      expect(find.text('Listings Management'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Property Types Editor'), findsOneWidget);
      expect(find.text('Bottom Nav Bar Tuner'), findsOneWidget);

      // Verify Badge count
      expect(find.text('5'), findsOneWidget);

      // Verify Sign Out option
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('triggers callback when navigating to different view', (tester) async {
      AdminView selectedView = AdminView.analytics;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: AdminDrawer(
              currentView: selectedView,
              pendingCount: 0,
              adminEmail: 'admin@vizare.com',
              onViewSelected: (view) => selectedView = view,
              onSignOut: () {},
            ),
            body: const SizedBox(),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap on Listings Management
      await tester.tap(find.text('Listings Management'));
      await tester.pumpAndSettle();

      expect(selectedView, equals(AdminView.listings));
    });
  });

  group('AdminPage Full Integration Tests', () {
    testWidgets('renders hamburger menu and opens drawer on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPage(),
        ),
      );
      await tester.pump();

      // Verify hamburger icon is present
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Default view is Platform Overview
      expect(find.text('Platform Overview'), findsOneWidget);

      // Tap hamburger button to open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Verify drawer opened
      expect(find.text('VIZARE CONSOLE'), findsOneWidget);
      expect(find.text('Listings Management'), findsOneWidget);

      // Switch to User Management view
      await tester.tap(find.text('User Management'));
      await tester.pumpAndSettle();

      // Verify title updated
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Manage buyer, homeowner, and administrator profiles.'), findsOneWidget);
    });

    testWidgets('switches to Moderation Queue view', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPage(),
        ),
      );
      await tester.pump();

      // Default view is Platform Overview
      expect(find.text('Platform Overview'), findsOneWidget);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Switch to Moderation Queue
      await tester.tap(find.text('Moderation Queue'));
      await tester.pumpAndSettle();

      expect(find.text('Moderation Queue'), findsOneWidget);
      expect(find.text('Review & approve submitted property listings.'), findsOneWidget);
    });
  });
}
