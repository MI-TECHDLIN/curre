import 'models.dart';
import 'sessions.dart';

class LauncherState {
  LauncherState({
    required this.settings,
    required List<Grant> grants,
    this.plan,
  }) : grants = List.unmodifiable(grants);

  final Settings settings;
  final Plan? plan;
  final List<Grant> grants;
}

bool isVisible(
  String packageName,
  DateTime now,
  LauncherState state, {
  CurreTimeZone timeZone = const SystemCurreTimeZone(),
}) {
  if (state.settings.essentials.contains(packageName)) return true;

  final instant = now.toUtc();
  final plan = state.plan;
  if (plan != null &&
      instant.isBefore(plan.endsAt) &&
      plan.packages.contains(packageName)) {
    final session = SessionSchedule.fromSettings(
      state.settings,
      timeZone: timeZone,
    ).current(instant);
    if (session.session == plan.session &&
        session.localStartDate == plan.date) {
      return true;
    }
  }

  return state.grants.any(
    (grant) => grant.packageName == packageName && grant.isActiveAt(instant),
  );
}

/// Returns the exact package set Home should render from a current app list.
Set<String> visiblePackages(
  Iterable<AppEntry> apps,
  DateTime now,
  LauncherState state, {
  CurreTimeZone timeZone = const SystemCurreTimeZone(),
}) => <String>{
  for (final app in apps)
    if (isVisible(app.packageName, now, state, timeZone: timeZone))
      app.packageName,
};
