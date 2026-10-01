import 'package:invoiso/models/product.dart';
import 'package:sqflite/sqflite.dart';
import 'package:invoiso/models/product_list_stats.dart';
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

  static Future<List<Product>> getOutOfStockProducts() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'stock <= ? AND unlimited_stock = 0',
      whereArgs: [0],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return maps.map((p) => Product.fromMap(p)).toList();
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
      final queryLOwer = query.toLowerCase();
      final result = await db.query(
        'products',
        where: typeFilter != null
            ? '(LOWER(name) LIKE ? OR LOWER(hsncode) LIKE ?) AND type = ?'
            : 'LOWER(name) LIKE ? OR LOWER(hsncode) LIKE ?',
        whereArgs: typeFilter != null
            ? ['%$queryLOwer%', '%$queryLOwer%', typeFilter]
            : ['%$queryLOwer%', '%$queryLOwer%'],
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
    final queryLOwer = query.toLowerCase();
    if (query.isNotEmpty && typeFilter != null) {
      where = '(LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(hsncode) LIKE ?) AND type = ?';
      whereArgs = ['%$queryLOwer%', '%$queryLOwer%', '%$queryLOwer%', typeFilter];
    } else if (query.isNotEmpty) {
      where = 'LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(hsncode) LIKE ?';
      whereArgs = ['%$queryLOwer%', '%$queryLOwer%', '%$queryLOwer%'];
    } else if (typeFilter != null) {
      where = 'type = ?';
      whereArgs = [typeFilter];
    }

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: '$orderBy COLLATE NOCASE $order',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Product.fromMap(map)).toList();
  }

  static Future<int> getProductCount([String query = '', String? type]) async {
    final db = await dbHelper.database;
    final typeFilter = (type != null && type != 'both') ? type : null;
    final queryLOwer = query.toLowerCase();
    if (query.isNotEmpty && typeFilter != null) {
      return Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM products WHERE (LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(hsncode) LIKE ?) AND type = ?",
        ['%$queryLOwer%', '%$queryLOwer%', '%$queryLOwer%', typeFilter],
      ))!;
    } else if (query.isNotEmpty) {
      return Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM products WHERE LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(hsncode) LIKE ?",
        ['%$queryLOwer%', '%$queryLOwer%', '%$queryLOwer%'],
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

  // ─────────────────────────────────────────────
  // Product management list (Issues.md #42) — one page + counts in SQL,
  // instead of loading the whole catalog into memory. COALESCE defaults
  // mirror Product.fromMap so SQL and Dart agree on NULL legacy rows.

  static const _typeExpr = "COALESCE(type, 'product')";
  static const _trackedExpr = 'COALESCE(unlimited_stock, 0) = 0';
  static const _stockExpr = 'COALESCE(stock, 0)';
  // Only ISO-looking dates count (DateTime.tryParse fails on others).
  static const _expiredIdsSql = 'SELECT product_id FROM product_metadata '
      "WHERE expiry_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*' "
      'AND expiry_date < ?';

  /// [tab]: 'all' | 'product' | 'service' | 'low' | 'out' | 'expired'.
  static (String?, List<Object?>) _productListWhere(String query, String tab) {
    final parts = <String>[];
    final args = <Object?>[];
    if (query.trim().isNotEmpty) {
      final q = query
          .trim()
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      parts.add(r"(name LIKE ? ESCAPE '\' OR alias_name LIKE ? ESCAPE '\' "
          r"OR hsncode LIKE ? ESCAPE '\')");
      args.addAll(['%$q%', '%$q%', '%$q%']);
    }
    switch (tab) {
      case 'product':
      case 'service':
        parts.add('$_typeExpr = ?');
        args.add(tab);
      case 'low':
        parts.add('$_trackedExpr AND $_stockExpr > 0 AND $_stockExpr <= 10');
      case 'out':
        parts.add('$_trackedExpr AND $_stockExpr <= 0');
      case 'expired':
        parts.add('id IN ($_expiredIdsSql)');
        args.add(DateTime.now().toIso8601String());
    }
    return (parts.isEmpty ? null : parts.join(' AND '), args);
  }

  static Future<List<Product>> getProductListPage({
    required int offset,
    required int limit,
    String query = '',
    String tab = 'all',
    String orderBy = 'name', // 'name' | 'price' | 'stock'
    bool ascending = true,
  }) async {
    final db = await dbHelper.database;
    final (where, args) = _productListWhere(query, tab);
    final dir = ascending ? 'ASC' : 'DESC';
    final order = switch (orderBy) {
      'price' => 'COALESCE(price, 0) $dir',
      'stock' => '$_stockExpr $dir',
      _ => 'name COLLATE NOCASE $dir',
    };
    final maps = await db.query(
      'products',
      where: where,
      whereArgs: args,
      orderBy: '$order, id ASC', // id tie-break keeps pages stable
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  static Future<int> getProductListCount(
      {String query = '', String tab = 'all'}) async {
    final db = await dbHelper.database;
    final (where, args) = _productListWhere(query, tab);
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM products${where == null ? '' : ' WHERE $where'}',
      args,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  static Future<ProductListStats> getProductListStats() async {
    final db = await dbHelper.database;
    final r = (await db.rawQuery(
      'SELECT COUNT(*) AS all_count, '
      "COALESCE(SUM($_typeExpr = 'product'), 0) AS products, "
      "COALESCE(SUM($_typeExpr = 'service'), 0) AS services, "
      'COALESCE(SUM($_trackedExpr AND $_stockExpr > 0 AND $_stockExpr <= 10), 0) AS low_stock, '
      'COALESCE(SUM($_trackedExpr AND $_stockExpr <= 0), 0) AS out_of_stock, '
      'COALESCE(SUM(id IN ($_expiredIdsSql)), 0) AS expired '
      'FROM products',
      [DateTime.now().toIso8601String()],
    ))
        .first;
    int v(String k) => (r[k] as num?)?.toInt() ?? 0;
    return (
      all: v('all_count'),
      products: v('products'),
      services: v('services'),
      lowStock: v('low_stock'),
      outOfStock: v('out_of_stock'),
      expired: v('expired'),
    );
  }

  static Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await db.delete('product_metadata', where: 'product_id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // CRUD for ProductMetadata
  static Future<ProductMetadata?> getProductMetadata(String productId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'product_metadata',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return maps.isNotEmpty ? ProductMetadata.fromMap(maps.first) : null;
  }

  static Future<Map<String, ProductMetadata>> getAllProductMetadata() async {
    final db = await dbHelper.database;
    final maps = await db.query('product_metadata');
    return {
      for (final m in maps) m['product_id'] as String: ProductMetadata.fromMap(m)
    };
  }

  static Future<Map<String, ProductMetadata>> getProductMetadataForIds(
      List<String> productIds) async {
    if (productIds.isEmpty) return {};
    final db = await dbHelper.database;
    final maps = await queryInChunks(
      productIds,
      (chunk, placeholders) => db.query(
        'product_metadata',
        where: 'product_id IN ($placeholders)',
        whereArgs: chunk,
      ),
    );
    return {
      for (final m in maps) m['product_id'] as String: ProductMetadata.fromMap(m)
    };
  }

  static Future<void> upsertProductMetadata(ProductMetadata metadata) async {
    if (metadata.isEmpty) {
      await deleteProductMetadata(metadata.productId);
      return;
    }
    final db = await dbHelper.database;
    await db.insert(
      'product_metadata',
      metadata.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteProductMetadata(String productId) async {
    final db = await dbHelper.database;
    await db.delete('product_metadata', where: 'product_id = ?', whereArgs: [productId]);
  }

  static Future<void> updateProductStock(String id, int newStock) async {
    final db = await dbHelper.database;
    await db.update('products', {'stock': newStock},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> hasSufficientStock(String productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return false;
    return product.unlimitedStock || product.stock >= quantity;
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
