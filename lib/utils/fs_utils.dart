import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Creates [path] and every missing ancestor, one level at a time.
///
/// Works around a Windows quirk where `Directory.create(recursive: true)`
/// throws `PathNotFoundException` (OS error 2) when an ancestor directory is
/// missing — e.g. the user's Documents folder was redirected to OneDrive or
/// never materialised on a fresh profile, so `getApplicationDocumentsDirectory()`
/// returns a path that doesn't physically exist yet.
Future<Directory> ensureDirectory(String path) async {
  final dir = Directory(path);
  if (await dir.exists()) return dir;

  final parent = dir.parent;
  if (parent.path != dir.path && !await parent.exists()) {
    await ensureDirectory(parent.path);
  }

  try {
    await dir.create();
  } on FileSystemException {
    if (!await dir.exists()) await dir.create(recursive: true);
  }
  return dir;
}

/// "Save As" for [bytes]: native dialog + write on desktop; on Android /
/// iOS the platform save flow writes the bytes itself (file_picker throws
/// there without them). Returns the saved path, or null if cancelled.
Future<String?> saveBytesAs(Uint8List bytes,
    {required String dialogTitle,
    required String fileName,
    required String extension}) async {
  final mobile = Platform.isAndroid || Platform.isIOS;
  final path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: mobile ? bytes : null,
  );
  if (path != null && !mobile) await File(path).writeAsBytes(bytes);
  return path;
}
