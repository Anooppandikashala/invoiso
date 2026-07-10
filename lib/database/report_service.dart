import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/domain/customer_identity.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/utils/app_date.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/models/report_models.dart';
export 'package:invoiso/models/report_models.dart';

// ─── Internal row ─────────────────────────────────────────────────────────────

class _InvRow {
  final String id;
  final String customerKey;
  final String customerName;
  final String date;
  final String? dueDate;
  final double total;
  final double paid;
  final double outstanding;
  final String currencyCode;
  final String currencySymbol;

  const _InvRow({
    required this.id,
    required this.customerKey,
    required this.customerName,
    required this.date,
    this.dueDate,
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.currencyCode,
    required this.currencySymbol,
  });
}

class _StatementLineDraft {
  final String date;
  final int order;
  final String type;
  final String reference;
  final String description;
  final double debit;
  final double credit;

  const _StatementLineDraft({
    required this.date,
    required this.order,
    required this.type,
    required this.reference,
    required this.description,
    required this.debit,
    required this.credit,
  });
}

// ─── Service ───────────────────────────────────────────────────────────────────

class ReportService {
  static final _db = DatabaseHelper();
  static const _invoiceItemNetSql = 'CASE WHEN ii.discount_per_unit = 1 '
      'THEN (COALESCE(ii.unit_price, ii.product_price) - ii.discount) * ii.quantity '
      '+ COALESCE(ii.extra_cost, 0) '
      'ELSE COALESCE(ii.unit_price, ii.product_price) * ii.quantity '
      '- ii.discount + COALESCE(ii.extra_cost, 0) END';
  static const _invoiceItemDiscountSql = 'CASE WHEN ii.discount_per_unit = 1 '
      'THEN ii.discount * ii.quantity ELSE ii.discount END';

  // ── Batch loader: invoice totals computed in Dart (accurate, no N+1) ────────

  static Future<List<_InvRow>> _loadRows({
    String type = 'Invoice',
    DateTime? from,
    DateTime? to,
    String? currencyCode,
    String? customerKey,
  }) async {
    final db = await _db.database;

    final sb = StringBuffer('type = ? AND deleted_at IS NULL');
    final args = <dynamic>[type];
    if (from != null) {
      sb.write(' AND date >= ?');
      args.add(AppDate.dateKeyStart(from));
    }
    if (to != null) {
      sb.write(' AND date <= ?');
      args.add(AppDate.dateKeyEnd(to));
    }
    if (currencyCode != null) {
      sb.write(' AND (currency_code = ? OR currency_code IS NULL)');
      args.add(currencyCode);
    }
    if (customerKey != null) {
      sb.write(" AND COALESCE(NULLIF(customer_id, ''), customer_name) = ?");
      args.add(customerKey);
    }

    final invRows = await db.query(
      'invoices',
      columns: [
        'id',
        'customer_id',
        'customer_name',
        'date',
        'due_date',
        'tax_rate',
        'tax_mode',
        'additional_costs',
        'currency_code',
        'currency_symbol',
      ],
      where: sb.toString(),
      whereArgs: args,
    );
    if (invRows.isEmpty) return [];

    final ids = invRows.map((r) => r['id'] as String).toList();
    final ph = List.filled(ids.length, '?').join(',');

    final itemRows = await db.rawQuery(
      'SELECT invoice_id, quantity, unit_price, product_price, discount, '
      'discount_per_unit, extra_cost, product_tax_rate '
      'FROM invoice_items WHERE invoice_id IN ($ph)',
      ids,
    );

    final payRows = await db.rawQuery(
      'SELECT invoice_id, COALESCE(SUM(amount_paid), 0.0) AS paid '
      'FROM invoice_payments WHERE invoice_id IN ($ph) '
      'GROUP BY invoice_id',
      ids,
    );

    final itemsByInv = <String, List<Map<String, dynamic>>>{};
    for (final r in itemRows) {
      (itemsByInv[r['invoice_id'] as String] ??= [])
          .add(r as Map<String, dynamic>);
    }

    final paidByInv = <String, double>{
      for (final r in payRows)
        r['invoice_id'] as String: (r['paid'] as num).toDouble()
    };

    return invRows.map((inv) {
      final id = inv['id'] as String;
      final taxMode = TaxModeExtension.fromKey(inv['tax_mode'] as String?);
      final taxRate = (inv['tax_rate'] as num?)?.toDouble() ?? 0.0;
      final items = itemsByInv[id] ?? [];
      final paid = paidByInv[id] ?? 0.0;

      final addCosts =
          AdditionalCost.listFromJson(inv['additional_costs'] as String?)
              .fold(0.0, (s, c) => s + c.amount);
      final totals = InvoiceTotalsCalculator.totals(
        lines: items.map(InvoiceTotalsCalculator.lineFromDbRow),
        taxMode: taxMode,
        globalTaxRate: taxRate,
        globalTaxRateFormat: TaxRateFormat.percent,
        additionalCostsTotal: addCosts,
      );
      final total = totals.total;
      final outstanding =
          InvoiceCalculator.outstanding(total: total, paid: paid);

      return _InvRow(
        id: id,
        customerKey: CustomerIdentity.key(
          id: inv['customer_id'] as String?,
          name: inv['customer_name'] as String?,
        ),
        customerName:
            CustomerIdentity.displayName(inv['customer_name'] as String?),
        date: inv['date'] as String? ?? '',
        dueDate: inv['due_date'] as String?,
        total: total,
        paid: paid,
        outstanding: outstanding,
        currencyCode: inv['currency_code'] as String? ?? 'INR',
        currencySymbol: inv['currency_symbol'] as String? ?? 'Rs.',
      );
    }).toList();
  }

