import 'dart:typed_data';

/// A customer photo loaded for PDF rendering.
typedef PdfAttachmentImage = ({Uint8List bytes, String? caption});

/// A photo attached to an invoice. Public ones are printed on the PDF's
/// Attachments page(s); private ones are never rendered anywhere.
class InvoiceAttachment {
  final String id;
  final String invoiceId;
  final String fileName; // inside the invoice's attachments folder
  final bool isPublic;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;

  const InvoiceAttachment({
    required this.id,
    required this.invoiceId,
    required this.fileName,
    required this.isPublic,
    this.caption,
    required this.sortOrder,
    required this.createdAt,
  });

  factory InvoiceAttachment.fromMap(Map<String, dynamic> map) =>
      InvoiceAttachment(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        fileName: map['file_name'] as String,
        isPublic: (map['is_public'] as int? ?? 0) == 1,
        caption: map['caption'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'file_name': fileName,
        'is_public': isPublic ? 1 : 0,
        'caption': caption,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Editable copy of one attachment in the Attachments screen / invoice form,
/// written to disk only by `InvoiceAttachmentService.sync`. [id] is null for
/// a newly picked photo; [path] is the file to show (the stored file for an
/// existing attachment, the picked file for a new one). List order = PDF order.
class AttachmentDraft {
  final String? id;
  final String path;
  bool isPublic;
  String? caption;

  AttachmentDraft({
    this.id,
    required this.path,
    required this.isPublic,
    this.caption,
  });
}
