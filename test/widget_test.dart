import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('biMüzik'),
        ),
      ),
    );

    expect(find.text('biMüzik'), findsOneWidget);
  });
}
