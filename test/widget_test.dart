// This is a basic Flutter widget test for AjarinYa!.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:ajarin_ya/main.dart';

void main() {
  testWidgets('AjarinYa! dashboard load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our premium dashboard loads with the app title.
    expect(find.text('AjarinYa! Dashboard'), findsOneWidget);
    expect(find.text('SDG Target 4: Pendidikan Berkualitas'), findsOneWidget);
  });
}
