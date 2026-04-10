import 'package:app_update_gate/src/models/app_entry.dart';
import 'package:app_update_gate/src/models/update_priority.dart';
import 'package:app_update_gate/src/models/update_status.dart';
import 'package:app_update_gate/src/registry/app_registry.dart';
import 'package:app_update_gate/src/utils/semantic_version.dart';
import 'package:flutter/widgets.dart';

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
/// Supports two modes:
/// - **Local** (synchronous): Uses the compile-time [AppRegistry] lookup.
/// - **Pre-fetched**: Call [evaluate] with an [AppEntry] already retrieved
///   from [RemoteRegistryService].
class VersionCheckerService {
  /// Creates a [VersionCheckerService].
  ///
  /// An optional [registryLookup] can be injected for testing; it defaults
  /// to [AppRegistry.lookup].
  const VersionCheckerService({
    AppEntry? Function(String appId)? registryLookup,
  }) : _lookup = registryLookup ?? AppRegistry.lookup;

  final AppEntry? Function(String appId) _lookup;

  /// Checks using the **local** compile-time registry.
  ///
  /// Prefer [evaluate] with a remotely-fetched [AppEntry] in production.
  VersionCheckResult check({
    required String appId,
    required String currentVersion,
  }) {
    final entry = _lookup(appId);
    return evaluate(entry: entry, currentVersion: currentVersion);
  }

  /// Pure comparison logic — evaluates a pre-fetched (or local) [AppEntry].
  ///
  /// If [entry] is `null`, returns [UpdateStatus.appNotFound].
  ///
  /// ```dart
  /// final entry = await remoteRegistry.lookup('com.myorg.coolapp');
  /// final result = VersionCheckerService.evaluate(
  ///   entry: entry,
  ///   currentVersion: '2.3.0',
  /// );
  /// ```
  static VersionCheckResult evaluate({
    required AppEntry? entry,
    required String currentVersion,
  }) {
    if (entry == null) {
      return const VersionCheckResult(status: UpdateStatus.appNotFound);
    }

    final running = SemanticVersion.parse(currentVersion);
    final latest = SemanticVersion.parse(entry.latestVersion);
    final minRequired = SemanticVersion.parse(entry.minRequiredVersion);
    debugPrint('Comparing versions: running=$running, latest=$latest, minRequired=$minRequired');

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
