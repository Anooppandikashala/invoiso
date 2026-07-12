import 'package:invoiso/common.dart';
import 'package:invoiso/database/invoice_item_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/product.dart';
import '../models/customer.dart';
import '../models/invoice_item.dart';
import '../models/invoice_payment.dart';
import '../utils/app_date.dart';
import '../utils/app_logger.dart';
import 'database_helper.dart';
import 'payment_service.dart';

const _tag = 'InvoiceService';

class InvoiceService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // Insert Invoice + Items + Stock Deduction (transactional)
  static Future<void> insertInvoice(Invoice invoice) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('invoices', {
        'id': invoice.id,
        'invoice_number': invoice.invoiceNumber,
        'customer_id': invoice.customer.id,
        'customer_name': invoice.customer.name,
        'customer_email': invoice.customer.email,
        'customer_phone': invoice.customer.phone,
        'customer_address': invoice.customer.address,
        'customer_gstin': invoice.customer.gstin,
        'customer_business_name': invoice.customer.businessName,
        'date': invoice.date.toIso8601String(),
        'notes': invoice.notes,
        'tax_rate': invoice.taxRate,
        'type': invoice.type,
        'currency_code': invoice.currencyCode,
        'currency_symbol': invoice.currencySymbol,
        'tax_mode': invoice.taxMode.key,
        'upi_id': invoice.upiId,
        'bank_account_id': invoice.bankAccountId,
        'due_date': invoice.dueDate?.toIso8601String(),
        'quantity_label': invoice.quantityLabel,
        'additional_costs': AdditionalCost.listToJson(invoice.additionalCosts),
      });

      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoice.id,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'product_description': item.product.description,
          'product_price': item.product.price,
          'product_tax_rate': item.product.tax_rate,
          'product_hsn_code': item.product.hsncode,
          'quantity': item.quantity,
          'discount': item.discount,
          'discount_per_unit': item.discountPerUnit ? 1 : 0,
          'unit_price': item.unitPrice,
          'extra_cost': item.extraCost,
          'is_product_saved': item.isProductSaved ? 1 : 0,
          'product_type': item.product.type,
          'product_purchase_price': item.product.purchasePrice,
        });
      }
    });

    // Stock deduction happens outside the transaction to avoid nested DB calls
    for (var item in invoice.items) {
      final product = await ProductService.getProductById(item.product.id);
      if (product != null) {
        final newStock = product.stock - item.quantity.round();
        await ProductService.updateProductStock(product.id, newStock);
      }
    }
  }

  static Future<void> updateInvoice(Invoice invoice) async {
    final db = await dbHelper.database;

    // Fetch existing items before transaction (to restore stock)
    final oldItems = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
    );

    await db.transaction((txn) async {
      // 1. Update the main invoice row
      await txn.update(
        'invoices',
        {
          'customer_id': invoice.customer.id,
          'customer_name': invoice.customer.name,
          'customer_email': invoice.customer.email,
          'customer_phone': invoice.customer.phone,
          'customer_address': invoice.customer.address,
          'customer_gstin': invoice.customer.gstin,
          'customer_business_name': invoice.customer.businessName,
          'notes': invoice.notes,
          'tax_rate': invoice.taxRate,
          'type': invoice.type,
          'tax_mode': invoice.taxMode.key,
          'upi_id': invoice.upiId,
          'due_date': invoice.dueDate?.toIso8601String(),
          'quantity_label': invoice.quantityLabel,
          'additional_costs':
              AdditionalCost.listToJson(invoice.additionalCosts),
        },
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // 2. Delete old invoice items
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      // 3. Insert new invoice items
      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoice.id,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'product_description': item.product.description,
          'product_price': item.product.price,
          'product_tax_rate': item.product.tax_rate,
          'product_hsn_code': item.product.hsncode,
          'quantity': item.quantity,
          'discount': item.discount,
          'discount_per_unit': item.discountPerUnit ? 1 : 0,
          'unit_price': item.unitPrice,
          'extra_cost': item.extraCost,
          'is_product_saved': item.isProductSaved ? 1 : 0,
          'product_type': item.product.type,
          'product_purchase_price': item.product.purchasePrice,
        });
      }
    });

    // Restore stock for old items (outside transaction)
    for (var oldItem in oldItems) {
      final product =
          await ProductService.getProductById(oldItem['product_id'] as String);
      if (product != null) {
        final rawQty = oldItem['quantity'];
        final oldQty = rawQty is int ? rawQty : (rawQty as double).round();
        final restoredStock = product.stock + oldQty;
        await ProductService.updateProductStock(product.id, restoredStock);
      }
    }

    // Deduct stock for new items
    for (var item in invoice.items) {
      final product = await ProductService.getProductById(item.product.id);
      if (product != null) {
        final newStock = product.stock - item.quantity.round();
        await ProductService.updateProductStock(product.id, newStock);
      }
    }
  }

  static Future<double> getPreviousBalanceDueForInvoice(Invoice invoice) async {
    if (invoice.type != 'Invoice' || invoice.customer.id.trim().isEmpty) {
      return 0.0;
    }

    return getPreviousBalanceDueForCustomer(
      customerId: invoice.customer.id,
      currencyCode: invoice.currencyCode,
      asOfDate: invoice.date,
      currentInvoiceId: invoice.id,
    );
  }

  static Future<double> getPreviousBalanceDueForCustomer({
    required String customerId,
    required String currencyCode,
    required DateTime asOfDate,
    String? currentInvoiceId,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) return 0.0;

    final db = await dbHelper.database;
    final invoiceDateKey = AppDate.dateKey(asOfDate);
    final sameDayId = currentInvoiceId?.trim();
    final dateFilter = sameDayId == null || sameDayId.isEmpty
        ? 'substr(date, 1, 10) < ?'
        : '(substr(date, 1, 10) < ? '
            'OR (substr(date, 1, 10) = ? AND id < ?))';
    final dateArgs = sameDayId == null || sameDayId.isEmpty
        ? <Object>[invoiceDateKey]
        : <Object>[invoiceDateKey, invoiceDateKey, sameDayId];

    final invoiceRows = await db.query(
      'invoices',
      columns: ['id', 'tax_rate', 'tax_mode', 'additional_costs'],
      where: 'customer_id = ? '
          'AND type = ? '
          'AND deleted_at IS NULL '
          'AND currency_code = ? '
          'AND $dateFilter',
      whereArgs: [
        normalizedCustomerId,
        'Invoice',
        currencyCode,
        ...dateArgs,
      ],
    );

    if (invoiceRows.isEmpty) return 0.0;

    final ids = invoiceRows.map((row) => row['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final itemRows = await db.rawQuery(
      'SELECT invoice_id, unit_price, product_price, quantity, discount, '
      'discount_per_unit, extra_cost, product_tax_rate '
      'FROM invoice_items WHERE invoice_id IN ($placeholders) ORDER BY rowid ASC',
      ids,
    );
    final paymentRows = await db.rawQuery(
      'SELECT invoice_id, COALESCE(SUM(amount_paid), 0.0) as paid '
      'FROM invoice_payments WHERE invoice_id IN ($placeholders) '
      'GROUP BY invoice_id',
      ids,
    );

    final itemsByInvoice = <String, List<Map<String, dynamic>>>{};
    for (final row in itemRows) {
      final invoiceId = row['invoice_id'] as String;
      itemsByInvoice.putIfAbsent(invoiceId, () => []).add(row);
    }

    final paidByInvoice = <String, double>{};
    for (final row in paymentRows) {
      paidByInvoice[row['invoice_id'] as String] =
          (row['paid'] as num).toDouble();
    }

    double previousBalanceDue = 0.0;
    for (final row in invoiceRows) {
      final invoiceId = row['id'] as String;
      final additionalCostsTotal =
          AdditionalCost.listFromJson(row['additional_costs'] as String?)
              .fold(0.0, (sum, cost) => sum + cost.amount);
      final totals = InvoiceTotalsCalculator.totals(
        lines: (itemsByInvoice[invoiceId] ?? [])
            .map(InvoiceTotalsCalculator.lineFromDbRow),
        taxMode: TaxModeExtension.fromKey(row['tax_mode'] as String?),
        globalTaxRate: (row['tax_rate'] as num?)?.toDouble() ?? 0.0,
        globalTaxRateFormat: TaxRateFormat.fraction,
        additionalCostsTotal: additionalCostsTotal,
      );
      previousBalanceDue += InvoiceCalculator.outstanding(
        total: totals.total,
        paid: paidByInvoice[invoiceId] ?? 0.0,
      );
    }

    return previousBalanceDue;
  }

  // ─────────────────────────────────────────────
  // Fetch Invoice with Items
  static Future<Invoice?> getInvoiceById(String id) async {
    final db = await dbHelper.database;

    final invoiceData = await db.query(
      'invoices',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (invoiceData.isEmpty) return null;
    final i = invoiceData.first;

    final customer = Customer.fromMap({
      'id': i['customer_id'],
      'name': i['customer_name'],
      'email': i['customer_email'],
      'phone': i['customer_phone'],
      'address': i['customer_address'],
      'gstin': i['customer_gstin'],
      'business_name': i['customer_business_name'] ?? '',
    });

    final itemRows = await db.query('invoice_items',
        where: 'invoice_id = ?', whereArgs: [id], orderBy: 'rowid ASC');
    final items = <InvoiceItem>[];

    for (var row in itemRows) {
      try {
        final product = Product.fromInvoiceItemsMap(row);
        final rawUnitPrice = row['unit_price'];
        final unitPrice = rawUnitPrice == null
            ? null
            : (rawUnitPrice is int
                ? rawUnitPrice.toDouble()
                : rawUnitPrice as double);
        final rawExtraCost = row['extra_cost'];
        final extraCost = rawExtraCost == null
            ? null
            : (rawExtraCost is int
                ? rawExtraCost.toDouble()
                : rawExtraCost as double);
        items.add(InvoiceItem(
          product: product,
          quantity: (row['quantity'] is int)
              ? (row['quantity'] as int).toDouble()
              : (row['quantity'] ?? 1.0) as double,
          discount: (row['discount'] is int)
              ? (row['discount'] as int).toDouble()
              : (row['discount'] ?? 0.0) as double,
          discountPerUnit: (row['discount_per_unit'] as int? ?? 0) == 1,
          unitPrice: unitPrice,
          extraCost: extraCost,
        ));
      } catch (e, stackTrace) {
        AppLogger.e(_tag, 'Error parsing invoice item row', e, stackTrace);
        continue;
      }
    }

    final payments = await PaymentService.getPaymentsForInvoice(id);

    return Invoice(
      id: id,
      invoiceNumber: i['invoice_number'] as String?,
      customer: customer,
      items: items,
      date: DateTime.parse(i['date'] as String),
      notes: i['notes'] as String?,
      taxRate: (i['tax_rate'] is int)
          ? (i['tax_rate'] as int).toDouble()
          : (i['tax_rate'] ?? 0.0) as double,
      type: i['type'] as String,
      currencyCode: i['currency_code'] as String? ?? 'INR',
      currencySymbol: i['currency_symbol'] as String? ?? '₹',
      taxMode: TaxModeExtension.fromKey(i['tax_mode'] as String?),
      upiId: i['upi_id'] as String?,
      bankAccountId: i['bank_account_id'] as String?,
      dueDate: i['due_date'] != null
          ? DateTime.tryParse(i['due_date'] as String)
          : null,
      quantityLabel: i['quantity_label'] as String?,
      additionalCosts:
          AdditionalCost.listFromJson(i['additional_costs'] as String?),
      previousBalance: (i['previous_balance'] as num?)?.toDouble() ?? 0.0,
      payments: payments,
    );
  }

  // Get all non-deleted invoices with customer and items
  static Future<List<Invoice>> getAllInvoices() async {
    final db = await dbHelper.database;
    final invoiceMaps = await db.query(
      'invoices',
      where: 'deleted_at IS NULL',
      orderBy: 'id DESC',
    );

    return _buildInvoiceList(invoiceMaps);
  }

  static Future<List<Invoice>> getInvoicesForExport({
    DateTime? fromDate,
    DateTime? toDate,
    int? fromId,
    int? toId,
    String? filterType,
  }) async {
    final db = await dbHelper.database;
    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (filterType != null && filterType.isNotEmpty) {
      whereParts.add('type = ?');
      whereArgs.add(filterType);
    }
    if (fromDate != null) {
      whereParts.add('date >= ?');
      whereArgs.add(AppDate.dateKeyStart(fromDate));
    }
    if (toDate != null) {
      whereParts.add('date <= ?');
      whereArgs.add(AppDate.dateKeyEnd(toDate));
    }
    if (fromId != null) {
      whereParts.add('CAST(id AS INTEGER) >= ?');
      whereArgs.add(fromId);
    }
    if (toId != null) {
      whereParts.add('CAST(id AS INTEGER) <= ?');
      whereArgs.add(toId);
    }

    final invoiceMaps = await db.query(
      'invoices',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date ASC',
    );

    return _buildInvoiceList(invoiceMaps);
  }

  // Lightweight COUNT — no object construction, used for filter preview + cap check.
  static Future<int> countInvoicesForExport({
    DateTime? fromDate,
    DateTime? toDate,
    int? fromId,
    int? toId,
    String? filterType,
  }) async {
    final db = await dbHelper.database;
    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (filterType != null && filterType.isNotEmpty) {
      whereParts.add('type = ?');
      whereArgs.add(filterType);
    }
    if (fromDate != null) {
      whereParts.add('date >= ?');
      whereArgs.add(AppDate.dateKeyStart(fromDate));
    }
    if (toDate != null) {
      whereParts.add('date <= ?');
      whereArgs.add(AppDate.dateKeyEnd(toDate));
    }
    if (fromId != null) {
      whereParts.add('CAST(id AS INTEGER) >= ?');
      whereArgs.add(fromId);
    }
    if (toId != null) {
      whereParts.add('CAST(id AS INTEGER) <= ?');
      whereArgs.add(toId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM invoices WHERE ${whereParts.join(' AND ')}',
      whereArgs.isEmpty ? null : whereArgs,
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────────
  // Paginated Invoice Fetching (DB-level)
  static Future<List<Invoice>> getInvoicesPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
    String? filterType,
  }) async {
    final db = await dbHelper.database;

    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (searchQuery.isNotEmpty) {
      whereParts.add('(customer_name LIKE ? OR id LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }
    if (filterType != null && filterType.isNotEmpty) {
      whereParts.add('type = ?');
      whereArgs.add(filterType);
    }

    final where = whereParts.join(' AND ');
    final invoiceMaps = await db.query(
      'invoices',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
      limit: pageSize,
      offset: page * pageSize,
    );

    return _buildInvoiceList(invoiceMaps);
  }

  static Future<int> getInvoiceCount({
    String searchQuery = '',
    String? filterType,
  }) async {
    final db = await dbHelper.database;

    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (searchQuery.isNotEmpty) {
      whereParts.add('(customer_name LIKE ? OR id LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }
    if (filterType != null && filterType.isNotEmpty) {
      whereParts.add('type = ?');
      whereArgs.add(filterType);
    }

    final where = whereParts.join(' AND ');
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM invoices WHERE $where',
      whereArgs.isEmpty ? null : whereArgs,
    );
    return (result.first.values.first as int?) ?? 0;
  }

  static Future<int> getTotalInvoiceCountIncludingTrashed() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM invoices');
    return (result.first.values.first as int?) ?? 0;
  }

  // ─────────────────────────────────────────────
  // Soft Delete
  static Future<void> softDeleteInvoice(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'invoices',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> restoreInvoice(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'invoices',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> permanentDeleteInvoice(String id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete('invoice_payments', where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<List<Invoice>> getDeletedInvoices() async {
    final db = await dbHelper.database;
    final invoiceMaps = await db.query(
      'invoices',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return _buildInvoiceList(invoiceMaps);
  }

  // ─────────────────────────────────────────────
  // Hard Delete (legacy — kept for backward compat; uses transaction)
  static Future<void> deleteInvoice(String id) async {
    await permanentDeleteInvoice(id);
  }

  // ─────────────────────────────────────────────
  // Private helper: build Invoice list from raw DB rows.
  // Payments are batch-loaded in a single query (no N+1).
  static Future<List<Invoice>> _buildInvoiceList(
    List<Map<String, dynamic>> invoiceMaps,
  ) async {
    if (invoiceMaps.isEmpty) return [];

    final invoices = <Invoice>[];

    for (var map in invoiceMaps) {
      final invoiceId = map['id'] as String?;
      final dateString = map['date'] as String?;
      final type = map['type'] as String? ?? '';
      final notes = map['notes'] as String? ?? '';
      final taxRateRaw = map['tax_rate'];

      if (invoiceId == null || dateString == null) continue;

      final customer = Customer.fromMap({
        'id': map['customer_id'],
        'name': map['customer_name'],
        'email': map['customer_email'],
        'phone': map['customer_phone'],
        'address': map['customer_address'],
        'gstin': map['customer_gstin'],
        'business_name': map['customer_business_name'] ?? '',
      });

      final items =
          await InvoiceItemService.getInvoiceItemsByInvoiceId(invoiceId);
      invoices.add(
        Invoice(
          id: invoiceId,
          invoiceNumber: map['invoice_number'] as String?,
          customer: customer,
          items: items,
          date: DateTime.tryParse(dateString) ?? DateTime.now(),
          notes: notes,
          taxRate: (taxRateRaw is int)
              ? taxRateRaw.toDouble()
              : (taxRateRaw as double? ?? 0.0),
          type: type,
          currencyCode: map['currency_code'] as String? ?? 'INR',
          currencySymbol: map['currency_symbol'] as String? ?? '₹',
          taxMode: TaxModeExtension.fromKey(map['tax_mode'] as String?),
          upiId: map['upi_id'] as String?,
          bankAccountId: map['bank_account_id'] as String?,
          dueDate: map['due_date'] != null
              ? DateTime.tryParse(map['due_date'] as String)
              : null,
          quantityLabel: map['quantity_label'] as String?,
          additionalCosts:
              AdditionalCost.listFromJson(map['additional_costs'] as String?),
          previousBalance: (map['previous_balance'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    }

    // Batch-load all payments for this page in one query, then assign
    final db = await dbHelper.database;
    final ids = invoices.map((inv) => inv.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final paymentRows = await db.rawQuery(
      'SELECT * FROM invoice_payments '
      'WHERE invoice_id IN ($placeholders) '
      'ORDER BY invoice_id, date_paid ASC, rowid ASC',
      ids,
    );

    // Group payments by invoice_id
    final paymentsByInvoice = <String, List<dynamic>>{};
    for (final row in paymentRows) {
      final invId = row['invoice_id'] as String;
      paymentsByInvoice.putIfAbsent(invId, () => []).add(row);
    }

    for (final invoice in invoices) {
      final rows = paymentsByInvoice[invoice.id] ?? [];
      invoice.payments = rows
          .map((r) => InvoicePayment.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    return invoices;
  }

  // ─────────────────────────────────────────────
  // Dashboard-specific targeted queries

  /// Returns invoice count, total revenue collected, and total outstanding
  /// using batch SQL — avoids loading full Invoice objects for summary data.
  static Future<({int count, double revenue, double outstanding})>
      getDashboardFinancials() async {
    final db = await dbHelper.database;

    // Count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM invoices WHERE type = ? AND deleted_at IS NULL',
      ['Invoice'],
    );
    final count = (countResult.first['cnt'] as int?) ?? 0;

    // Revenue: pure SQL — no item loading needed
    final revenueResult = await db.rawQuery(
      'SELECT COALESCE(SUM(ip.amount_paid), 0.0) as revenue '
      'FROM invoice_payments ip '
      'JOIN invoices i ON ip.invoice_id = i.id '
      'WHERE i.type = ? AND i.deleted_at IS NULL',
      ['Invoice'],
    );
    final revenue = (revenueResult.first['revenue'] as num?)?.toDouble() ?? 0.0;

    // Outstanding: batch-load invoice rows + items + payments (3 queries, no N+1)
    final invoiceRows = await db.query(
      'invoices',
      columns: ['id', 'tax_rate', 'tax_mode', 'additional_costs'],
      where: 'type = ? AND deleted_at IS NULL',
      whereArgs: ['Invoice'],
    );

    if (invoiceRows.isEmpty) {
      return (count: count, revenue: revenue, outstanding: 0.0);
    }

    final ids = invoiceRows.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');

    final itemRows = await db.rawQuery(
      'SELECT invoice_id, unit_price, product_price, quantity, discount, '
      'discount_per_unit, extra_cost, product_tax_rate '
      'FROM invoice_items WHERE invoice_id IN ($placeholders) ORDER BY rowid ASC',
      ids,
    );

    final paymentSums = await db.rawQuery(
      'SELECT invoice_id, COALESCE(SUM(amount_paid), 0.0) as paid '
      'FROM invoice_payments WHERE invoice_id IN ($placeholders) '
      'GROUP BY invoice_id',
      ids,
    );

    final itemsByInvoice = <String, List<Map<String, dynamic>>>{};
    for (final row in itemRows) {
      final invId = row['invoice_id'] as String;
      itemsByInvoice
          .putIfAbsent(invId, () => [])
          .add(row as Map<String, dynamic>);
    }

    final paidByInvoice = <String, double>{};
    for (final row in paymentSums) {
      paidByInvoice[row['invoice_id'] as String] =
          (row['paid'] as num).toDouble();
    }

    double outstanding = 0.0;
    for (final inv in invoiceRows) {
      final invId = inv['id'] as String;
      final taxRate = (inv['tax_rate'] as num?)?.toDouble() ?? 0.0;
      final taxMode = inv['tax_mode'] as String? ?? 'global';
      final items = itemsByInvoice[invId] ?? [];

      final additionalTotal =
          AdditionalCost.listFromJson(inv['additional_costs'] as String?)
              .fold(0.0, (sum, c) => sum + c.amount);
      final totals = InvoiceTotalsCalculator.totals(
        lines: items.map(InvoiceTotalsCalculator.lineFromDbRow),
        taxMode: TaxModeExtension.fromKey(taxMode),
        globalTaxRate: taxRate,
        globalTaxRateFormat: TaxRateFormat.percent,
        additionalCostsTotal: additionalTotal,
      );
      final total = totals.total;
      final paid = paidByInvoice[invId] ?? 0.0;
      outstanding += InvoiceCalculator.outstanding(total: total, paid: paid);
    }

    return (count: count, revenue: revenue, outstanding: outstanding);
  }

  /// Most recent [limit] invoices across all types.
  static Future<List<Invoice>> getRecentInvoices({int limit = 5}) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'invoices',
      where: 'deleted_at IS NULL',
      orderBy: 'id DESC',
      limit: limit,
    );
    return _buildInvoiceList(rows);
  }

  /// Invoices with due_date = today or tomorrow that are not fully paid.
  static Future<List<Invoice>> getDueSoonInvoices() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final todayStart = AppDate.dateKeyStart(now);
    final tomorrowEnd = AppDate.dateKeyStart(DateTime(now.year, now.month, now.day + 2));
    final rows = await db.query(
      'invoices',
      where: 'deleted_at IS NULL AND type = ? AND due_date IS NOT NULL '
          'AND due_date >= ? AND due_date < ?',
      whereArgs: ['Invoice', todayStart, tomorrowEnd],
      orderBy: 'due_date ASC',
    );
    final invoices = await _buildInvoiceList(rows);
    return invoices
        .where((inv) => inv.outstandingBalance > InvoiceCalculator.moneyEpsilon)
        .toList();
  }

  /// Invoices past their due_date that are not fully paid, up to [limit] rows.
  static Future<List<Invoice>> getOverdueInvoices({int limit = 10}) async {
    final db = await dbHelper.database;
    final todayStart = AppDate.dateKeyStart(DateTime.now());
    // Fetch more than limit to account for some already being paid
    final rows = await db.query(
      'invoices',
      where:
          'deleted_at IS NULL AND type = ? AND due_date IS NOT NULL AND due_date < ?',
      whereArgs: ['Invoice', todayStart],
      orderBy: 'due_date ASC',
      limit: limit * 3,
    );
    final invoices = await _buildInvoiceList(rows);
    final overdue = invoices
        .where((inv) => InvoiceCalculator.isOverdue(
              dueDate: inv.dueDate,
              outstanding: inv.outstandingBalance,
            ))
        .toList();
    return overdue.length > limit ? overdue.sublist(0, limit) : overdue;
  }

  /// Revenue grouped by month for the last [months] calendar months.
  /// Returns rows with keys 'month' (YYYY-MM string) and 'revenue' (double).
  static Future<List<Map<String, dynamic>>> getMonthlyRevenue(
      {int months = 6}) async {
    final db = await dbHelper.database;
    final cutoff = DateTime.now().subtract(Duration(days: months * 31));
    final cutoffStr =
        '${cutoff.year.toString().padLeft(4, '0')}-${cutoff.month.toString().padLeft(2, '0')}-01';
    final rows = await db.rawQuery(
      "SELECT substr(ip.date_paid, 1, 7) as month, "
      "COALESCE(SUM(ip.amount_paid), 0.0) as revenue "
      "FROM invoice_payments ip "
      "JOIN invoices i ON ip.invoice_id = i.id "
      "WHERE i.type = 'Invoice' AND i.deleted_at IS NULL "
      "AND substr(ip.date_paid, 1, 10) >= ? "
      "GROUP BY substr(ip.date_paid, 1, 7) "
      "ORDER BY month ASC",
      [cutoffStr],
    );
    return rows
        .map((r) => {
              'month': r['month'] as String,
              'revenue': (r['revenue'] as num).toDouble()
            })
        .toList();
  }

  /// Top [limit] customers by total payments received.
  static Future<List<Map<String, dynamic>>> getTopCustomers(
      {int limit = 5}) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT i.customer_name, '
      'COALESCE(SUM(ip.amount_paid), 0.0) as total_paid, '
      'COUNT(DISTINCT i.id) as invoice_count '
      'FROM invoices i '
      'LEFT JOIN invoice_payments ip ON i.id = ip.invoice_id '
      "WHERE i.type = 'Invoice' AND i.deleted_at IS NULL "
      'GROUP BY i.customer_name '
      'ORDER BY total_paid DESC, invoice_count DESC '
      'LIMIT ?',
      [limit],
    );
    return rows
        .map((r) => {
              'customer_name': r['customer_name'] as String? ?? '',
              'total_paid': (r['total_paid'] as num).toDouble(),
              'invoice_count': (r['invoice_count'] as int?) ?? 0,
            })
        .toList();
  }

  /// Top [limit] products by total units sold across all invoices.
  static Future<List<Map<String, dynamic>>> getTopProducts(
      {int limit = 5}) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT ii.product_name, COALESCE(SUM(ii.quantity), 0) as total_qty '
      'FROM invoice_items ii '
      'JOIN invoices i ON ii.invoice_id = i.id '
      "WHERE i.type = 'Invoice' AND i.deleted_at IS NULL "
      "AND ii.product_name IS NOT NULL AND ii.product_name != '' "
      'GROUP BY ii.product_name '
      'ORDER BY total_qty DESC '
      'LIMIT ?',
      [limit],
    );
    return rows
        .map((r) => {
              'product_name': r['product_name'] as String? ?? '',
              'total_qty': (r['total_qty'] as num).toDouble(),
            })
        .toList();
  }

  /// Generates the next `id` (primary key) — global sequence across all
  /// types, unchanged from before. Other queries (e.g. "recent invoices")
  /// rely on `id` sorting as a single monotonic sequence, so this must never
  /// be scoped by type.
  static Future<String> generateNextId() async {
    final db = await dbHelper.database;
    final result =
        await db.rawQuery("SELECT id FROM invoices ORDER BY id DESC LIMIT 1");

    int nextNumber;
    if (result.isNotEmpty) {
      final lastNumberStr = result.first['id'] as String;
      final numericPart =
          int.tryParse(lastNumberStr.replaceAll(RegExp(r'\D'), ''));
      nextNumber = (numericPart != null) ? numericPart + 1 : 1;
    } else {
      final startStr = await SettingsService.getSetting(SettingKey.invoiceStartingNumber);
      nextNumber = int.tryParse(startStr ?? '') ?? 1;
      if (nextNumber < 1) nextNumber = 1;
    }

    return nextNumber.toString().padLeft(8, '0');
  }

  /// Generates the next **display** number for [type] ('Invoice' |
  /// 'Quotation' | 'Receipt') — each type has its own independent sequence.
  /// This is separate from `id` (the PK, always global) and is stored in the
  /// `invoice_number` column purely for display.
  ///
  /// Derived from existing rows rather than a persisted counter: takes the
  /// max of the legacy `id` sequence (pre-migration rows, shared across all
  /// types) and the new `invoice_number` column (post-migration, per-type)
  /// for this type, so upgrading preserves numbering continuity for existing
  /// customers without any data migration.
  static Future<String> generateNextInvoiceNumber(String type) async {
    final db = await dbHelper.database;

    final idResult = await db.rawQuery(
        "SELECT id FROM invoices WHERE type = ? ORDER BY id DESC LIMIT 1",
        [type]);
    final numResult = await db.rawQuery(
        "SELECT invoice_number FROM invoices WHERE type = ? AND invoice_number IS NOT NULL ORDER BY invoice_number DESC LIMIT 1",
        [type]);

    int fromId = 0;
    if (idResult.isNotEmpty) {
      final idStr = idResult.first['id'] as String;
      fromId = int.tryParse(idStr.replaceAll(RegExp(r'\D'), '')) ?? 0;
    }
    int fromNum = 0;
    if (numResult.isNotEmpty) {
      final numStr = numResult.first['invoice_number'] as String;
      fromNum = int.tryParse(numStr.replaceAll(RegExp(r'\D'), '')) ?? 0;
    }

    int nextNumber;
    if (fromNum > 0) {
      // Authoritative: this type already has real invoice_number rows.
      nextNumber = fromNum + 1;
    } else if (fromId > 0) {
      // Legacy fallback: pre-migration rows of this type exist with an id
      // but no invoice_number yet.
      nextNumber = fromId + 1;
    } else if (type.toLowerCase() == 'invoice') {
      final startStr =
          await SettingsService.getSetting(SettingKey.invoiceStartingNumber);
      nextNumber = int.tryParse(startStr ?? '') ?? 1;
      if (nextNumber < 1) nextNumber = 1;
    } else {
      nextNumber = 1;
    }

    return nextNumber.toString().padLeft(8, '0');
  }
}
