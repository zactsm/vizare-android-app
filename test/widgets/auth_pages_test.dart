import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/pages/create_account_page.dart';
import 'package:untitled/pages/login_page.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      routes: {
        '/login': (context) => const LoginPage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/tos': (context) =>
            const Scaffold(body: Text('Terms of Service Screen')),
      },
      home: child,
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('renders all fields, headers, and action buttons',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const LoginPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('Log In'), findsWidgets);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('shows missing fields dialog when submitting empty credentials',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const LoginPage()));
      await tester.pump(const Duration(milliseconds: 100));

      final loginBtn = find.text('Log In').last;
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Required Fields'), findsOneWidget);
      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });

    testWidgets('toggles password visibility on icon tap', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const LoginPage()));
      await tester.pump(const Duration(milliseconds: 100));

      final passwordFieldBefore =
          tester.widget<TextField>(find.byType(TextField).at(1));
      expect(passwordFieldBefore.obscureText, isTrue);

      final iconFinder = find.byIcon(Icons.visibility_off_outlined);
      await tester.ensureVisible(iconFinder);
      await tester.tap(iconFinder);
      await tester.pump();

      final passwordFieldAfter =
          tester.widget<TextField>(find.byType(TextField).at(1));
      expect(passwordFieldAfter.obscureText, isFalse);
    });
  });

  group('CreateAccountPage Widget Tests', () {
    testWidgets('renders all fields, roles toggle, and sign-up button',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const CreateAccountPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Join Vizare'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
      expect(find.text('Homebuyer'), findsOneWidget);
      expect(find.text('Homeowner'), findsOneWidget);
      expect(find.text('Register Account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('validates required fields when policy is checked and form is empty',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const CreateAccountPage()));
      await tester.pump(const Duration(milliseconds: 100));

      final checkbox = find.byType(Checkbox).first;
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      final registerButton = find.text('Register Account');
      expect(registerButton, findsOneWidget);
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Required Fields'), findsOneWidget);
    });

    testWidgets('validates password mismatch when passwords differ',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const CreateAccountPage()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'John Doe');
      await tester.enterText(textFields.at(1), 'john@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'different_password');

      final checkbox = find.byType(Checkbox).first;
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      final registerButton = find.text('Register Account');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Password Mismatch'), findsOneWidget);
    });

    testWidgets('toggles user role pill', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const CreateAccountPage()));
      await tester.pump(const Duration(milliseconds: 100));

      final homeownerRole = find.text('Homeowner');
      await tester.ensureVisible(homeownerRole);
      await tester.tap(homeownerRole);
      await tester.pump();

      expect(find.byType(CreateAccountPage), findsOneWidget);
    });
  });
}
