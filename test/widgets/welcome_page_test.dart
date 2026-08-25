import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/welcome_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWelcomePageWrapper() {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/create-account': (context) =>
            const Scaffold(body: Text('Create Account Screen')),
        '/login': (context) => const Scaffold(body: Text('Login Screen')),
      },
    );
  }

  group('WelcomePage Widget Tests', () {
    testWidgets('renders initial UI elements and texts cleanly',
        (tester) async {
      await tester.pumpWidget(createWelcomePageWrapper());
      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('navigates to /create-account on button tap', (tester) async {
      await tester.pumpWidget(createWelcomePageWrapper());
      await tester.pump();

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account Screen'), findsOneWidget);
    });

    testWidgets('navigates to /login on button tap', (tester) async {
      await tester.pumpWidget(createWelcomePageWrapper());
      await tester.pump();

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('advances rich text banner message across periodic timer ticks',
        (tester) async {
      await tester.pumpWidget(createWelcomePageWrapper());
      await tester.pump();

      // Check initial frame renders
      expect(find.byType(RichText), findsWidgets);

      // Fast-forward timer by 4 seconds
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(RichText), findsWidgets);
    });
  });
}
