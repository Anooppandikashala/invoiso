import 'package:invoiso/models/report_models.dart';

abstract class ReportRepository {
  Future<RevenueKpi> getRevenueSummary(DateTime from, DateTime to, {String? currencyCode});
  Future<List<MonthlyPoint>> getMonthlyRevenueTrend(DateTime from, DateTime to, {String? currencyCode});
  Future<StatusBreakdown> getPaymentStatusBreakdown(DateTime from, DateTime to, {String? currencyCode});
  Future<List<AgedReceivable>> getAgedReceivables({String? currencyCode});
  Future<List<TaxBucket>> getTaxByRate(DateTime from, DateTime to, {String? currencyCode});
  Future<List<TopCustomer>> getTopCustomers(DateTime from, DateTime to, {int limit = 500, String? currencyCode});
  Future<List<CustomerStatementCustomer>> getStatementCustomers({String? currencyCode});
  Future<List<CustomerStatement>> getCustomerStatements(String customerKey, DateTime from, DateTime to, {String? currencyCode});
  Future<List<TopProduct>> getTopProducts(DateTime from, DateTime to, {int limit = 500, String? currencyCode, bool rankByProfit = false});
  Future<QuotationStats> getQuotationStats(DateTime from, DateTime to, {String? currencyCode});
  Future<List<InvoiceStatusRow>> getInvoiceStatusList(DateTime from, DateTime to, {String? currencyCode});
  Future<int> getMissingCostItemCount(DateTime from, DateTime to, {String? currencyCode});
}