  // ── 1. Revenue KPIs ────────────────────────────────────────────────────────

  static Future<RevenueKpi> getRevenueSummary(DateTime from, DateTime to,
      {String? currencyCode}) async {
    final rows =
        await _loadRows(from: from, to: to, currencyCode: currencyCode);
    if (rows.isEmpty) return RevenueKpi.empty;

    double billed = 0, collected = 0, outstanding = 0;
    for (final r in rows) {
      billed += r.total;
      collected += r.paid;
      outstanding += r.outstanding;
    }
    final profit = await _getTotalProfit(from, to, currencyCode: currencyCode);
    return RevenueKpi(
      invoiceCount: rows.length,
      billed: billed,
      collected: collected,
      outstanding: outstanding,
      avgInvoiceValue: billed / rows.length,
      profit: profit,
    );
  }

  /// Net product revenue minus cost of goods sold, for [from]..[to]. Uses the
  /// same net-revenue basis as [getTopProducts] (tax-exclusive line total),
  /// not the tax-inclusive invoice `billed` total used elsewhere in this KPI.
  static Future<double> _getTotalProfit(DateTime from, DateTime to,
      {String? currencyCode}) async {
    final db = await _db.database;
    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final ccFilter = currencyCode != null
        ? 'AND (i.currency_code = ? OR i.currency_code IS NULL) '
        : '';
    final args = <Object?>[
      if (currencyCode != null) currencyCode,
      f,
      t,
    ];
    final rows = await db.rawQuery(
      "SELECT SUM($_invoiceItemNetSql) AS revenue, "
      "SUM(ii.quantity * ii.product_purchase_price) AS cogs "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "$ccFilter"
      "AND i.date >= ? AND i.date <= ?",
      args,
    );
    if (rows.isEmpty) return 0.0;
    final revenue = (rows.first['revenue'] as num?)?.toDouble() ?? 0.0;
    final cogs = (rows.first['cogs'] as num?)?.toDouble() ?? 0.0;
    return revenue - cogs;
  }

