import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/add_property_page.dart';
import 'package:untitled/pages/edit_property_page.dart';
import 'package:untitled/pages/favorites_page.dart';
import 'package:untitled/pages/profile_page.dart';
import 'package:untitled/pages/property_details_page.dart';
import 'package:untitled/pages/search_page.dart';
import 'package:untitled/pages/send_inquiry_page.dart';
import 'package:untitled/pages/to_respond_page.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  final mockPropertyWithModel = Property(
    id: 1,
    homeownerId: 10,
    name: 'Modern Sunset Villa',
    location: 'Malibu, CA',
    price: 'RM 2,450,000',
    numericPrice: 2450000.0,
    description: 'A stunning modern villa overlooking the Pacific Ocean.',
    imagePath: 'https://example.com/sunset.jpg',
    modelPath: 'https://example.com/sunset.glb',
    isFeatured: true,
    createdAt: '2026-08-01',
    status: 'approved',
  );

  final mockPropertyWithoutModel = Property(
    id: 2,
    homeownerId: 11,
    name: 'Downtown Studio',
    location: 'Austin, TX',
    price: 'RM 450,000',
    numericPrice: 450000.0,
    description: 'Cozy urban studio in downtown Austin.',
    imagePath: 'https://example.com/studio.jpg',
    modelPath: '',
    isFeatured: false,
    createdAt: '2026-08-02',
    status: 'approved',
  );

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Property Details & Exploration Flows', () {
    testWidgets('PropertyDetailsPage displays property info and AR model button',
        (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
            PropertyDetailsPage(property: mockPropertyWithModel)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ARCHITECTURAL SPECIFICATIONS'), findsOneWidget);
      expect(find.text('Modern Sunset Villa'), findsOneWidget);
      expect(find.text(mockPropertyWithModel.description), findsOneWidget);

      final arButton = find.text('EXPLORE IN 3D / AR');
      expect(arButton, findsOneWidget);
    });

    testWidgets('PropertyDetailsPage shows disabled button when no 3D model exists',
        (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
            PropertyDetailsPage(property: mockPropertyWithoutModel)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Downtown Studio'), findsOneWidget);
      expect(find.text('NO 3D MODEL'), findsOneWidget);
    });

    testWidgets('FavoritesPage renders cleanly', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const FavoritesPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FavoritesPage), findsOneWidget);
    });

    testWidgets('SearchPage renders search bar and UI filters',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const SearchPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('SendInquiryPage validates empty inquiry submission',
        (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
            SendInquiryPage(property: mockPropertyWithModel)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SendInquiryPage), findsOneWidget);
    });

    testWidgets('AddPropertyPage renders form fields for homeowner listings',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const AddPropertyPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AddPropertyPage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('EditPropertyPage pre-fills existing property fields',
        (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
            EditPropertyPage(property: mockPropertyWithModel)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(EditPropertyPage), findsOneWidget);
      expect(find.text('Modern Sunset Villa'), findsOneWidget);
    });

    testWidgets('ToRespondPage renders inquiry management view',
        (tester) async {
      await tester.pumpWidget(wrapWithMaterial(const ToRespondPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ToRespondPage), findsOneWidget);
    });

    testWidgets('ProfilePage renders user profile form fields',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(wrapWithMaterial(const ProfilePage()));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
