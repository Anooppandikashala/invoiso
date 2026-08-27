import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF002E78);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: Row(
        children: [
          Icon(Icons.system_update_alt_rounded, color: primary, size: 22),
          const SizedBox(width: 10),
          Text(
            l10n.updateDialogTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          _versionRow(
              context,
              l10n.appInfoCurrentVersionLabel,
              info.currentVersion,
              Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          _versionRow(context, l10n.appInfoLatestVersionLabel,
              info.latestVersion, Colors.green.shade700),
          const SizedBox(height: 16),
          Text(
            l10n.updateDialogBodyMessage,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await UpdateService.markNotified(info.latestVersion);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n.actionDismiss,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: primary),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: Text(l10n.createInvoiceDownloadLabel),
          onPressed: () async {
            await UpdateService.markNotified(info.latestVersion);
            if (context.mounted) Navigator.of(context).pop();
            await launchUrl(
              Uri.parse('https://invoiso.co.in/download.html'),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ],
    );
  }

  Widget _versionRow(
      BuildContext context, String label, String version, Color versionColor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Text(
          version,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: versionColor),
        ),
      ],
    );
  }
}
