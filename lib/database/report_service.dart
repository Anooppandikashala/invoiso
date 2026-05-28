import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/models/additional_cost.dart';

// ─── Result types ──────────────────────────────────────────────────────────────

class RevenueKpi {
  final int invoiceCount;
  final double billed;
  final double collected;
  final double outstanding;
  final double avgInvoiceValue;

  const RevenueKpi({
    required this.invoiceCount,
    required this.billed,
    required this.collected,
    required this.outstanding,
    required this.avgInvoiceValue,
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
  final String month; // 'YYYY-MM'
  final double billed;
  final double collected;

  const MonthlyPoint({
    required this.month,
    required this.billed,
    required this.collected,
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

  const AgedReceivable({
    required this.invoiceId,
    required this.customerName,
    required this.outstanding,
    required this.daysOverdue,
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

class TopProduct {
  final String name;
  final double unitsSold;
  final double revenue;
  final double discountGiven;

  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
    required this.discountGiven,
  });
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

// ─── Internal row ─────────────────────────────────────────────────────────────

class _InvRow {
  final String id;
  final String customerName;
  final String date;
  final String? dueDate;
  final double total;
  final double paid;
  final double outstanding;

  const _InvRow({
    required this.id,
    required this.customerName,
    required this.date,
    this.dueDate,
    required this.total,
    required this.paid,
    required this.outstanding,
  });
}

// ─── Service ───────────────────────────────────────────────────────────────────

class ReportService {
  static final _db = DatabaseHelper();

  // ── Batch loader: invoice totals computed in Dart (accurate, no N+1) ────────

  static Future<List<_InvRow>> _loadRows({
    String type = 'Invoice',
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;

    final sb = StringBuffer('type = ? AND deleted_at IS NULL');
    final args = <dynamic>[type];
    if (from != null) {
      sb.write(' AND date >= ?');
      args.add(from.toIso8601String().split('T').first);
    }
    if (to != null) {
      sb.write(' AND date <= ?');
      args.add(to.toIso8601String().split('T').first);
    }

    final invRows = await db.query(
      'invoices',
      columns: [
        'id',
        'customer_name',
        'date',
        'due_date',
        'tax_rate',
        'tax_mode',
        'additional_costs'
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

      double subtotal = 0.0, itemTax = 0.0;
      for (final it in items) {
        final price = (it['unit_price'] as num?)?.toDouble() ??
            (it['product_price'] as num?)?.toDouble() ??
            0.0;
        final qty = (it['quantity'] as num?)?.toDouble() ?? 0.0;
        final disc = (it['discount'] as num?)?.toDouble() ?? 0.0;
        final dpu = (it['discount_per_unit'] as int?) == 1;
        final extra = (it['extra_cost'] as num?)?.toDouble() ?? 0.0;
        final itRate =
            (it['product_tax_rate'] as num?)?.toDouble() ?? 0.0;

        final lt = dpu
            ? (price - disc) * qty + extra
            : price * qty - disc + extra;
        subtotal += lt;
        if (taxMode == TaxMode.perItem) itemTax += lt * (itRate / 100);
      }

      final tax = switch (taxMode) {
        TaxMode.global => subtotal * (taxRate / 100),
        TaxMode.perItem => itemTax,
        TaxMode.none => 0.0,
      };

      final addCosts =
          AdditionalCost.listFromJson(inv['additional_costs'] as String?)
              .fold(0.0, (s, c) => s + c.amount);

      final total = subtotal + tax + addCosts;
      final outstanding =
          (total - paid).clamp(0.0, double.infinity);

      return _InvRow(
        id: id,
        customerName: inv['customer_name'] as String? ?? '',
        date: inv['date'] as String? ?? '',
        dueDate: inv['due_date'] as String?,
        total: total,
        paid: paid,
        outstanding: outstanding,
      );
    }).toList();
  }

  // ── 1. Revenue KPIs ────────────────────────────────────────────────────────

  static Future<RevenueKpi> getRevenueSummary(
      DateTime from, DateTime to) async {
    final rows = await _loadRows(from: from, to: to);
    if (rows.isEmpty) return RevenueKpi.empty;

    double billed = 0, collected = 0, outstanding = 0;
    for (final r in rows) {
      billed += r.total;
      collected += r.paid;
      outstanding += r.outstanding;
    }
    return RevenueKpi(
      invoiceCount: rows.length,
      billed: billed,
      collected: collected,
      outstanding: outstanding,
      avgInvoiceValue: billed / rows.length,
    );
  }

  // ── 2. Monthly revenue trend ───────────────────────────────────────────────

  static Future<List<MonthlyPoint>> getMonthlyRevenueTrend(
      DateTime from, DateTime to) async {
    final rows = await _loadRows(from: from, to: to);
    final db = await _db.database;

    // Collected grouped by payment date (more accurate for cash-flow view)
    final collectedRows = await db.rawQuery(
      "SELECT strftime('%Y-%m', ip.date_paid) AS month, "
      "COALESCE(SUM(ip.amount_paid), 0.0) AS collected "
      "FROM invoice_payments ip "
      "JOIN invoices i ON ip.invoice_id = i.id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "AND ip.date_paid >= ? AND ip.date_paid <= ? "
      "GROUP BY month ORDER BY month",
      [
        from.toIso8601String().split('T').first,
        to.toIso8601String().split('T').first
      ],
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

    final allMonths = {
      ...billedByMonth.keys,
      ...collectedByMonth.keys
    }.toList()
      ..sort();

    return allMonths
        .map((m) => MonthlyPoint(
              month: m,
              billed: billedByMonth[m] ?? 0,
              collected: collectedByMonth[m] ?? 0,
            ))
        .toList();
  }

  // ── 3. Payment status breakdown ────────────────────────────────────────────

  static Future<StatusBreakdown> getPaymentStatusBreakdown(
      DateTime from, DateTime to) async {
    final rows = await _loadRows(from: from, to: to);
    int paid = 0, partial = 0, unpaid = 0;
    for (final r in rows) {
      if (r.paid <= 0) {
        unpaid++;
      } else if (r.outstanding <= 0.005) {
        paid++;
      } else {
        partial++;
      }
    }
    return StatusBreakdown(paid: paid, partial: partial, unpaid: unpaid);
  }

  // ── 4. Aged receivables (all time, all overdue) ────────────────────────────

  static Future<List<AgedReceivable>> getAgedReceivables() async {
    final rows = await _loadRows();
    final now = DateTime.now();
    final result = <AgedReceivable>[];

    for (final r in rows) {
      if (r.outstanding <= 0.005) continue;
      final dueDate =
          r.dueDate != null ? DateTime.tryParse(r.dueDate!) : null;
      final daysOverdue =
          dueDate != null ? now.difference(dueDate).inDays : 0;
      result.add(AgedReceivable(
        invoiceId: r.id,
        customerName: r.customerName,
        outstanding: r.outstanding,
        daysOverdue: daysOverdue > 0 ? daysOverdue : 0,
      ));
    }
    result.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
    return result;
  }

  // ── 5. Tax collected by rate ───────────────────────────────────────────────

  static Future<List<TaxBucket>> getTaxByRate(
      DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT ii.product_tax_rate AS rate, "
      "SUM(CASE WHEN ii.discount_per_unit = 1 "
      "  THEN (COALESCE(ii.unit_price, ii.product_price) - ii.discount) * ii.quantity "
      "       + COALESCE(ii.extra_cost, 0) "
      "  ELSE  COALESCE(ii.unit_price, ii.product_price) * ii.quantity "
      "       - ii.discount + COALESCE(ii.extra_cost, 0) "
      "END * ii.product_tax_rate / 100) AS tax_amount "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "AND i.date >= ? AND i.date <= ? "
      "AND ii.product_tax_rate > 0 "
      "GROUP BY ii.product_tax_rate ORDER BY rate",
      [
        from.toIso8601String().split('T').first,
        to.toIso8601String().split('T').first
      ],
    );
    return rows
        .map((r) => TaxBucket(
              rate: (r['rate'] as num).toDouble(),
              taxCollected: (r['tax_amount'] as num).toDouble(),
            ))
        .toList();
  }

  // ── 6. Top customers ──────────────────────────────────────────────────────

  static Future<List<TopCustomer>> getTopCustomers(
    DateTime from,
    DateTime to, {
    int limit = 10,
  }) async {
    final rows = await _loadRows(from: from, to: to);

    final byCustomer = <String, List<_InvRow>>{};
    for (final r in rows) {
      (byCustomer[r.customerName] ??= []).add(r);
    }

    final result = byCustomer.entries.map((e) {
      double billed = 0, collected = 0, outstanding = 0;
      for (final r in e.value) {
        billed += r.total;
        collected += r.paid;
        outstanding += r.outstanding;
      }
      return TopCustomer(
        name: e.key,
        invoiceCount: e.value.length,
        billed: billed,
        collected: collected,
        outstanding: outstanding,
      );
    }).toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));

    return result.take(limit).toList();
  }

  // ── 7. Top products ───────────────────────────────────────────────────────

  static Future<List<TopProduct>> getTopProducts(
    DateTime from,
    DateTime to, {
    int limit = 10,
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT ii.product_name, "
      "SUM(ii.quantity) AS units_sold, "
      "SUM(CASE WHEN ii.discount_per_unit = 1 "
      "  THEN (COALESCE(ii.unit_price, ii.product_price) - ii.discount) * ii.quantity "
      "       + COALESCE(ii.extra_cost, 0) "
      "  ELSE  COALESCE(ii.unit_price, ii.product_price) * ii.quantity "
      "       - ii.discount + COALESCE(ii.extra_cost, 0) "
      "END) AS revenue, "
      "SUM(CASE WHEN ii.discount_per_unit = 1 "
      "  THEN ii.discount * ii.quantity ELSE ii.discount END) AS discount_given "
      "FROM invoice_items ii "
      "JOIN invoices i ON i.id = ii.invoice_id "
      "WHERE i.deleted_at IS NULL AND i.type = 'Invoice' "
      "AND i.date >= ? AND i.date <= ? "
      "GROUP BY ii.product_name ORDER BY revenue DESC LIMIT ?",
      [
        from.toIso8601String().split('T').first,
        to.toIso8601String().split('T').first,
        limit,
      ],
    );
    return rows
        .map((r) => TopProduct(
              name: r['product_name'] as String? ?? 'Unknown',
              unitsSold: (r['units_sold'] as num).toDouble(),
              revenue: (r['revenue'] as num).toDouble(),
              discountGiven: (r['discount_given'] as num).toDouble(),
            ))
        .toList();
  }

  // ── 8. Quotation conversion ───────────────────────────────────────────────

  static Future<QuotationStats> getQuotationStats(
      DateTime from, DateTime to) async {
    final db = await _db.database;
    final f = from.toIso8601String().split('T').first;
    final t = to.toIso8601String().split('T').first;

    final qr = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM invoices "
      "WHERE type = 'Quotation' AND deleted_at IS NULL "
      "AND date >= ? AND date <= ?",
      [f, t],
    );
    final quotationsIssued = (qr.first['cnt'] as int?) ?? 0;

    final ir = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM invoices "
      "WHERE type = 'Invoice' AND deleted_at IS NULL "
      "AND date >= ? AND date <= ?",
      [f, t],
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
    final sb = StringBuffer('Month,Billed,Collected\n');
    for (final p in trend) {
      sb.writeln(
          '${p.month},${p.billed.toStringAsFixed(2)},${p.collected.toStringAsFixed(2)}');
    }
    return sb.toString();
  }

  static String exportTopCustomersCsv(List<TopCustomer> list) {
    final sb =
        StringBuffer('Customer,Invoices,Billed,Collected,Outstanding\n');
    for (final c in list) {
      sb.writeln(
          '"${c.name}",${c.invoiceCount},${c.billed.toStringAsFixed(2)},${c.collected.toStringAsFixed(2)},${c.outstanding.toStringAsFixed(2)}');
    }
    return sb.toString();
  }

  static String exportTopProductsCsv(List<TopProduct> list) {
    final sb =
        StringBuffer('Product,Units Sold,Revenue,Discount Given\n');
    for (final p in list) {
      sb.writeln(
          '"${p.name}",${p.unitsSold.toStringAsFixed(2)},${p.revenue.toStringAsFixed(2)},${p.discountGiven.toStringAsFixed(2)}');
    }
    return sb.toString();
  }

  static String exportAgedReceivablesCsv(List<AgedReceivable> list) {
    final sb =
        StringBuffer('Invoice ID,Customer,Outstanding,Days Overdue\n');
    for (final r in list) {
      sb.writeln(
          '"${r.invoiceId}","${r.customerName}",${r.outstanding.toStringAsFixed(2)},${r.daysOverdue}');
    }
    return sb.toString();
  }

  static String exportTaxCsv(List<TaxBucket> list) {
    final sb = StringBuffer('Tax Rate (%),Tax Collected\n');
    for (final b in list) {
      sb.writeln(
          '${b.rate.toStringAsFixed(0)},${b.taxCollected.toStringAsFixed(2)}');
    }
    return sb.toString();
  }
}
