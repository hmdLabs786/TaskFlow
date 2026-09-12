import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  setUpAll(() async {
    await Hive.initFlutter();
  });

  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}