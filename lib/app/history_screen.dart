import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'prooflight_view.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _HistoryBody(controller: controller),
  );
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final entries = _entries(controller);
    return CurrePage(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              CurreSpace.gutter,
              CurreSpace.s3,
              CurreSpace.gutter,
              0,
            ),
            child: CurreTopBar(
              title: 'History',
              subtitle: 'The last 30 days · only on this phone',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CurreSpace.gutter),
              children: [
                _DawnOverview(controller: controller),
                const SizedBox(height: CurreSpace.s3),
                _ProofSlot(controller: controller),
                const SizedBox(height: CurreSpace.s6),
                Text('What happened', style: type.title),
                const SizedBox(height: CurreSpace.s3),
                if (entries.isEmpty)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.raised,
                      borderRadius: CurreShape.dome,
                      border: Border.all(color: colors.hairline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(CurreSpace.s5),
                      child: Column(
                        children: [
                          CurreGlyph(
                            CurreGlyphKind.history,
                            size: 32,
                            color: colors.emberText,
                          ),
                          const SizedBox(height: CurreSpace.s3),
                          Text('A quiet start.', style: type.title),
                          const SizedBox(height: CurreSpace.s2),
                          Text(
                            'Your plans, and the apps you bring back, will show up here. It all stays on this phone.',
                            style: type.body.copyWith(color: colors.ink2),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._groupedEntries(context, controller, entries),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DawnOverview extends StatelessWidget {
  const _DawnOverview({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final today = controller.currentSession.localStartDate;
    final days = <LocalDate>[
      for (var offset = 6; offset >= 0; offset--) _addDays(today, -offset),
    ];
    final planned = <String>{
      for (final plan in controller.historyPlans)
        '${plan.date}:${plan.session.wireValue}',
    };
    final count = days.fold<int>(
      0,
      (total, day) =>
          total +
          SessionName.values
              .where((session) => planned.contains('$day:${session.wireValue}'))
              .length,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.dome,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count of 21 planned', style: type.title),
            const SizedBox(height: CurreSpace.s1),
            Text(
              'Each square is a morning, afternoon or evening in the last 7 days. Filled ones started with a plan.',
              style: type.caption.copyWith(color: colors.ink3),
            ),
            const SizedBox(height: CurreSpace.s4),
            for (final day in days)
              Padding(
                padding: const EdgeInsets.only(bottom: CurreSpace.s2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(_shortDay(day), style: type.meta),
                    ),
                    for (final session in SessionName.values) ...[
                      Expanded(
                        child: _SessionMark(
                          session: session,
                          planned: planned.contains(
                            '$day:${session.wireValue}',
                          ),
                        ),
                      ),
                      if (session != SessionName.evening)
                        const SizedBox(width: CurreSpace.s2),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionMark extends StatelessWidget {
  const _SessionMark({required this.session, required this.planned});

  final SessionName session;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final sky = colors.sky(session.designSession);
    return Semantics(
      label: '${session.label}: ${planned ? 'planned' : 'no plan'}',
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: planned ? sky.bg : colors.sunk,
          borderRadius: BorderRadius.circular(CurreSpace.s1),
          border: Border.all(
            color: planned ? sky.fg.withValues(alpha: .36) : colors.hairline,
          ),
        ),
      ),
    );
  }
}

/// Prooflight's reserved slot: the run, what stays across runs, and the
/// week's marks. Nothing here is red, and a run that ended is told as one
/// that ended, never as a loss.
class _ProofSlot extends StatelessWidget {
  const _ProofSlot({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final summary = controller.proofSummary;
    final started = summary.totalProofDays > 0 || summary.cloudDays > 0;
    final toCloud = ProoflightRules.provedDaysPerCloud - summary.towardCloud;
    final cloudLine = summary.cloudInHand
        ? 'You have a cloud day. $cloudDayLine'
        : summary.currentRun > 0
        ? toCloud == 1
              ? '1 more proof day to your next cloud day.'
              : '$toCloud more proof days to your next cloud day.'
        : null;
    return DecoratedBox(
      key: const Key('history-prooflight'),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProofDaysLabel(
              days: summary.currentRun,
              raysToday: summary.raysToday,
              cloudDay: summary.cloudInHand,
              runEnded: summary.betweenRuns,
            ),
            if (started) ...[
              const SizedBox(height: CurreSpace.s2),
              // Each figure keeps its words together; lines break only
              // between figures.
              Text(
                [
                  '${proofDaysText(summary.totalProofDays)} in all',
                  'Best run ${summary.bestRun}',
                  summary.cloudDays == 1
                      ? '1 cloud day'
                      : '${summary.cloudDays} cloud days',
                ].map((part) => part.replaceAll(' ', '\u00A0')).join(' · '),
                style: type.meta,
              ),
            ],
            const SizedBox(height: CurreSpace.s4),
            WeekStrip(
              days: proofWeek(summary),
              session: controller.currentSession.session.designSession,
              todayLit: summary.raysToday > 0 ? 1 : 0,
            ),
            if (!started && summary.pendingDates.isEmpty) ...[
              const SizedBox(height: CurreSpace.s3),
              Text(
                'After a task, say what changed. A specific note adds a proof day.',
                style: type.caption.copyWith(color: colors.ink2),
              ),
            ],
            if (cloudLine != null) ...[
              const SizedBox(height: CurreSpace.s3),
              Text(cloudLine, style: type.caption.copyWith(color: colors.ink2)),
            ],
            if (summary.betweenRuns) ...[
              const SizedBox(height: CurreSpace.s4),
              RunEndedNote(
                endedAt: summary.lastEndedRun!,
                best: summary.bestRun,
                total: summary.totalProofDays,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<Widget> _groupedEntries(
  BuildContext context,
  CurreController controller,
  List<_HistoryEntry> entries,
) {
  final type = Theme.of(context).extension<CurreType>()!;
  final result = <Widget>[];
  LocalDate? previous;
  for (final entry in entries) {
    if (entry.date != previous) {
      if (result.isNotEmpty) result.add(const SizedBox(height: CurreSpace.s4));
      result.add(Text(_longDate(entry.date), style: type.meta));
      result.add(const SizedBox(height: CurreSpace.s2));
      previous = entry.date;
    } else {
      result.add(const SizedBox(height: CurreSpace.s2));
    }
    result.add(switch (entry) {
      _PlanEntry(:final plan) => _PlanHistoryCard(
        plan: plan,
        controller: controller,
      ),
      _AttemptEntry(:final attempt) => _AttemptHistoryCard(
        attempt: attempt,
        controller: controller,
      ),
      _GrantEntry(:final grant) => _GrantHistoryCard(
        grant: grant,
        controller: controller,
      ),
      _ProofEntry(:final record) => _ProofHistoryCard(
        record: record,
        controller: controller,
      ),
    });
  }
  return result;
}

class _PlanHistoryCard extends StatelessWidget {
  const _PlanHistoryCard({required this.plan, required this.controller});

  final Plan plan;
  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final sky = colors.sky(plan.session.designSession);
    final highlights = <SpanHighlight>[
      for (final (index, app) in plan.apps.indexed)
        if (app.query case final span?)
          SpanHighlight(
            span.start,
            span.end,
            style: type.youSmall.copyWith(
              backgroundColor: colors.link(index + 1).mark,
              color: colors.markInk,
            ),
          ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(color: sky.bg, borderRadius: CurreShape.md),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurreGlyph(plan.session.glyph, size: 20, color: sky.fg),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Text(
                    '${_capitalise(plan.session.label)} plan',
                    style: type.label.copyWith(color: sky.fg),
                  ),
                ),
                Text(
                  '${plan.apps.length} ${plan.apps.length == 1 ? 'app' : 'apps'}',
                  style: type.meta.copyWith(color: sky.fg),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s3),
            SpanText(
              plan.intention,
              style: type.youSmall.copyWith(color: sky.fg),
              highlights: highlights,
            ),
            const SizedBox(height: CurreSpace.s3),
            Wrap(
              spacing: CurreSpace.s2,
              runSpacing: CurreSpace.s2,
              children: [
                for (final app in plan.apps)
                  _PlainPill(
                    label:
                        controller.appFor(app.packageName)?.label ??
                        app.packageName,
                    foreground: sky.fg,
                    background: sky.fg.withValues(alpha: .10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttemptHistoryCard extends StatelessWidget {
  const _AttemptHistoryCard({required this.attempt, required this.controller});

  final Attempt attempt;
  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final reason = attempt.reason;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: CurreSpace.s2,
              runSpacing: CurreSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _OutcomePill(attempt.outcome),
                if (attempt.kind != null) KindChip(kind: attempt.kind!),
                if (attempt.overridden)
                  _PlainPill(
                    label: 'Waited $overrideWaitWords',
                    foreground: colors.emberText,
                    background: colors.marker,
                  ),
              ],
            ),
            const SizedBox(height: CurreSpace.s3),
            Text(
              'Why now? · ${controller.appFor(attempt.packageName)?.label ?? attempt.packageName}',
              style: type.label,
            ),
            const SizedBox(height: CurreSpace.s1),
            if (reason == null)
              Text(
                'Reason wasn’t stored in this older entry.',
                style: type.caption.copyWith(color: colors.ink3),
              )
            else
              SpanText(
                reason,
                style: type.youSmall,
                highlights: _historyHighlights(
                  context,
                  reason,
                  attempt.highlights,
                  ordinaryMark: attempt.outcome == UnlockOutcome.flagged
                      ? colors.guardMark
                      : colors.marker,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GrantHistoryCard extends StatelessWidget {
  const _GrantHistoryCard({required this.grant, required this.controller});

  final Grant grant;
  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final open = colors.outcome(Outcome.open, laterTarget: Session.evening);
    final minutes = grant.expiresAt.difference(grant.grantedAt).inMinutes;
    return DecoratedBox(
      decoration: BoxDecoration(color: open.bg, borderRadius: CurreShape.md),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurreGlyph(CurreGlyphKind.rise, size: 20, color: open.fg),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Text(
                    '${controller.appFor(grant.packageName)?.label ?? grant.packageName} came back',
                    style: type.label.copyWith(color: open.fg),
                  ),
                ),
                Text('$minutes min', style: type.meta.copyWith(color: open.fg)),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            SpanText(
              grant.reason,
              style: type.youSmall.copyWith(color: open.fg),
              highlights: _historyHighlights(
                context,
                grant.reason,
                const <SourceSpan>[],
              ),
            ),
            if (grant.source == GrantSource.override) ...[
              const SizedBox(height: CurreSpace.s2),
              Text(
                'Opened after waiting $overrideWaitWords',
                style: type.caption.copyWith(color: open.fg),
              ),
            ],
            if (grant.source == GrantSource.later) ...[
              const SizedBox(height: CurreSpace.s2),
              Text(
                'Saved for later, then opened from a plan',
                style: type.caption.copyWith(color: open.fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A task closed after it started: its evidence named honestly
/// (supported, waiting to be checked, or done without proof) and the
/// user's own words, with the part that counted marked.
class _ProofHistoryCard extends StatelessWidget {
  const _ProofHistoryCard({required this.record, required this.controller});

  final ProofRecord record;
  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final (label, glyph) = record.countsForProoflight
        ? ('Supported proof', CurreGlyphKind.check)
        : record.isPending
        ? ('Waiting to be checked', CurreGlyphKind.later)
        : ('Marked done', CurreGlyphKind.kindTask);
    final supported = record.countsForProoflight;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurreGlyph(
                  glyph,
                  size: 20,
                  color: supported ? colors.emberText : colors.ink3,
                ),
                const SizedBox(width: CurreSpace.s2),
                Expanded(
                  child: Text(
                    label,
                    style: type.label.copyWith(
                      color: supported ? colors.emberText : colors.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text(
              controller.titleFor(
                planId: record.planId,
                packageName: record.packageName,
              ),
              style: type.label,
            ),
            const SizedBox(height: CurreSpace.s1),
            if (record.note.isEmpty)
              Text('No note', style: type.caption.copyWith(color: colors.ink3))
            else
              SpanText(
                record.note,
                style: type.youSmall,
                highlights: _historyHighlights(
                  context,
                  record.note,
                  <SourceSpan>[?record.result, ?record.learning],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<SpanHighlight> _historyHighlights(
  BuildContext context,
  String text,
  Iterable<SourceSpan> ordinary, {
  Color? ordinaryMark,
}) {
  final colors = Theme.of(context).extension<CurreColors>()!;
  final type = Theme.of(context).extension<CurreType>()!;
  final hidden = personalDetailPlaceholdersIn(text);
  bool touchesHidden(SourceSpan span) =>
      hidden.any((item) => span.start < item.end && item.start < span.end);
  return <SpanHighlight>[
    for (final span in ordinary)
      if (!touchesHidden(span))
        SpanHighlight(
          span.start,
          span.end,
          style: type.youSmall.copyWith(
            backgroundColor: ordinaryMark ?? colors.marker,
            color: colors.markInk,
          ),
        ),
    for (final span in hidden)
      SpanHighlight(
        span.start,
        span.end,
        semanticsLabel: 'Personal detail hidden',
        style: type.youSmall.copyWith(
          backgroundColor: colors.guardMark,
          color: colors.markInk,
        ),
      ),
  ];
}

class _OutcomePill extends StatelessWidget {
  const _OutcomePill(this.outcome);

  final UnlockOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final pair = colors.outcome(
      outcome.designOutcome,
      laterTarget: Session.evening,
    );
    return _PlainPill(
      label: switch (outcome) {
        UnlockOutcome.open => 'Opened',
        UnlockOutcome.later => 'Not now',
        UnlockOutcome.specify => 'Needed more detail',
        UnlockOutcome.flagged => 'Not a reason',
        UnlockOutcome.unavailable => 'Couldn’t check',
      },
      foreground: pair.fg,
      background: pair.bg,
    );
  }
}

class _PlainPill extends StatelessWidget {
  const _PlainPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: ShapeDecoration(color: background, shape: CurreShape.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CurreSpace.s3,
          vertical: CurreSpace.s2,
        ),
        child: Text(label, style: type.caption.copyWith(color: foreground)),
      ),
    );
  }
}

sealed class _HistoryEntry {
  const _HistoryEntry(this.date, this.sortAt);

  final LocalDate date;
  final DateTime sortAt;
}

class _PlanEntry extends _HistoryEntry {
  const _PlanEntry(super.date, super.sortAt, this.plan);
  final Plan plan;
}

class _AttemptEntry extends _HistoryEntry {
  const _AttemptEntry(super.date, super.sortAt, this.attempt);
  final Attempt attempt;
}

class _GrantEntry extends _HistoryEntry {
  const _GrantEntry(super.date, super.sortAt, this.grant);
  final Grant grant;
}

class _ProofEntry extends _HistoryEntry {
  const _ProofEntry(super.date, super.sortAt, this.record);
  final ProofRecord record;
}

List<_HistoryEntry> _entries(CurreController controller) {
  final entries = <_HistoryEntry>[
    for (final plan in controller.historyPlans)
      _PlanEntry(plan.date, _planStart(controller.settings, plan), plan),
    for (final attempt in controller.historyAttempts)
      _AttemptEntry(_localDate(attempt.at), attempt.at, attempt),
    for (final grant in controller.historyGrants)
      _GrantEntry(_localDate(grant.grantedAt), grant.grantedAt, grant),
    // Proof records outlive the 30-day history without their words; only
    // the ones that still have them are told here.
    for (final record in controller.proofRecords)
      if ((record.note.isNotEmpty || record.taskText.isNotEmpty) &&
          !record.submittedAt.isBefore(
            controller.now.toUtc().subtract(CurreLocalStore.historyRetention),
          ))
        _ProofEntry(record.date, record.submittedAt, record),
  ]..sort((a, b) => b.sortAt.compareTo(a.sortAt));
  return entries;
}

DateTime _planStart(Settings settings, Plan plan) {
  final time = settings.sessionStarts[plan.session]!;
  return DateTime(
    plan.date.year,
    plan.date.month,
    plan.date.day,
    time.hour,
    time.minute,
  ).toUtc();
}

LocalDate _localDate(DateTime instant) {
  final local = instant.toLocal();
  return LocalDate(local.year, local.month, local.day);
}

LocalDate _addDays(LocalDate value, int days) {
  final shifted = DateTime.utc(value.year, value.month, value.day + days);
  return LocalDate(shifted.year, shifted.month, shifted.day);
}

String _shortDay(LocalDate value) {
  const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final weekday = DateTime.utc(value.year, value.month, value.day).weekday;
  return names[weekday - 1];
}

String _longDate(LocalDate value) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${_shortDay(value)}, ${value.day} ${months[value.month - 1]}';
}

String _capitalise(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}';

extension on UnlockOutcome {
  Outcome get designOutcome => switch (this) {
    UnlockOutcome.open => Outcome.open,
    UnlockOutcome.later => Outcome.later,
    UnlockOutcome.specify => Outcome.specify,
    UnlockOutcome.flagged => Outcome.flagged,
    UnlockOutcome.unavailable => Outcome.unavailable,
  };
}
