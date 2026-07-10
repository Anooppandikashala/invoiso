class RevenueKpi {
  final int invoiceCount;
  final double billed;
  final double collected;
  final double outstanding;
  final double avgInvoiceValue;
  final double profit;

  const RevenueKpi({
    required this.invoiceCount,
    required this.billed,
    required this.collected,
    required this.outstanding,
    required this.avgInvoiceValue,
    this.profit = 0.0,
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

  const MonthlyPoint({
    required this.month,
    required this.billed,
    required this.collected,
    this.profit = 0.0,
  });
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

class TaxBucket {
  final double rate;
  final double taxCollected;

  const TaxBucket({required this.rate, required this.taxCollected});
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
