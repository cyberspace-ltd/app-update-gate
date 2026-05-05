# App Update Gate

A centralized remote version registry and force-update gate for Flutter app portfolios. Manage version enforcement across **all your apps** from a single Git-hosted Dart package — no backend required.

---

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  This Package (Git repo)                                │
│                                                         │
│  app_registry.dart ← single source of truth             │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 'com.myorg.coolapp'  → latest: 2.4.1, min: 2.0.0 │  │
│  │ 'com.myorg.another'  → latest: 1.1.0, min: 1.0.0 │  │
│  └───────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │  Git dependency
        ┌────────────┼────────────┐
        ▼            ▼            ▼
    Cool App    Another App   Future App
    (v2.3.0)    (v1.1.0)     (v1.0.0)
        │            │
   "Update!"    "Up to date"
```

1. **Release** a new version of any app to the stores.
2. **Update** `app_registry.dart` in this package with the new version metadata.
3. **Push & tag** a new package version.
4. Apps pull the update on their next `flutter pub get` and compare versions at launch.

---

## Installation

Add this package as a Git dependency in your app's `pubspec.yaml`:

```yaml
dependencies:
  app_update_gate:
    git:
      url: https://github.com/myorg/app_update_gate.git
      ref: v1.0.0   # pin to a release tag, or use 'main' for latest
```

Then run:

```bash
flutter pub get
```

---

## Quick Start (3 Steps)

### Step 1 — Register your app

Open `lib/src/registry/app_registry.dart` in **this** package and add an entry:

```dart
'com.myorg.coolapp': AppEntry(
  appName: 'Cool App',
  appId: 'com.myorg.coolapp',
  latestVersion: '2.4.1',
  minRequiredVersion: '2.0.0',
  playStoreUrl: 'https://play.google.com/store/apps/details?id=com.myorg.coolapp',
  appStoreUrl: 'https://apps.apple.com/app/cool-app/id1234567890',
  releaseNotes: 'Bug fixes and performance improvements.',
  updatePriority: UpdatePriority.recommended,
),
```

### Step 2 — Add the check in your app

```dart
import 'package:app_update_gate/app_update_gate.dart';

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppUpdateGate.check(
        context: context,
        appId: 'com.myorg.coolapp',
        // currentVersion is auto-detected if omitted.
      );
    });
  }
}
```

### Step 3 — When you release a new version

1. Update `latestVersion` (and optionally `minRequiredVersion`) in `app_registry.dart`.
2. Commit, push, and tag:
   ```bash
   git add .
   git commit -m "bump Cool App to 2.5.0"
   git tag v1.1.0
   git push origin main --tags
   ```
3. In every consuming app, run `flutter pub upgrade app_update_gate` (or let CI do it).

---

## Update Priority Tiers

| Priority      | Dialog Behavior                                      |
|---------------|------------------------------------------------------|
| `optional`    | Dismissible dialog — "Later" and "Update" buttons.   |
| `recommended` | Dismissible dialog — visual emphasis on "Update".    |
| `forced`      | Non-dismissible barrier — **only** action is "Update".|

> **Note:** If the running version falls below `minRequiredVersion`, a force-update barrier is shown **regardless** of the `updatePriority` setting.

---

## Customizing the Dialog

### Visual Customization

Pass an `UpdateDialogTheme` to override the default appearance:

```dart
await AppUpdateGate.check(
  context: context,
  appId: 'com.myorg.coolapp',
  dialogTheme: UpdateDialogTheme(
    title: 'New Version Ready!',
    body: 'We\'ve been busy making things better.',
    updateButtonLabel: 'Get It',
    laterButtonLabel: 'Not Now',
    primaryColor: Colors.teal,
    icon: Icons.rocket_launch,
    iconColor: Colors.teal,
  ),
);
```

### Custom Release Notes

Override the registry release notes for a specific check:

```dart
await AppUpdateGate.check(
  context: context,
  appId: 'com.myorg.coolapp',
  releaseNotes: 'Custom release notes shown in the dialog.\nCan include multiple lines.',
);
```

If `releaseNotes` is omitted, the value from `AppRegistry` is used (or `null` if not set).

---

## API Reference

### `AppUpdateGate.check()`

| Parameter        | Type                   | Required | Default                         |
|------------------|------------------------|----------|---------------------------------|
| `context`        | `BuildContext`         | ✓        |                                 |
| `appId`          | `String`               | ✓        |                                 |
| `currentVersion` | `String?`              |          | Auto-detected via package_info  |
| `releaseNotes`   | `String?`              |          | From AppRegistry entry          |
| `dialogTheme`    | `UpdateDialogTheme`    |          | Default Material 3 dialog       |

**Returns:** `Future<UpdateStatus>`

### `UpdateStatus` enum

| Value               | Meaning                                    |
|---------------------|--------------------------------------------|
| `upToDate`          | Running version ≥ latest.                  |
| `optionalUpdate`    | Newer version exists, update is optional.  |
| `recommendedUpdate` | Newer version exists, update is encouraged.|
| `forceUpdate`       | Below minimum version — must update.       |
| `appNotFound`       | App ID not in registry.                    |

---

## Dependencies

| Package            | Why                                                |
|--------------------|----------------------------------------------------|
| `url_launcher`     | Opens the correct store URL on Android/iOS.        |
| `package_info_plus`| Auto-detects the running app version at runtime.   |

Both are maintained by the Flutter Community and widely adopted in production.

---

## License

MIT
# app-update-gate
