import 'dart:io';
import 'dart:convert';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../common.dart';
import '../models/backup_info.dart';
import '../models/backup_results.dart';

class BackupManager {
  static const String _backupExtension = '.invoicedb';
  static const String _jsonExtension = '.json';

  // Tables excluded from JSON exports (contain sensitive data).
  static const Set<String> _excludedFromJsonExport = {'users'};

  // Restore order ensures parent tables are inserted before child tables,
  // preventing foreign-key constraint violations.
  static const List<String> _restoreTableOrder = [
    'customers',
    'products',
    'company_info',
    'settings',
    'invoices',
    'invoice_items',
  ];

  // Create backup of the entire database
  Future<BackupResult> createBackup({
    String? customPath,
    BackupType type = BackupType.database,
  }) async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        return BackupResult(
          success: false,
          message: 'Storage permission denied',
        );
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupName = 'invoice_backup_$timestamp';

      String backupPath;

      if (type == BackupType.database) {
        backupPath = await _createDatabaseBackup(backupName, customPath);
      } else {
        backupPath = await _createJsonBackup(backupName, customPath);
      }

      return BackupResult(
        success: true,
        message: 'Backup created successfully',
        filePath: backupPath,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Backup failed: ${e.toString()}',
      );
    }
  }

  // Create database file backup — copies the live DB file while it is open.
  // SQLite WAL mode on desktop keeps the file consistent during a copy.
  Future<String> _createDatabaseBackup(
      String backupName,
      String? customPath,
      ) async {
    final dbPath = DatabaseHelper.path!;
    final backupDir = customPath ?? await _getBackupDirectory();
    final backupPath = join(backupDir, '$backupName$_backupExtension');

    await File(dbPath).copy(backupPath);

    return backupPath;
  }

  // Create JSON export backup (excludes sensitive tables such as 'users')
  Future<String> _createJsonBackup(
      String backupName,
      String? customPath,
      ) async {
    final backupDir = customPath ?? await _getBackupDirectory();
    final backupPath = join(backupDir, '$backupName$_jsonExtension');

    final backupData = await _exportDataToJson(await DatabaseHelper().database);

    await File(backupPath).writeAsString(jsonEncode(backupData));

    return backupPath;
  }

  // Export database data to JSON format (sensitive tables excluded)
  Future<Map<String, dynamic>> _exportDataToJson(Database database) async {
    final backupData = <String, dynamic>{};

    final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    );

    for (final table in tables) {
      final tableName = table['name'] as String;
      if (_excludedFromJsonExport.contains(tableName)) continue;
      final tableData = await database.query(tableName);
      backupData[tableName] = tableData;
    }

    backupData['_metadata'] = {
      'created_at': DateTime.now().toIso8601String(),
      'version': '1.0',
      'app_name': AppConfig.name,
      'backup_type': 'json_export',
      'record_count': backupData.length - 1,
    };

    return backupData;
  }

  // Restore from backup
  Future<BackupResult> restoreBackup({
    required String backupPath,
  }) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      // Verify integrity before touching the live database
      if (!await verifyBackup(backupPath)) {
        return BackupResult(
          success: false,
          message: 'Backup file is corrupted or invalid',
        );
      }

      final extension = backupPath.split('.').last;

      if (extension == _backupExtension.replaceAll('.', '')) {
        await _restoreFromDatabaseBackup(backupPath);
      } else if (extension == _jsonExtension.replaceAll('.', '')) {
        await _restoreFromJsonBackup(backupPath);
      } else {
        return BackupResult(
          success: false,
          message: 'Unsupported backup format',
        );
      }

      return BackupResult(
        success: true,
        message: 'Backup restored successfully',
        filePath: backupPath,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }

  // Restore from database backup.
  // Takes a safety copy first, then replaces the file and re-initializes the
  // singleton so all subsequent DB calls get a live connection.
  Future<void> _restoreFromDatabaseBackup(String backupPath) async {
    final dbPath = DatabaseHelper.path!;
    final safetyPath = '$dbPath.pre_restore_backup';

    // Safety copy of current database
    await File(dbPath).copy(safetyPath);

    try {
      // Close singleton and null its reference
      await DatabaseHelper().close();

      // Replace the database file on disk
      await File(backupPath).copy(dbPath);

      // Re-initialize through the singleton — runs migrations if needed
      await DatabaseHelper().reinitialize();
    } catch (e) {
      // Restore safety copy on failure
      try {
        await DatabaseHelper().close();
        await File(safetyPath).copy(dbPath);
        await DatabaseHelper().reinitialize();
      } catch (_) {}
      rethrow;
    } finally {
      // Clean up safety copy
      final safetyFile = File(safetyPath);
      if (await safetyFile.exists()) await safetyFile.delete();
    }
  }

  // Restore from JSON backup
  Future<void> _restoreFromJsonBackup(String backupPath) async {
    final jsonContent = await File(backupPath).readAsString();
    final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;

    // Validate metadata version
    const supportedVersion = '1.0';
    final metadata = backupData['_metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      final backupVersion = metadata['version'] as String?;
      if (backupVersion != null && backupVersion != supportedVersion) {
        throw Exception(
          'Incompatible backup version: $backupVersion. '
          'This backup was created with a newer version of the app.',
        );
      }
    }

    final database = await DatabaseHelper().database;

    await database.transaction((txn) async {
      // Clear existing data in reverse FK order
      for (final tableName in _restoreTableOrder.reversed) {
        await txn.delete(tableName);
      }

      // Restore in FK-safe order (parents before children)
      for (final tableName in _restoreTableOrder) {
        if (!backupData.containsKey(tableName)) continue;
        final tableData = backupData[tableName] as List<dynamic>;
        for (final row in tableData) {
          await txn.insert(
            tableName,
            row as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Restore any tables not in the ordered list (excluding metadata keys)
      for (final entry in backupData.entries) {
        if (entry.key.startsWith('_')) continue;
        if (_restoreTableOrder.contains(entry.key)) continue;
        final tableData = entry.value as List<dynamic>;
        for (final row in tableData) {
          await txn.insert(
            entry.key,
            row as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  // Get list of available backups
  Future<List<BackupInfo>> getBackupList() async {
    final backupDir = await _getBackupDirectory();
    final directory = Directory(backupDir);

    if (!await directory.exists()) {
      return [];
    }

    final files = await directory.list().toList();
    final backups = <BackupInfo>[];

    for (final file in files) {
      if (file is File) {
        final fileName = basename(file.path);
        if (fileName.endsWith(_backupExtension) || fileName.endsWith(_jsonExtension)) {
          final stat = await file.stat();
          final type = fileName.endsWith(_backupExtension)
              ? BackupType.database
              : BackupType.json;

          backups.add(BackupInfo(
            fileName: fileName,
            filePath: file.path,
            size: stat.size,
            createdAt: stat.modified,
            type: type,
          ));
        }
      }
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return backups;
  }

  // Delete backup file
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Share backup file
  Future<void> shareBackup(String backupPath) async {
    final file = File(backupPath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(backupPath)]);
    }
  }

  // Auto backup (scheduled)
  Future<void> performAutoBackup(Database database) async {
    final backups = await getBackupList();

    if (backups.isEmpty ||
        DateTime.now().difference(backups.first.createdAt).inDays >= 7) {
      await createBackup();
      await _cleanupOldBackups();
    }
  }

  // Clean up old backups
  Future<void> _cleanupOldBackups() async {
    final backups = await getBackupList();

    if (backups.length > 5) {
      final oldBackups = backups.skip(5);
      for (final backup in oldBackups) {
        await deleteBackup(backup.filePath);
      }
    }
  }

  // Import backup from external source
  Future<BackupResult> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['invoicedb', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        return await restoreBackup(backupPath: filePath);
      }

      return BackupResult(
        success: false,
        message: 'No file selected',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

  // Download backup file to Downloads folder
  Future<BackupResult> downloadBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return BackupResult(success: false, message: 'Backup file not found');
      }

      final downloadsDir = await _getDownloadsDirectory();
      final fileName = basename(backupPath);
      final newPath = join(downloadsDir.path, fileName);

      await file.copy(newPath);

      return BackupResult(
        success: true,
        message: 'Backup downloaded to Downloads folder',
        filePath: newPath,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return BackupResult(success: false, message: 'Download failed: ${e.toString()}');
    }
  }

  // Verify backup integrity
  Future<bool> verifyBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) return false;

      final extension = backupPath.split('.').last;

      if (extension == _backupExtension.replaceAll('.', '')) {
        final tempDb = await openDatabase(backupPath, readOnly: true);
        await tempDb.close();
        return true;
      } else if (extension == _jsonExtension.replaceAll('.', '')) {
        final content = await file.readAsString();
        jsonDecode(content);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get backup directory
  Future<String> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(appDir.path, 'backups'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir.path;
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final path = (await getDownloadsDirectory())?.path ?? '';
      final dir = Directory(path);
      if (await dir.exists()) return dir;
    }

    return await getApplicationDocumentsDirectory();
  }

  // Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final permission = await Permission.storage.request();
      return permission == PermissionStatus.granted;
    }
    return true;
  }
}
