/// Determines how urgently the user should be prompted to update.
enum UpdatePriority {
  /// A skippable, low-emphasis update dialog.
  optional,

  /// A dismissible dialog with visual emphasis on the "Update" action.
  recommended,

  /// A non-dismissible, full-screen barrier. The only action is "Update".
  forced,
}
