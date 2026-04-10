import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:app_update_gate/src/config/app_update_gate_config.dart';
import 'package:app_update_gate/src/models/update_status.dart';
import 'package:app_update_gate/src/services/remote_registry_service.dart';
import 'package:app_update_gate/src/services/version_checker_service.dart';
import 'package:app_update_gate/src/ui/update_dialog.dart';

/// The primary public API for consuming apps.
///
/// Call [check] once after the first frame (e.g., in `initState` of your
/// home screen or inside a post-frame callback) to evaluate whether the
/// user should be prompted to update.
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     AppUpdateGate.check(
///       context: context,
///       appId: 'com.myorg.coolapp',
///     );
///   });
/// }
/// ```
class AppUpdateGate {
  AppUpdateGate._();

  /// Checks the running version against the registry and, if an update is
  /// available, shows the appropriate dialog.
  ///
  /// [appId] — The bundle identifier registered in [AppRegistry].
  ///
  /// [registryUrl] — Optional URL to remote registry. If omitted, uses the
  /// default URL from [AppUpdateGateConfig].
  ///
  /// [currentVersion] — The running semantic version string. If omitted,
  /// the version is automatically read from the app's platform metadata
  /// via `package_info_plus`.
  ///
  /// [dialogTheme] — Optional visual overrides for the update dialog.
  ///
  /// Returns the [UpdateStatus] that was evaluated (useful for logging or
  /// analytics).
  static Future<UpdateStatus> check({
    required BuildContext context,
    required String appId,
    String? registryUrl,
    String? currentVersion,
    UpdateDialogTheme dialogTheme = const UpdateDialogTheme(),
  }) async {
    final version = currentVersion ?? await _resolveVersion();
    final result = service.check(appId: appId, currentVersion: version);

      debugPrint('Version check result: current version=$version, status=${result.status}, entry=${result.entry}'); 
    if (!context.mounted) return result.status;

    if (result.status != UpdateStatus.upToDate &&
        result.status != UpdateStatus.appNotFound &&
        result.entry != null) {
      await showUpdateDialog(
        context: context,
        status: result.status,
        entry: result.entry!,
        theme: dialogTheme,
      );
    }

    return result.status;
  }

  static Future<String> _resolveVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
