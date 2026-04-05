import 'package:invoiso/common.dart';
import 'package:invoiso/database/invoice_item_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/product.dart';
import '../models/customer.dart';
import '../models/invoice_item.dart';
import '../models/invoice_payment.dart';
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
        'customer_id': invoice.customer.id,
        'customer_name': invoice.customer.name,
        'customer_email': invoice.customer.email,
        'customer_phone': invoice.customer.phone,
        'customer_address': invoice.customer.address,
        'customer_gstin': invoice.customer.gstin,
        'date': invoice.date.toIso8601String(),
        'notes': invoice.notes,
        'tax_rate': invoice.taxRate,
        'type': invoice.type,
        'currency_code': invoice.currencyCode,
        'currency_symbol': invoice.currencySymbol,
        'tax_mode': invoice.taxMode.key,
        'upi_id': invoice.upiId,
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
          'unit_price': item.unitPrice,
          'extra_cost': item.extraCost,
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
          'notes': invoice.notes,
          'tax_rate': invoice.taxRate,
          'type': invoice.type,
          'tax_mode': invoice.taxMode.key,
          'upi_id': invoice.upiId,
          'due_date': invoice.dueDate?.toIso8601String(),
          'quantity_label': invoice.quantityLabel,
          'additional_costs': AdditionalCost.listToJson(invoice.additionalCosts),
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
          'unit_price': item.unitPrice,
          'extra_cost': item.extraCost,
        });
      }
    });

    // Restore stock for old items (outside transaction)
    for (var oldItem in oldItems) {
      final product = await ProductService.getProductById(oldItem['product_id'] as String);
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
    });

    final itemRows = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    final items = <InvoiceItem>[];

    for (var row in itemRows) {
      try {
        final product = Product.fromInvoiceItemsMap(row);
        final rawUnitPrice = row['unit_price'];
        final unitPrice = rawUnitPrice == null
            ? null
            : (rawUnitPrice is int ? rawUnitPrice.toDouble() : rawUnitPrice as double);
        final rawExtraCost = row['extra_cost'];
        final extraCost = rawExtraCost == null
            ? null
            : (rawExtraCost is int ? rawExtraCost.toDouble() : rawExtraCost as double);
        items.add(InvoiceItem(
          product: product,
          quantity: (row['quantity'] is int)
              ? (row['quantity'] as int).toDouble()
              : (row['quantity'] ?? 1.0) as double,
          discount: (row['discount'] is int)
              ? (row['discount'] as int).toDouble()
              : (row['discount'] ?? 0.0) as double,
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
      dueDate: i['due_date'] != null ? DateTime.tryParse(i['due_date'] as String) : null,
      quantityLabel: i['quantity_label'] as String?,
      additionalCosts: AdditionalCost.listFromJson(i['additional_costs'] as String?),
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
      });

      final items = await InvoiceItemService.getInvoiceItemsByInvoiceId(invoiceId);
      invoices.add(
        Invoice(
          id: invoiceId,
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
          dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'] as String) : null,
          quantityLabel: map['quantity_label'] as String?,
          additionalCosts: AdditionalCost.listFromJson(map['additional_costs'] as String?),
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
}
