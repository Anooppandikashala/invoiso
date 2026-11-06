import 'dart:typed_data';

import 'package:invoiso/models/invoice_attachment.dart';

/// Invoice photo attachments. Behind an interface so the cloud edition can
/// store them elsewhere (SQLite edition: InvoiceAttachmentService, files on
/// disk next to the company database).
abstract class InvoiceAttachmentRepository {
  Future<List<InvoiceAttachment>> listFor(String invoiceId);

  /// Public / private photo counts per invoice id (ids with none are omitted).
  Future<Map<String, ({int public, int private})>> countsFor(
      List<String> invoiceIds);

  Future<List<AttachmentDraft>> draftsFor(String invoiceId);

  /// Makes [invoiceId]'s stored photos match [drafts].
  Future<void> sync(String invoiceId, List<AttachmentDraft> drafts);

  /// Stored image bytes, or null if the file is missing.
  Future<Uint8List?> readBytes(InvoiceAttachment attachment);
}
