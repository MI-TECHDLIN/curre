import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curre/design/design.dart';
import 'package:curre/main.dart';

void main() {
  testWidgets('CurreApp renders the starter home with the Curre theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CurreApp());

    expect(find.byKey(const Key('curre-splash-mark')), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.extension<CurreColors>(), isNotNull);
  });
}
