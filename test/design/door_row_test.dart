import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DoorRow shows the app name and destination, and reports taps separately from long-press', (
    tester,
  ) async {
    var tapped = false;
    var longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: Scaffold(
          body: DoorRow(
            appName: 'YouTube',
            destination: 'Search "G chord"',
            onTap: () => tapped = true,
            onLongPress: () => longPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('YouTube'), findsOneWidget);
    expect(find.textContaining('G chord'), findsOneWidget);

    await tester.tap(find.byType(DoorRow));
    expect(tapped, isTrue);
    expect(longPressed, isFalse);

    await tester.longPress(find.byType(DoorRow));
    expect(longPressed, isTrue);
  });

  testWidgets('DoorRow is at least the minimum row height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        home: const Scaffold(
          body: DoorRow(appName: 'Spotify', destination: 'Search "worship"'),
        ),
      ),
    );

    final size = tester.getSize(find.byType(DoorRow));
    expect(size.height, greaterThanOrEqualTo(CurreSpace.doorRowMinHeight));
  });
}
