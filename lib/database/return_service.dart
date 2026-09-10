import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/payment_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/payment_receipt_numbers.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer_credit.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/refund.dart';
import 'package:invoiso/utils/app_logger.dart';

const _tag = 'ReturnService';
const _eps = InvoiceCalculator.moneyEpsilon;

/// Persistence + money/stock effects for return management (Credit / Debit
/// Notes). Callers build a fully-formed [Invoice] (type `Credit Note` /
/// `Debit Note`, `invoiceNumber` already assigned via
/// [InvoiceService.generateNextInvoiceNumber], items = the returned lines with
/// their `restocked` flags, `original*` / `returnReason` / `creditSettlement`
/// populated) and hand it here — mirrors [InvoiceService.insertInvoice].
class ReturnService {
  static final _dbHelper = DatabaseHelper();
  static const _uuid = Uuid();

  // ─────────────────────────────────────────────────────────────────────
  // Credit note (sales return)
  // ─────────────────────────────────────────────────────────────────────
  static Future<void> createCreditNote({
    required Invoice creditNote,
    Invoice? originalInvoice,
    RefundInput? immediateRefund,
  }) async {
    assert(creditNote.type == 'Credit Note');
    final db = await _dbHelper.database;
    final settlement = creditNote.creditSettlement;
    final total = creditNote.total;

    await db.transaction((txn) async {
      await txn.insert('invoices', _invoiceRow(creditNote));
      for (final item in creditNote.items) {
        await txn.insert('invoice_items', _itemRow(item, creditNote.id));
      }
    });

    // Settlement — each step is self-contained, run after the row is committed
    // (same shape as InvoiceService doing stock outside its insert txn).
    switch (settlement) {
      case CreditSettlement.reduceInvoice:
        final applied = originalInvoice == null
            ? 0.0
            : math.min(total, originalInvoice.outstandingBalance);
        if (originalInvoice != null && applied > _eps) {
          await PaymentService.addPayment(
            invoice: originalInvoice,
            amountPaid: applied,
            datePaid: creditNote.date,
            paymentMethod: 'Credit Note',
            notes: _creditNoteRef(creditNote),
          );
        }
        if (total - applied > _eps) {
          await _insertCredit(db, creditNote, total - applied);
        }
        break;
      case CreditSettlement.customerCredit:
        await _insertCredit(db, creditNote, total);
        break;
      case CreditSettlement.refund:
        await _insertCredit(db, creditNote, total);
        if (immediateRefund != null && immediateRefund.amount > _eps) {
          await recordRefund(
            creditNote: creditNote,
            amount: immediateRefund.amount,
            method: immediateRefund.method,
            date: immediateRefund.date,
            notes: immediateRefund.notes,
          );
        }
        break;
      case null:
        break;
    }

    await _restock(creditNote, direction: 1);
    AppLogger.d(
        _tag, 'Credit note ${creditNote.invoiceNumber} (${settlement?.key})');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Debit note — supplementary charge. No stock, no settlement; it just adds
  // to what the customer owes (surfaced via the ledger / previous balance).
  // ─────────────────────────────────────────────────────────────────────
  static Future<void> createDebitNote({
    required Invoice debitNote,
    Invoice? originalInvoice,
  }) async {
    assert(debitNote.type == 'Debit Note');
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('invoices', _invoiceRow(debitNote));
      for (final item in debitNote.items) {
        await txn.insert('invoice_items', _itemRow(item, debitNote.id));
      }
    });
    AppLogger.d(_tag, 'Debit note ${debitNote.invoiceNumber} created');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Refund against a credit note. Also serves "convert customer credit to a
  // refund" — both consume the credit note's unused credit and pay out.
  // ─────────────────────────────────────────────────────────────────────
  static Future<Refund> recordRefund({
    required Invoice creditNote,
    required double amount,
    required DateTime date,
    String? method,
    String? notes,
  }) async {
    if (amount <= _eps) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    final db = await _dbHelper.database;
    late Refund saved;

    await db.transaction((txn) async {
      final creditRows = await txn.query('customer_credits',
          where: 'source_id = ?',
          whereArgs: [creditNote.id],
          orderBy: 'created_at ASC, rowid ASC');
      final remaining = creditRows.fold<double>(
          0.0, (s, r) => s + _free(r));
      if (amount > remaining + _eps) {
        throw StateError(
            'Refund $amount exceeds available credit $remaining for credit note ${creditNote.id}');
      }

      await _consume(txn, creditRows, amount);

      final existing = await txn.rawQuery(
        'SELECT receipt_number FROM refunds WHERE credit_note_id = ?',
        [creditNote.id],
      );
      final receiptNumber = PaymentReceiptNumbers.nextReceiptNumber(
        invoiceId: creditNote.id,
        existingReceiptNumbers:
            existing.map((r) => r['receipt_number'] as String?),
      );

      final taxAmount = creditNote.total > _eps
          ? amount * (creditNote.tax / creditNote.total)
          : 0.0;

      saved = Refund(
        id: _uuid.v4(),
        creditNoteId: creditNote.id,
        creditNoteNumber: creditNote.invoiceNumber ?? creditNote.id,
        receiptNumber: receiptNumber,
        amount: amount,
        taxAmount: taxAmount,
        refundMethod: method,
        dateRefunded: date,
        notes: notes,
      );
      await txn.insert('refunds', saved.toMap());
    });

    AppLogger.d(_tag, 'Refund ${saved.receiptNumber} — $amount');
    return saved;
  }

