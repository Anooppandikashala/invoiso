import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Tells the user an action changed which database file is loaded (backup
/// restore, company switch/create/delete) and the app needs a restart to
/// pick it up cleanly — in-memory state (cached provider data, the logged-in
/// user, theme/locale loaded once at startup) isn't refreshed by swapping
/// the file alone. Restart is mandatory here, not optional: continuing in
/// the same process would keep showing a mix of the old and new company's
/// data (e.g. the previous company's user still "logged in" against the
/// newly-active database), so there is no "close later" escape hatch — only
/// "Close App Now" (`exit(0)`), and the dialog can't be dismissed any other
/// way (barrier tap, back button, or Esc).
void showRestartRequiredDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            child: Text(l10n.backupCloseAppNowButton),
          ),
        ],
      ),
    ),
  );
}
