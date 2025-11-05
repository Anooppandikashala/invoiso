
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