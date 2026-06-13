// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eye_app/main.dart';

void main() {
  testWidgets('GlassCard renders child widget', (WidgetTester tester) async {
    // Build a GlassCard with a text child.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Test Child Text'),
          ),
        ),
      ),
    );

    // Verify that the child text is displayed.
    expect(find.text('Test Child Text'), findsOneWidget);
  });
}
