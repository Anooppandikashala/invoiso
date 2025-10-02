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
import 'package:crypto/crypto.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';

class BackupManager {
  static const String _backupExtension = '.invoicedb';
  static const String _jsonExtension = '.json';

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

  // Create database file backup
  Future<String> _createDatabaseBackup(
      String backupName,
      String? customPath,
      ) async {
    final dbPath = DatabaseHelper.path!;
    final backupDir = customPath ?? await _getBackupDirectory();
    final backupPath = join(backupDir, '$backupName$_backupExtension');

    // Copy database file
    final dbFile = File(dbPath);
    await dbFile.copy(backupPath);

    // Reopen database
    await openDatabase(dbPath);

    return backupPath;
  }

  // Create JSON export backup
  Future<String> _createJsonBackup(
      String backupName,
      String? customPath,
      ) async {
    final backupDir = customPath ?? await _getBackupDirectory();
    final backupPath = join(backupDir, '$backupName$_jsonExtension');

    // Export all data to JSON
    final backupData = await _exportDataToJson(await DatabaseHelper().database);

    // Write JSON file
    final backupFile = File(backupPath);
    await backupFile.writeAsString(jsonEncode(backupData));

    return backupPath;
  }

  // Export database data to JSON format
  Future<Map<String, dynamic>> _exportDataToJson(Database database) async {
    final backupData = <String, dynamic>{};

    // Get all table names
    final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    );

    // Export each table
    for (final table in tables) {
      final tableName = table['name'] as String;
      final tableData = await database.query(tableName);
      backupData[tableName] = tableData;
    }

    // Add metadata
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
    required Database database,
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

      final extension = backupPath.split('.').last;

      if (extension == _backupExtension.replaceAll('.', '')) {
        await _restoreFromDatabaseBackup(database, backupPath);
      } else if (extension == _jsonExtension.replaceAll('.', '')) {
        await _restoreFromJsonBackup(database, backupPath);
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

  // Restore from database backup
  Future<void> _restoreFromDatabaseBackup(
      Database database,
      String backupPath,
      ) async {
    final dbPath = database.path;

    // Close current database
    await database.close();

    // Replace current database with backup
    final backupFile = File(backupPath);
    await backupFile.copy(dbPath);

    // Reopen database
    await openDatabase(dbPath);
  }

  // Restore from JSON backup
  Future<void> _restoreFromJsonBackup(
      Database database,
      String backupPath,
      ) async {
    final backupFile = File(backupPath);
    final jsonContent = await backupFile.readAsString();
    final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;

    // Begin transaction
    await database.transaction((txn) async {
      // Clear existing data
      final tables = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );

      for (final table in tables) {
        final tableName = table['name'] as String;
        await txn.delete(tableName);
      }

      // Restore data
      for (final entry in backupData.entries) {
        if (entry.key.startsWith('_')) continue; // Skip metadata

        final tableName = entry.key;
        final tableData = entry.value as List<dynamic>;

        for (final row in tableData) {
          await txn.insert(tableName, row as Map<String, dynamic>);
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

    // Sort by creation date (newest first)
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

    // Check if we need to create a new backup
    if (backups.isEmpty ||
        DateTime.now().difference(backups.first.createdAt).inDays >= 7) {
      await createBackup();

      // Clean up old backups (keep only last 5)
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
  Future<BackupResult> importBackup(Database database) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['invoicedb', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        return await restoreBackup(
          database: database,
          backupPath: filePath,
        );
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
        // For database backups, try to open the file
        final tempDb = await openDatabase(backupPath, readOnly: true);
        await tempDb.close();
        return true;
      } else if (extension == _jsonExtension.replaceAll('.', '')) {
        // For JSON backups, try to parse the JSON
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
      final downloadsPath = join(
        (await getDownloadsDirectory())?.path ?? '',
      );
      final dir = Directory(downloadsPath);
      if (await dir.exists()) return dir;
    }

    // Fallback to app documents dir
    return await getApplicationDocumentsDirectory();
  }

  // Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final permission = await Permission.storage.request();
      return permission == PermissionStatus.granted;
    }
    return true; // iOS doesn't need explicit permission for app documents
  }
}

// Data classes
class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final DateTime? timestamp;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.timestamp,
  });
}

class BackupInfo {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime createdAt;
  final BackupType type;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.createdAt,
    required this.type,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

enum BackupType { database, json }