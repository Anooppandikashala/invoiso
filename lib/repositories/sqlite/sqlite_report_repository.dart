import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/models/report_models.dart';
import 'package:invoiso/repositories/report_repository.dart';

class SqliteReportRepository implements ReportRepository {
  @override
  Future<RevenueKpi> getRevenueSummary(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getRevenueSummary(from, to, currencyCode: currencyCode);
  @override
  Future<List<MonthlyPoint>> getMonthlyRevenueTrend(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getMonthlyRevenueTrend(from, to, currencyCode: currencyCode);
  @override
  Future<StatusBreakdown> getPaymentStatusBreakdown(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getPaymentStatusBreakdown(from, to, currencyCode: currencyCode);
  @override
  Future<List<AgedReceivable>> getAgedReceivables({String? currencyCode}) =>
      ReportService.getAgedReceivables(currencyCode: currencyCode);
  @override
  Future<List<TaxBucket>> getTaxByRate(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getTaxByRate(from, to, currencyCode: currencyCode);
  @override
  Future<List<TopCustomer>> getTopCustomers(DateTime from, DateTime to, {int limit = 500, String? currencyCode}) =>
      ReportService.getTopCustomers(from, to, limit: limit, currencyCode: currencyCode);
  @override
  Future<List<CustomerStatementCustomer>> getStatementCustomers({String? currencyCode}) =>
      ReportService.getStatementCustomers(currencyCode: currencyCode);
  @override
  Future<List<CustomerStatement>> getCustomerStatements(
          String customerKey, DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getCustomerStatements(customerKey, from, to, currencyCode: currencyCode);
  @override
  Future<List<TopProduct>> getTopProducts(DateTime from, DateTime to, {int limit = 500, String? currencyCode, bool rankByProfit = false}) =>
      ReportService.getTopProducts(from, to, limit: limit, currencyCode: currencyCode, rankByProfit: rankByProfit);
  @override
  Future<QuotationStats> getQuotationStats(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getQuotationStats(from, to, currencyCode: currencyCode);
  @override
  Future<List<InvoiceStatusRow>> getInvoiceStatusList(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getInvoiceStatusList(from, to, currencyCode: currencyCode);
  @override
  Future<int> getMissingCostItemCount(DateTime from, DateTime to, {String? currencyCode}) =>
      ReportService.getMissingCostItemCount(from, to, currencyCode: currencyCode);
}
