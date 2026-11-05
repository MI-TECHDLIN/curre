import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../l10n/l10n.dart';
import '../platform/platform.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

/// "Mon 17 Nov".
String formatFocusDate(LocalDate day, [String? locale]) => DateFormat(
  'EEE d MMM',
  locale,
).format(DateTime(day.year, day.month, day.day));

extension FocusPurposeArt on FocusPurpose {
  CurreProp get prop => switch (this) {
    FocusPurpose.exams => CurreProp.openBook,
    FocusPurpose.deadline => CurreProp.hourglass,
    FocusPurpose.habit => CurreProp.seedling,
    FocusPurpose.other => CurreProp.star,
  };

  String labelFor(AppLocalizations l10n) => switch (this) {
    FocusPurpose.exams => l10n.focusPurposeExams,
    FocusPurpose.deadline => l10n.focusPurposeDeadline,
    FocusPurpose.habit => l10n.focusPurposeHabit,
    FocusPurpose.other => l10n.focusPurposeOther,
  };

  String hintFor(AppLocalizations l10n) => switch (this) {
    FocusPurpose.exams => l10n.focusHintExams,
    FocusPurpose.deadline => l10n.focusHintDeadline,
    FocusPurpose.habit => l10n.focusHintHabit,
    FocusPurpose.other => l10n.focusHintOther,
  };

  String endLineFor(AppLocalizations l10n) => switch (this) {
    FocusPurpose.exams => l10n.focusEndExams,
    FocusPurpose.deadline => l10n.focusEndDeadline,
    FocusPurpose.habit => l10n.focusEndHabit,
    FocusPurpose.other => l10n.focusEndOther,
  };
}

extension FocusLengthLocalizations on FocusLength {
  String labelFor(AppLocalizations l10n) => switch (this) {
    FocusLength.oneWeek => l10n.focusLengthWeek,
    FocusLength.twoWeeks => l10n.focusLengthTwoWeeks,
    FocusLength.threeWeeks => l10n.focusLengthThreeWeeks,
    FocusLength.thirtyDays => l10n.focusLengthThirtyDays,
  };
}

String _focusTitle(FocusPeriod focus, AppLocalizations l10n) =>
    focus.goal.isEmpty ? focus.purpose.labelFor(l10n) : focus.goal;

/// Asks what a focus is for and how long it runs: purpose chips, a short
/// goal, ready-made lengths and a date picker. The parent keeps the
/// answers, so onboarding can save them between steps.
class FocusPicker extends StatelessWidget {
  const FocusPicker({
    super.key,
    required this.today,
    required this.purpose,
    required this.goal,
    required this.days,
    required this.endsOn,
    required this.onPurpose,
    required this.onDays,
    required this.onEndsOn,
    this.onGoalChanged,
  });

  final LocalDate today;
  final FocusPurpose? purpose;
  final TextEditingController goal;

  /// A ready-made length, or null when [endsOn] was picked instead.
  final int? days;
  final LocalDate? endsOn;
  final ValueChanged<FocusPurpose> onPurpose;
  final ValueChanged<int> onDays;
  final ValueChanged<LocalDate> onEndsOn;
  final ValueChanged<String>? onGoalChanged;

