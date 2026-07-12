import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/repositories/invoice_repository.dart';

class SqliteInvoiceRepository implements InvoiceRepository {
  @override
  Future<void> insertInvoice(Invoice invoice) => InvoiceService.insertInvoice(invoice);
  @override
  Future<void> updateInvoice(Invoice invoice) => InvoiceService.updateInvoice(invoice);
  @override
  Future<double> getPreviousBalanceDueForInvoice(Invoice invoice) =>
      InvoiceService.getPreviousBalanceDueForInvoice(invoice);
  @override
  Future<double> getPreviousBalanceDueForCustomer({
    required String customerId,
    required String currencyCode,
    required DateTime asOfDate,
    String? currentInvoiceId,
  }) =>
      InvoiceService.getPreviousBalanceDueForCustomer(
        customerId: customerId,
        currencyCode: currencyCode,
        asOfDate: asOfDate,
        currentInvoiceId: currentInvoiceId,
      );
  @override
  Future<Invoice?> getInvoiceById(String id) => InvoiceService.getInvoiceById(id);
  @override
  Future<List<Invoice>> getAllInvoices() => InvoiceService.getAllInvoices();
  @override
  Future<List<Invoice>> getInvoicesForExport({
    DateTime? fromDate,
    DateTime? toDate,
    int? fromId,
    int? toId,
    String? filterType,
  }) =>
      InvoiceService.getInvoicesForExport(
        fromDate: fromDate,
        toDate: toDate,
        fromId: fromId,
        toId: toId,
        filterType: filterType,
      );
  @override
  Future<int> countInvoicesForExport({
    DateTime? fromDate,
    DateTime? toDate,
    int? fromId,
    int? toId,
    String? filterType,
  }) =>
      InvoiceService.countInvoicesForExport(
        fromDate: fromDate,
        toDate: toDate,
        fromId: fromId,
        toId: toId,
        filterType: filterType,
      );
  @override
  Future<List<Invoice>> getInvoicesPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
    String? filterType,
  }) =>
      InvoiceService.getInvoicesPaginated(
        page: page,
        pageSize: pageSize,
        searchQuery: searchQuery,
        filterType: filterType,
      );
  @override
  Future<int> getInvoiceCount({String searchQuery = '', String? filterType}) =>
      InvoiceService.getInvoiceCount(searchQuery: searchQuery, filterType: filterType);
  @override
  Future<void> softDeleteInvoice(String id) => InvoiceService.softDeleteInvoice(id);
  @override
  Future<void> restoreInvoice(String id) => InvoiceService.restoreInvoice(id);
  @override
  Future<void> permanentDeleteInvoice(String id) => InvoiceService.permanentDeleteInvoice(id);
  @override
  Future<List<Invoice>> getDeletedInvoices() => InvoiceService.getDeletedInvoices();
  @override
  Future<void> deleteInvoice(String id) => InvoiceService.deleteInvoice(id);
  @override
  Future<int> getTotalInvoiceCountIncludingTrashed() =>
      InvoiceService.getTotalInvoiceCountIncludingTrashed();
  @override
  Future<({int count, double revenue, double outstanding})> getDashboardFinancials() =>
      InvoiceService.getDashboardFinancials();
  @override
  Future<List<Invoice>> getRecentInvoices({int limit = 5}) => InvoiceService.getRecentInvoices(limit: limit);
  @override
  Future<List<Invoice>> getDueSoonInvoices() => InvoiceService.getDueSoonInvoices();
  @override
  Future<List<Invoice>> getOverdueInvoices({int limit = 10}) => InvoiceService.getOverdueInvoices(limit: limit);
  @override
  Future<List<Map<String, dynamic>>> getMonthlyRevenue() => InvoiceService.getMonthlyRevenue();
  @override
  Future<List<Map<String, dynamic>>> getTopCustomers() => InvoiceService.getTopCustomers();
  @override
  Future<List<Map<String, dynamic>>> getTopProducts() => InvoiceService.getTopProducts();

  @override
  Future<String> generateNextId() {
    return InvoiceService.generateNextId();
  }

  @override
  Future<String> generateNextInvoiceNumber(String type) {
    return InvoiceService.generateNextInvoiceNumber(type);
  }

  @override
  Future<String> peekNextId() {
    return InvoiceService.generateNextId();
  }

  @override
  Future<String> peekNextInvoiceNumber(String type) {
    return InvoiceService.generateNextInvoiceNumber(type);
  }
}
