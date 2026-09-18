import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Tells the user an action changed which database file is loaded (backup
/// restore, company switch/create/delete) and the app needs a restart to
/// pick it up cleanly — in-memory state (cached provider data, theme/locale
/// loaded once at startup) isn't refreshed by swapping the file alone.
/// Offers "Close Later" (dismiss, keep using the stale session) or
/// "Close App Now" (`exit(0)` — the user relaunches manually).
void showRestartRequiredDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupCloseLaterButton),
        ),
        TextButton(
          onPressed: () => exit(0),
          child: Text(l10n.backupCloseAppNowButton),
        ),
      ],
    ),
  );
}