  /// Count of sold line items in [from]..[to] with no purchase-price
  /// snapshot (0 or null) — i.e. sales made before purchase price was set on
  /// the product, or before this feature existed. Profit/margin figures are
  /// understated by this many items' worth of unknown cost.
  static Future<int> getMissingCostItemCount(DateTime from, DateTime to,
      {String? currencyCode}) async {
    final db = await _db.database;
    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final ccFilter = currencyCode != null
        ? 'AND (i.currency_code = ? OR i.currency_code IS NULL) '
        : '';
    final args = <Object?>[
      if (currencyCode != null) currencyCode,
      f,
      t,
    ];
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "AND (ii.product_purchase_price IS NULL OR ii.product_purchase_price = 0) "
      "$ccFilter"
      "AND i.date >= ? AND i.date <= ?",
      args,
    );
    return (rows.first['cnt'] as num?)?.toInt() ?? 0;
  }

  // ── 2. Monthly revenue trend ───────────────────────────────────────────────

  static Future<List<MonthlyPoint>> getMonthlyRevenueTrend(
      DateTime from, DateTime to,
      {String? currencyCode}) async {
    final rows =
        await _loadRows(from: from, to: to, currencyCode: currencyCode);
    final db = await _db.database;

    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final currencyFilter = currencyCode != null
        ? 'AND (i.currency_code = ? OR i.currency_code IS NULL) '
        : '';
    final args = <Object?>[
      if (currencyCode != null) currencyCode,
      f,
      t,
    ];

    // Collected grouped by payment date (more accurate for cash-flow view)
    final collectedRows = await db.rawQuery(
      "SELECT strftime('%Y-%m', ip.date_paid) AS month, "
      "COALESCE(SUM(ip.amount_paid), 0.0) AS collected "
      "FROM invoice_payments ip "
      "JOIN invoices i ON ip.invoice_id = i.id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "$currencyFilter"
      "AND ip.date_paid >= ? AND ip.date_paid <= ? "
      "GROUP BY month ORDER BY month",
      args,
    );

    final collectedByMonth = <String, double>{
      for (final r in collectedRows)
        r['month'] as String: (r['collected'] as num).toDouble()
    };

    // Billed grouped by invoice date
    final billedByMonth = <String, double>{};
    for (final r in rows) {
      if (r.date.length >= 7) {
        final m = r.date.substring(0, 7);
        billedByMonth[m] = (billedByMonth[m] ?? 0) + r.total;
      }
    }

    // Profit grouped by invoice date (net revenue minus COGS)
    final profitRows = await db.rawQuery(
      "SELECT strftime('%Y-%m', i.date) AS month, "
      "SUM($_invoiceItemNetSql) AS revenue, "
      "SUM(ii.quantity * ii.product_purchase_price) AS cogs "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "$currencyFilter"
      "AND i.date >= ? AND i.date <= ? "
      "GROUP BY month",
      args,
    );
    final profitByMonth = <String, double>{
      for (final r in profitRows)
        r['month'] as String:
            ((r['revenue'] as num?)?.toDouble() ?? 0.0) -
                ((r['cogs'] as num?)?.toDouble() ?? 0.0)
    };

    final allMonths = {...billedByMonth.keys, ...collectedByMonth.keys}.toList()
      ..sort();

    return allMonths
        .map((m) => MonthlyPoint(
              month: m,
              billed: billedByMonth[m] ?? 0,
              collected: collectedByMonth[m] ?? 0,
              profit: profitByMonth[m] ?? 0,
            ))
        .toList();
  }

  // ── 3. Payment status breakdown ────────────────────────────────────────────

  static Future<StatusBreakdown> getPaymentStatusBreakdown(
      DateTime from, DateTime to,
      {String? currencyCode}) async {
    final rows =
        await _loadRows(from: from, to: to, currencyCode: currencyCode);
    int paid = 0, partial = 0, unpaid = 0;
    for (final r in rows) {
      switch (InvoiceCalculator.paymentStatus(total: r.total, paid: r.paid)) {
        case PaymentStatus.unpaid:
          unpaid++;
        case PaymentStatus.paid:
          paid++;
        case PaymentStatus.partial:
          partial++;
      }
    }
    return StatusBreakdown(paid: paid, partial: partial, unpaid: unpaid);
  }

  // ── 4. Aged receivables (all time, all overdue) ────────────────────────────

  static Future<List<AgedReceivable>> getAgedReceivables(
      {String? currencyCode}) async {
    final rows = await _loadRows(currencyCode: currencyCode);
    final now = DateTime.now();
    final result = <AgedReceivable>[];

    for (final r in rows) {
      if (r.outstanding <= InvoiceCalculator.moneyEpsilon) continue;
      final dueDate = r.dueDate != null ? DateTime.tryParse(r.dueDate!) : null;
      final bool noDueDate = dueDate == null;
      final daysOverdue =
          InvoiceCalculator.daysOverdue(dueDate: dueDate, asOf: now);
      result.add(AgedReceivable(
        invoiceId: r.id,
        customerName: r.customerName,
        outstanding: r.outstanding,
        daysOverdue: daysOverdue,
        hasNoDueDate: noDueDate,
      ));
    }
    // Sort: no-due-date last, then by days overdue descending
    result.sort((a, b) {
      if (a.hasNoDueDate != b.hasNoDueDate) return a.hasNoDueDate ? 1 : -1;
      return b.daysOverdue.compareTo(a.daysOverdue);
    });
    return result;
  }

  // ── 5. Tax collected by rate ───────────────────────────────────────────────

  static Future<List<TaxBucket>> getTaxByRate(DateTime from, DateTime to,
      {String? currencyCode}) async {
    final db = await _db.database;
    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final ccFilter = currencyCode != null
        ? 'AND (i.currency_code = ? OR i.currency_code IS NULL) '
        : '';
    final dateArgs = <Object?>[
      if (currencyCode != null) currencyCode,
      f,
      t,
    ];

    final buckets = <double, double>{};

    // Per-item mode: tax computed per line item's product_tax_rate
    final perItemRows = await db.rawQuery(
      "SELECT ii.product_tax_rate AS rate, "
      "SUM($_invoiceItemNetSql * ii.product_tax_rate / 100) AS tax_amount "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "AND i.tax_mode = 'per_item' "
      "$ccFilter"
      "AND i.date >= ? AND i.date <= ? "
      "AND ii.product_tax_rate > 0 "
      "GROUP BY ii.product_tax_rate",
      dateArgs,
    );
    for (final r in perItemRows) {
      final rate = (r['rate'] as num).toDouble();
      buckets[rate] =
          (buckets[rate] ?? 0) + (r['tax_amount'] as num).toDouble();
    }

    // Global mode: single tax rate applied to the invoice subtotal
    final globalInvRows = await db.rawQuery(
      "SELECT i.id, i.tax_rate, i.additional_costs "
      "FROM invoices i "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "AND i.tax_mode = 'global' AND i.tax_rate > 0 "
      "$ccFilter"
      "AND i.date >= ? AND i.date <= ?",
      dateArgs,
    );

    if (globalInvRows.isNotEmpty) {
      final ids = globalInvRows.map((r) => r['id'] as String).toList();
      final ph = List.filled(ids.length, '?').join(',');
      final itemRows = await db.rawQuery(
        "SELECT invoice_id, quantity, unit_price, product_price, discount, "
        "discount_per_unit, extra_cost "
        "FROM invoice_items WHERE invoice_id IN ($ph)",
        ids,
      );
      final itemsByInv = <String, List<Map<String, dynamic>>>{};
      for (final r in itemRows) {
        (itemsByInv[r['invoice_id'] as String] ??= [])
            .add(r as Map<String, dynamic>);
      }
      for (final inv in globalInvRows) {
        final id = inv['id'] as String;
        final taxRate = (inv['tax_rate'] as num?)?.toDouble() ?? 0.0;
        final totals = InvoiceTotalsCalculator.totals(
          lines:
              (itemsByInv[id] ?? []).map(InvoiceTotalsCalculator.lineFromDbRow),
          taxMode: TaxMode.global,
          globalTaxRate: taxRate,
          globalTaxRateFormat: TaxRateFormat.percent,
        );
        final tax = totals.tax;
        if (tax > 0) buckets[taxRate] = (buckets[taxRate] ?? 0) + tax;
      }
    }

    return (buckets.entries
        .map((e) => TaxBucket(rate: e.key, taxCollected: e.value))
        .toList()
      ..sort((a, b) => a.rate.compareTo(b.rate)));
  }

  // ── 6. Top customers ──────────────────────────────────────────────────────

  static Future<List<TopCustomer>> getTopCustomers(
    DateTime from,
    DateTime to, {
    int limit = 500,
    String? currencyCode,
  }) async {
    final rows =
        await _loadRows(from: from, to: to, currencyCode: currencyCode);

    final byCustomer = <String, List<_InvRow>>{};
    for (final r in rows) {
      (byCustomer[r.customerKey] ??= []).add(r);
    }

    final result = byCustomer.entries.map((e) {
      double billed = 0, collected = 0, outstanding = 0;
      for (final r in e.value) {
        billed += r.total;
        collected += r.paid;
        outstanding += r.outstanding;
      }
      return TopCustomer(
        name: e.value.first.customerName,
        invoiceCount: e.value.length,
        billed: billed,
        collected: collected,
        outstanding: outstanding,
      );
    }).toList()
      ..sort((a, b) => b.billed.compareTo(a.billed));

    return result.take(limit).toList();
  }

  static Future<List<CustomerStatementCustomer>> getStatementCustomers({
    String? currencyCode,
  }) async {
    final db = await _db.database;
    final sb = StringBuffer(
      "type = 'Invoice' AND deleted_at IS NULL "
      "AND COALESCE(NULLIF(customer_id, ''), customer_name) IS NOT NULL",
    );
    final args = <Object?>[];
    if (currencyCode != null) {
      sb.write(' AND (currency_code = ? OR currency_code IS NULL)');
      args.add(currencyCode);
    }

    final rows = await db.rawQuery(
      "SELECT COALESCE(NULLIF(customer_id, ''), customer_name) AS customer_key, "
      "COALESCE(NULLIF(customer_name, ''), 'Unknown') AS customer_name, "
      'COUNT(*) AS invoice_count '
      'FROM invoices '
      'WHERE ${sb.toString()} '
      'GROUP BY customer_key '
      'ORDER BY customer_name COLLATE NOCASE',
      args,
    );

    return rows
        .map((r) => CustomerStatementCustomer(
              key: CustomerIdentity.key(
                id: r['customer_key'] as String?,
                name: r['customer_name'] as String?,
              ),
              name: CustomerIdentity.displayName(r['customer_name'] as String?),
              invoiceCount: (r['invoice_count'] as num).toInt(),
            ))
        .toList();
  }

  static Future<List<CustomerStatement>> getCustomerStatements(
    String customerKey,
    DateTime from,
    DateTime to, {
    String? currencyCode,
  }) async {
    final rows = await _loadRows(
      customerKey: customerKey,
      currencyCode: currencyCode,
    );
    if (rows.isEmpty) return [];

    final db = await _db.database;
    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final byCurrency = <String, List<_InvRow>>{};
    for (final row in rows) {
      (byCurrency[row.currencyCode] ??= []).add(row);
    }

    final statements = <CustomerStatement>[];
    for (final entry in byCurrency.entries) {
      final currencyRows = entry.value;
      final ids = currencyRows.map((r) => r.id).toList();
      final ph = List.filled(ids.length, '?').join(',');
      final paymentRows = await db.rawQuery(
        'SELECT invoice_id, receipt_number, amount_paid, date_paid, '
        'payment_method, notes '
        'FROM invoice_payments WHERE invoice_id IN ($ph) '
        'ORDER BY date_paid ASC, rowid ASC',
        ids,
      );
      final invoicesById = {for (final r in currencyRows) r.id: r};
      final drafts = <_StatementLineDraft>[];
      double opening = 0;
      double invoiced = 0;
      double paid = 0;
      double overdue = 0;

      for (final invoice in currencyRows) {
        if (invoice.date.compareTo(f) < 0) {
          opening += invoice.total;
        } else if (invoice.date.compareTo(t) <= 0) {
          invoiced += invoice.total;
          drafts.add(_StatementLineDraft(
            date: invoice.date,
            order: 0,
            type: 'Invoice',
            reference: invoice.id,
            description: 'Invoice raised',
            debit: invoice.total,
            credit: 0,
          ));
        }

        final dueDate = invoice.dueDate;
        if (InvoiceCalculator.isOverdue(
          dueDate: dueDate == null ? null : DateTime.tryParse(dueDate),
          outstanding: invoice.outstanding,
        )) {
          overdue += invoice.outstanding;
        }
      }

      for (final payment in paymentRows) {
        final invoice = invoicesById[payment['invoice_id'] as String];
        if (invoice == null) continue;
        final date = payment['date_paid'] as String? ?? '';
        final amount = (payment['amount_paid'] as num?)?.toDouble() ?? 0;
        if (date.compareTo(f) < 0) {
          opening -= amount;
        } else if (date.compareTo(t) <= 0) {
          paid += amount;
          final method = payment['payment_method'] as String?;
          drafts.add(_StatementLineDraft(
            date: date,
            order: 1,
            type: 'Payment',
            reference: payment['receipt_number'] as String? ?? invoice.id,
            description: method == null || method.isEmpty
                ? 'Payment for ${invoice.id}'
                : 'Payment for ${invoice.id} ($method)',
            debit: 0,
            credit: amount,
          ));
        }
      }

      drafts.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.order.compareTo(b.order);
      });

      var running = opening;
      final lines = drafts.map((draft) {
        running += draft.debit - draft.credit;
        return CustomerStatementLine(
          date: draft.date,
          type: draft.type,
          reference: draft.reference,
          description: draft.description,
          debit: draft.debit,
          credit: draft.credit,
          balance: running,
        );
      }).toList();

      statements.add(CustomerStatement(
        customerKey: customerKey,
        customerName: currencyRows.first.customerName,
        currencyCode: entry.key,
        currencySymbol: currencyRows.first.currencySymbol,
        openingBalance: opening,
        invoiced: invoiced,
        paid: paid,
        closingBalance: running,
        overdueBalance: overdue,
        lines: lines,
      ));
    }

    statements.sort((a, b) => a.currencyCode.compareTo(b.currencyCode));
    return statements;
  }

  // ── 7. Top products ───────────────────────────────────────────────────────

  static Future<List<TopProduct>> getTopProducts(
    DateTime from,
    DateTime to, {
    int limit = 500,
    String? currencyCode,
    bool rankByProfit = false,
  }) async {
    final db = await _db.database;
    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final ccFilter = currencyCode != null
        ? 'AND (i.currency_code = ? OR i.currency_code IS NULL) '
        : '';
    final args = <Object?>[
      if (currencyCode != null) currencyCode,
      f,
      t,
      limit,
    ];
    final orderBy = rankByProfit
        ? '(SUM($_invoiceItemNetSql) - SUM(ii.quantity * ii.product_purchase_price))'
        : 'revenue';
    final rows = await db.rawQuery(
      "SELECT ii.product_name, "
      "SUM(ii.quantity) AS units_sold, "
      "SUM($_invoiceItemNetSql) AS revenue, "
      "SUM($_invoiceItemDiscountSql) AS discount_given, "
      "SUM(ii.quantity * ii.product_purchase_price) AS cogs "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "$ccFilter"
      "AND i.date >= ? AND i.date <= ? "
      "GROUP BY ii.product_name ORDER BY $orderBy DESC LIMIT ?",
      args,
    );
    return rows
        .map((r) => TopProduct(
              name: r['product_name'] as String? ?? 'Unknown',
              unitsSold: (r['units_sold'] as num).toDouble(),
              revenue: (r['revenue'] as num).toDouble(),
              discountGiven: (r['discount_given'] as num).toDouble(),
              cogs: (r['cogs'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  // ── 8. Quotation conversion ───────────────────────────────────────────────

  static Future<QuotationStats> getQuotationStats(
    DateTime from,
    DateTime to, {
    String? currencyCode,
  }) async {
    final db = await _db.database;
    final f = AppDate.dateKeyStart(from);
    final t = AppDate.dateKeyEnd(to);
    final currencyFilter = currencyCode != null
        ? 'AND (currency_code = ? OR currency_code IS NULL) '
        : '';
    final args = <Object?>[
      if (currencyCode != null) currencyCode,
      f,
      t,
    ];

    final qr = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM invoices "
      "WHERE type = 'Quotation' AND deleted_at IS NULL "
      "$currencyFilter"
      "AND date >= ? AND date <= ?",
      args,
    );
    final quotationsIssued = (qr.first['cnt'] as int?) ?? 0;

    final ir = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM invoices "
      "WHERE type = 'Invoice' AND deleted_at IS NULL "
      "$currencyFilter"
      "AND date >= ? AND date <= ?",
      args,
    );
    final invoicesInPeriod = (ir.first['cnt'] as int?) ?? 0;

    final rate = quotationsIssued == 0
        ? 0.0
        : (invoicesInPeriod / quotationsIssued * 100).clamp(0.0, 100.0);

    return QuotationStats(
      quotationsIssued: quotationsIssued,
      invoicesInPeriod: invoicesInPeriod,
      conversionRate: rate,
    );
  }

  // ── CSV export helpers ─────────────────────────────────────────────────────

  static String exportTrendCsv(List<MonthlyPoint> trend) {
    return buildQuotedCsv([
      ['Month', 'Billed', 'Collected', 'Profit'],
      for (final p in trend)
        [
          p.month,
          p.billed.toStringAsFixed(2),
          p.collected.toStringAsFixed(2),
          p.profit.toStringAsFixed(2),
        ],
    ]);
  }

  static String exportTopCustomersCsv(List<TopCustomer> list) {
    return buildQuotedCsv([
      ['Customer', 'Invoices', 'Billed', 'Collected', 'Outstanding'],
      for (final c in list)
        [
          c.name,
          c.invoiceCount,
          c.billed.toStringAsFixed(2),
          c.collected.toStringAsFixed(2),
          c.outstanding.toStringAsFixed(2),
        ],
    ]);
  }

  static String exportCustomerStatementsCsv(
      List<CustomerStatement> statements) {
    final blocks = <String>[];
    for (final statement in statements) {
      blocks.add(buildQuotedCsv([
        [
          'Customer',
          statement.customerName,
          'Currency',
          statement.currencyCode
        ],
        ['Opening Balance', statement.openingBalance.toStringAsFixed(2)],
        ['Invoiced', statement.invoiced.toStringAsFixed(2)],
        ['Paid', statement.paid.toStringAsFixed(2)],
        ['Closing Balance', statement.closingBalance.toStringAsFixed(2)],
        ['Overdue Balance', statement.overdueBalance.toStringAsFixed(2)],
        [
          'Date',
          'Type',
          'Reference',
          'Description',
          'Debit',
          'Credit',
          'Balance'
        ],
        for (final line in statement.lines)
          [
            line.date,
            line.type,
            line.reference,
            line.description,
            line.debit.toStringAsFixed(2),
            line.credit.toStringAsFixed(2),
            line.balance.toStringAsFixed(2),
          ],
      ]));
    }
    return blocks.join('\n\n');
  }

  static String exportTopProductsCsv(List<TopProduct> list) {
    return buildQuotedCsv([
      ['SL', 'Product', 'Units Sold', 'Revenue', 'Discount Given', 'Profit', 'Margin %'],
      for (var i = 0; i < list.length; i++)
        [
          i + 1,
          list[i].name,
          list[i].unitsSold.toStringAsFixed(2),
          list[i].revenue.toStringAsFixed(2),
          list[i].discountGiven.toStringAsFixed(2),
          list[i].profit.toStringAsFixed(2),
          list[i].marginPercent.toStringAsFixed(1),
        ],
    ]);
  }

  static String exportAgedReceivablesCsv(List<AgedReceivable> list) {
    return buildQuotedCsv([
      ['Invoice ID', 'Customer', 'Outstanding', 'Days Overdue'],
      for (final r in list)
        [
          r.invoiceId,
          r.customerName,
          r.outstanding.toStringAsFixed(2),
          r.daysOverdue,
        ],
    ]);
  }

  static String exportTaxCsv(List<TaxBucket> list) {
    return buildQuotedCsv([
      ['Tax Rate (%)', 'Tax Collected'],
      for (final b in list)
        [b.rate.toStringAsFixed(0), b.taxCollected.toStringAsFixed(2)],
    ]);
  }

  // ── 9. Invoice status list ─────────────────────────────────────────────────

  static Future<List<InvoiceStatusRow>> getInvoiceStatusList(
    DateTime from,
    DateTime to, {
    String? currencyCode,
  }) async {
    final rows = await _loadRows(
      from: from,
      to: to,
      currencyCode: currencyCode,
    );
    final now = DateTime.now();
    final result = rows.map((r) {
      final dueDate = r.dueDate != null ? DateTime.tryParse(r.dueDate!) : null;
      final noDueDate = r.dueDate == null;
      final daysOverdue =
          InvoiceCalculator.daysOverdue(dueDate: dueDate, asOf: now);

      final status = switch (
          InvoiceCalculator.paymentStatus(total: r.total, paid: r.paid)) {
        PaymentStatus.paid => 'Paid',
        PaymentStatus.partial => 'Partial',
        PaymentStatus.unpaid => 'Unpaid',
      };

      final isOverdue = InvoiceCalculator.isOverdue(
        dueDate: dueDate,
        outstanding: r.outstanding,
        asOf: now,
      );

      return InvoiceStatusRow(
        id: r.id,
        date: r.date,
        dueDate: r.dueDate,
        customerName: r.customerName,
        total: r.total,
        paid: r.paid,
        outstanding: r.outstanding,
        daysOverdue: daysOverdue,
        hasNoDueDate: noDueDate,
        status: status,
        isOverdue: isOverdue,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  static String exportInvoiceStatusCsv(List<InvoiceStatusRow> list) {
    return buildQuotedCsv([
      [
        'Date',
        'Invoice ID',
        'Customer',
        'Total',
        'Paid',
        'Outstanding',
        'Status',
        'Days Overdue',
      ],
      for (final r in list)
        [
          r.date,
          r.id,
          r.customerName,
          r.total.toStringAsFixed(2),
          r.paid.toStringAsFixed(2),
          r.outstanding.toStringAsFixed(2),
          r.status,
          r.hasNoDueDate ? '' : r.daysOverdue,
        ],
    ]);
  }
}
