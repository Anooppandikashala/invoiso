import 'package:invoiso/models/invoice_item.dart';
import '../models/product.dart';
import '../utils/app_logger.dart';
import 'database_helper.dart';

const _tag = 'InvoiceItemService';

class InvoiceItemService {
  static final dbHelper = DatabaseHelper();

  static Future<void> insertInvoiceItems(String invId, InvoiceItem item) async {
    final db = await dbHelper.database;
    await db.insert('invoice_items', {
      'invoice_id': invId,
      'product_id': item.product.id,
      'product_name': item.product.name,
      'product_description': item.product.description,
      'product_price': item.product.price,
      'product_tax_rate': item.product.tax_rate,
      'product_hsn_code': item.product.hsncode,
      'quantity': item.quantity,
      'discount': item.discount,
    });
  }

  static Future<List<InvoiceItem>> getInvoiceItemsByInvoiceId(String invoiceId) async {
    final db = await dbHelper.database;
    final maps = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    final List<InvoiceItem> items = [];

    for (var map in maps) {
      try {
        final product = Product.fromInvoiceItemsMap(map);
        items.add(
          InvoiceItem(
            product: product,
            quantity: map['quantity'] as int,
            discount: (map['discount'] is int)
                ? (map['discount'] as int).toDouble()
                : (map['discount'] ?? 0.0) as double,
          ),
        );
      } catch (e, stackTrace) {
        AppLogger.e(_tag, 'Error parsing invoice item row', e, stackTrace);
        continue;
      }
    }

    return items;
  }
}
