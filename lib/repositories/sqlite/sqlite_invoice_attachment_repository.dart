import 'dart:io';
import 'dart:typed_data';

import 'package:invoiso/database/invoice_attachment_service.dart';
import 'package:invoiso/models/invoice_attachment.dart';
import 'package:invoiso/repositories/invoice_attachment_repository.dart';

class SqliteInvoiceAttachmentRepository implements InvoiceAttachmentRepository {
  @override
  Future<List<InvoiceAttachment>> listFor(String invoiceId) =>
      InvoiceAttachmentService.listFor(invoiceId);

  @override
  Future<Map<String, ({int public, int private})>> countsFor(
          List<String> invoiceIds) =>
      InvoiceAttachmentService.countsFor(invoiceIds);

  @override
  Future<List<AttachmentDraft>> draftsFor(String invoiceId) =>
      InvoiceAttachmentService.draftsFor(invoiceId);

  @override
  Future<void> sync(String invoiceId, List<AttachmentDraft> drafts) =>
      InvoiceAttachmentService.sync(invoiceId, drafts);

  @override
  Future<Uint8List?> readBytes(InvoiceAttachment attachment) async {
    final f = File(InvoiceAttachmentService.filePath(attachment));
    return await f.exists() ? await f.readAsBytes() : null;
  }
}
