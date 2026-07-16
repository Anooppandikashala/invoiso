import 'package:invoiso/models/invoice_item.dart';

abstract class InvoiceItemRepository {
  Future<void> insertInvoiceItems(String invId, InvoiceItem item);
  Future<List<InvoiceItem>> getInvoiceItemsByInvoiceId(String invoiceId);
  Future<void> markProductSaved(String invoiceId, String productId);
}