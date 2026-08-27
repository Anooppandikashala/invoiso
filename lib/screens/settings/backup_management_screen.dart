import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/backup/backup_manager.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/backup_info.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  final BackupManager _backupManager = BackupManager();
  List<BackupInfo> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);

    try {
      final backups = await _backupManager.getBackupList();
      setState(() => _backups = backups);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(AppLocalizations.of(context)!.backupLoadErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup(BackupType type) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final result = await _backupManager.createBackup(
        type: type,
      );

      if (result.success) {
        _showSuccessDialog(l10n.backupCreatedSuccessMessage);
        _loadBackups();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog(l10n.backupCreateErrorMessage(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      l10n.backupRestoreConfirmTitle,
      l10n.backupRestoreConfirmBody,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final result = await _backupManager.restoreBackup(
        backupPath: backup.filePath,
      );

      if (result.success) {
        _showRestartDialog();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog(l10n.backupRestoreErrorMessage(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      l10n.backupDeleteConfirmTitle,
      l10n.backupDeleteConfirmBody,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final success = await _backupManager.deleteBackup(backup.filePath);

      if (success) {
        _showSuccessDialog(l10n.backupDeletedSuccessMessage);
        _loadBackups();
      } else {
        _showErrorDialog(l10n.backupDeleteFailedMessage);
      }
    } catch (e) {
      _showErrorDialog(l10n.backupDeleteErrorMessage(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadBackup(BackupInfo backup) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final result = await _backupManager.downloadBackup(backup.filePath);
      if (result.success) {
        _showSuccessDialog(l10n.backupSavedToDownloadsMessage);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog(l10n.backupDownloadErrorMessage(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareBackup(BackupInfo backup) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _backupManager.shareBackup(backup.filePath);
    } catch (e) {
      _showErrorDialog(l10n.backupShareErrorMessage(e.toString()));
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final result = await _backupManager.importBackup();

      if (result.success) {
        _showRestartDialog();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog(l10n.backupImportErrorMessage(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupManagementTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actionsPadding: EdgeInsets.only(right: 50),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Action buttons
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      child: Row(
                        spacing: 16,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _createBackup(BackupType.database),
                              icon: const Icon(Icons.backup),
                              label: Text(l10n.backupCreateDbButton),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _createBackup(BackupType.json),
                              icon: const Icon(Icons.download),
                              label: Text(l10n.backupExportJsonButton),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _importBackup,
                              icon: const Icon(Icons.upload),
                              label: Text(l10n.backupImportButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // Backup list
                Expanded(
                  child: _backups.isEmpty
                      ? Center(
                          child: Text(
                            l10n.backupNoBackupsFoundMessage,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: ListView.builder(
                              itemCount: _backups.length,
                              itemBuilder: (context, index) {
                                final backup = _backups[index];
                                return _buildBackupTile(backup);
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildBackupTile(BackupInfo backup) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              backup.type == BackupType.database ? Colors.blue : Colors.green,
          child: Icon(
            backup.type == BackupType.database ? Icons.storage : Icons.code,
            color: Colors.white,
          ),
        ),
        title: Text(backup.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupSizeLabel(backup.formattedSize)),
            Text(l10n.backupCreatedLabel(dateFormat.format(backup.createdAt))),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreBackup(backup);
                break;
              case 'download':
                _downloadBackup(backup);
                break;
              case 'share':
                _shareBackup(backup);
                break;
              case 'delete':
                _deleteBackup(backup);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.actionRestore),
              ),
            ),
            PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: const Icon(Icons.download),
                title: Text(l10n.createInvoiceDownloadLabel),
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.actionShare),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete),
                title: Text(l10n.actionDelete),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.actionConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showRestartDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestoreSuccessTitle),
        content: Text(l10n.backupRestoreSuccessBody),
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

  void _showSuccessDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonSuccessTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionOk),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionOk),
          ),
        ],
      ),
    );
  }
}
