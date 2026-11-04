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

/// Whether [packageName] is on Home (and opens without "Why now?") now.
///
/// Only the apps the user chose to hide ([Settings.hiddenApps]) are ever
/// hidden; every other app is visible. A hidden app comes back while the
/// active plan uses it or while a grant for it runs. The apps always on
/// Home can't be hidden.
bool isVisible(
  String packageName,
  DateTime now,
  LauncherState state, {
  CurreTimeZone timeZone = const SystemCurreTimeZone(),
}) {
  if (!isHiddenByChoice(packageName, state.settings)) return true;

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

/// Whether the user chose to hide [packageName]. The apps always on Home
/// never are, even if an old list still names one.
bool isHiddenByChoice(String packageName, Settings settings) =>
    settings.hiddenApps.contains(packageName) &&
    !settings.essentials.contains(packageName);

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

/// The hidden list for someone who set Curre up before only the chosen
/// apps were hidden.
///
/// Back then the "What pulls you in?" picks were never saved by name: they
/// were simply left out of the apps plans can use, and every other app was
/// hidden too. So the picks are read back as the well-known pull apps
/// ([pullPackages]) that are installed but neither always on Home nor
/// usable by plans. Nothing else is hidden; the user can hide more from
/// "All apps" or Hidden apps.
Set<String> legacyHiddenApps({
  required Settings settings,
  required Iterable<String> installed,
  required Iterable<String> pullPackages,
}) {
  final onPhone = installed.toSet();
  return <String>{
    for (final package in pullPackages)
      if (onPhone.contains(package) &&
          !settings.essentials.contains(package) &&
          !settings.candidates.contains(package))
        package,
  };
}
