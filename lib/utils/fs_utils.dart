import 'dart:io';

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
