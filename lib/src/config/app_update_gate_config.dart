class AppUpdateGateConfig {
  /// ✏️ Set this ONCE when you first set up the package
  static const String registryUrl =
    'https://raw.githubusercontent.com/cyberspace-ltd/app-update-gate/refs/heads/main/app_registry.json';
  static const Duration fetchTimeout = Duration(seconds: 5);
}