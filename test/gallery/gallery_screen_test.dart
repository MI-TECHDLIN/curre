import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:curre/gallery/gallery_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DesignGalleryScreen renders every section without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: curreTheme(Brightness.light),
        darkTheme: curreTheme(Brightness.dark),
        home: const DesignGalleryScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Curre design gallery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
