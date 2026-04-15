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

  static Future<List<Product>> searchProducts(String query, {String? type}) async {
    final db = await dbHelper.database;
    final typeFilter = (type != null && type != 'both') ? type : null;
    if (query.isEmpty) {
      final result = await db.query(
        'products',
        where: typeFilter != null ? 'type = ?' : null,
        whereArgs: typeFilter != null ? [typeFilter] : null,
      );
      return result.map((e) => Product.fromMap(e)).toList();
    } else {
      final result = await db.query(
        'products',
        where: typeFilter != null
            ? '(LOWER(name) LIKE ? OR hsncode LIKE ?) AND type = ?'
            : 'LOWER(name) LIKE ? OR hsncode LIKE ?',
        whereArgs: typeFilter != null
            ? ['%${query.toLowerCase()}%', '%$query%', typeFilter]
            : ['%${query.toLowerCase()}%', '%$query%'],
      );
      return result.map((e) => Product.fromMap(e)).toList();
    }
  }

  static Future<List<Product>> getProductsPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
    String? type,
  }) async {
    final db = await dbHelper.database;
    final order = orderASC ? "ASC" : "DESC";
    final typeFilter = (type != null && type != 'both') ? type : null;

    String? where;
    List<dynamic>? whereArgs;
    if (query.isNotEmpty && typeFilter != null) {
      where = '(name LIKE ? OR description LIKE ?) AND type = ?';
      whereArgs = ['%$query%', '%$query%', typeFilter];
    } else if (query.isNotEmpty) {
      where = 'name LIKE ? OR description LIKE ?';
      whereArgs = ['%$query%', '%$query%'];
    } else if (typeFilter != null) {
      where = 'type = ?';
      whereArgs = [typeFilter];
    }

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: '$orderBy $order',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<int> getProductCount([String query = '', String? type]) async {
    final db = await dbHelper.database;
    final typeFilter = (type != null && type != 'both') ? type : null;

    if (query.isNotEmpty && typeFilter != null) {
      return Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM products WHERE (name LIKE ? OR description LIKE ?) AND type = ?",
        ['%$query%', '%$query%', typeFilter],
      ))!;
    } else if (query.isNotEmpty) {
      return Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM products WHERE name LIKE ? OR description LIKE ?",
        ['%$query%', '%$query%'],
      ))!;
    } else if (typeFilter != null) {
      return Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM products WHERE type = ?",
        [typeFilter],
      ))!;
    }
    return Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM products"))!;
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

  static Future<bool> hasSufficientStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return false;
    return product.stock >= quantity;
  }

  /// Find an existing product by name (case-insensitive).
  static Future<Product?> findDuplicateByName(String name) async {
    if (name.trim().isEmpty) return null;
    final db = await dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'LOWER(name) = ?',
      whereArgs: [name.trim().toLowerCase()],
      limit: 1,
    );
    return maps.isNotEmpty ? Product.fromMap(maps.first) : null;
  }

  static Future<void> deleteAllProducts() async {
    final db = await dbHelper.database;
    await db.delete('products');
  }

  /// Insert products in batches of [batchSize] rows per transaction.
  static Future<void> insertBatch(List<Product> products,
      {int batchSize = 50}) async {
    final db = await dbHelper.database;
    for (int i = 0; i < products.length; i += batchSize) {
      final chunk =
          products.sublist(i, (i + batchSize).clamp(0, products.length));
      await db.transaction((txn) async {
        for (final p in chunk) {
          await txn.insert('products', p.toMap());
        }
      });
    }
  }
}