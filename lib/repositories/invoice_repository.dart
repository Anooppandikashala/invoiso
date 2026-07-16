import 'package:invoiso/models/invoice.dart';

abstract class InvoiceRepository {
  Future<void> insertInvoice(Invoice invoice);
  Future<void> updateInvoice(Invoice invoice);
  Future<double> getPreviousBalanceDueForInvoice(Invoice invoice);
  Future<double> getPreviousBalanceDueForCustomer({
    required String customerId,
    required String currencyCode,
    required DateTime asOfDate,
    String? currentInvoiceId,
  });
  Future<Invoice?> getInvoiceById(String id);
  Future<List<Invoice>> getAllInvoices();
  Future<List<Invoice>> getInvoicesForExport({
    DateTime? fromDate,
    DateTime? toDate,
    int? fromId,
    int? toId,
    String? filterType,
  });
  Future<int> countInvoicesForExport({
    DateTime? fromDate,
    DateTime? toDate,
    int? fromId,
    int? toId,
    String? filterType,
  });
  Future<List<Invoice>> getInvoicesPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
    String? filterType,
  });
  Future<int> getInvoiceCount({
    String searchQuery = '',
    String? filterType,
  });
  Future<void> softDeleteInvoice(String id);
  Future<void> restoreInvoice(String id);
  Future<void> permanentDeleteInvoice(String id);
  Future<List<Invoice>> getDeletedInvoices();
  Future<void> deleteInvoice(String id);
  Future<int> getTotalInvoiceCountIncludingTrashed();
  Future<String> generateNextId();
  Future<String> generateNextInvoiceNumber(String type);
  /// Non-consuming preview of [generateNextId] — for UI display only, must
  /// not advance any counter. Call [generateNextId] again at actual save time.
  Future<String> peekNextId();
  /// Non-consuming preview of [generateNextInvoiceNumber] — for UI display
  /// only, must not advance any counter. Call [generateNextInvoiceNumber]
  /// again at actual save time.
  Future<String> peekNextInvoiceNumber(String type);
  Future<({int count, double revenue, double outstanding})> getDashboardFinancials();
  Future<List<Invoice>> getRecentInvoices({int limit = 5});
  Future<List<Invoice>> getDueSoonInvoices();
  Future<List<Invoice>> getOverdueInvoices({int limit = 10});
  Future<List<Map<String, dynamic>>> getMonthlyRevenue();
  Future<List<Map<String, dynamic>>> getTopCustomers();
  Future<List<Map<String, dynamic>>> getTopProducts();
}
