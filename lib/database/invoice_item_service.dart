import 'package:invoiso/models/invoice_item.dart';
import '../models/product.dart';
import 'database_helper.dart';

class InvoiceItemService
{
  static final dbHelper = DatabaseHelper();

  static Future<void> insertInvoiceItems(String invId,InvoiceItem item) async {
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
    List<InvoiceItem> items = [];

    for (var map in maps)
    {
      try
      {
        // final product = await getProductById(map['product_id'] as String);
        final product = Product.fromInvoiceItemsMap(map);
        items.add(
          InvoiceItem(
            product: product,
            quantity: map['quantity'] as int,
            discount: map['discount'] as double,
          ),
        );
      }
      catch (e, stackTrace)
      {
        print('Error parsing invoice item row: $e');
        print(stackTrace);
        // optionally continue, skip this row
        continue;
      }
    }

    return items;
  }
}