import 'package:uuid/uuid.dart';

import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/models/stock_transaction.dart';
import 'package:invoiso/models/supplier_payment.dart';
import 'database_helper.dart';

class PurchaseBillService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // Insert Purchase Bill + Items + Stock Addition (transactional)
  static Future<void> insertPurchaseBill(PurchaseBill bill) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('purchase_bills', {
        'id': bill.id,
        'supplier_id': bill.supplierId,
        'supplier_name': bill.supplierName,
        'bill_number': bill.billNumber,
        'bill_date': bill.billDate.toIso8601String(),
        'notes': bill.notes,
        'attachment_path': bill.attachmentPath,
        'subtotal': bill.subtotal,
        'tax_amount': bill.tax,
        'total_amount': bill.total,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (var item in bill.items) {
        await txn.insert('purchase_bill_items', {
          'bill_id': bill.id,
          ...item.toMap(),
        });
      }
    });

    // Stock/purchase-info/ledger sync happens outside the transaction to
    // avoid nested DB calls, mirroring invoice_service.dart.
    for (var item in bill.items) {
      await _applyPurchase(item, bill);
    }
  }

  static Future<void> updatePurchaseBill(PurchaseBill bill) async {
    final db = await dbHelper.database;

    // Fetch existing items before the transaction (to reverse their stock)
    final oldItems = await db.query(
      'purchase_bill_items',
      where: 'bill_id = ?',
      whereArgs: [bill.id],
    );

    await db.transaction((txn) async {
      await txn.update(
        'purchase_bills',
        {
          'supplier_id': bill.supplierId,
          'supplier_name': bill.supplierName,
          'bill_number': bill.billNumber,
          'bill_date': bill.billDate.toIso8601String(),
          'notes': bill.notes,
          'attachment_path': bill.attachmentPath,
          'subtotal': bill.subtotal,
          'tax_amount': bill.tax,
          'total_amount': bill.total,
        },
        where: 'id = ?',
        whereArgs: [bill.id],
      );

      await txn.delete(
        'purchase_bill_items',
        where: 'bill_id = ?',
        whereArgs: [bill.id],
      );

      for (var item in bill.items) {
        await txn.insert('purchase_bill_items', {
          'bill_id': bill.id,
          ...item.toMap(),
        });
      }
    });

    // Reverse stock for old items, then reapply for new items (outside
    // transaction). Each step writes its own stock_transactions row rather
    // than mutating the original purchase row — same append-only ledger
    // philosophy as the soft-delete compensating reversal (D6).
    for (var oldItem in oldItems) {
      final rawQty = oldItem['quantity'];
      final qty = rawQty is int ? rawQty.toDouble() : (rawQty as num).toDouble();
      await _reverseStock(
        productId: oldItem['product_id'] as String?,
        quantity: qty,
        referenceDate: bill.billDate,
        billId: bill.id,
        notes: 'bill update reversal',
      );
    }
    for (var item in bill.items) {
      await _applyPurchase(item, bill);
    }
  }

  // ─────────────────────────────────────────────
  // Apply one purchased line item: purchase-price/last-purchase-date sync +
  // stock addition + ledger row. Ad-hoc items (product_id == null) and
  // unlimited-stock products are skipped for the stock/ledger part.
  static Future<void> _applyPurchase(
      PurchaseBillItem item, PurchaseBill bill) async {
    if (item.productId == null) return;
    final product = await ProductService.getProductById(item.productId!);
    if (product == null) return;

    await ProductService.updatePurchaseInfo(
      product.id,
      purchasePrice: item.netCostPerUnit,
      lastPurchaseDate: bill.billDate,
    );

    if (product.unlimitedStock) return;

    // D2: products.stock stays INTEGER (rounds), while purchase_bill_items
    // .quantity / stock_transactions.quantity_change stay REAL so the audit
    // trail keeps full precision even though the stock counter rounds.
    final stockBefore = product.stock;
    final stockAfter = stockBefore + item.quantity.round();
    await ProductService.updateProductStock(product.id, stockAfter);
    await _writeStockTransaction(
      productId: product.id,
      transactionType: 'purchase',
      referenceId: bill.id,
      quantityChange: item.quantity,
      stockBefore: stockBefore.toDouble(),
      stockAfter: stockAfter.toDouble(),
      unitCost: item.netCostPerUnit,
      transactionDate: bill.billDate,
    );
  }

  // Reverses a previously-applied purchase line's stock effect. Writes a
  // compensating row rather than mutating/deleting the original (D6).
  static Future<void> _reverseStock({
    required String? productId,
    required double quantity,
    required DateTime referenceDate,
    required String billId,
    required String notes,
  }) async {
    if (productId == null) return;
    final product = await ProductService.getProductById(productId);
    if (product == null || product.unlimitedStock) return;

    final stockBefore = product.stock;
    final stockAfter = stockBefore - quantity.round();
    await ProductService.updateProductStock(product.id, stockAfter);
    await _writeStockTransaction(
      productId: product.id,
      transactionType: 'adjustment',
      referenceId: billId,
      quantityChange: -quantity,
      stockBefore: stockBefore.toDouble(),
      stockAfter: stockAfter.toDouble(),
      transactionDate: referenceDate,
      notes: notes,
    );
  }

  static Future<void> _writeStockTransaction({
    required String productId,
    required String transactionType,
    String? referenceId,
    required double quantityChange,
    required double stockBefore,
    required double stockAfter,
    double? unitCost,
    required DateTime transactionDate,
    String? notes,
  }) async {
    final db = await dbHelper.database;
    final tx = StockTransaction(
      id: const Uuid().v4(),
      productId: productId,
      transactionType: transactionType,
      referenceId: referenceId,
      quantityChange: quantityChange,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      unitCost: unitCost,
      transactionDate: transactionDate,
      notes: notes,
    );
    await db.insert('stock_transactions', tx.toMap());
  }

  // ─────────────────────────────────────────────
  // Fetch Purchase Bill with Items + Payments
  static Future<PurchaseBill?> getPurchaseBillById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'purchase_bills',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final list = await _buildPurchaseBillList(maps);
    return list.isEmpty ? null : list.first;
  }

  static Future<List<PurchaseBill>> getAllPurchaseBills() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'purchase_bills',
      where: 'deleted_at IS NULL',
      orderBy: 'id DESC',
    );
    return _buildPurchaseBillList(maps);
  }

  // ─────────────────────────────────────────────
  // Paginated Purchase Bill Fetching (DB-level)
  static Future<List<PurchaseBill>> getPurchaseBillsPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
    String orderBy = 'bill_date',
    bool orderAscending = false,
  }) async {
    final db = await dbHelper.database;

    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (searchQuery.isNotEmpty) {
      whereParts
          .add('(supplier_name LIKE ? OR bill_number LIKE ? OR id LIKE ?)');
      whereArgs.addAll(
          ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    final order = orderAscending ? 'ASC' : 'DESC';
    final orderClause = switch (orderBy) {
      'supplier_name' => 'supplier_name COLLATE NOCASE $order, id DESC',
      'total_amount' => 'total_amount $order, id DESC',
      _ => 'bill_date $order, id DESC',
    };

    final maps = await db.query(
      'purchase_bills',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderClause,
      limit: pageSize,
      offset: page * pageSize,
    );

    return _buildPurchaseBillList(maps);
  }

  static Future<int> getPurchaseBillCount({String searchQuery = ''}) async {
    final db = await dbHelper.database;

    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    if (searchQuery.isNotEmpty) {
      whereParts
          .add('(supplier_name LIKE ? OR bill_number LIKE ? OR id LIKE ?)');
      whereArgs.addAll(
          ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM purchase_bills WHERE ${whereParts.join(' AND ')}',
      whereArgs.isEmpty ? null : whereArgs,
    );
    return (result.first.values.first as int?) ?? 0;
  }

  // ─────────────────────────────────────────────
  // Soft Delete — reverses stock and writes a compensating reversal row to
  // stock_transactions rather than mutating/deleting the original rows (D6).
  static Future<void> softDeletePurchaseBill(String id) async {
    final bill = await getPurchaseBillById(id);
    final db = await dbHelper.database;
    await db.update(
      'purchase_bills',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (bill == null) return;
    for (var item in bill.items) {
      await _reverseStock(
        productId: item.productId,
        quantity: item.quantity,
        referenceDate: DateTime.now(),
        billId: id,
        notes: 'bill soft-delete reversal',
      );
    }
  }

  // Restore only clears deleted_at — does not re-apply stock (mirrors
  // invoice soft-delete precedent; no verification step requires it).
  static Future<void> restorePurchaseBill(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'purchase_bills',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<PurchaseBill>> getDeletedPurchaseBills() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'purchase_bills',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return _buildPurchaseBillList(maps);
  }

  // ─────────────────────────────────────────────
  // Private helper: build PurchaseBill list from raw DB rows.
  // Items and payments are batch-loaded in single queries (no N+1).
  static Future<List<PurchaseBill>> _buildPurchaseBillList(
    List<Map<String, dynamic>> billMaps,
  ) async {
    if (billMaps.isEmpty) return [];

    final db = await dbHelper.database;
    final ids = billMaps.map((m) => m['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');

    final itemRows = await db.rawQuery(
      'SELECT * FROM purchase_bill_items WHERE bill_id IN ($placeholders) '
      'ORDER BY bill_id, rowid ASC',
      ids,
    );
    final itemsByBill = <String, List<PurchaseBillItem>>{};
    for (final row in itemRows) {
      final billId = row['bill_id'] as String;
      itemsByBill
          .putIfAbsent(billId, () => [])
          .add(PurchaseBillItem.fromMap(row));
    }

    final paymentRows = await db.rawQuery(
      'SELECT * FROM supplier_payments WHERE bill_id IN ($placeholders) '
      'ORDER BY bill_id, date_paid ASC, rowid ASC',
      ids,
    );
    final paymentsByBill = <String, List<SupplierPayment>>{};
    for (final row in paymentRows) {
      final billId = row['bill_id'] as String;
      paymentsByBill
          .putIfAbsent(billId, () => [])
          .add(SupplierPayment.fromMap(row));
    }

    return billMaps.map((map) {
      final id = map['id'] as String;
      return PurchaseBill(
        id: id,
        supplierId: map['supplier_id'] as String?,
        supplierName: map['supplier_name'] as String? ?? '',
        billNumber: map['bill_number'] as String?,
        billDate: DateTime.tryParse(map['bill_date'] as String? ?? '') ??
            DateTime.now(),
        notes: map['notes'] as String?,
        attachmentPath: map['attachment_path'] as String?,
        items: itemsByBill[id] ?? [],
        payments: paymentsByBill[id] ?? [],
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null,
      );
    }).toList();
  }
}
