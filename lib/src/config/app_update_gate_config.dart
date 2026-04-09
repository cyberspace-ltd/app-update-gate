class AppUpdateGateConfig {
  /// ✏️ Set this ONCE when you first set up the package
  static const String registryUrl =
      'https://raw.githubusercontent.com/cyberspace-ltd/app_update_gate/main/app_registry.json';
  static const Duration fetchTimeout = Duration(seconds: 5);
}