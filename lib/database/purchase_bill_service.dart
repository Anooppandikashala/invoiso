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
        'is_draft': bill.isDraft ? 1 : 0,
      });

      for (var item in bill.items) {
        await txn.insert('purchase_bill_items', {
          'bill_id': bill.id,
          ...item.toMap(),
        });
      }
    });

    // Stock/purchase-info/ledger sync happens outside the transaction to
    // avoid nested DB calls, mirroring invoice_service.dart. Drafts are inert.
    if (bill.isDraft) return;
    for (var item in bill.items) {
      await _applyPurchase(item, bill);
    }
    await _refreshPurchaseInfo(_productIds(bill.items));
  }

  static Future<void> updatePurchaseBill(PurchaseBill bill) async {
    final db = await dbHelper.database;

    // Fetch existing items before the transaction (to reverse their stock)
    final oldItems = await db.query(
      'purchase_bill_items',
      where: 'bill_id = ?',
      whereArgs: [bill.id],
    );
    final oldRow = await db.query('purchase_bills',
        columns: ['is_draft'], where: 'id = ?', whereArgs: [bill.id]);
    final wasDraft =
        oldRow.isNotEmpty && (oldRow.first['is_draft'] as int? ?? 0) == 1;
    // One-way: a final bill's stock is already applied and may have payments.
    if (!wasDraft && bill.isDraft) {
      throw StateError('A final purchase bill cannot be saved as a draft.');
    }

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
          'is_draft': bill.isDraft ? 1 : 0,
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
    for (var oldItem in wasDraft ? const <Map<String, Object?>>[] : oldItems) {
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
    if (!bill.isDraft) {
      for (var item in bill.items) {
        await _applyPurchase(item, bill);
      }
    }
    await _refreshPurchaseInfo({
      ...oldItems.map((r) => r['product_id'] as String?).whereType<String>(),
      ..._productIds(bill.items),
    });
  }

  // ─────────────────────────────────────────────
  // Apply one purchased line item: stock addition + ledger row. Ad-hoc items
  // (product_id == null) and unlimited-stock products are skipped. Purchase
  // price / last purchase date are synced separately by _refreshPurchaseInfo.
  static Future<void> _applyPurchase(
      PurchaseBillItem item, PurchaseBill bill, {String? notes}) async {
    if (item.productId == null) return;
    final product = await ProductService.getProductById(item.productId!);
    if (product == null || product.unlimitedStock) return;

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
      notes: notes,
    );
  }

  static Set<String> _productIds(List<PurchaseBillItem> items) =>
      items.map((i) => i.productId).whereType<String>().toSet();

  // Sets each product's purchase price / last purchase date from its latest
  // remaining final, non-deleted bill line, so deleting or editing a bill
  // never leaves a stale cost behind. No such line left → the price is kept
  // (it may have been entered by hand) and only the date is cleared.
  static Future<void> _refreshPurchaseInfo(Set<String> productIds) async {
    final db = await dbHelper.database;
    for (final productId in productIds) {
      final rows = await db.rawQuery(
        'SELECT pbi.*, pb.bill_date AS bill_date FROM purchase_bill_items pbi '
        'JOIN purchase_bills pb ON pb.id = pbi.bill_id '
        'WHERE pbi.product_id = ? AND pb.deleted_at IS NULL '
        'AND COALESCE(pb.is_draft, 0) = 0 '
        'ORDER BY pb.bill_date DESC, pb.created_at DESC, pbi.rowid DESC '
        'LIMIT 1',
        [productId],
      );
      if (rows.isEmpty) {
        await db.update('products', {'last_purchase_date': null},
            where: 'id = ?', whereArgs: [productId]);
        continue;
      }
      await ProductService.updatePurchaseInfo(
        productId,
        purchasePrice: PurchaseBillItem.fromMap(rows.first).netCostPerUnit,
        lastPurchaseDate: DateTime.parse(rows.first['bill_date'] as String),
      );
    }
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

    if (bill == null || bill.isDraft) return;
    for (var item in bill.items) {
      await _reverseStock(
        productId: item.productId,
        quantity: item.quantity,
        referenceDate: DateTime.now(),
        billId: id,
        notes: 'bill soft-delete reversal',
      );
    }
    await _refreshPurchaseInfo(_productIds(bill.items));
  }

  // Restore re-applies the stock that soft-delete reversed (drafts never had
  // any applied).
  static Future<void> restorePurchaseBill(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'purchase_bills',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );

    final bill = await getPurchaseBillById(id);
    if (bill == null || bill.isDraft) return;
    for (var item in bill.items) {
      await _applyPurchase(item, bill, notes: 'bill restore');
    }
    await _refreshPurchaseInfo(_productIds(bill.items));
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
        isDraft: (map['is_draft'] as int? ?? 0) == 1,
      );
    }).toList();
  }
}
