import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: curreTheme(Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  ),
);

void main() {
  testWidgets('picker exposes labels and selected state, then reports a tap', (
    tester,
  ) async {
    String? selected = 'avatar-01';
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => AvatarPicker(
            selectedAvatarId: selected,
            onSelected: (id) => setState(() => selected = id),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Choose a profile avatar'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile avatar 1, selected'), findsOneWidget);
    expect(find.byType(Avatar), findsNWidgets(12));
    for (var number = 1; number <= 12; number++) {
      expect(find.text('Avatar $number'), findsNothing);
    }

    await tester.tap(find.bySemanticsLabel('Profile avatar 7'));
    await tester.pump();

    expect(selected, 'avatar-07');
    expect(find.bySemanticsLabel('Profile avatar 7, selected'), findsOneWidget);
  });

  for (final textScale in const [1.0, 2.0]) {
    testWidgets('picker has no overflow at 360 dp and ${textScale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          AvatarPicker(selectedAvatarId: 'avatar-08', onSelected: (_) {}),
          textScale: textScale,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(Avatar), findsNWidgets(12));
    });
  }
}
