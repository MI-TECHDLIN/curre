import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
  theme: curreTheme(brightness),
  themeAnimationDuration: Duration.zero,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('DoorRow shows the app and its destination, and reports taps apart from long-presses', (tester) async {
    var tapped = false;
    var longPressed = false;
    await tester.pumpWidget(
      _host(
        DoorRow(
          appName: 'YouTube',
          destination: '→ Search “G chord”',
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
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
    await tester.pumpWidget(_host(const DoorRow(appName: 'Spotify', destination: '→ Search “worship”')));
    expect(tester.getSize(find.byType(DoorRow)).height, greaterThanOrEqualTo(CurreSpace.doorRowMinHeight));
  });

  testWidgets('a linked DoorRow wears its link colour and shows the number', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        _host(
          const DoorRow(appName: 'Spotify', destination: '→ Search “worship”', link: 2),
          brightness: brightness,
        ),
      );
      final colors = brightness == Brightness.light ? CurreColors.light : CurreColors.dark;
      final material = tester.widget<Material>(
        find.descendant(of: find.byType(DoorRow), matching: find.byType(Material)).first,
      );
      expect(material.color, colors.link(2).card.bg);
      expect(find.text('2'), findsOneWidget);
    }
  });

  testWidgets('a tint overrides the link colour, and trailing content shows', (tester) async {
    final open = CurreColors.light.outcomes[Outcome.open]!;
    await tester.pumpWidget(
      _host(DoorRow(appName: 'Instagram', destination: '→ Messages · Ada', tint: open, trailing: const Text('3:12'))),
    );
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(DoorRow), matching: find.byType(Material)).first,
    );
    expect(material.color, open.bg);
    expect(find.text('3:12'), findsOneWidget);
  });

  testWidgets('long names and destinations ellipsize instead of overflowing at 360 dp', (tester) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        const DoorRow(
          appName: 'Samsung Health Monitor for Galaxy Watch',
          destination: '→ Search “how to play the G chord on an acoustic guitar for beginners”',
          link: 1,
          trailing: Text('12:00'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a DoorRow reads as one button with its own label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const DoorRow(
          appName: 'YouTube',
          destination: '→ Search “G chord”',
          semanticLabel: 'YouTube, opens search for G chord',
        ),
      ),
    );
    expect(find.bySemanticsLabel('YouTube, opens search for G chord'), findsOneWidget);
    handle.dispose();
  });
}
