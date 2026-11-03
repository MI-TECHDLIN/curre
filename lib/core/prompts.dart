/// What first-run setup no longer asks up front. Each is offered once, at
/// the moment it first helps, and Curre settings always has it too.
enum ContextPrompt {
  /// Android's notification permission for quiet nudges: offered on Home
  /// the first time a plan or a hidden app's time is running.
  nudges,

  /// Usage access, so Curre can ask "Why now?" when a hidden app opens
  /// from elsewhere: offered the first time Hidden apps is opened.
  askWhy,

  /// Notification access, to keep hidden apps quiet: offered on a later
  /// visit to Hidden apps. Android shows Curre no hidden app's notification
  /// until this is on, so that is the closest moment to the first ping.
  quietHidden,
}
