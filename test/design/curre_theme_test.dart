import 'package:flutter/material.dart';
import 'package:curre/design/design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('curreTheme exposes CurreColors and CurreType for both brightnesses', () {
    for (final brightness in Brightness.values) {
      final theme = curreTheme(brightness);
      expect(theme.brightness, brightness);
      expect(theme.extension<CurreColors>(), isNotNull);
      expect(theme.extension<CurreType>(), isNotNull);
    }
  });

  test('CurreColors.outcome resolves `later` to the target session sky', () {
    final c = CurreColors.light;
    expect(c.outcome(Outcome.later, laterTarget: Session.morning), c.sky(Session.morning));
    expect(c.outcome(Outcome.open, laterTarget: Session.morning), c.outcomes[Outcome.open]);
  });

  test('CurreColors.lerp interpolates every field without throwing', () {
    final lerped = CurreColors.light.lerp(CurreColors.dark, 0.5);
    expect(lerped, isA<CurreColors>());
    expect(lerped.skies.length, Session.values.length);
    expect(lerped.outcomes.length, CurreColors.light.outcomes.length);
  });

  test('CurreType.lerp interpolates every text style without throwing', () {
    final light = CurreType.of(CurreColors.light);
    final dark = CurreType.of(CurreColors.dark);
    final lerped = light.lerp(dark, 0.5);
    expect(lerped, isA<CurreType>());
  });
}
