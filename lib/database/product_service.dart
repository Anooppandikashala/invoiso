import 'package:invoiso/models/product.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class ProductService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // CRUD for Product
  static Future<void> insertProduct(Product product) async {
    final db = await dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
    );
  }

  static Future<List<Product>> getAllProducts() async {
    final db = await dbHelper.database;
    final maps = await db.query('products');

    if (maps.isEmpty) return [];
    return maps.map((p) => Product.fromMap(p)).toList();
  }

  static Future<int> getTotalProductCount() async {
    final db = await dbHelper.database; // your initialized Database object
    final result = await db.rawQuery('SELECT COUNT(*) FROM products');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  static Future<Product?> getProductById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> updateProduct(Product product) async {
    final db = await dbHelper.database;

    // Create a map without the 'id' field
    final updateMap = product.toMap();
    updateMap.remove('id');

    await db.update(
      'products',
      updateMap,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  static Future<List<Product>> getProductsPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
  }) async {
    final db = await dbHelper.database;

    final maps = await db.query(
      'products',
      where: query.isNotEmpty ? 'name LIKE ? OR description LIKE ?' : null,
      whereArgs: query.isNotEmpty ? ['%$query%', '%$query%'] : null,
      orderBy: '$orderBy ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<int> getProductCount([String query = '']) async {
    final db = await dbHelper.database;
    return Sqflite.firstIntValue(await db.rawQuery(
      query.isNotEmpty
          ? "SELECT COUNT(*) FROM products WHERE name LIKE ? OR description LIKE ?"
          : "SELECT COUNT(*) FROM products",
      query.isNotEmpty ? ['%$query%', '%$query%'] : null,
    ))!;
  }

  static Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateProductStock(String id, int newStock) async {
    final db = await dbHelper.database;
    await db.update('products', {'stock': newStock},
        where: 'id = ?', whereArgs: [id]);
  }
}