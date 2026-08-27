import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/chat_models.dart';
import 'package:untitled/models/property_model.dart';
import 'package:untitled/pages/chat/chat_page.dart';
import 'package:untitled/pages/chat/conversations_inbox_page.dart';
import 'package:untitled/pages/chat/schedule_viewing_dialog.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  final mockProperty = Property(
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

  final mockConversation = Conversation(
    id: 1,
    propertyId: 1,
    buyerId: 5,
    homeownerId: 10,
    lastMessage: 'Viewing request received',
    lastMessageAt: DateTime.now(),
    createdAt: DateTime.now(),
    property: mockProperty,
    otherUser: const ConversationParticipant(
      id: 10,
      fullName: 'Alexander Wright',
      email: 'alex@estate.com',
      role: 'homeowner',
    ),
    unreadCount: 1,
  );

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_email': 'buyer@example.com',
      'user_type': 'homebuyer',
    });
  });

  group('Chat & Appointment Flow Widget Tests', () {
    testWidgets('ScheduleViewingDialog renders options and triggers callback',
        (WidgetTester tester) async {
      DateTime? selectedDate;
      String? selectedTime;
      String? selectedMode;

      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    ScheduleViewingDialog.show(
                      context: context,
                      property: mockProperty,
                      onSchedule: (date, timeSlot, tourMode, note) {
                        selectedDate = date;
                        selectedTime = timeSlot;
                        selectedMode = tourMode;
                      },
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule a Viewing'), findsOneWidget);
      expect(find.text('On-Site Tour'), findsOneWidget);
      expect(find.text('Virtual 3D AR'), findsOneWidget);
      expect(find.text('Request Exclusive Viewing'), findsOneWidget);

      // Switch to Virtual 3D AR
      await tester.tap(find.text('Virtual 3D AR'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Request Exclusive Viewing'));
      await tester.pumpAndSettle();

      expect(selectedMode, 'virtual_ar');
      expect(selectedTime, isNotNull);
      expect(selectedDate, isNotNull);
    });

    testWidgets('ChatPage renders header, chips, and input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ChatPage(conversation: mockConversation),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alexander Wright'), findsOneWidget);
      expect(find.text('HOMEOWNER'), findsOneWidget);
      expect(find.text('Modern Sunset Villa'), findsOneWidget);
      expect(find.text('📅 Schedule Viewing'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('ConversationsInboxPage renders search bar and UI cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const ConversationsInboxPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
