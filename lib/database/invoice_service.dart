import 'package:invoiso/database/invoice_item_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/product.dart';
import '../models/customer.dart';
import '../models/invoice_item.dart';
import 'database_helper.dart';

class InvoiceService
{
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // Insert Invoice + Items + Stock Deduction
  static Future<void> insertInvoice(Invoice invoice) async {
    final db = await dbHelper.database;
    await db.insert('invoices', {
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
    });

    for (var item in invoice.items) {
      await InvoiceItemService.insertInvoiceItems(invoice.id,item);
      // Deduct stock
      final product = await ProductService.getProductById(item.product.id);
      if (product != null) {
        final newStock = product.stock - item.quantity;
        await ProductService.updateProductStock(product.id, newStock);
      }
    }
  }

  static Future<void> updateInvoice(Invoice invoice) async {
    final db = await dbHelper.database;

    // 1️⃣ Update the main invoice table
    await db.update(
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
        // You may keep 'date' as is or allow updating
      },
      where: 'id = ?',
      whereArgs: [invoice.id],
    );

    // 2️⃣ Fetch existing invoice items to adjust stock
    final oldItems = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
    );

    // 3️⃣ Restore stock for old items
    for (var oldItem in oldItems) {
      final product = await ProductService.getProductById(oldItem['product_id'] as String);
      if (product != null) {
        final restoredStock = product.stock + (oldItem['quantity'] as int);
        await ProductService.updateProductStock(product.id, restoredStock);
      }
    }

    // 4️⃣ Delete old items
    await db.delete(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoice.id],
    );

    // 5️⃣ Insert new items and deduct stock
    for (var item in invoice.items) {
      await InvoiceItemService.insertInvoiceItems(invoice.id,item);
      final product = await ProductService.getProductById(item.product.id);
      if (product != null) {
        final newStock = product.stock - item.quantity;
        await ProductService.updateProductStock(product.id, newStock);
      }
    }
  }


  // ─────────────────────────────────────────────
  // Fetch Invoice with Items
  static Future<Invoice?> getInvoiceById(String id) async {
    final db = await dbHelper.database;

    // Fetch invoice
    final invoiceData = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (invoiceData.isEmpty) return null;
    final i = invoiceData.first;

    // Create Customer from invoice row
    final customer = Customer.fromMap({
      'id': i['customer_id'],
      'name': i['customer_name'],
      'email': i['customer_email'],
      'phone': i['customer_phone'],
      'address': i['customer_address'],
      'gstin': i['customer_gstin'],
    });

    // Fetch invoice items
    final itemRows = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    final items = <InvoiceItem>[];

    for (var row in itemRows) {
      // final product = await getProductById(row['product_id'] as String);
      try {
        final product = Product.fromInvoiceItemsMap(row);
        items.add(InvoiceItem(
          product: product,
          quantity: row['quantity'] as int,
          discount: (row['discount'] is int)
              ? (row['discount'] as int).toDouble()
              : (row['discount'] ?? 0.0) as double,
        ));
      }
      catch (e, stackTrace) {
        print('Error parsing invoice item row: $e');
        print(stackTrace);
        // optionally continue, skip this row
        continue;
      }
    }

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
    );
  }

  // Get all invoices with customer and items
  static Future<List<Invoice>> getAllInvoices() async {
    final db = await dbHelper.database;
    final invoiceMaps = await db.query(
      'invoices',
      orderBy: 'id DESC',
    );

    final invoices = <Invoice>[];

    for (var map in invoiceMaps) {
      final invoiceId = map['id'] as String?;
      final dateString = map['date'] as String?;
      final type = map['type'] as String? ?? '';
      final notes = map['notes'] as String? ?? '';
      final taxRateRaw = map['tax_rate'];

      if (invoiceId == null || dateString == null) continue;

      // Use fromMap for customer
      final customer = Customer.fromMap({
        'id': map['customer_id'],
        'name': map['customer_name'],
        'email': map['customer_email'],
        'phone': map['customer_phone'],
        'address': map['customer_address'],
        'gstin': map['customer_gstin'],
      });

      // Fetch items for this invoice
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
        ),
      );
    }

    return invoices;
  }

  // ─────────────────────────────────────────────
  // Delete Invoice
  static Future<void> deleteInvoice(String id) async {
    final db = await  dbHelper.database;
    await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }
}