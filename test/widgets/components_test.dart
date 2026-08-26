import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/pages/utils/abstract_background.dart';
import 'package:untitled/pages/utils/floating_bottom_nav_bar.dart';
import 'package:untitled/pages/utils/premium_background.dart';
import 'package:untitled/pages/utils/top_bar_gradient_blur.dart';
import 'package:untitled/pages/homebuyer_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI Components Widget Tests', () {
    testWidgets('FloatingBottomNavBar renders active state for each NavPageIndex',
        (tester) async {
      for (final index in NavPageIndex.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FloatingBottomNavBar(activeIndex: index),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingBottomNavBar), findsOneWidget);
      }
    });

    testWidgets('FloatingBottomNavBar triggers onTap callback with correct index',
        (tester) async {
      NavPageIndex? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingBottomNavBar(
              activeIndex: NavPageIndex.home,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on search nav item (item 1)
      final items = find.byType(GestureDetector);
      expect(items, findsWidgets);

      await tester.tap(items.at(1));
      await tester.pump();

      expect(selectedIndex, NavPageIndex.search);

      // Tap on favorites (item 2)
      await tester.tap(items.at(2));
      await tester.pump();
      expect(selectedIndex, NavPageIndex.favorites);

      // Tap on settings (item 3)
      await tester.tap(items.at(3));
      await tester.pump();
      expect(selectedIndex, NavPageIndex.settings);
    });

    testWidgets('AbstractBackground renders child and layers cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AbstractBackground(
              child: Center(
                child: Text('Content inside abstract background'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Content inside abstract background'), findsOneWidget);
      expect(find.byType(AbstractBackground), findsOneWidget);
    });

    testWidgets('PremiumBackground custom wave painter paints without error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumBackground(
              child: Center(
                child: Text('Premium Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byType(PremiumBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('TopBarGradientBlur renders with backdrop filter and gradient',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TopBarGradientBlur(height: 80),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TopBarGradientBlur), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TopBarGradientBlur),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('HomeBuyerPage PageView has NeverScrollableScrollPhysics (swipe disabled)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeBuyerPage(),
        ),
      );
      await tester.pump();

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