  /// The end date the current answers give.
  LocalDate get end =>
      endsOn ?? today.addDays(days ?? purpose?.defaultDays ?? 14);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final picked =
        endsOn != null && FocusLengthWords.forDays(days ?? -1) == null;
    final shownDays = endsOn == null
        ? days ?? purpose?.defaultDays ?? 14
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: CurreSpace.s2,
          runSpacing: CurreSpace.s2,
          children: [
            for (final option in FocusPurpose.values)
              FocusChoiceChip(
                key: ValueKey('focus-purpose-${option.name}'),
                label: option.labelFor(l10n),
                prop: option.prop,
                selected: option == purpose,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPurpose(option);
                },
              ),
          ],
        ),
        if (purpose != null) ...[
          const SizedBox(height: CurreSpace.s4),
          TextField(
            key: const Key('focus-goal'),
            controller: goal,
            maxLength: FocusPeriod.maxGoalLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: type.you,
            decoration: InputDecoration(
              labelText: l10n.focusGoalLabel,
              hintText: purpose!.hintFor(l10n),
              filled: true,
              fillColor: colors.raised,
              counterText: '',
            ),
            onChanged: onGoalChanged,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: CurreSpace.s3),
          Text(l10n.untilWhen, style: type.label),
          const SizedBox(height: CurreSpace.s2),
          Wrap(
            spacing: CurreSpace.s2,
            runSpacing: CurreSpace.s2,
            children: [
              for (final length in FocusLength.values)
                FocusChoiceChip(
                  key: ValueKey('focus-length-${length.days}'),
                  label: length.labelFor(l10n),
                  selected: !picked && shownDays == length.days,
                  onTap: () => onDays(length.days),
                ),
              FocusChoiceChip(
                key: const Key('focus-pick-date'),
                label: picked
                    ? formatFocusDate(endsOn!, locale)
                    : l10n.pickDate,
                selected: picked,
                onTap: () => _pickDate(context),
              ),
            ],
          ),
          const SizedBox(height: CurreSpace.s2),
          Text(
            l10n.focusEndsSummary(
              formatFocusDate(end, locale),
              l10n.daysCount(daysBetween(today, end)),
            ),
            style: type.caption.copyWith(color: colors.ink3),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showFocusDatePicker(
      context,
      today: today,
      initial: end,
      latest: today.addDays(FocusPeriod.maxDays),
    );
    if (picked != null) onEndsOn(picked);
  }
}

/// Android's calendar, for a focus end after [today].
Future<LocalDate?> showFocusDatePicker(
  BuildContext context, {
  required LocalDate today,
  required LocalDate initial,
  required LocalDate latest,
}) async {
  DateTime asDate(LocalDate day) => DateTime(day.year, day.month, day.day);
  final first = today.addDays(1);
  final start = initial.compareTo(first) < 0 ? first : initial;
  final picked = await showDatePicker(
    context: context,
    initialDate: asDate(start.compareTo(latest) > 0 ? latest : start),
    firstDate: asDate(first),
    lastDate: asDate(latest),
    helpText: context.l10n.focusEndsOn,
  );
  return picked == null ? null : LocalDate.fromLocalDateTime(picked);
}

