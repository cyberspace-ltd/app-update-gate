import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_update_gate/src/models/app_entry.dart';
import 'package:app_update_gate/src/models/update_status.dart';

/// Visual configuration overrides for the update dialog.
///
/// Every field is optional — sensible defaults are provided.
class UpdateDialogTheme {
  /// Title text shown at the top of the dialog.
  final String? title;

  /// Body text shown below the title. If `null`, a default message is
  /// generated from the [AppEntry] fields.
  final String? body;

  /// Label for the primary "Update" button.
  final String updateButtonLabel;

  /// Label for the secondary "Later" button (hidden for force updates).
  final String laterButtonLabel;

  /// Background color of the primary button.
  final Color? primaryColor;

  /// Icon displayed above the title.
  final IconData? icon;

  /// Icon color.
  final Color? iconColor;

  /// Icon size in logical pixels.
  final double iconSize;

  /// Creates an [UpdateDialogTheme] with optional overrides.
  const UpdateDialogTheme({
    this.title,
    this.body,
    this.updateButtonLabel = 'Update Now',
    this.laterButtonLabel = 'Later',
    this.primaryColor,
    this.icon,
    this.iconColor,
    this.iconSize = 48.0,
  });
}

/// Shows the appropriate update dialog based on [status].
///
/// Returns `true` if the user tapped "Update" (store was launched),
/// `false` if they dismissed, or `null` if no dialog was needed.
Future<bool?> showUpdateDialog({
  required BuildContext context,
  required UpdateStatus status,
  required AppEntry entry,
  UpdateDialogTheme theme = const UpdateDialogTheme(),
}) async {
  switch (status) {
    case UpdateStatus.upToDate:
    case UpdateStatus.appNotFound:
      return null;
    case UpdateStatus.optionalUpdate:
      return _showDismissibleDialog(
        context: context,
        entry: entry,
        theme: theme,
        emphasizeUpdate: false,
      );
    case UpdateStatus.recommendedUpdate:
      return _showDismissibleDialog(
        context: context,
        entry: entry,
        theme: theme,
        emphasizeUpdate: true,
      );
    case UpdateStatus.forceUpdate:
      return _showForceUpdateBarrier(
        context: context,
        entry: entry,
        theme: theme,
      );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────

Future<bool> _showDismissibleDialog({
  required BuildContext context,
  required AppEntry entry,
  required UpdateDialogTheme theme,
  required bool emphasizeUpdate,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _UpdateDialogContent(
      entry: entry,
      theme: theme,
      showLaterButton: true,
      emphasizeUpdate: emphasizeUpdate,
    ),
  );
  return result ?? false;
}

Future<bool> _showForceUpdateBarrier({
  required BuildContext context,
  required AppEntry entry,
  required UpdateDialogTheme theme,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    // ignore: deprecated_member_use
    barrierColor: Colors.black.withOpacity(0.85),
    builder: (ctx) => PopScope(
      canPop: false,
      child: _UpdateDialogContent(
        entry: entry,
        theme: theme,
        showLaterButton: false,
        emphasizeUpdate: true,
      ),
    ),
  );
  return result ?? false;
}

class _UpdateDialogContent extends StatelessWidget {
  const _UpdateDialogContent({
    required this.entry,
    required this.theme,
    required this.showLaterButton,
    required this.emphasizeUpdate,
  });

  final AppEntry entry;
  final UpdateDialogTheme theme;
  final bool showLaterButton;
  final bool emphasizeUpdate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = theme.primaryColor ?? colorScheme.primary;

    final title = theme.title ?? 'Update Available';
    final body = theme.body ?? _defaultBody();
    final icon = theme.icon ?? Icons.system_update_rounded;
    final iconColor = theme.iconColor ?? primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: theme.iconSize, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (showLaterButton)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              theme.laterButtonLabel,
              style: emphasizeUpdate
                  ? TextStyle(color: colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primary),
            onPressed: () async {
              await _launchStore(entry);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: Text(theme.updateButtonLabel),
          ),
        ),
      ],
    );
  }

  String _defaultBody() {
    final buffer = StringBuffer(
      'A new version of ${entry.appName} (v${entry.latestVersion}) is '
      'available.',
    );
    if (entry.releaseNotes != null && entry.releaseNotes!.isNotEmpty) {
      buffer.write('\n\n${entry.releaseNotes}');
    }
    return buffer.toString();
  }
}

/// Allowed domains for store URLs — prevents malicious redirects if the
/// registry JSON is tampered with.
const _allowedStoreDomains = {
  'play.google.com',
  'apps.apple.com',
  'itunes.apple.com',
  'appgallery.huawei.com',
};

/// Returns `true` if [url] points to a legitimate app store domain.
bool _isStoreUrl(String url) {
  try {
    final host = Uri.parse(url).host.toLowerCase();
    return _allowedStoreDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  } catch (_) {
    return false;
  }
}

/// Launches the correct store URL based on the running platform.
///
/// Validates that the URL points to a legitimate store domain before
/// launching. This prevents a compromised registry from redirecting users
/// to phishing or malware sites.
Future<void> _launchStore(AppEntry entry) async {
  final String url;
  if (Platform.isAndroid) {
    url = entry.playStoreUrl;
  } else if (Platform.isIOS) {
    url = entry.appStoreUrl;
  } else {
    url = entry.playStoreUrl;
  }

  if (!_isStoreUrl(url)) {
    return;
  }

  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}