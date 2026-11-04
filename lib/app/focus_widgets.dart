import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../platform/platform.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';

/// "Mon 17 Nov".
String formatFocusDate(LocalDate day) {
  const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final weekday = DateTime.utc(day.year, day.month, day.day).weekday;
  return '${weekdays[weekday - 1]} ${day.day} ${months[day.month - 1]}';
}

/// "1 day" / "5 days".
String dayCount(int days) => days == 1 ? '1 day' : '$days days';

extension FocusPurposeArt on FocusPurpose {
  CurreProp get prop => switch (this) {
    FocusPurpose.exams => CurreProp.openBook,
    FocusPurpose.deadline => CurreProp.hourglass,
    FocusPurpose.habit => CurreProp.seedling,
    FocusPurpose.other => CurreProp.star,
  };
}

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
                label: option.label,
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
              labelText: 'Your goal, in a few words (optional)',
              hintText: purpose!.goalHint,
              filled: true,
              fillColor: colors.raised,
              counterText: '',
            ),
            onChanged: onGoalChanged,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: CurreSpace.s3),
          Text('Until when?', style: type.label),
          const SizedBox(height: CurreSpace.s2),
          Wrap(
            spacing: CurreSpace.s2,
            runSpacing: CurreSpace.s2,
            children: [
              for (final length in FocusLength.values)
                FocusChoiceChip(
                  key: ValueKey('focus-length-${length.days}'),
                  label: length.label,
                  selected: !picked && shownDays == length.days,
                  onTap: () => onDays(length.days),
                ),
              FocusChoiceChip(
                key: const Key('focus-pick-date'),
                label: picked ? formatFocusDate(endsOn!) : 'Pick a date',
                selected: picked,
                onTap: () => _pickDate(context),
              ),
            ],
          ),
          const SizedBox(height: CurreSpace.s2),
          Text(
            'Ends ${formatFocusDate(end)}, in ${dayCount(daysBetween(today, end))}. You can change it later.',
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
    helpText: 'Focus ends on',
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
      showCurreSnack(
        context,
        'Curre couldn’t save your focus. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    final colors = Theme.of(context).extension<CurreColors>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CurreSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What’s this focus for?', style: type.headline),
            const SizedBox(height: CurreSpace.s2),
            Text(
              'Curre helps most for a stretch with an end: exams, a deadline, a habit you want to break.',
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
              label: _purpose == null ? 'Pick what it’s for' : 'Start my focus',
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
    return _FocusCardFrame(
      key: const Key('home-focus-offer'),
      prop: CurreProp.pin,
      title: 'Set a focus?',
      children: [
        const SizedBox(height: CurreSpace.s2),
        Text(
          'Curre helps most for a stretch with an end: exams, a deadline, a habit to break. Pick one and when it ends.',
          style: type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: CurreSpace.s4),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: controller.dismissFocusOffer,
                child: const Text('Maybe later'),
              ),
            ),
            const SizedBox(width: CurreSpace.s2),
            Expanded(
              flex: 2,
              child: CurreSecondaryButton(
                label: 'Set a focus',
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
    final left = focus.daysLeft(controller.today);
    final resting = controller.isRestDay;
    return _FocusCardFrame(
      key: const Key('home-focus'),
      prop: resting ? CurreProp.hotDrink : focus.purpose.prop,
      eyebrow: resting ? 'Rest day' : 'Your focus',
      title: focus.title,
      children: [
        const SizedBox(height: CurreSpace.s2),
        Text(
          resting
              ? 'Hidden apps open without asking today, their notifications come through, and reminders stay quiet. Your proof days are safe. Back to focus tomorrow.'
              : '${dayCount(left)} left · ends ${formatFocusDate(focus.endsOn)}',
          style: type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: CurreSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: resting
              ? TextButton(
                  onPressed: () => _endRest(context),
                  child: const Text('Back to focus now'),
                )
              : controller.canRestToday
              ? TextButton(
                  key: const Key('home-take-rest-day'),
                  onPressed: () => confirmRestDay(context, controller),
                  child: const Text('Take today off'),
                )
              : Text(
                  'Next rest day: ${_nextRest(controller)}',
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
        showCurreSnack(
          context,
          'Curre couldn’t change that. Please try again.',
        );
      }
    }
  }
}

String _nextRest(CurreController controller) {
  final next = controller.nextRestDay;
  if (next == controller.today) return 'today';
  if (next == controller.today.addDays(1)) return 'tomorrow';
  return formatFocusDate(next);
}

/// Asks once, then makes today a rest day.
Future<void> confirmRestDay(
  BuildContext context,
  CurreController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Take today off?'),
      content: const Text(
        'Until tomorrow morning, hidden apps open without asking why, their notifications come through and Curre sends no reminders. Your proof days stay safe. You can take one rest day a week.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep going'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Take today off'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final rested = await controller.takeRestDay();
    if (context.mounted && rested) {
      showCurreSnack(context, 'Enjoy your rest day. Back to focus tomorrow.');
    }
  } on Object {
    if (context.mounted) {
      showCurreSnack(context, 'Curre couldn’t save that. Please try again.');
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
    return _FocusCardFrame(
      key: const Key('home-focus-end'),
      prop: CurreProp.sparkles,
      eyebrow: 'Your focus is done',
      title: focus.title,
      tint: sky.bg,
      children: [
        const SizedBox(height: CurreSpace.s2),
        Text(
          summary.restDays == 0
              ? '${dayCount(summary.days)} of focus.'
              : '${dayCount(summary.days)} of focus, '
                    '${summary.restDays == 1 ? '1 rest day' : '${summary.restDays} rest days'}.',
          style: type.body.copyWith(color: colors.ink2),
        ),
        const SizedBox(height: CurreSpace.s4),
        Row(
          children: [
            _Stat(value: summary.proofDays, label: 'days with proof'),
            const SizedBox(width: CurreSpace.s2),
            _Stat(value: summary.proofs, label: 'tasks proved'),
            const SizedBox(width: CurreSpace.s2),
            _Stat(
              value: summary.opensAvoided,
              label: 'hidden apps left closed',
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        Text(
          focus.purpose.endLine,
          style: type.you.copyWith(color: colors.ink),
        ),
        const SizedBox(height: CurreSpace.s4),
        CurrePrimaryButton(
          label: 'Start another focus period',
          glyph: CurreGlyphKind.go,
          onPressed: () => showFocusSheet(context, controller: controller),
        ),
        const SizedBox(height: CurreSpace.s2),
        CurreSecondaryButton(
          label: 'Go back to my old home screen',
          glyph: CurreGlyphKind.homeRole,
          onPressed: () => _leave(context),
        ),
        const SizedBox(height: CurreSpace.s2),
        Text(
          'Your history and proof days stay on this phone either way.',
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
        showCurreSnack(context, 'Curre couldn’t save that. Please try again.');
      }
      return;
    }
    if (!context.mounted) return;
    showCurreSnack(context, homeSwitchHelp(opened));
  }
}

/// What to do in Android's settings to choose another home screen.
String homeSwitchHelp(HomeSettingsOpened opened) => switch (opened) {
  HomeSettingsOpened.homeApps => 'Choose your old home screen in the list. Curre stops asking why and lets every notification through.',
  HomeSettingsOpened.defaultApps =>
    'Tap “Home app”, then choose your old home screen.',
  HomeSettingsOpened.settings => 'Your phone opened Settings. Search for “Home app”, then choose your old home screen.',
  HomeSettingsOpened.none => 'Open your phone’s Settings app and search for “Home app”. Choose your old home screen there.',
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
                        focus?.title ?? 'No focus set',
                        style: type.label.weight(700).copyWith(fontSize: 16),
                      ),
                      Text(
                        focus == null
                            ? 'Pick what this stretch is for and when it ends.'
                            : controller.focusIsOver
                            ? 'Ended ${formatFocusDate(focus.endsOn)}. See how it went on Home.'
                            : 'Ends ${formatFocusDate(focus.endsOn)}, ${dayCount(focus.daysLeft(today))} left',
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
                label: focus == null
                    ? 'Set a focus'
                    : 'Start another focus period',
                onPressed: () =>
                    showFocusSheet(context, controller: controller),
              )
            else ...[
              CurreSecondaryButton(
                key: const Key('settings-focus-end-date'),
                label: 'Change end date',
                onPressed: () => _changeEnd(context, focus),
              ),
              const SizedBox(height: CurreSpace.s2),
              if (controller.isRestDay)
                TextButton(
                  onPressed: controller.endRestDay,
                  child: const Text('Back to focus now'),
                )
              else if (controller.canRestToday)
                TextButton(
                  onPressed: () => confirmRestDay(context, controller),
                  child: const Text('Take today off'),
                )
              else
                Text(
                  'One rest day a week. Next one: ${_nextRest(controller)}.',
                  style: type.caption.copyWith(color: colors.ink3),
                  textAlign: TextAlign.center,
                ),
              TextButton(
                key: const Key('settings-focus-end-now'),
                onPressed: () => _confirmEndNow(context),
                child: const Text('End focus now'),
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
          'Your focus now ends ${formatFocusDate(picked)}.',
        );
      }
    } on Object {
      if (context.mounted) {
        showCurreSnack(context, 'Curre couldn’t save that. Please try again.');
      }
    }
  }

  Future<void> _confirmEndNow(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End your focus now?'),
        content: const Text(
          'Home shows how it went, then you choose what’s next. Your history and proof days stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End focus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.endFocusNow();
    } on Object {
      if (context.mounted) {
        showCurreSnack(context, 'Curre couldn’t save that. Please try again.');
      }
    }
  }
}
