import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:intl/intl.dart';

import 'package:invoiso/backup/backup_manager.dart';

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
      _showErrorDialog('Failed to load backups: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup(BackupType type) async {
    setState(() => _isLoading = true);

    try {

      final result = await _backupManager.createBackup(
        type: type,
      );

      if (result.success) {
        _showSuccessDialog('Backup created successfully!');
        _loadBackups();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Failed to create backup: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirmed = await _showConfirmDialog(
      'Restore Backup',
      'This will replace all current data with the backup. Are you sure?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final result = await _backupManager.restoreBackup(
        database: await DatabaseHelper().database,
        backupPath: backup.filePath,
      );

      if (result.success) {
        _showSuccessDialog('Backup restored successfully!');
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Failed to restore backup: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await _showConfirmDialog(
      'Delete Backup',
      'Are you sure you want to delete this backup?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final success = await _backupManager.deleteBackup(backup.filePath);

      if (success) {
        _showSuccessDialog('Backup deleted successfully!');
        _loadBackups();
      } else {
        _showErrorDialog('Failed to delete backup');
      }
    } catch (e) {
      _showErrorDialog('Failed to delete backup: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareBackup(BackupInfo backup) async {
    try {
      await _backupManager.downloadBackup(backup.filePath);
    } catch (e) {
      _showErrorDialog('Failed to share backup: ${e.toString()}');
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isLoading = true);

    try {
      final result = await _backupManager.importBackup(await DatabaseHelper().database);

      if (result.success) {
        _showSuccessDialog('Backup imported successfully!');
        _loadBackups();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Failed to import backup: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Management'),
        backgroundColor: Theme.of(context).primaryColor,
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
          Padding(
            padding: const EdgeInsets.only(left: 50,right: 50,top: 16,bottom: 16),
            child: Column(
              children: [
                Row(
                  spacing: 30,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _createBackup(BackupType.database),
                        icon: const Icon(Icons.backup),
                        label: const Text('Create DB Backup'),
                      ),
                    ),
                    AppSpacing.hSmall,
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _createBackup(BackupType.json),
                        icon: const Icon(Icons.download),
                        label: const Text('Export JSON'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _importBackup,
                        icon: const Icon(Icons.upload),
                        label: const Text('Import Backup'),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Backup list
          Expanded(
            child: _backups.isEmpty
                ? const Center(
              child: Text(
                'No backups found',
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _backups.length,
              itemBuilder: (context, index) {
                final backup = _backups[index];
                return _buildBackupTile(backup);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTile(BackupInfo backup) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backup.type == BackupType.database
              ? Colors.blue
              : Colors.green,
          child: Icon(
            backup.type == BackupType.database
                ? Icons.storage
                : Icons.code,
            color: Colors.white,
          ),
        ),
        title: Text(backup.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${backup.formattedSize}'),
            Text('Created: ${dateFormat.format(backup.createdAt)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreBackup(backup);
                break;
              case 'download':
                _shareBackup(backup);
                break;
              case 'delete':
                _deleteBackup(backup);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: Icon(Icons.restore),
                title: Text('Restore'),
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}