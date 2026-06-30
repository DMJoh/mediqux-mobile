import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediqux_mobile/config/theme.dart';

void main() {
  testWidgets('App theme and scaffold render', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
