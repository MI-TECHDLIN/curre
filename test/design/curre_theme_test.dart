import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

void main() {
  test('curreTheme exposes CurreColors and CurreType for both brightnesses', () {
    for (final brightness in Brightness.values) {
      final theme = curreTheme(brightness);
      expect(theme.brightness, brightness);
      expect(theme.extension<CurreColors>(), isNotNull);
      expect(theme.extension<CurreType>(), isNotNull);
    }
  });

  test('`later` resolves to the target session sky', () {
    final c = CurreColors.light;
    expect(c.outcome(Outcome.later, laterTarget: Session.morning), c.sky(Session.morning));
    expect(c.outcome(Outcome.open, laterTarget: Session.morning), c.outcomes[Outcome.open]);
  });

  test('every session has a sky and a ground in both themes', () {
    for (final c in [CurreColors.light, CurreColors.dark]) {
      for (final s in Session.values) {
        expect(c.skies[s], isNotNull);
        expect(c.grounds[s], isNotNull);
      }
    }
  });

  test('link tints cycle after the last one, numbered from 1', () {
    final c = CurreColors.light;
    expect(c.link(1), c.links.first);
    expect(c.link(c.links.length + 1), c.links.first);
  });

  test('every text pair clears WCAG AA (4.5:1) in both themes', () {
    for (final c in [CurreColors.light, CurreColors.dark]) {
      expect(_contrast(c.ink, c.paper), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.ink2, c.paper), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.ink3, c.paper), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.ink3, c.sunk), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.emberText, c.paper), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.markInk, c.ember), greaterThanOrEqualTo(4.5), reason: 'ink label on the ember pill');
      for (final s in Session.values) {
        expect(_contrast(c.sky(s).fg, c.sky(s).bg), greaterThanOrEqualTo(4.5), reason: '$s sky');
        expect(_contrast(c.sky(s).fg, c.ground(s)), greaterThanOrEqualTo(4.5), reason: '$s ground');
      }
      for (final o in c.outcomes.values) {
        expect(_contrast(o.fg, o.bg), greaterThanOrEqualTo(4.5));
      }
      for (final l in c.links) {
        expect(_contrast(c.markInk, l.mark), greaterThanOrEqualTo(4.5));
        expect(_contrast(l.card.fg, l.card.bg), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('every session\'s water stands apart from its ground, with a visible crest', () {
    for (final c in [CurreColors.light, CurreColors.dark]) {
      for (final s in Session.values) {
        expect(_contrast(c.water(s).bg, c.ground(s)), greaterThanOrEqualTo(1.4), reason: '$s water on its ground');
        expect(_contrast(c.water(s).fg, c.water(s).bg), greaterThanOrEqualTo(2.5), reason: '$s crest on its water');
      }
    }
  });

  test('CurreColors.lerp interpolates every field without throwing', () {
    final lerped = CurreColors.light.lerp(CurreColors.dark, .5);
    expect(lerped.skies.length, Session.values.length);
    expect(lerped.grounds.length, Session.values.length);
    expect(lerped.waters.length, Session.values.length);
    expect(lerped.outcomes.length, CurreColors.light.outcomes.length);
    expect(lerped.links.length, CurreColors.light.links.length);
  });

  test('CurreType.lerp interpolates every text style without throwing', () {
    final lerped = CurreType.of(CurreColors.light).lerp(CurreType.of(CurreColors.dark), .5);
    expect(lerped, isA<CurreType>());
  });

  test('weight() moves the variable wght axis and keeps the other axes', () {
    final title = CurreType.of(CurreColors.light).title;
    final heavier = title.weight(760);
    expect(heavier.fontVariations!.firstWhere((v) => v.axis == 'wght').value, 760);
    expect(heavier.fontVariations!.any((v) => v.axis == 'SHRP'), isTrue);
    expect(heavier.fontWeight, FontWeight.w800);
  });
}
