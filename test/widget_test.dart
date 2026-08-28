import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/main.dart';
import 'package:untitled/welcome_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts with WelcomePage and renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: '/'));
    await tester.pump();

    expect(find.byType(WelcomePage), findsOneWidget);
  });
}