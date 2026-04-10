import 'dart:convert';
import 'dart:developer' as developer;
import 'package:app_update_gate/src/config/app_update_gate_config.dart';
import 'package:http/http.dart' as http;

import 'package:app_update_gate/src/models/app_entry.dart';
import 'package:app_update_gate/src/registry/app_registry.dart';

/// Fetches the app registry JSON from a remote URL at runtime.
///
/// This is the key piece that makes the package work in **production**:
/// old app binaries fetch the *latest* registry over the network instead
/// of relying on the compile-time snapshot.
///
/// Falls back to the compile-time [AppRegistry] if the network request
/// fails (offline, timeout, malformed JSON, etc.).
class RemoteRegistryService {
  /// The URL pointing to the raw `app_registry.json` file.
  ///
  /// For GitHub-hosted repos, this is typically:
  /// ```
  /// https://raw.githubusercontent.com/<org>/<repo>/main/app_registry.json
  /// ```
  final String? registryUrl;

  /// HTTP request timeout.
  final Duration timeout;

  /// Optional HTTP client — injectable for testing.
  final http.Client? _client;

  /// Creates a [RemoteRegistryService].
  ///
  /// [registryUrl] must point to a publicly accessible raw JSON file.
  const RemoteRegistryService({
    required this.registryUrl,
    this.timeout = const Duration(seconds: 5),
    http.Client? client,
  }) : _client = client;

  /// Fetches the remote registry and returns the [AppEntry] for [appId].
  ///
  /// If the fetch fails for any reason, falls back to the local
  /// compile-time [AppRegistry].
 Future<AppEntry?> lookup(String appId) async {
    developer.log('[AppUpdateGate] Fetching registry from: $registryUrl');
    try {
      final entries = await fetchAll();
      developer.log('[AppUpdateGate] Remote fetch succeeded. Found ${entries.length} app(s): ${entries.keys.toList()}');
      final entry = entries[appId];
      if (entry == null) {
        developer.log('[AppUpdateGate] ⚠️ appId "$appId" NOT found in remote registry');
      } else {
        developer.log('[AppUpdateGate] ✅ Found "$appId" → latest: ${entry.latestVersion}, min: ${entry.minRequiredVersion}, priority: ${entry.updatePriority}');
      }
      return entry;
    } catch (e) {
      developer.log('[AppUpdateGate] ❌ Remote fetch FAILED: $e');
      developer.log('[AppUpdateGate] Falling back to local registry...');
      return AppRegistry.lookup(appId);
    }
  }

  /// Fetches and parses the entire remote registry.
  ///
  /// Throws on network or parse errors — callers should handle exceptions
  /// or use [lookup] which has built-in fallback.
  Future<Map<String, AppEntry>> fetchAll() async {
    final client = _client ?? http.Client();
    final shouldClose = _client == null;

    try {
      final response = await client
          .get(Uri.parse(registryUrl??AppUpdateGateConfig.registryUrl))
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw HttpException(
          'Registry fetch returned ${response.statusCode}',
        );
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      final Map<String, dynamic> appsJson =
          json['apps'] as Map<String, dynamic>;

      return appsJson.map(
        (key, value) => MapEntry(
          key,
          AppEntry.fromJson(value as Map<String, dynamic>),
        ),
      );
    } finally {
      if (shouldClose) client.close();
    }
  }
}

/// Simple HTTP exception for non-200 responses.
class HttpException implements Exception {
  /// The error message.
  final String message;

  /// Creates an [HttpException].
  const HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
