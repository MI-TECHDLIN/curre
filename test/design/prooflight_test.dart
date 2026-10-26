import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
  theme: curreTheme(brightness),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('the sun draws below the line, risen, with any number of rays and every milestone', (tester) async {
    for (final brightness in Brightness.values) {
      for (final rays in [0, 1, 2, 5, 12, 20]) {
        for (final days in [0, 7, 21, 50]) {
          await tester.pumpWidget(
            _host(
              ProoflightSun(rays: rays, proofDays: days, lineColor: Colors.black),
              brightness: brightness,
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
    expect(tester.getSize(find.byType(ProoflightSun)), Size(96, ProoflightSun.heightFor(96)));
  });

  testWidgets('the sunrise and the new ray can be driven frame by frame', (tester) async {
    for (final t in [0.0, .2, .5, .8, 1.0]) {
      await tester.pumpWidget(_host(ProoflightSun(rays: 3, proofDays: 8, rise: t, grow: t, size: 200)));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('it is still: nothing animates on its own', (tester) async {
    await tester.pumpWidget(_host(const ProoflightSun(rays: 2)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('the label counts proof days, one day and none in plain words', () {
    expect(ProofDaysLabel.text(0), 'No proof days yet');
    expect(ProofDaysLabel.text(1), '1 proof day');
    expect(ProofDaysLabel.text(7), '7 proof days');
  });

  testWidgets('the label reads the count, today\'s sun and a cloud day in hand', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const ProofDaysLabel(days: 7, raysToday: 1, cloudDay: true)));
    expect(find.text('7 proof days'), findsOneWidget);
    expect(find.bySemanticsLabel('7 proof days, today’s sun is up, one cloud day in hand'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a cloud day covers its day with a soft cloud', (tester) async {
    final handle = tester.ensureSemantics();
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(_host(const CloudDayMark(label: '21'), brightness: brightness));
      expect(find.text('21'), findsOneWidget);
      expect(find.bySemanticsLabel('Cloud day, 21'), findsOneWidget);
    }
    handle.dispose();
  });

  test('a run that ends is told plainly, with nothing lost', () {
    expect(RunEndedNote.headline(12), 'That run ended at 12 proof days.');
    expect(RunEndedNote.headline(1), 'That run ended at 1 proof day.');
    expect(RunEndedNote.next, 'Today’s proof starts the next sunrise.');
    expect(RunEndedNote.record(best: 12, total: 31), 'Best run 12 · 31 proof days in all');
    expect(RunEndedNote.record(), isNull);
    final copy = [RunEndedNote.headline(12), RunEndedNote.next, RunEndedNote.record(best: 12, total: 31)!];
    for (final line in copy) {
      for (final word in ['lost', 'failed', 'zero', 'broke', 'reset']) {
        expect(line.toLowerCase(), isNot(contains(word)));
      }
    }
  });

  testWidgets('the run-ended note draws in both themes', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 340, child: RunEndedNote(endedAt: 12, best: 12, total: 31)),
          brightness: brightness,
        ),
      );
      expect(find.text('That run ended at 12 proof days.'), findsOneWidget);
      expect(find.text('Best run 12 · 31 proof days in all'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('between runs the label looks ahead instead of reading zero', () {
    expect(ProofDaysLabel.text(0, runEnded: true), 'Next sunrise: one proof away');
    expect(ProofDaysLabel.text(0), 'No proof days yet');
    // A run in progress never reads as ended.
    expect(ProofDaysLabel.text(3, runEnded: true), '3 proof days');
  });

  testWidgets('the week strip marks proof, waiting, cloud, quiet and today days', (tester) async {
    final handle = tester.ensureSemantics();
    const days = [
      WeekDay('Sun', 18, DayState.quiet),
      WeekDay('Mon', 19, DayState.proof),
      WeekDay('Tue', 20, DayState.cloud),
      WeekDay('Wed', 21, DayState.proof),
      WeekDay('Thu', 22, DayState.pending),
      WeekDay('Fri', 23, DayState.proof),
      WeekDay('Sat', 24, DayState.today),
    ];
    for (final brightness in Brightness.values) {
      for (final lit in [0.0, .5, 1.0]) {
        await tester.pumpWidget(
          _host(const SizedBox(width: 320, child: WeekStrip(days: days)), brightness: brightness),
        );
        await tester.pumpWidget(
          _host(SizedBox(width: 320, child: WeekStrip(days: days, todayLit: lit)), brightness: brightness),
        );
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.byType(CloudDayMark), findsOneWidget);
    expect(find.bySemanticsLabel('Mon 19, proof day'), findsOneWidget);
    expect(find.bySemanticsLabel('Tue 20, cloud day'), findsOneWidget);
    expect(find.bySemanticsLabel('Thu 22, note waiting to be checked'), findsOneWidget);
    expect(find.bySemanticsLabel('Sat 24, today, proof day'), findsOneWidget);
    await tester.pumpWidget(_host(const SizedBox(width: 320, child: WeekStrip(days: days))));
    expect(find.bySemanticsLabel('Sat 24, today, still open'), findsOneWidget);
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 320,
          child: WeekStrip(days: [WeekDay('Sat', 24, DayState.pending, isToday: true)]),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Sat 24, today, note waiting to be checked'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the rolling count reads its number and holds when nothing changes', (tester) async {
    final handle = tester.ensureSemantics();
    const style = TextStyle(fontSize: 56);
    await tester.pumpWidget(_host(const RollingCount(from: 1, to: 1, t: 0, style: style)));
    expect(find.bySemanticsLabel('1 proof day'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    // It is still: the parent drives it.
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(_host(const RollingCount(from: 4, to: 5, t: .2, style: style)));
    expect(find.bySemanticsLabel('4 proof days'), findsOneWidget);
    await tester.pumpWidget(_host(const RollingCount(from: 4, to: 5, t: .8, style: style)));
    expect(find.bySemanticsLabel('5 proof days'), findsOneWidget);
    handle.dispose();
  });
}
