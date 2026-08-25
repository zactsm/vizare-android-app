import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/pages/settings_page.dart';
import 'package:untitled/pages/settings/change_password_page.dart';
import 'package:untitled/pages/settings/contact_support_page.dart';
import 'package:untitled/pages/settings/deactivate_account_page.dart';
import 'package:untitled/pages/settings/faq_page.dart';
import 'package:untitled/pages/settings/notification_preferences_page.dart';
import 'package:untitled/pages/settings/preferred_location_page.dart';
import 'package:untitled/pages/settings/preferred_property_types_page.dart';
import 'package:untitled/pages/settings/privacy_policy_page.dart';
import 'package:untitled/pages/settings/tos_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Settings and Preference Pages Tests', () {
    testWidgets('SettingsPage renders sections and header properly',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SettingsPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('ACCOUNT PREFERENCES'), findsOneWidget);
      expect(find.text('SUPPORT & LEGAL'), findsOneWidget);
    });

    testWidgets('ChangePasswordPage renders fields and validates empty inputs',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const ChangePasswordPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsWidgets);

      final updateBtn = find.widgetWithText(ElevatedButton, 'Save');
      expect(updateBtn, findsOneWidget);
      await tester.tap(updateBtn);
      await tester.pump();

      expect(find.text('Please fill in all fields.'), findsOneWidget);
    });

    testWidgets('DeactivateAccountPage renders warning text and button',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const DeactivateAccountPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Deactivate account'), findsOneWidget);
      expect(find.text('Reason for Deactivation:'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ContactSupportPage renders form fields and submit button',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const ContactSupportPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Contact Support'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });

    testWidgets('FAQPage renders FAQ title and expandable items',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const FAQPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Frequently Asked Questions (FAQs)'), findsWidgets);
    });

    testWidgets('NotificationPreferencesPage renders preference toggles',
        (tester) async {
      await tester
          .pumpWidget(wrapWithMaterial(const NotificationPreferencesPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Notification preferences'), findsWidgets);
    });

    testWidgets('PreferredLocationPage renders location selectors',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const PreferredLocationPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preferred location'), findsWidgets);
    });

    testWidgets('PreferredPropertyTypesPage renders type selection options',
        (tester) async {
      await tester
          .pumpWidget(wrapWithMaterial(const PreferredPropertyTypesPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preferred property types'), findsWidgets);
    });

    testWidgets('PrivacyPolicyPage renders policy terms', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const PrivacyPolicyPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Privacy Policy'), findsWidgets);
    });

    testWidgets('TOSPage renders terms of service content', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const TOSPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Terms of Service'), findsWidgets);
    });
  });
}
