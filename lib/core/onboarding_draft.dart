/// Onboarding's answers so far, kept on the phone after every step.
///
/// Making Curre the home screen can make Android start Curre afresh: a
/// second copy in Android's Home task, or a new process. The draft lets
/// that copy pick up where the user was instead of starting over. It is
/// cleared once onboarding finishes.
class OnboardingDraft {
  const OnboardingDraft({
    required this.step,
    this.displayName = '',
    this.avatarId,
    this.hidden = const <String>{},
    this.showAllApps = false,
    this.plan = '',
    this.focusPurpose,
    this.focusGoal = '',
    this.focusDays,
    this.focusEndsOn,
  });

  /// The step's name, as onboarding calls it.
  final String step;
  final String displayName;
  final String? avatarId;

  /// The apps picked to go to Hidden apps.
  final Set<String> hidden;
  final bool showAllApps;
  final String plan;

  /// The focus picked so far: its purpose's name, the goal, and a length
  /// in days or an end date ('YYYY-MM-DD').
  final String? focusPurpose;
  final String focusGoal;
  final int? focusDays;
  final String? focusEndsOn;

  Map<String, Object?> toJson() => <String, Object?>{
    'step': step,
    'displayName': displayName,
    'avatarId': avatarId,
    'hidden': hidden.toList(growable: false),
    'showAllApps': showAllApps,
    'plan': plan,
    'focusPurpose': focusPurpose,
    'focusGoal': focusGoal,
    'focusDays': focusDays,
    'focusEndsOn': focusEndsOn,
  };

  factory OnboardingDraft.fromJson(Map<String, Object?> json) {
    final step = json['step'];
    if (step is! String) throw const FormatException('No onboarding step');
    final hidden = json['hidden'];
    return OnboardingDraft(
      step: step,
      displayName: json['displayName'] as String? ?? '',
      avatarId: json['avatarId'] as String?,
      hidden: hidden is List ? {...hidden.whereType<String>()} : <String>{},
      showAllApps: json['showAllApps'] as bool? ?? false,
      plan: json['plan'] as String? ?? '',
      focusPurpose: json['focusPurpose'] as String?,
      focusGoal: json['focusGoal'] as String? ?? '',
      focusDays: json['focusDays'] as int?,
      focusEndsOn: json['focusEndsOn'] as String?,
    );
  }
}