/// A rounded choice, filled when picked.
class FocusChoiceChip extends StatelessWidget {
  const FocusChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.prop,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final CurreProp? prop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.ink : colors.raised,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.ink : colors.hairline,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CurreSpace.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CurreSpace.s4,
                vertical: CurreSpace.s2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prop != null) ...[
                    CurrePropArt(prop!, size: 22),
                    const SizedBox(width: CurreSpace.s2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: type.label.copyWith(
                        color: selected ? colors.paper : colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sets a new focus (or the next one) in a sheet; true once it is saved.
Future<bool> showFocusSheet(
  BuildContext context, {
  required CurreController controller,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).extension<CurreColors>()!.paper,
    builder: (_) => _FocusSheet(controller: controller),
  );
  return saved ?? false;
}

class _FocusSheet extends StatefulWidget {
  const _FocusSheet({required this.controller});

  final CurreController controller;

  @override
  State<_FocusSheet> createState() => _FocusSheetState();
}

class _FocusSheetState extends State<_FocusSheet> {
  final _goal = TextEditingController();
  FocusPurpose? _purpose;
  int? _days;
  LocalDate? _endsOn;
  var _saving = false;

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final purpose = _purpose;
    if (purpose == null) return;
    setState(() => _saving = true);
    try {
      await widget.controller.startFocus(
        FocusChoice(
          purpose: purpose,
          goal: _goal.text,
          days: _days,
          endsOn: _endsOn,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      showCurreSnack(context, context.l10n.focusSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CurreSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.focusQuestion, style: type.headline),
            const SizedBox(height: CurreSpace.s2),
            Text(
              l10n.focusPickerBody,
              style: type.body.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: CurreSpace.s4),
            FocusPicker(
              today: widget.controller.today,
              purpose: _purpose,
              goal: _goal,
              days: _days,
              endsOn: _endsOn,
              onPurpose: (value) => setState(() {
                _purpose = value;
                if (_endsOn == null) _days = null;
              }),
              onDays: (value) => setState(() {
                _days = value;
                _endsOn = null;
              }),
              onEndsOn: (value) => setState(() {
                _endsOn = value;
                _days = null;
              }),
            ),
            const SizedBox(height: CurreSpace.s5),
            CurrePrimaryButton(
              label: _purpose == null
                  ? l10n.pickFocusPurpose
                  : l10n.startMyFocus,
              glyph: CurreGlyphKind.go,
              onPressed: _purpose == null || _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// The focus on Home: "Set a focus" when there is none, its goal and days
/// left while it runs (with the rest day), and how it went once it ends.
class FocusHomeCard extends StatelessWidget {
  const FocusHomeCard({super.key, required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final focus = controller.focus;
    if (focus == null) {
      if (controller.focusOfferDismissed) return const SizedBox.shrink();
      return _FocusOfferCard(controller: controller);
    }
    if (controller.focusIsOver) {
      return FocusEndCard(controller: controller, focus: focus);
    }
    return _FocusRunningCard(controller: controller, focus: focus);
  }
}

class _FocusCardFrame extends StatelessWidget {
  const _FocusCardFrame({
    super.key,
    required this.prop,
    required this.title,
    required this.children,
    this.eyebrow,
    this.tint,
  });

  final CurreProp prop;
  final String? eyebrow;
  final String title;
  final List<Widget> children;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurrePropArt(prop, size: 44),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null)
                        Text(
                          eyebrow!,
                          style: type.caption.copyWith(color: colors.ink3),
                        ),
                      Text(title, style: type.title),
                    ],
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FocusOfferCard extends StatelessWidget {
  const _FocusOfferCard({required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    return _FocusCardFrame(
      key: const Key('home-focus-offer'),
      prop: CurreProp.pin,
      title: l10n.setFocusQuestion,
      children: [
        const SizedBox(height: CurreSpace.s2),
        Text(
          l10n.focusOfferBody,
          style: type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: CurreSpace.s4),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: controller.dismissFocusOffer,
                child: Text(l10n.maybeLater),
              ),
            ),
            const SizedBox(width: CurreSpace.s2),
            Expanded(
              flex: 2,
              child: CurreSecondaryButton(
                label: l10n.setFocus,
                onPressed: () =>
                    showFocusSheet(context, controller: controller),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusRunningCard extends StatelessWidget {
  const _FocusRunningCard({required this.controller, required this.focus});

  final CurreController controller;
  final FocusPeriod focus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final left = focus.daysLeft(controller.today);
    final resting = controller.isRestDay;
    return _FocusCardFrame(
      key: const Key('home-focus'),
      prop: resting ? CurreProp.hotDrink : focus.purpose.prop,
      eyebrow: resting ? l10n.restDay : l10n.yourFocus,
      title: _focusTitle(focus, l10n),
      children: [
        const SizedBox(height: CurreSpace.s2),
        Text(
          resting
              ? l10n.restDayBody
              : l10n.focusLeft(
                  l10n.daysCount(left),
                  formatFocusDate(focus.endsOn, locale),
                ),
          style: type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: CurreSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: resting
              ? TextButton(
                  onPressed: () => _endRest(context),
                  child: Text(l10n.backToFocusNow),
                )
              : controller.canRestToday
              ? TextButton(
                  key: const Key('home-take-rest-day'),
                  onPressed: () => confirmRestDay(context, controller),
                  child: Text(l10n.takeTodayOff),
                )
              : Text(
                  l10n.nextRestDay(_nextRest(context, controller)),
                  style: type.caption.copyWith(color: colors.ink3),
                ),
        ),
      ],
    );
  }

  Future<void> _endRest(BuildContext context) async {
    try {
      await controller.endRestDay();
    } on Object {
      if (context.mounted) {
        showCurreSnack(context, context.l10n.couldNotSave);
      }
    }
  }
}

String _nextRest(BuildContext context, CurreController controller) {
  final l10n = context.l10n;
  final next = controller.nextRestDay;
  if (next == controller.today) return l10n.today;
  if (next == controller.today.addDays(1)) return l10n.tomorrow;
  return formatFocusDate(next, Localizations.localeOf(context).toLanguageTag());
}

/// Asks once, then makes today a rest day.
Future<void> confirmRestDay(
  BuildContext context,
  CurreController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.takeTodayOffQuestion),
      content: Text(context.l10n.takeTodayOffBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.keepGoing),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.takeTodayOff),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final rested = await controller.takeRestDay();
    if (context.mounted && rested) {
      showCurreSnack(context, context.l10n.enjoyRestDay);
    }
  } on Object {
    if (context.mounted) {
      showCurreSnack(context, context.l10n.couldNotSave);
    }
  }
}

/// How the focus went, once its end date has come, and what's next.
class FocusEndCard extends StatelessWidget {
  const FocusEndCard({
    super.key,
    required this.controller,
    required this.focus,
  });

  final CurreController controller;
  final FocusPeriod focus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final summary = controller.focusSummary!;
    final sky = colors.sky(Session.morning);
    final l10n = context.l10n;
    return _FocusCardFrame(
      key: const Key('home-focus-end'),
      prop: CurreProp.sparkles,
      eyebrow: l10n.focusDone,
      title: _focusTitle(focus, l10n),
      tint: sky.bg,
      children: [
        const SizedBox(height: CurreSpace.s2),
        Text(
          summary.restDays == 0
              ? l10n.focusSummaryDays(l10n.daysCount(summary.days))
              : l10n.focusSummaryWithRest(
                  l10n.daysCount(summary.days),
                  l10n.restDaysCount(summary.restDays),
                ),
          style: type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: CurreSpace.s4),
        Row(
          children: [
            _Stat(value: summary.proofDays, label: l10n.daysWithProof),
            const SizedBox(width: CurreSpace.s2),
            _Stat(value: summary.proofs, label: l10n.tasksProved),
            const SizedBox(width: CurreSpace.s2),
            _Stat(
              value: summary.opensAvoided,
              label: l10n.hiddenAppsLeftClosed,
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        Text(
          focus.purpose.endLineFor(l10n),
          style: type.you.copyWith(color: colors.ink),
        ),
        const SizedBox(height: CurreSpace.s4),
        CurrePrimaryButton(
          label: l10n.startAnotherFocus,
          glyph: CurreGlyphKind.go,
          onPressed: () => showFocusSheet(context, controller: controller),
        ),
        const SizedBox(height: CurreSpace.s2),
        CurreSecondaryButton(
          label: l10n.oldHomeScreen,
          glyph: CurreGlyphKind.homeRole,
          onPressed: () => _leave(context),
        ),
        const SizedBox(height: CurreSpace.s2),
        Text(
          l10n.focusHistoryStays,
          style: type.caption.copyWith(color: colors.ink3),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _leave(BuildContext context) async {
    final HomeSettingsOpened opened;
    try {
      opened = await controller.leaveForOldHomeScreen();
    } on Object {
      if (context.mounted) {
        showCurreSnack(context, context.l10n.couldNotSave);
      }
      return;
    }
    if (!context.mounted) return;
    showCurreSnack(context, homeSwitchHelp(opened, context.l10n));
  }
}

/// What to do in Android's settings to choose another home screen.
String homeSwitchHelp(HomeSettingsOpened opened, AppLocalizations l10n) =>
    switch (opened) {
      HomeSettingsOpened.homeApps => l10n.chooseOldHome,
      HomeSettingsOpened.defaultApps => l10n.tapOldHome,
      HomeSettingsOpened.settings => l10n.searchOldHome,
      HomeSettingsOpened.none => l10n.openSettingsOldHome,
    };

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper.withValues(alpha: .7),
            borderRadius: CurreShape.md,
          ),
          child: Padding(
            padding: const EdgeInsets.all(CurreSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: type.figure.copyWith(color: colors.ink)),
                Text(label, style: type.caption.copyWith(color: colors.ink2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Your focus" in Curre settings: set one, move its end, end it now, or
/// take today off.
class FocusSettingsCard extends StatelessWidget {
  const FocusSettingsCard({super.key, required this.controller});

  final CurreController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final focus = controller.focus;
    final today = controller.today;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DecoratedBox(
      key: const Key('settings-focus'),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: CurreShape.md,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CurrePropArt(focus?.purpose.prop ?? CurreProp.pin, size: 40),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        focus == null
                            ? l10n.noFocusSet
                            : _focusTitle(focus, l10n),
                        style: type.label.weight(700).copyWith(fontSize: 16),
                      ),
                      Text(
                        focus == null
                            ? l10n.focusSettingsEmpty
                            : controller.focusIsOver
                            ? l10n.focusEndedOn(
                                formatFocusDate(focus.endsOn, locale),
                              )
                            : l10n.focusEndsLeft(
                                formatFocusDate(focus.endsOn, locale),
                                l10n.daysCount(focus.daysLeft(today)),
                              ),
                        style: type.caption.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CurreSpace.s3),
            if (focus == null || controller.focusIsOver)
              CurreSecondaryButton(
                label: focus == null ? l10n.setFocus : l10n.startAnotherFocus,
                onPressed: () =>
                    showFocusSheet(context, controller: controller),
              )
            else ...[
              CurreSecondaryButton(
                key: const Key('settings-focus-end-date'),
                label: l10n.changeEndDate,
                onPressed: () => _changeEnd(context, focus),
              ),
              const SizedBox(height: CurreSpace.s2),
              if (controller.isRestDay)
                TextButton(
                  onPressed: controller.endRestDay,
                  child: Text(l10n.backToFocusNow),
                )
              else if (controller.canRestToday)
                TextButton(
                  onPressed: () => confirmRestDay(context, controller),
                  child: Text(l10n.takeTodayOff),
                )
              else
                Text(
                  l10n.weeklyRestNext(_nextRest(context, controller)),
                  style: type.caption.copyWith(color: colors.ink3),
                  textAlign: TextAlign.center,
                ),
              TextButton(
                key: const Key('settings-focus-end-now'),
                onPressed: () => _confirmEndNow(context),
                child: Text(l10n.endFocusNow),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeEnd(BuildContext context, FocusPeriod focus) async {
    final picked = await showFocusDatePicker(
      context,
      today: controller.today,
      initial: focus.endsOn,
      latest: focus.latestEnd(),
    );
    if (picked == null) return;
    try {
      await controller.changeFocusEnd(picked);
      if (context.mounted) {
        showCurreSnack(
          context,
          context.l10n.focusNowEnds(
            formatFocusDate(
              picked,
              Localizations.localeOf(context).toLanguageTag(),
            ),
          ),
        );
      }
    } on Object {
      if (context.mounted) {
        showCurreSnack(context, context.l10n.couldNotSave);
      }
    }
  }

  Future<void> _confirmEndNow(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.endFocusQuestion),
        content: Text(context.l10n.endFocusBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.keepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.endFocus),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.endFocusNow();
    } on Object {
      if (context.mounted) {
        showCurreSnack(context, context.l10n.couldNotSave);
      }
    }
  }
}
