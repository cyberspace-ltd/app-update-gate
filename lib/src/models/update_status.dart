/// The outcome of a version check against the registry.
enum UpdateStatus {
  /// The running version meets or exceeds the latest registered version.
  upToDate,

  /// A newer version exists but the update is optional.
  optionalUpdate,

  /// A newer version exists and the update is recommended.
  recommendedUpdate,

  /// The running version is below [AppEntry.minRequiredVersion] — the user
  /// **must** update before continuing.
  forceUpdate,

  /// The app was not found in the registry. No action taken.
  appNotFound,
}
