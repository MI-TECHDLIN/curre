import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import '../design/design.dart';
import '../platform/speech_input.dart';
import 'app_widgets.dart';
import 'curre_controller.dart';
import 'prooflight_view.dart';

enum CompletionSheetState {
  compose,
  thinking,
  vagueFollowUp,
  pending,
  accepted,
  selfReported,
}

/// The one question Prooflight asks after a task (proof audit §3, rule 3).
const completionQuestion = 'What changed, finished, or became clear?';

/// The longest note the phone sends, in code points.
const completionNoteLimit = 300;

Future<void> showCompletionSheet(
  BuildContext context, {
  required CurreController controller,
  required PlannedTask task,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => CompletionSheet(controller: controller, task: task),
);

/// The calm close-out after a task Curre saw start: one question, typed or
/// spoken, and one gentle follow-up when the answer is vague. A specific
/// answer plays the Prooflight moment; anything else is kept honestly as
/// done or waiting, never as a failure.
class CompletionSheet extends StatefulWidget {
  const CompletionSheet({
    super.key,
    required this.controller,
    required this.task,
  });

  final CurreController controller;
  final PlannedTask task;

  @override
  State<CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<CompletionSheet> {
  final _note = TextEditingController();
  var _state = CompletionSheetState.compose;
  ProofSubmission? _submission;
  String? _message;

  CurreController get controller => widget.controller;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final task = widget.task;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: CurreShape.sheet,
          boxShadow: CurreElevation.e2,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CurreSpace.s5),
            // The sheet grows and shrinks with its state instead of
            // jumping.
            child: AnimatedSize(
              duration: CurreMotion.of(context, CurreMotion.base),
              curve: CurreMotion.standard,
              alignment: Alignment.topCenter,
              child: ListenableBuilder(
                listenable: _note,
                builder: (context, _) => CompletionSheetView(
                  state: _state,
                  task: task,
                  title: controller.taskTitle(task),
                  link: _link(task),
                  session: controller.currentSession.session.designSession,
                  noteController: _note,
                  submission: _submission,
                  avatarId: controller.settings.avatarId,
                  displayName: controller.settings.displayName,
                  message: _message,
                  onSubmit: _note.text.trim().isEmpty ? null : _submit,
                  onSpeak: _listen,
                  onMarkDone: _markDone,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The door's link number in its plan, so the proof card wears the same
  /// colour as the door and the plan's marked words.
  int? _link(PlannedTask task) {
    final package = task.packageName;
    if (package == null) return null;
    for (final plan in controller.plans) {
      if (plan.id != task.planId) continue;
      final index = plan.apps.indexWhere((app) => app.packageName == package);
      if (index >= 0) return index + 1;
    }
    return null;
  }

  String get _cleanNote =>
      String.fromCharCodes(_note.text.trim().runes.take(completionNoteLimit));

  Future<void> _listen() async {
    final result = await controller.speech.listen(prompt: completionQuestion);
    if (!mounted) return;
    switch (result.status) {
      case SpeechInputStatus.recognized:
        final spoken = result.transcript!;
        final written = _note.text.trim();
        // In the follow-up, speech adds the detail to the first answer.
        final text =
            _state == CompletionSheetState.vagueFollowUp && written.isNotEmpty
            ? '$written $spoken'
            : spoken;
        _note.text = String.fromCharCodes(text.runes.take(completionNoteLimit));
        setState(() => _message = null);
      case SpeechInputStatus.cancelled:
        break;
      case SpeechInputStatus.unavailable:
        setState(() => _message = result.message);
    }
  }

  Future<void> _submit() async {
    final note = _cleanNote;
    if (note.isEmpty || _state == CompletionSheetState.thinking) return;
    FocusScope.of(context).unfocus();
    final followUp = _state == CompletionSheetState.vagueFollowUp;
    setState(() {
      _state = CompletionSheetState.thinking;
      _message = null;
    });
    final submission = await controller.submitProof(
      task: widget.task,
      note: note,
    );
    if (!mounted) return;
    setState(() {
      _submission = submission;
      _state = switch (submission.record.judgement) {
        _ when submission.supported => CompletionSheetState.accepted,
        ProofJudgement.pending => CompletionSheetState.pending,
        ProofJudgement.vague when !followUp =>
          CompletionSheetState.vagueFollowUp,
        _ => CompletionSheetState.selfReported,
      };
    });
    if (_state == CompletionSheetState.vagueFollowUp) {
      // The first answer stays in the field, so one detail can join it.
      _note.selection = TextSelection.collapsed(offset: _note.text.length);
    }
  }

  Future<void> _markDone() async {
    if (_state == CompletionSheetState.vagueFollowUp) {
      // The first answer is already kept as done, without proof.
      setState(() => _state = CompletionSheetState.selfReported);
      return;
    }
    final submission = await controller.markDone(
      task: widget.task,
      note: _cleanNote,
    );
    if (!mounted) return;
    setState(() {
      _submission = submission;
      _state = CompletionSheetState.selfReported;
    });
  }
}

/// Renders one state of the completion sheet. It decides nothing: the
/// production sheet and the widget tests drive it.
class CompletionSheetView extends StatelessWidget {
  const CompletionSheetView({
    super.key,
    required this.state,
    required this.task,
    required this.title,
    required this.noteController,
    required this.onClose,
    this.link,
    this.session = Session.morning,
    this.submission,
    this.avatarId,
    this.displayName,
    this.message,
    this.onSubmit,
    this.onSpeak,
    this.onMarkDone,
  });

  final CompletionSheetState state;
  final PlannedTask task;

  /// Where the task went: "YouTube → Search “G chord”".
  final String title;
  final int? link;
  final Session session;
  final TextEditingController noteController;
  final ProofSubmission? submission;
  final String? avatarId;
  final String? displayName;

  /// A short line under the field, such as speech being unavailable.
  final String? message;
  final VoidCallback? onSubmit;
  final VoidCallback? onSpeak;
  final VoidCallback? onMarkDone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (state == CompletionSheetState.accepted && submission != null) {
      return ProoflightMoment(
        submission: submission!,
        title: title,
        link: link,
        session: session,
        avatarId: avatarId,
        displayName: displayName,
        onContinue: onClose,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const SizedBox(height: CurreSpace.s4),
        switch (state) {
          CompletionSheetState.compose => _compose(context),
          CompletionSheetState.thinking => _thinking(context),
          CompletionSheetState.vagueFollowUp => _followUp(context),
          CompletionSheetState.pending => _pending(context),
          CompletionSheetState.accepted ||
          CompletionSheetState.selfReported => _done(context),
        },
      ],
    );
  }

  Widget _header(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: type.label.weight(660),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: CurreSpace.s1),
              Text(
                task.text,
                style: type.youSmall.copyWith(color: colors.ink2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: CurreSpace.s3),
        RoundGlyphButton(
          glyph: CurreGlyphKind.close,
          label: 'Close',
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _compose(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      key: const Key('proof-compose'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          completionQuestion,
          style: type.headline.copyWith(fontSize: 24, height: 30 / 24),
        ),
        const SizedBox(height: CurreSpace.s3),
        _field(context, hint: 'One sentence is enough'),
        ..._actions(context),
      ],
    );
  }

  Widget _followUp(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final prompt = switch (submission?.kind) {
      ProofKind.future => 'That sounds like what comes next. What changed, finished, or became clear?',
      ProofKind.unrelated => 'Say how it connects to your plan. What changed, finished, or became clear?',
      _ => 'A name, a number or a step is enough. What changed, finished, or became clear?',
    };
    return Column(
      key: const Key('proof-vague-follow-up'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add one detail', style: type.title),
        const SizedBox(height: CurreSpace.s1),
        Text(prompt, style: type.body.copyWith(color: colors.ink2)),
        const SizedBox(height: CurreSpace.s3),
        _field(context, hint: 'Add what changed'),
        ..._actions(context),
      ],
    );
  }

  List<Widget> _actions(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return [
      if (message case final text?) ...[
        const SizedBox(height: CurreSpace.s2),
        Text(text, style: type.caption.copyWith(color: colors.ink2)),
      ],
      const SizedBox(height: CurreSpace.s4),
      CurrePrimaryButton(
        label: 'Add proof',
        glyph: CurreGlyphKind.check,
        onPressed: onSubmit,
      ),
      const SizedBox(height: CurreSpace.s2),
      CurreSecondaryButton(label: 'Just mark it done', onPressed: onMarkDone),
    ];
  }

  Widget _field(BuildContext context, {required String hint}) => TextField(
    key: const Key('completion-note'),
    controller: noteController,
    minLines: 3,
    maxLines: 5,
    maxLength: completionNoteLimit,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      hintText: hint,
      suffixIcon: IconButton(
        onPressed: onSpeak,
        tooltip: 'Say it instead',
        icon: const CurreGlyph(CurreGlyphKind.speak, size: 21),
      ),
    ),
  );

  Widget _thinking(BuildContext context) {
    final type = Theme.of(context).extension<CurreType>()!;
    return Padding(
      key: const Key('proof-thinking'),
      padding: const EdgeInsets.symmetric(vertical: CurreSpace.s6),
      child: Column(
        children: [
          HorizonLine(
            scanning: !MediaQuery.disableAnimationsOf(context),
            semanticLabel: 'Reading your note',
          ),
          const SizedBox(height: CurreSpace.s3),
          Text('Reading your note…', style: type.body),
        ],
      ),
    );
  }

  Widget _pending(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return Column(
      key: const Key('proof-pending'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _NoteCard(
          glyph: CurreGlyphKind.later,
          headline: 'Your note is saved',
          body: 'Couldn’t check it right now. It will be checked once you’re back online.',
        ),
        const SizedBox(height: CurreSpace.s3),
        Text(
          'Your run stays safe while it waits.',
          style: type.caption.copyWith(color: colors.ink3),
        ),
        const SizedBox(height: CurreSpace.s4),
        CurrePrimaryButton(label: 'Done', onPressed: onClose),
      ],
    );
  }

  Widget _done(BuildContext context) => Column(
    key: const Key('proof-self-reported'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _NoteCard(
        glyph: CurreGlyphKind.kindTask,
        headline: 'Marked as done',
        body: 'It’s in your history. Proof days come from a note about what changed.',
      ),
      const SizedBox(height: CurreSpace.s4),
      CurrePrimaryButton(label: 'Done', onPressed: onClose),
    ],
  );
}

/// A quiet card for a note that is kept but adds no proof day yet.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.glyph,
    required this.headline,
    required this.body,
  });

  final CurreGlyphKind glyph;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: CurreShape.dome,
      ),
      child: Padding(
        padding: const EdgeInsets.all(CurreSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurreGlyph(glyph, size: 22, color: colors.ink2),
            const SizedBox(width: CurreSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: type.title),
                  const SizedBox(height: CurreSpace.s1),
                  Text(body, style: type.body.copyWith(color: colors.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Prooflight moment (proof audit §4), the production form of the
/// gallery's approved streak moment, played in the completion sheet after a
/// supported note. The first proof of the day raises today's sun over the
/// line as the session's sky floods up from it, grows its first ray, rolls
/// the count and lights today in the week; a later proof grows one more ray
/// on a sun already up. The avatar reacts once, happily, as the sun clears
/// the line. The sun has no face and never judges. Reduced motion shows the
/// end state; [progress] (0–1) freezes the moment for tests and renders.
class ProoflightMoment extends StatefulWidget {
  const ProoflightMoment({
    super.key,
    required this.submission,
    required this.title,
    required this.onContinue,
    this.link,
    this.session = Session.morning,
    this.avatarId,
    this.displayName,
    this.progress,
  });

  final ProofSubmission submission;
  final String title;
  final int? link;
  final Session session;
  final String? avatarId;
  final String? displayName;
  final VoidCallback onContinue;
  final double? progress;

  static const length = Duration(milliseconds: 3600);

  @override
  State<ProoflightMoment> createState() => _ProoflightMomentState();
}

class _ProoflightMomentState extends State<ProoflightMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ProoflightMoment.length,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || widget.progress != null) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0–1 progress of a beat running from [startMs] to [endMs].
  static double _beat(
    double ms,
    double startMs,
    double endMs, [
    Curve curve = Curves.linear,
  ]) {
    if (ms <= startMs) return 0;
    if (ms >= endMs) return 1;
    return curve.transform((ms - startMs) / (endMs - startMs));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => _frame(
      context,
      (widget.progress ?? _controller.value).clamp(0.0, 1.0) *
          ProoflightMoment.length.inMilliseconds,
    ),
  );

  Widget _frame(BuildContext context, double ms) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final proof = widget.submission;
    final after = proof.after;
    final sunrise = proof.earnedProofDay;

    // The approved choreography: the sun rises over the line (650 ms), the
    // sky floods up from it, the ray grows, then the count rolls, today
    // lights and the proof arrives. A later proof only grows its ray.
    final rise = sunrise ? _beat(ms, 300, 950, CurreMotion.riseCurve) : 1.0;
    final flood = sunrise ? _beat(ms, 520, 1170, CurreMotion.standard) : 1.0;
    final ray = sunrise ? _beat(ms, 950, 1370) : _beat(ms, 300, 720);
    final words = _beat(ms, 120, 520);
    final tick = _beat(ms, 1300, 1460, Curves.easeOutCubic);
    final todayLit = sunrise && proof.isToday
        ? _beat(ms, 1380, 1740)
        : (after.raysToday > 0 ? 1.0 : 0.0);
    final card = _beat(ms, 1640, 2000, CurreMotion.riseCurve);
    final extras = _beat(ms, 1900, 2260);
    final reacting = ms >= (sunrise ? 950 : 300);

    final from = sunrise ? proof.before.currentRun : after.currentRun;
    final to = after.currentRun;
    final rays = proof.isToday ? after.raysToday : 1;
    final headline = switch (proof) {
      _ when sunrise && proof.isToday => 'Today’s sun is up',
      _ when sunrise => '${weekdayName(proof.record.date)}’s sun is up',
      _ when proof.addedRay => 'One more ray',
      _ => 'Proof added',
    };
    final caption = proof.record.caption?.text ?? proof.record.note;
    final milestone = sunrise ? milestoneLine(to) : null;

    return Column(
      key: const Key('proof-accepted'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Opacity(
                opacity: words,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: type.headline),
                    const SizedBox(height: CurreSpace.s1),
                    Text(
                      'Your note counts as proof.',
                      style: type.body.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: CurreSpace.s3),
            Avatar(
              avatarId: widget.avatarId,
              initial: widget.displayName,
              size: 52,
              proofToday: proof.isToday,
              expression: AvatarExpression.happy,
              motion: reacting ? AvatarMotion.reactOnce : AvatarMotion.still,
              semanticLabel: 'Your profile, smiling',
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (context, box) {
              const horizon = .78;
              final lineY = (200 * horizon).roundToDouble();
              final sunSize = box.maxWidth < 300 ? 160.0 : 188.0;
              final sunHeight = ProoflightSun.heightFor(sunSize);
              return Stack(
                children: [
                  Positioned.fill(
                    child: SkyScene(
                      session: widget.session,
                      sun: SkySun.none,
                      horizon: horizon,
                      live: true,
                      flood: flood,
                    ),
                  ),
                  // The sun sits on the scene's own line.
                  Positioned(
                    left: (box.maxWidth - sunSize) / 2,
                    top: lineY - sunHeight + 1.5,
                    child: ProoflightSun(
                      rays: rays,
                      proofDays: to,
                      size: sunSize,
                      rise: rise,
                      grow: ray,
                      semanticLabel: rays == 1
                          ? 'Today’s sun, one ray: one task with proof'
                          : 'Today’s sun, $rays rays: $rays tasks with proof',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: CurreSpace.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RollingCount(
              from: from,
              to: to,
              t: tick,
              style: type.display
                  .copyWith(
                    fontSize: 56,
                    height: 1,
                    color: Color.lerp(colors.ink3, colors.ink, rise),
                  )
                  .weight(760),
            ),
            const SizedBox(width: CurreSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    to == 1 ? 'proof day' : 'proof days',
                    style: type.title.copyWith(fontSize: 20, height: 26 / 20),
                  ),
                  Text(
                    runRange(after),
                    style: type.caption.copyWith(color: colors.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: CurreSpace.s4),
        WeekStrip(
          days: proofWeek(after),
          session: widget.session,
          todayLit: todayLit,
        ),
        const SizedBox(height: CurreSpace.s5),
        _arrive(
          card,
          _ProofCard(
            title: widget.title,
            caption: caption,
            link: widget.link,
            offline: proof.record.packageName == null,
          ),
        ),
        if (proof.earnedCloudDay)
          _extra(
            extras,
            Row(
              children: [
                const CloudDayMark(size: 40, semanticLabel: null),
                const SizedBox(width: CurreSpace.s3),
                Expanded(
                  child: Text(
                    'You earned a cloud day. $cloudDayLine',
                    style: type.body,
                  ),
                ),
              ],
            ),
          ),
        if (milestone != null)
          _extra(
            extras,
            Text(milestone, style: type.body.copyWith(color: colors.ink2)),
          ),
        if (proof.startedNewRun)
          _extra(
            extras,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A new run starts here.', style: type.body),
                if (RunEndedNote.record(
                      best: after.bestRun,
                      total: after.totalProofDays,
                    )
                    case final record?) ...[
                  const SizedBox(height: CurreSpace.s1),
                  Text(record, style: type.meta),
                ],
              ],
            ),
          ),
        const SizedBox(height: CurreSpace.s5),
        CurrePrimaryButton(label: 'Continue', onPressed: widget.onContinue),
      ],
    );
  }

  Widget _arrive(double p, Widget child) => Opacity(
    opacity: p.clamp(0.0, 1.0),
    child: Transform.translate(offset: Offset(0, (1 - p) * 14), child: child),
  );

  Widget _extra(double p, Widget child) => Padding(
    padding: const EdgeInsets.only(top: CurreSpace.s4),
    child: _arrive(p, child),
  );
}

/// The proof: where the task went, in its door's colour, and the user's own
/// words about what changed, as they were copied from the note. "Supported"
/// is the honest name for it (proof audit §1), never "verified".
class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.title,
    required this.caption,
    this.link,
    this.offline = false,
  });

  final String title;
  final String caption;
  final int? link;

  /// Started with Start rather than through a door.
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CurreColors>()!;
    final type = Theme.of(context).extension<CurreType>()!;
    final card = link != null
        ? colors.link(link!).card
        : Pair(colors.sunk, colors.ink);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        CurreSpace.s3,
        CurreSpace.s3,
        CurreSpace.s4,
        CurreSpace.s3,
      ),
      decoration: BoxDecoration(color: card.bg, borderRadius: CurreShape.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurreGlyph(
            CurreGlyphKind.check,
            size: 24,
            color: card.fg,
            semanticLabel: 'Supported',
          ),
          const SizedBox(width: CurreSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: type.label.copyWith(color: card.fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  '“$caption”',
                  style: type.you.copyWith(
                    fontSize: 18,
                    height: 24 / 18,
                    color: card.fg,
                  ),
                ),
                const SizedBox(height: CurreSpace.s1),
                Text(
                  offline
                      ? 'Supported by your Start and your note'
                      : 'Supported by the door you opened and your note',
                  style: type.meta.copyWith(
                    color: card.fg.withValues(alpha: .78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
