# Changelog

## 1.0.0 — 2026-04-09

### Added
- Centralized `AppRegistry` with compile-time Dart constant map.
- `VersionCheckerService` with proper semantic version comparison.
- Three-tier update dialogs: optional, recommended, and forced.
- `AppUpdateGate.check()` — single-call integration API.
- Auto-detection of running app version via `package_info_plus`.
- Fully customizable dialog theme via `UpdateDialogTheme`.
- Platform-aware store redirect (Play Store / App Store).
- Unit tests for version parsing, comparison, and checker service.
