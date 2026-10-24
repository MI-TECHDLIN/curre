import 'package:curre/design/design.dart';
import 'package:curre/gallery/gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DesignGalleryScreen renders every section without throwing', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        darkTheme: curreTheme(Brightness.dark),
        home: const DesignGalleryScreen(),
      ),
    );
    // Past every staggered entrance timer in the previews.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Curre design gallery'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Step the gallery itself (not the phone previews' own scroll views)
    // to the end, so every lazily built section gets built once.
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    while (position.pixels < position.maxScrollExtent) {
      position.jumpTo((position.pixels + 1600).clamp(0, position.maxScrollExtent));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Prooflight'), findsOneWidget);
  });
}
