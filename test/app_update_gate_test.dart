import 'package:flutter_test/flutter_test.dart';

import 'package:app_update_gate/src/models/app_entry.dart';
import 'package:app_update_gate/src/models/update_priority.dart';
import 'package:app_update_gate/src/models/update_status.dart';
import 'package:app_update_gate/src/services/version_checker_service.dart';
import 'package:app_update_gate/src/utils/semantic_version.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════════
  //  SemanticVersion
  // ════════════════════════════════════════════════════════════════════════

  group('SemanticVersion.parse', () {
    test('parses standard major.minor.patch', () {
      final v = SemanticVersion.parse('2.4.1');
      expect(v.major, 2);
      expect(v.minor, 4);
      expect(v.patch, 1);
    });

    test('parses major.minor (missing patch defaults to 0)', () {
      final v = SemanticVersion.parse('3.1');
      expect(v, equals(const SemanticVersion(3, 1, 0)));
    });

    test('parses major only', () {
      final v = SemanticVersion.parse('5');
      expect(v, equals(const SemanticVersion(5, 0, 0)));
    });

    test('strips leading v prefix', () {
      expect(SemanticVersion.parse('v1.2.3'), equals(SemanticVersion.parse('1.2.3')));
      expect(SemanticVersion.parse('V1.2.3'), equals(SemanticVersion.parse('1.2.3')));
    });

    test('strips pre-release and build metadata', () {
      expect(
        SemanticVersion.parse('1.0.0-beta+42'),
        equals(const SemanticVersion(1, 0, 0)),
      );
    });

    test('throws on empty string', () {
      expect(() => SemanticVersion.parse(''), throwsFormatException);
    });

    test('throws on non-numeric components', () {
      expect(() => SemanticVersion.parse('a.b.c'), throwsFormatException);
    });
  });

  group('SemanticVersion comparison', () {
    test('equal versions', () {
      expect(SemanticVersion.parse('1.0.0') == SemanticVersion.parse('1.0.0'), isTrue);
    });

    test('major difference', () {
      expect(SemanticVersion.parse('2.0.0') > SemanticVersion.parse('1.9.9'), isTrue);
    });

    test('minor difference', () {
      expect(SemanticVersion.parse('1.10.0') > SemanticVersion.parse('1.9.0'), isTrue);
    });

    test('patch difference', () {
      expect(SemanticVersion.parse('1.0.2') > SemanticVersion.parse('1.0.1'), isTrue);
    });

    test('1.9.0 is NOT greater than 1.10.0 (not string comparison)', () {
      // This is the critical test — string comparison would get this wrong.
      expect(SemanticVersion.parse('1.9.0') < SemanticVersion.parse('1.10.0'), isTrue);
    });

    test('operators >=, <=', () {
      final a = SemanticVersion.parse('2.0.0');
      final b = SemanticVersion.parse('2.0.0');
      expect(a >= b, isTrue);
      expect(a <= b, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  //  VersionCheckerService
  // ════════════════════════════════════════════════════════════════════════

  const _testEntry = AppEntry(
    appName: 'Test App',
    appId: 'com.test.app',
    latestVersion: '2.4.1',
    minRequiredVersion: '2.0.0',
    playStoreUrl: 'https://play.google.com/store/apps/details?id=com.test.app',
    appStoreUrl: 'https://apps.apple.com/app/test-app/id000',
    updatePriority: UpdatePriority.recommended,
  );

  VersionCheckerService _serviceWith(AppEntry? entry) {
    return VersionCheckerService(
      registryLookup: (id) => id == _testEntry.appId ? entry : null,
    );
  }

  group('VersionCheckerService', () {
    test('returns appNotFound for unknown appId', () {
      final result = _serviceWith(null).check(
        appId: 'com.unknown',
        currentVersion: '1.0.0',
      );
      expect(result.status, UpdateStatus.appNotFound);
      expect(result.entry, isNull);
    });

    test('returns upToDate when running >= latest', () {
      final result = _serviceWith(_testEntry).check(
        appId: _testEntry.appId,
        currentVersion: '2.4.1',
      );
      expect(result.status, UpdateStatus.upToDate);
    });

    test('returns upToDate when running > latest', () {
      final result = _serviceWith(_testEntry).check(
        appId: _testEntry.appId,
        currentVersion: '3.0.0',
      );
      expect(result.status, UpdateStatus.upToDate);
    });

    test('returns forceUpdate when below minRequiredVersion', () {
      final result = _serviceWith(_testEntry).check(
        appId: _testEntry.appId,
        currentVersion: '1.9.9',
      );
      expect(result.status, UpdateStatus.forceUpdate);
    });

    test('returns recommendedUpdate for entry with recommended priority', () {
      final result = _serviceWith(_testEntry).check(
        appId: _testEntry.appId,
        currentVersion: '2.3.0',
      );
      expect(result.status, UpdateStatus.recommendedUpdate);
    });

    test('returns optionalUpdate for entry with optional priority', () {
      const optionalEntry = AppEntry(
        appName: 'Opt App',
        appId: 'com.test.app',
        latestVersion: '2.4.1',
        minRequiredVersion: '2.0.0',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.test.app',
        appStoreUrl: 'https://apps.apple.com/app/test-app/id000',
        updatePriority: UpdatePriority.optional,
      );
      final result = _serviceWith(optionalEntry).check(
        appId: optionalEntry.appId,
        currentVersion: '2.3.0',
      );
      expect(result.status, UpdateStatus.optionalUpdate);
    });

    test('returns forceUpdate for entry with forced priority', () {
      const forcedEntry = AppEntry(
        appName: 'Forced App',
        appId: 'com.test.app',
        latestVersion: '2.4.1',
        minRequiredVersion: '2.0.0',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.test.app',
        appStoreUrl: 'https://apps.apple.com/app/test-app/id000',
        updatePriority: UpdatePriority.forced,
      );
      final result = _serviceWith(forcedEntry).check(
        appId: forcedEntry.appId,
        currentVersion: '2.3.0',
      );
      expect(result.status, UpdateStatus.forceUpdate);
    });

    test('minRequired takes precedence over optional priority', () {
      // Even if priority is optional, being below min = force update.
      const optionalEntry = AppEntry(
        appName: 'Opt App',
        appId: 'com.test.app',
        latestVersion: '3.0.0',
        minRequiredVersion: '2.5.0',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.test.app',
        appStoreUrl: 'https://apps.apple.com/app/test-app/id000',
        updatePriority: UpdatePriority.optional,
      );
      final result = _serviceWith(optionalEntry).check(
        appId: optionalEntry.appId,
        currentVersion: '2.4.0',
      );
      expect(result.status, UpdateStatus.forceUpdate);
    });
  });
}
