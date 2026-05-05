# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**App Update Gate** is a centralized version registry and force-update gate for Flutter app portfolios. It allows you to manage version enforcement across multiple apps from a single Git-hosted Dart package with no backend required.

The package provides:
- A centralized registry of app versions (`AppRegistry`)
- Version checking logic to determine if an update is needed
- Material 3 UI dialogs for update prompts with configurable themes
- Support for optional, recommended, and forced update priorities
- Automatic version detection via `package_info_plus`

## Architecture

### Core Layers

1. **Registry** (`lib/src/registry/`)
   - `AppRegistry` — Dart constant map keyed by `appId`. The single source of truth for all app versions. Add/update entries here when releasing new versions.

2. **Models** (`lib/src/models/`)
   - `AppEntry` — Represents one app's metadata (name, IDs, versions, store URLs, release notes, priority)
   - `UpdateStatus` — Enum indicating the check result: `upToDate`, `optionalUpdate`, `recommendedUpdate`, `forceUpdate`, `appNotFound`
   - `UpdatePriority` — Enum controlling dialog behavior: `optional` (dismissible), `recommended` (dismissible with emphasis), `forced` (non-dismissible)

3. **Services** (`lib/src/services/`)
   - `VersionCheckerService.evaluate()` — Compares current version against registry entry using semantic versioning. Returns status + entry.
   - `RemoteRegistryService` — Fetches registry from a configurable URL (used when serving registry over HTTP). Falls back to local registry on failure.

4. **UI** (`lib/src/ui/`)
   - `showUpdateDialog()` — Displays Material 3 dialog with configurable theme (title, body, button labels, colors, icon). Opens store URL on update click.

5. **Utilities** (`lib/src/utils/`)
   - `SemanticVersion` — Parses and compares versions using numeric major/minor/patch logic (not string comparison). Handles leading `v`, pre-release, and build metadata.

6. **Public API** (`lib/src/app_update_gate.dart`)
   - `AppUpdateGate.check()` — Main entry point. Resolves running version → fetches entry from registry → evaluates → shows dialog if needed. Returns `UpdateStatus`.

### Dependency Flow

```
AppUpdateGate.check()
  ├─> PackageInfo (get running version)
  ├─> RemoteRegistryService.lookup() → AppRegistry (if remote fails)
  ├─> VersionCheckerService.evaluate()
  │    └─> SemanticVersion.parse() and comparison
  └─> showUpdateDialog()
```

## Common Development Tasks

### Run Tests
```bash
flutter test
```

### Run Linting
```bash
flutter analyze
```

### Add/Update an App in the Registry

Open `lib/src/registry/app_registry.dart` and edit the `apps` map:

```dart
'com.myorg.newapp': AppEntry(
  appName: 'New App',
  appId: 'com.myorg.newapp',
  latestVersion: '1.0.0',
  minRequiredVersion: '1.0.0',
  playStoreUrl: 'https://play.google.com/store/apps/details?id=com.myorg.newapp',
  appStoreUrl: 'https://apps.apple.com/app/new-app/id...',
  releaseNotes: 'Initial release.',
  updatePriority: UpdatePriority.optional,
),
```

Then commit, push, and tag: `git tag vX.Y.Z && git push origin main --tags`.

### Update Version for an Existing App

Edit `lib/src/registry/app_registry.dart` — bump `latestVersion` (and/or `minRequiredVersion`) for the app entry, then tag and push.

### Test Version Comparison Logic

Tests are in `test/app_update_gate_test.dart`. Key test groups:
- `SemanticVersion.parse` — Version string parsing
- `SemanticVersion comparison` — Numeric comparison (e.g., 1.10.0 > 1.9.0)
- `VersionCheckerService` — Full check logic (status evaluation)

### Customize Update Dialog Theme

Pass `UpdateDialogTheme` to customize the dialog appearance:

```dart
await AppUpdateGate.check(
  context: context,
  appId: 'com.myorg.app',
  dialogTheme: UpdateDialogTheme(
    title: 'New Version!',
    body: 'Custom message here.',
    updateButtonLabel: 'Install',
    laterButtonLabel: 'Skip',
    primaryColor: Colors.teal,
    icon: Icons.rocket_launch,
    iconColor: Colors.teal,
  ),
);
```

Override the registry release notes with a custom value:

```dart
await AppUpdateGate.check(
  context: context,
  appId: 'com.myorg.app',
  releaseNotes: 'Custom release notes for this specific flow.',
);
```

If `releaseNotes` is omitted, the package uses the notes from `AppRegistry`.

## Key Invariants

- **Semantic versioning is numeric, not lexicographic.** `1.10.0 > 1.9.0` — see the test `1.9.0 is NOT greater than 1.10.0` for why this matters.
- **minRequiredVersion overrides updatePriority.** If the running version is below `minRequiredVersion`, a force-update barrier is shown regardless of `updatePriority` setting.
- **Registry is a compile-time Dart map**, not JSON/YAML, for type safety, IDE support, and zero runtime parsing cost.
- **Dialog opens the appropriate store URL** based on platform (Android → Play Store, iOS → App Store) using `url_launcher`.

## Dependencies

- `flutter` (SDK)
- `http` — Used by `RemoteRegistryService` (optional; falls back to local registry on failure)
- `url_launcher` — Opens store URLs
- `package_info_plus` — Auto-detects running app version
- `flutter_svg` — Asset support
- `flutter_lints` — Linting

## File Organization

```
lib/
  app_update_gate.dart          # Library export (re-exports public API)
  src/
    app_update_gate.dart        # AppUpdateGate.check() entry point
    config/
      app_update_gate_config.dart  # Configuration defaults
    models/
      app_entry.dart            # Data class for app metadata
      update_priority.dart      # Enum: optional, recommended, forced
      update_status.dart        # Enum: upToDate, optionalUpdate, ...
    registry/
      app_registry.dart         # Central registry (constant map)
    services/
      remote_registry_service.dart  # Fetch registry from HTTP
      version_checker_service.dart  # Evaluate update status
    ui/
      update_dialog.dart        # Material 3 dialog + theme
    utils/
      semantic_version.dart     # Version parsing & comparison
test/
  app_update_gate_test.dart     # All unit tests
```
