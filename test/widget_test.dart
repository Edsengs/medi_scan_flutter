// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:medi_scan_flutter/main.dart'; // Correctly import your main file

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Replace MyApp() with your main app widget, MediScanApp()
    await tester.pumpWidget(const MediScanApp());

    // This is just a basic test to ensure the app doesn't crash on startup.
    // You can add more specific tests later.
    expect(find.text('MediScan'), findsOneWidget);
  });
}
