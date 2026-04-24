import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synthox/main.dart';

void main() {
  testWidgets('Splash screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SynthoXApp());

    // Verify that our app name is present.
    expect(find.text('SynthoX'), findsOneWidget);
    
    // Verify that the CircularProgressIndicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
