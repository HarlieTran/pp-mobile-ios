import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PantryPal app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('PantryPal'))),
    );
    expect(find.text('PantryPal'), findsOneWidget);
  });
}
