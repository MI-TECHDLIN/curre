import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

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
                const _ProofSlot(),
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
                            'Your check-ins and deliberate unlock choices will appear here. Nothing is uploaded.',
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
            Text(
              '$count of 21 sessions started with a plan',
              style: type.title,
            ),
            const SizedBox(height: CurreSpace.s1),
            Text(
              'Morning · afternoon · evening, across the last seven days',
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

class _ProofSlot extends StatelessWidget {
  const _ProofSlot();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: CurreShape.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Row(
          children: [
            CurreGlyph(CurreGlyphKind.streak, color: colors.ink3),
            const SizedBox(width: CurreSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proof days · —', style: type.label),
                  Text(
                    'Reserved for Prooflight. No proof is counted here yet.',
                    style: type.caption.copyWith(color: colors.ink3),
                  ),
                ],
              ),
            ),
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
                    '${_capitalise(plan.session.label)} check-in',
                    style: type.label.copyWith(color: sky.fg),
                  ),
                ),
                Text(
                  '${plan.apps.length} ${plan.apps.length == 1 ? 'door' : 'doors'}',
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
                if (attempt.kind != null)
                  KindChip(
                    kind: attempt.kind!,
                    confidence: attempt.confidence,
                    threshold: controller.settings.threshold,
                  ),
                if (attempt.overridden)
                  _PlainPill(
                    label: '60 s override used',
                    foreground: colors.emberText,
                    background: colors.marker,
                  ),
              ],
            ),
            const SizedBox(height: CurreSpace.s3),
            Text(
              'Unlock · ${controller.appFor(attempt.packageName)?.label ?? attempt.packageName}',
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
                highlights: [
                  for (final span in attempt.highlights)
                    SpanHighlight(
                      span.start,
                      span.end,
                      style: type.youSmall.copyWith(
                        backgroundColor:
                            attempt.outcome == UnlockOutcome.flagged
                            ? colors.guardMark
                            : colors.marker,
                        color: colors.markInk,
                      ),
                    ),
                ],
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
                    '${controller.appFor(grant.packageName)?.label ?? grant.packageName} came into sight',
                    style: type.label.copyWith(color: open.fg),
                  ),
                ),
                Text('$minutes min', style: type.meta.copyWith(color: open.fg)),
              ],
            ),
            const SizedBox(height: CurreSpace.s2),
            Text(grant.reason, style: type.youSmall.copyWith(color: open.fg)),
            if (grant.source == GrantSource.override) ...[
              const SizedBox(height: CurreSpace.s2),
              Text(
                'Opened after the 60-second wait',
                style: type.caption.copyWith(color: open.fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
      label: _capitalise(outcome.name),
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

List<_HistoryEntry> _entries(CurreController controller) {
  final entries = <_HistoryEntry>[
    for (final plan in controller.historyPlans)
      _PlanEntry(plan.date, _planStart(controller.settings, plan), plan),
    for (final attempt in controller.historyAttempts)
      _AttemptEntry(_localDate(attempt.at), attempt.at, attempt),
    for (final grant in controller.historyGrants)
      _GrantEntry(_localDate(grant.grantedAt), grant.grantedAt, grant),
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
