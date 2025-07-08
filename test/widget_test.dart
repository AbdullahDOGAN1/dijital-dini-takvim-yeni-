// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_dini_takvim/main.dart';
import 'package:dijital_dini_takvim/core/providers/settings_provider.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final settingsProvider = SettingsProvider();
    await tester.pumpWidget(MyApp(settingsProvider: settingsProvider));

    // Basic smoke test - just verify app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