  /// Customer parked a credit but now wants cash. Identical mechanics to
  /// [recordRefund]; kept as its own name for call-site clarity.
  static Future<Refund> convertCreditToRefund({
    required Invoice creditNote,
    required double amount,
    required DateTime date,
    String? method,
    String? notes,
  }) =>
      recordRefund(
        creditNote: creditNote,
        amount: amount,
        date: date,
        method: method,
        notes: notes,
      );

  // ─────────────────────────────────────────────────────────────────────
  // Apply a customer's stored credit against a new invoice. Consumes only
  // what credit is actually available (FIFO) and records a matching payment
  // on the invoice for that consumed amount.
  // ─────────────────────────────────────────────────────────────────────
  static Future<double> applyCustomerCreditToInvoice({
    required Invoice invoice,
    required double amount,
  }) async {
    if (amount <= _eps) return 0.0;
    final db = await _dbHelper.database;
    double consumed = 0.0;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'customer_credits',
        where:
            '${_customerWhere(invoice.customer.id, invoice.customer.name)} AND currency_code = ?',
        whereArgs: [
          ..._customerArgs(invoice.customer.id, invoice.customer.name),
          invoice.currencyCode,
        ],
        orderBy: 'created_at ASC, rowid ASC',
      );
      consumed = await _consume(txn, rows, amount);
    });

    if (consumed > _eps) {
      await PaymentService.addPayment(
        invoice: invoice,
        amountPaid: consumed,
        datePaid: invoice.date,
        paymentMethod: 'Customer Credit',
        notes: 'Applied from credit note(s)',
      );
    }
    return consumed;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Void a credit note (admin). Reverses stock and settlement, then
  // soft-deletes. Blocked once any of its credit was spent on an invoice.
  // ─────────────────────────────────────────────────────────────────────
  static Future<void> voidCreditNote(String creditNoteId) async {
    final db = await _dbHelper.database;
    final cn = await InvoiceService.getInvoiceById(creditNoteId);
    if (cn == null) throw StateError('Credit note $creditNoteId not found');

    final credits = await db.query('customer_credits',
        where: 'source_id = ?', whereArgs: [creditNoteId]);
    final applied = credits.fold<double>(
        0.0, (s, r) => s + (r['applied_amount'] as num).toDouble());
    final refunded = ((await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) AS t FROM refunds WHERE credit_note_id = ?',
      [creditNoteId],
    ))
            .first['t'] as num)
        .toDouble();
    if (applied - refunded > _eps) {
      throw StateError(
          'Cannot void: some of this credit note has already been applied to an invoice');
    }

    await _restock(cn, direction: -1);

    await db.transaction((txn) async {
      await txn.delete('refunds',
          where: 'credit_note_id = ?', whereArgs: [creditNoteId]);
      await txn.delete('customer_credits',
          where: 'source_id = ?', whereArgs: [creditNoteId]);
      if (cn.creditSettlement == CreditSettlement.reduceInvoice &&
          cn.originalInvoiceId != null) {
        await txn.delete(
          'invoice_payments',
          where:
              "invoice_id = ? AND payment_method = 'Credit Note' AND notes = ?",
          whereArgs: [cn.originalInvoiceId, _creditNoteRef(cn)],
        );
      }
      await txn.update(
        'invoices',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [creditNoteId],
      );
    });
    AppLogger.d(_tag, 'Credit note ${cn.invoiceNumber} voided');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Reads
  // ─────────────────────────────────────────────────────────────────────

  /// Credit / debit notes raised against [invoiceId], oldest first.
  static Future<List<Invoice>> getNotesForInvoice(String invoiceId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'invoices',
      columns: ['id'],
      where:
          "original_invoice_id = ? AND type IN ('Credit Note', 'Debit Note') AND deleted_at IS NULL",
      whereArgs: [invoiceId],
      orderBy: 'date ASC, rowid ASC',
    );
    final out = <Invoice>[];
    for (final r in rows) {
      final inv = await InvoiceService.getInvoiceById(r['id'] as String);
      if (inv != null) out.add(inv);
    }
    return out;
  }

  /// Cumulative returned quantity per product across every credit note raised
  /// against [originalInvoiceId] — caps how much more a line can be returned.
  static Future<Map<String, double>> getReturnedQtyByLine(
      String originalInvoiceId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT ii.product_id AS pid, COALESCE(SUM(ii.quantity), 0.0) AS q
      FROM invoice_items ii
      JOIN invoices i ON i.id = ii.invoice_id
      WHERE i.original_invoice_id = ?
        AND i.type = 'Credit Note'
        AND i.deleted_at IS NULL
      GROUP BY ii.product_id
    ''', [originalInvoiceId]);
    return {
      for (final r in rows)
        (r['pid'] as String? ?? ''): (r['q'] as num).toDouble()
    };
  }

  static Future<double> getRemainingCustomerCredit({
    required String customerId,
    String? customerName,
    required String currencyCode,
  }) async {
    if (customerId.trim().isEmpty &&
        (customerName == null || customerName.trim().isEmpty)) {
      return 0.0;
    }
    final db = await _dbHelper.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(amount - applied_amount), 0.0) AS c '
      'FROM customer_credits '
      'WHERE ${_customerWhere(customerId, customerName ?? '')} AND currency_code = ?',
      [..._customerArgs(customerId, customerName ?? ''), currencyCode],
    );
    return (r.first['c'] as num).toDouble();
  }

  static Future<List<Refund>> getRefundsForCreditNote(
      String creditNoteId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('refunds',
        where: 'credit_note_id = ?',
        whereArgs: [creditNoteId],
        orderBy: 'date_refunded ASC, rowid ASC');
    return rows.map(Refund.fromMap).toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Internals
  // ─────────────────────────────────────────────────────────────────────

  static String _creditNoteRef(Invoice cn) =>
      'Credit Note ${cn.invoiceNumber ?? cn.id}';

  static double _free(Map<String, Object?> row) =>
      (row['amount'] as num).toDouble() -
      (row['applied_amount'] as num).toDouble();

  /// Draw [amount] from [creditRows] (already ordered), bumping applied_amount.
  /// Returns the amount actually consumed (may be less if rows run dry).
  static Future<double> _consume(
    DatabaseExecutor txn,
    List<Map<String, Object?>> creditRows,
    double amount,
  ) async {
    var left = amount;
    for (final r in creditRows) {
      if (left <= _eps) break;
      final free = _free(r);
      if (free <= _eps) continue;
      final take = math.min(free, left);
      await txn.update(
        'customer_credits',
        {'applied_amount': (r['applied_amount'] as num).toDouble() + take},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
      left -= take;
    }
    return amount - left;
  }

  static Future<void> _insertCredit(
      DatabaseExecutor db, Invoice cn, double amount) async {
    final credit = CustomerCredit(
      id: _uuid.v4(),
      customerId: cn.customer.id.trim().isEmpty ? null : cn.customer.id.trim(),
      customerName: cn.customer.name,
      currencyCode: cn.currencyCode,
      sourceType: 'credit_note',
      sourceId: cn.id,
      amount: amount,
      createdAt: cn.date,
    );
    await db.insert('customer_credits', credit.toMap());
  }

  /// Add ([direction] 1) or remove ([direction] -1) returned quantity from
  /// sellable stock for every restocked line. Skips unlimited-stock products.
  static Future<void> _restock(Invoice cn, {required int direction}) async {
    for (final item in cn.items) {
      if (!item.restocked) continue;
      final p = await ProductService.getProductById(item.product.id);
      if (p == null || p.unlimitedStock) continue;
      await ProductService.updateProductStock(
          p.id, p.stock + direction * item.quantity.round());
    }
  }

  static String _customerWhere(String id, String name) =>
      id.trim().isNotEmpty
          ? 'customer_id = ?'
          : "(customer_id IS NULL OR customer_id = '') AND customer_name = ?";

  static List<Object?> _customerArgs(String id, String name) =>
      id.trim().isNotEmpty ? [id.trim()] : [name.trim()];

  static Map<String, Object?> _invoiceRow(Invoice inv) => {
        'id': inv.id,
        'invoice_number': inv.invoiceNumber,
        'customer_id': inv.customer.id,
        'customer_name': inv.customer.name,
        'customer_email': inv.customer.email,
        'customer_phone': inv.customer.phone,
        'customer_address': inv.customer.address,
        'customer_gstin': inv.customer.gstin,
        'customer_business_name': inv.customer.businessName,
        'date': inv.date.toIso8601String(),
        'notes': inv.notes,
        'tax_rate': inv.taxRate,
        'type': inv.type,
        'invoice_title': inv.invoiceTitle,
        'currency_code': inv.currencyCode,
        'currency_symbol': inv.currencySymbol,
        'tax_mode': inv.taxMode.key,
        'is_interstate': inv.isInterState ? 1 : 0,
        'upi_id': inv.upiId,
        'bank_account_id': inv.bankAccountId,
        'due_date': inv.dueDate?.toIso8601String(),
        'quantity_label': inv.quantityLabel,
        'additional_costs': AdditionalCost.listToJson(inv.additionalCosts),
        'invoice_discount_type': inv.invoiceDiscountType.key,
        'invoice_discount_value': inv.invoiceDiscountValue,
        'hide_invoice_number': inv.hideInvoiceNumber ? 1 : 0,
        'custom_invoice_number': inv.customInvoiceNumber,
        'custom_fields': CustomFieldValue.listToJson(inv.customFields),
        'original_invoice_id': inv.originalInvoiceId,
        'original_invoice_number': inv.originalInvoiceNumber,
        'original_invoice_date': inv.originalInvoiceDate?.toIso8601String(),
        'return_reason': inv.returnReason,
        'credit_settlement': inv.creditSettlement?.key,
      };

  static Map<String, Object?> _itemRow(InvoiceItem item, String invoiceId) => {
        'id': item.id,
        'invoice_id': invoiceId,
        'product_id': item.product.id,
        'product_name': item.product.name,
        'product_description': item.product.description,
        'product_price': item.product.price,
        'product_tax_rate': item.product.tax_rate,
        'product_price_includes_tax': item.product.priceIncludesTax ? 1 : 0,
        'product_hsn_code': item.product.hsncode,
        'quantity': item.quantity,
        'discount': item.discount,
        'discount_per_unit': item.discountPerUnit ? 1 : 0,
        'unit_price': item.unitPrice,
        'extra_cost': item.extraCost,
        'is_product_saved': item.isProductSaved ? 1 : 0,
        'product_type': item.product.type,
        'product_purchase_price': item.product.purchasePrice,
        'product_alias_name': item.product.aliasName,
        'product_unit': item.product.unit,
        'unit': item.unit,
        'description': item.description,
        'line_metadata': item.metadata == null
            ? null
            : jsonEncode(item.metadata!.toMap()),
        'restocked': item.restocked ? 1 : 0,
      };
}
