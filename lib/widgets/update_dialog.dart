import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';

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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: Row(
        children: [
          Icon(Icons.system_update_alt_rounded, color: primary, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Update Available',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          _versionRow('Current version', info.currentVersion, Colors.grey.shade600),
          const SizedBox(height: 6),
          _versionRow('Latest version', info.latestVersion, Colors.green.shade700),
          const SizedBox(height: 16),
          Text(
            'A new version of invoiso is available. Visit the download page to get the latest release.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
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
          child: Text('Dismiss', style: TextStyle(color: Colors.grey.shade600)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: primary),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Download'),
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

  Widget _versionRow(String label, String version, Color versionColor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
        Text(
          version,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: versionColor),
        ),
      ],
    );
  }
}
