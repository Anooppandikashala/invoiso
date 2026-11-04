import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/models/invoice_attachment.dart';

/// Invoice photo storage: rows in `invoice_attachments`, files at
/// `attachments/<db file stem>/<invoice id>/<attachment id>.jpg` beside the
/// database. Keyed by the db stem because each company has its own database
/// with its own invoice id sequence — two companies can both have invoice 1042.
class InvoiceAttachmentService {
  static const int publicLimit = 10;
  static const int maxDimension = 1600;
  static const int maxBytes = 400 * 1024;

  @visibleForTesting
  static String? rootOverride;

  /// This company's attachments folder.
  static String get companyDir {
    if (rootOverride != null) return rootOverride!;
    final dbPath = DatabaseHelper.path!;
    return join(dirname(dbPath), 'attachments',
        basenameWithoutExtension(dbPath));
  }

  /// Attachments folder of the company stored in [dbFileName], for cleanup
  /// when that company is deleted (its database isn't the open one).
  static String companyDirFor(String dbDirPath, String dbFileName) =>
      join(dbDirPath, 'attachments', basenameWithoutExtension(dbFileName));

  static String invoiceDir(String invoiceId) => join(companyDir, invoiceId);

  static String filePath(InvoiceAttachment a) =>
      join(invoiceDir(a.invoiceId), a.fileName);

  static Future<List<InvoiceAttachment>> listFor(String invoiceId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('invoice_attachments',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
        orderBy: 'sort_order, created_at');
    return rows.map(InvoiceAttachment.fromMap).toList();
  }

  /// Public / private counts per invoice, in one query (invoice list badges).
  static Future<Map<String, ({int public, int private})>> countsFor(
      List<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return {};
    final db = await DatabaseHelper().database;
    final rows = await db.rawQuery(
        'SELECT invoice_id, SUM(is_public) AS pub, COUNT(*) AS total '
        'FROM invoice_attachments '
        'WHERE invoice_id IN (${List.filled(invoiceIds.length, '?').join(',')}) '
        'GROUP BY invoice_id',
        invoiceIds);
    return {
      for (final r in rows)
        r['invoice_id'] as String: (
          public: (r['pub'] as int?) ?? 0,
          private: (r['total'] as int) - ((r['pub'] as int?) ?? 0),
        ),
    };
  }

  /// Drafts for editing [invoiceId]'s current attachments.
  static Future<List<AttachmentDraft>> draftsFor(String invoiceId) async => [
        for (final a in await listFor(invoiceId))
          AttachmentDraft(
              id: a.id, path: filePath(a), isPublic: a.isPublic, caption: a.caption),
      ];

  /// Makes [invoiceId]'s attachments match [drafts]: new drafts (id == null)
  /// are compressed and stored, kept ones get their caption / visibility /
  /// order updated, missing ones are removed. New files are written before the
  /// DB commit and removed again if it fails; removed files are deleted after.
  static Future<void> sync(String invoiceId, List<AttachmentDraft> drafts) async {
    if (drafts.where((d) => d.isPublic).length > publicLimit) {
      throw StateError('At most $publicLimit customer photos per invoice');
    }
    final existing = {for (final a in await listFor(invoiceId)) a.id: a};
    final keptIds = drafts.map((d) => d.id).whereType<String>().toSet();
    final removed = existing.values.where((a) => !keptIds.contains(a.id)).toList();

    final newIds = <AttachmentDraft, String>{};
    final written = <File>[];
    try {
      for (final d in drafts.where((d) => d.id == null)) {
        final id = const Uuid().v4();
        final file = File(join(invoiceDir(invoiceId), '$id.jpg'));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(await _storedBytes(d.path));
        written.add(file);
        newIds[d] = id;
      }

      final db = await DatabaseHelper().database;
      final now = DateTime.now();
      await db.transaction((txn) async {
        for (final a in removed) {
          await txn.delete('invoice_attachments', where: 'id = ?', whereArgs: [a.id]);
        }
        for (var i = 0; i < drafts.length; i++) {
          final d = drafts[i];
          final caption = (d.caption?.trim().isEmpty ?? true) ? null : d.caption!.trim();
          if (d.id != null && existing.containsKey(d.id)) {
            await txn.update(
                'invoice_attachments',
                {'is_public': d.isPublic ? 1 : 0, 'caption': caption, 'sort_order': i},
                where: 'id = ?',
                whereArgs: [d.id]);
          } else if (newIds.containsKey(d)) {
            await txn.insert(
                'invoice_attachments',
                InvoiceAttachment(
                  id: newIds[d]!,
                  invoiceId: invoiceId,
                  fileName: '${newIds[d]}.jpg',
                  isPublic: d.isPublic,
                  caption: caption,
                  sortOrder: i,
                  createdAt: now,
                ).toMap());
          }
        }
      });
    } catch (_) {
      for (final f in written) {
        if (await f.exists()) await f.delete();
      }
      rethrow;
    }
    for (final a in removed) {
      final f = File(filePath(a));
      if (await f.exists()) await f.delete();
    }
  }

  /// Removes every attachment row and file of [invoiceId] (permanent delete).
  static Future<void> deleteAll(String invoiceId) async {
    final db = await DatabaseHelper().database;
    await db.delete('invoice_attachments',
        where: 'invoice_id = ?', whereArgs: [invoiceId]);
    // In-memory test databases have no file, hence no photo folder.
    if (rootOverride == null && DatabaseHelper.path == null) return;
    final dir = Directory(invoiceDir(invoiceId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// A file already in this company's store (e.g. a quotation's photo carried
  /// into the converted invoice) is copied as-is; anything else is compressed.
  static Future<Uint8List> _storedBytes(String path) async {
    final bytes = await File(path).readAsBytes();
    if (isWithin(companyDir, path)) return bytes;
    return Isolate.run(() => compress(bytes));
  }

  /// Applies EXIF rotation, scales the long edge to [maxDimension], and
  /// re-encodes as JPEG at the highest quality that fits [maxBytes].
  @visibleForTesting
  static Uint8List compress(Uint8List source) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(source);
    } catch (_) {
      decoded = null; // the decoders throw RangeError etc. on junk bytes
    }
    if (decoded == null) {
      throw const FormatException('Not a valid image file');
    }
    var image = img.bakeOrientation(decoded);
    if (image.width > maxDimension || image.height > maxDimension) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
      );
    }
    for (final quality in [85, 75, 65, 55, 45]) {
      final out = img.encodeJpg(image, quality: quality);
      if (out.length <= maxBytes) return out;
    }
    return img.encodeJpg(image, quality: 35);
  }
}
