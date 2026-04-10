import 'package:app_update_gate/src/models/app_entry.dart';
import 'package:app_update_gate/src/models/update_priority.dart';

/// The single source-of-truth for all managed application versions.
///
/// ## How to update
///
/// 1. Open this file in the package repository.
/// 2. Find the [AppEntry] for your app (by `appId`).
/// 3. Bump `latestVersion` (and optionally `minRequiredVersion`).
/// 4. Set `updatePriority` and `releaseNotes` as desired.
/// 5. Commit, push, and tag a new package version.
///
/// Every consuming app will pick up the change on its next `flutter pub get`
/// (or CI build).
///
/// ### Design decision — Dart constant map
///
/// A compile-time Dart map was chosen over JSON/YAML because:
/// - **Type safety** — the compiler catches typos in field names.
/// - **No runtime I/O** — no file reads, no asset bundling, no parsing.
/// - **IDE support** — full autocomplete and go-to-definition.
/// - **Tree-shaking** — unused entries are eliminated by the compiler.
class AppRegistry {
  AppRegistry._();

  /// The master list of all registered applications.
  ///
  /// Keyed by `appId` (bundle identifier) for O(1) lookup.
  static const Map<String, AppEntry> apps = {
    'com.cyberspaceltd.ltemobile': AppEntry(
      appName: 'CybyrSpace Nexus',
      appId: 'com.cyberspaceltd.ltemobile',
      latestVersion: '1.0.29',
      minRequiredVersion: '1.0.11',
      playStoreUrl:
      'https://play.google.com/store/apps/details?id=com.cyberspaceltd.ltemobile',
      appStoreUrl:
          'https://apps.apple.com/us/app/cyberspace-nexus/id6745322533',
      releaseNotes: 'Bug fixes and performance improvements.',
      updatePriority: UpdatePriority.recommended,
    ),
    // 'com.myorg.anotherone': AppEntry(
    //   appName: 'Another One',
    //   appId: 'com.myorg.anotherone',
    //   latestVersion: '1.1.0',
    //   minRequiredVersion: '1.0.0',
    //   playStoreUrl:
    //       'https://play.google.com/store/apps/details?id=com.myorg.anotherone',
    //   appStoreUrl:
    //       'https://apps.apple.com/app/another-one/id9876543210',
    //   releaseNotes: null,
    //   updatePriority: UpdatePriority.optional,
    // ),

  };

  /// Looks up an [AppEntry] by its [appId].
  ///
  /// Returns `null` if the app is not registered.
  static AppEntry? lookup(String appId) => apps[appId];
}
