import 'package:app_update_gate/src/models/app_entry.dart';
import 'package:app_update_gate/src/models/update_priority.dart';
import 'package:app_update_gate/src/models/update_status.dart';
import 'package:app_update_gate/src/registry/app_registry.dart';
import 'package:app_update_gate/src/utils/semantic_version.dart';

/// The result of a version check, bundling the [status] with the
/// corresponding [AppEntry] (if found).
class VersionCheckResult {
  /// The computed update status.
  final UpdateStatus status;

  /// The registry entry for the app, or `null` if [status] is
  /// [UpdateStatus.appNotFound].
  final AppEntry? entry;

  /// Creates a [VersionCheckResult].
  const VersionCheckResult({required this.status, this.entry});
}

/// Compares the running app version against the centralized [AppRegistry]
/// and returns an [UpdateStatus].
///
/// This service contains **no network calls** — all data comes from the
/// compile-time registry baked into the package.
class VersionCheckerService {
  /// Creates a [VersionCheckerService].
  ///
  /// An optional [registryLookup] can be injected for testing; it defaults
  /// to [AppRegistry.lookup].
  const VersionCheckerService({
    AppEntry? Function(String appId)? registryLookup,
  }) : _lookup = registryLookup ?? AppRegistry.lookup;

  final AppEntry? Function(String appId) _lookup;

  /// Checks the [currentVersion] of the app identified by [appId] against
  /// the registry and returns a [VersionCheckResult].
  ///
  /// ```dart
  /// final result = const VersionCheckerService().check(
  ///   appId: 'com.myorg.coolapp',
  ///   currentVersion: '2.3.0',
  /// );
  /// ```
  VersionCheckResult check({
    required String appId,
    required String currentVersion,
  }) {
    final entry = _lookup(appId);
    if (entry == null) {
      return const VersionCheckResult(status: UpdateStatus.appNotFound);
    }

    final running = SemanticVersion.parse(currentVersion);
    final latest = SemanticVersion.parse(entry.latestVersion);
    final minRequired = SemanticVersion.parse(entry.minRequiredVersion);

    if (running < minRequired) {
      return VersionCheckResult(status: UpdateStatus.forceUpdate, entry: entry);
    }

    if (running >= latest) {
      return VersionCheckResult(status: UpdateStatus.upToDate, entry: entry);
    }

    switch (entry.updatePriority) {
      case UpdatePriority.forced:
        return VersionCheckResult(
          status: UpdateStatus.forceUpdate,
          entry: entry,
        );
      case UpdatePriority.recommended:
        return VersionCheckResult(
          status: UpdateStatus.recommendedUpdate,
          entry: entry,
        );
      case UpdatePriority.optional:
        return VersionCheckResult(
          status: UpdateStatus.optionalUpdate,
          entry: entry,
        );
    }
  }
}
