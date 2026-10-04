class RevenueKpi {
  final int invoiceCount;
  final double billed;
  final double collected;
  final double outstanding;
  final double avgInvoiceValue;
  final double profit;
  // Profit scaled by each invoice's collected fraction — the realized
  // (cash-basis) counterpart to [profit].
  final double realizedProfit;

  const RevenueKpi({
    required this.invoiceCount,
    required this.billed,
    required this.collected,
    required this.outstanding,
    required this.avgInvoiceValue,
    this.profit = 0.0,
    this.realizedProfit = 0.0,
  });

  static const RevenueKpi empty = RevenueKpi(
    invoiceCount: 0,
    billed: 0,
    collected: 0,
    outstanding: 0,
    avgInvoiceValue: 0,
  );
}

class MonthlyPoint {
  final String month;
  final double billed;
  final double collected;
  final double profit;
  final int invoiceCount;
  final double netSales;
  final double cogs;
  final double outstanding;

  const MonthlyPoint({
    required this.month,
    required this.billed,
    required this.collected,
    this.profit = 0.0,
    this.invoiceCount = 0,
    this.netSales = 0.0,
    this.cogs = 0.0,
    this.outstanding = 0.0,
  });

  double get marginPercent =>
      netSales == 0 ? 0.0 : (profit / netSales) * 100;
}

class DailyPoint {
  final String date;
  final int invoiceCount;
  final double billed;
  final double cogs;

  const DailyPoint({
    required this.date,
    required this.invoiceCount,
    required this.billed,
    this.cogs = 0.0,
  });

  double get profit => billed - cogs;

  double get marginPercent => billed == 0 ? 0.0 : (profit / billed) * 100;
}

class StatusBreakdown {
  final int paid;
  final int partial;
  final int unpaid;

  const StatusBreakdown({
    required this.paid,
    required this.partial,
    required this.unpaid,
  });

  int get total => paid + partial + unpaid;

  static const StatusBreakdown empty =
      StatusBreakdown(paid: 0, partial: 0, unpaid: 0);
}

class AgedReceivable {
  final String invoiceId;
  final String customerName;
  final double outstanding;
  final int daysOverdue;
  final bool hasNoDueDate;

  const AgedReceivable({
    required this.invoiceId,
    required this.customerName,
    required this.outstanding,
    required this.daysOverdue,
    this.hasNoDueDate = false,
  });
}

/// One customer's outstanding balance split into aging buckets, for the
/// A/R Aging Summary. Bucket boundaries match [AgedReceivable]'s detail rows.
class AgedReceivableSummaryRow {
  final String customerName;
  final double current;
  final double d0to30;
  final double d31to60;
  final double d61to90;
  final double d90plus;
  final double noDueDate;

  const AgedReceivableSummaryRow({
    required this.customerName,
    this.current = 0.0,
    this.d0to30 = 0.0,
    this.d31to60 = 0.0,
    this.d61to90 = 0.0,
    this.d90plus = 0.0,
    this.noDueDate = 0.0,
  });

  double get total =>
      current + d0to30 + d31to60 + d61to90 + d90plus + noDueDate;
}

class TaxBucket {
  final double rate;
  final double taxCollected;
  final double taxableAmount;

  const TaxBucket({
    required this.rate,
    required this.taxCollected,
    this.taxableAmount = 0.0,
  });

  double get gross => taxableAmount + taxCollected;
}

class TopCustomer {
  final String name;
  final int invoiceCount;
  final double billed;
  final double collected;
  final double outstanding;

  const TopCustomer({
    required this.name,
    required this.invoiceCount,
    required this.billed,
    required this.collected,
    required this.outstanding,
  });
}

class CustomerStatementCustomer {
  final String key;
  final String name;
  final int invoiceCount;

  const CustomerStatementCustomer({
    required this.key,
    required this.name,
    required this.invoiceCount,
  });
}

class CustomerStatementLine {
  final String date;
  final String type;
  final String reference;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  const CustomerStatementLine({
    required this.date,
    required this.type,
    required this.reference,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}

class CustomerStatement {
  final String customerKey;
  final String customerName;
  final String currencyCode;
  final String currencySymbol;
  final double openingBalance;
  final double invoiced;
  final double paid;
  final double closingBalance;
  final double overdueBalance;
  final List<CustomerStatementLine> lines;

  const CustomerStatement({
    required this.customerKey,
    required this.customerName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.openingBalance,
    required this.invoiced,
    required this.paid,
    required this.closingBalance,
    required this.overdueBalance,
    required this.lines,
  });
}

class TopProduct {
  final String name;
  final double unitsSold;
  final double revenue;
  final double discountGiven;
  final double cogs;

  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
    required this.discountGiven,
    this.cogs = 0.0,
  });

  double get profit => revenue - cogs;

  double get marginPercent => revenue == 0 ? 0.0 : (profit / revenue) * 100;
}

class InventoryValuationSummary {
  final double stockValue;
  final double retailValue;
  final int totalUnits;
  final int productCount;
  final int excludedCount;

  const InventoryValuationSummary({
    required this.stockValue,
    required this.retailValue,
    required this.totalUnits,
    required this.productCount,
    required this.excludedCount,
  });

  double get lockedProfit => retailValue - stockValue;

  static const empty = InventoryValuationSummary(
    stockValue: 0,
    retailValue: 0,
    totalUnits: 0,
    productCount: 0,
    excludedCount: 0,
  );
}

class InventoryValuationRow {
  final String productId;
  final String name;
  final int stock;
  final double purchasePrice;
  final double price;
  final String unit;

  const InventoryValuationRow({
    required this.productId,
    required this.name,
    required this.stock,
    required this.purchasePrice,
    required this.price,
    required this.unit,
  });

  double get stockValue => stock * purchasePrice;

  double get retailValue => stock * price;
}

class QuotationStats {
  final int quotationsIssued;
  final int invoicesInPeriod;
  final double conversionRate;

  const QuotationStats({
    required this.quotationsIssued,
    required this.invoicesInPeriod,
    required this.conversionRate,
  });

  static const QuotationStats empty = QuotationStats(
    quotationsIssued: 0,
    invoicesInPeriod: 0,
    conversionRate: 0,
  );
}

class InvoiceStatusRow {
  final String id;
  final String date;
  final String? dueDate;
  final String customerName;
  final double total;
  final double paid;
  final double outstanding;
  final int daysOverdue;
  final bool hasNoDueDate;
  final String status;
  final bool isOverdue;

  const InvoiceStatusRow({
    required this.id,
    required this.date,
    this.dueDate,
    required this.customerName,
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.daysOverdue,
    required this.hasNoDueDate,
    required this.status,
    required this.isOverdue,
  });
}
