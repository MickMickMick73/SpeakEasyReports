import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy_reports/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakEasyApp());
    await tester.pump();
    expect(find.byType(SpeakEasyApp), findsOneWidget);
  });
}