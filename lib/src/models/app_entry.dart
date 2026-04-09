import 'package:app_update_gate/src/models/update_priority.dart';

/// A single application's version metadata in the centralized registry.
///
/// Each [AppEntry] represents one app in your portfolio and contains all
/// the information needed to decide whether an update prompt should appear
/// and where to redirect the user.
class AppEntry {
  /// Human-readable application name shown in the update dialog.
  final String appName;

  /// Unique identifier — typically the bundle ID / application ID
  /// (e.g. `com.myorg.coolapp`).
  final String appId;

  /// The latest semantic version available in the stores (e.g. `"2.4.1"`).
  final String latestVersion;

  /// The minimum version the app must be running. If the user's version is
  /// below this, a **force-update** barrier is shown regardless of
  /// [updatePriority].
  final String minRequiredVersion;

  /// Full Google Play Store listing URL for Android users.
  final String playStoreUrl;

  /// Full Apple App Store listing URL for iOS users.
  final String appStoreUrl;

  /// Optional release notes displayed in the update dialog body.
  final String? releaseNotes;

  /// Controls the visual urgency and dismissibility of the update dialog.
  final UpdatePriority updatePriority;

  /// Creates an [AppEntry].
  const AppEntry({
    required this.appName,
    required this.appId,
    required this.latestVersion,
    required this.minRequiredVersion,
    required this.playStoreUrl,
    required this.appStoreUrl,
    this.releaseNotes,
    this.updatePriority = UpdatePriority.optional,
  });

   /// Deserializes an [AppEntry] from a JSON map.
  ///
  /// The `updatePriority` field maps from the strings `"optional"`,
  /// `"recommended"`, and `"forced"`.
  factory AppEntry.fromJson(Map<String, dynamic> json) {
    return AppEntry(
      appName: json['appName'] as String,
      appId: json['appId'] as String,
      latestVersion: json['latestVersion'] as String,
      minRequiredVersion: json['minRequiredVersion'] as String,
      playStoreUrl: json['playStoreUrl'] as String,
      appStoreUrl: json['appStoreUrl'] as String,
      releaseNotes: json['releaseNotes'] as String?,
      updatePriority: _parsePriority(json['updatePriority'] as String?),
    );
  }

  static UpdatePriority _parsePriority(String? value) {
    switch (value) {
      case 'forced':
        return UpdatePriority.forced;
      case 'recommended':
        return UpdatePriority.recommended;
      case 'optional':
      default:
        return UpdatePriority.optional;
    }
  }

}
