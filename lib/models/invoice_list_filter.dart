/// Invoice list filters applied in the query, before pagination
/// (Issues.md #39). Defaults = no filtering.
class InvoiceListFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? numberFrom;
  final int? numberTo;

  /// 'all' | 'overdue' | 'due_today' | 'due_week' | 'due_month'
  final String dueDate;

  /// 'all' | 'paid' | 'partial' | 'unpaid' — applies to 'Invoice' rows only.
  final String paymentStatus;

  /// Drop fully-paid Invoices (other types are kept).
  final bool hidePaid;

  const InvoiceListFilter({
    this.dateFrom,
    this.dateTo,
    this.numberFrom,
    this.numberTo,
    this.dueDate = 'all',
    this.paymentStatus = 'all',
    this.hidePaid = false,
  });

  /// True when a filter depends on each invoice's total/paid balance, which
  /// isn't stored — those are resolved in Dart over the SQL-filtered set.
  bool get needsBalance =>
      hidePaid || dueDate == 'overdue' || paymentStatus != 'all';
}
