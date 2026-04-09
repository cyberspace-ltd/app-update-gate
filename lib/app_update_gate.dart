/// Centralized remote version registry and force-update gate for Flutter
/// app portfolios.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:app_update_gate/app_update_gate.dart';
///
/// // After first frame:
/// await AppUpdateGate.check(
///   context: context,
///   appId: 'com.myorg.coolapp',
/// );
/// ```
///
/// See the [README](https://github.com/myorg/app_update_gate) for full
/// setup and registry update instructions.
library app_update_gate;

export 'src/models/app_entry.dart';
export 'src/models/update_priority.dart';
export 'src/models/update_status.dart';
export 'src/registry/app_registry.dart';
export 'src/services/version_checker_service.dart';
export 'src/ui/update_dialog.dart' show UpdateDialogTheme, showUpdateDialog;
export 'src/utils/semantic_version.dart';
export 'src/app_update_gate.dart';
