import 'dart:ffi';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';

import '../common.dart';
import '../models/company_info.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static String? _path;
  static String? get path => _path;
  static Database? _database;
  final dbVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    _path = join(await getDatabasesPath(), 'invoice_manager.db');
    return await openDatabase(
      _path!,
      version: dbVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        gstin TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        stock INTEGER,
        hsncode TEXT,
        tax_rate INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        customer_name TEXT,
        customer_email TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        customer_gstin TEXT,
        date TEXT,
        notes TEXT,
        tax_rate REAL,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        invoice_id TEXT,
        product_id TEXT,
        quantity INTEGER,
        discount REAL,
        PRIMARY KEY (invoice_id, product_id),
        FOREIGN KEY (invoice_id) REFERENCES invoices(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE,
        password TEXT,
        user_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE company_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        website TEXT,
        gstin TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert dummy company info
    await db.insert('company_info', {
      'name': 'Your Company Name',
      'address': '123 Street \nCity, State 12345',
      'phone': '9876543210',
      'email': 'info@yourcompany.com',
      'website': 'www.yourcompany.com',
      'gstin': ''
    });

    // Insert default admin user (for first-time login)
    await db.insert('users', {
      'id': 'user-001',
      'username': 'admin',
      'password': 'admin',
      'user_type': 'admin'
    });

    // Insert default template
    await db.insert('settings', {
      'key': 'invoice_template',
      'value': 'classic'
    });
  }

  // ─────────────────────────────────────────────
  // CRUD for Customer
  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
      //conflictAlgorithm: ConflictAlgorithm.replace, // optional, avoids duplicate ID errors
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;

    // Create a map without 'id' for update
    final updateMap = customer.toMap()..remove('id');

    await db.update(
      'customers',
      updateMap,
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }


  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers');
    return maps.map((c) => Customer.fromMap(c)).toList();
  }

  // ─────────────────────────────────────────────
  // CRUD for Product
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products');

    if (maps.isEmpty) return [];
    return maps.map((p) => Product.fromMap(p)).toList();
  }

  Future<int> getTotalProductCount() async {
    final db = await database; // your initialized Database object
    final result = await db.rawQuery('SELECT COUNT(*) FROM products');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  Future<int> getTotalCustomerCount() async {
    final db = await database; // your initialized Database object
    final result = await db.rawQuery('SELECT COUNT(*) FROM customers');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
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

  Future<void> updateProduct(Product product) async {
    final db = await database;

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

  Future<List<Product>> getProductsPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
  }) async {
    final db = await database;

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

  Future<int> getProductCount([String query = '']) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
      query.isNotEmpty
          ? "SELECT COUNT(*) FROM products WHERE name LIKE ? OR description LIKE ?"
          : "SELECT COUNT(*) FROM products",
      query.isNotEmpty ? ['%$query%', '%$query%'] : null,
    ))!;
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductStock(String id, int newStock) async {
    final db = await database;
    await db.update('products', {'stock': newStock},
        where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // Insert Invoice + Items + Stock Deduction
  Future<void> insertInvoice(Invoice invoice) async {
    final db = await database;
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
      'type':invoice.type
    });

    for (var item in invoice.items) {
      await db.insert('invoice_items', {
        'invoice_id': invoice.id,
        'product_id': item.product.id,
        'quantity': item.quantity,
        'discount': item.discount,
      });

      // Deduct stock
      final product = await getProductById(item.product.id);
      if (product != null) {
        final newStock = product.stock - item.quantity;
        await updateProductStock(product.id, newStock);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Fetch Invoice with Items
  Future<Invoice?> getInvoiceById(String id) async {
    final db = await database;

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
      final product = await getProductById(row['product_id'] as String);
      if (product != null) {
        items.add(InvoiceItem(
          product: product,
          quantity: row['quantity'] as int,
          discount: (row['discount'] is int)
              ? (row['discount'] as int).toDouble()
              : (row['discount'] ?? 0.0) as double,
        ));
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
    );
  }


  // ─────────────────────────────────────────────
  // Delete Invoice
  Future<void> deleteInvoice(String id) async {
    final db = await database;
    await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // CRUD for User
  Future<User?> getUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      return User.fromMap(user);
    }

    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> updatePassword(String id, String newPassword) async {
    final db = await database;
    await db.update('users', {'password': newPassword}, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> userExists(String userId) async {
    final db = await database;

    try {
      final result = await db.query(
        'users', // Replace with your actual table name
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  Future<int> _deleteUser(String userId) async {
    final db = await database;

    try {
      // Delete the user from the database
      int result = await db.delete(
        'users', // Replace with your actual table name
        where: 'id = ?',
        whereArgs: [userId],
      );

      print('User deleted successfully. Rows affected: $result');
      return result;
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<bool> deleteUserSafely(String userId) async {
    try {
      // Check if user exists first
      bool exists = await userExists(userId);
      if (!exists) {
        print('User with ID $userId does not exist');
        return false;
      }

      // Delete the user
      int result = await _deleteUser(userId);
      return result > 0;
    } catch (e) {
      print('Error in safe delete: $e');
      return false;
    }
  }


  // Get all invoices with customer and items
  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
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
      final items = await getInvoiceItemsByInvoiceId(invoiceId);

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
        ),
      );
    }

    return invoices;
  }



  Future<List<InvoiceItem>> getInvoiceItemsByInvoiceId(String invoiceId) async {
    final db = await database;
    final maps = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    List<InvoiceItem> items = [];

    for (var map in maps) {
      final product = await getProductById(map['product_id'] as String);
      if (product != null) {
        items.add(
          InvoiceItem(
            product: product,
            quantity: map['quantity'] as int,
            discount: map['discount'] as double,
          ),
        );
      }
    }

    return items;
  }


  Future<CompanyInfo?> getCompanyInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('company_info', limit: 1);

    if (result.isNotEmpty) {
      return CompanyInfo.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertCompanyInfo(CompanyInfo info) async {
    final db = await database;
    return await db.insert('company_info', info.toMap());
  }

  Future<int> updateCompanyInfo(CompanyInfo info) async {
    final db = await database;
    return await db.update(
      'company_info',
      info.toMap(),
      where: 'id = ?',
      whereArgs: [info.id],
    );
  }

  Future<void> setInvoiceTemplate(InvoiceTemplate template) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'invoice_template', 'value': template.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<InvoiceTemplate> getInvoiceTemplate() async {
    final db = await database;
    final result = await db.query('settings',
        where: 'key = ?', whereArgs: ['invoice_template']);

    if (result.isNotEmpty) {
      return InvoiceTemplate.values.firstWhere(
            (e) => e.name == result.first['value'],
        orElse: () => InvoiceTemplate.classic,
      );
    }
    return InvoiceTemplate.classic;
  }

  Future<void> setCompanyLogo(String base64Logo) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'company_logo', 'value': base64Logo},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCompanyLogo() async {
    final db = await database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: ['company_logo']);
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  // ─────────────────────────────────────────────
  // Optional: Clear All Tables (For Debug)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('invoice_items');
    await db.delete('invoices');
    await db.delete('customers');
    await db.delete('products');
    await db.delete('users');
  }
}
