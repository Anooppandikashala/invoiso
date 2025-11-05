import '../common.dart';

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