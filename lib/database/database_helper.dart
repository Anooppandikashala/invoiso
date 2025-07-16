import 'dart:ffi';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:invoiceapp/models/customer.dart';
import 'package:invoiceapp/models/product.dart';
import 'package:invoiceapp/models/invoice.dart';
import 'package:invoiceapp/models/invoice_item.dart';

import '../models/company_info.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static String? _path;
  static String? get path => _path;
  static Database? _database;



  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    _path = join(await getDatabasesPath(), 'invoice_manager.db');
    return await openDatabase(
      _path!,
      version: 1,
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
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        stock INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        date TEXT,
        notes TEXT,
        taxRate REAL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
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
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE company_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        website TEXT
      )
    ''');

    // Insert dummy company info
    await db.insert('company_info', {
      'name': 'Your Company Name',
      'address': '123 Business Street\nCity, State 12345',
      'phone': '(555) 123-4567',
      'email': 'info@yourcompany.com',
      'website': 'www.yourcompany.com',
    });

    // Insert default admin user (for first-time login)
    await db.insert('users', {
      'id': 'user-001',
      'username': 'admin',
      'password': 'admin',
    });
  }

  // ─────────────────────────────────────────────
  // CRUD for Customer
  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', {
      'id': customer.id,
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'address': customer.address,
    });
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      {
        'name': customer.name,
        'email': customer.email,
        'phone': customer.phone,
        'address': customer.address,
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final c = maps.first;
      return Customer(
        id: c['id'] as String,
        name: c['name'] as String,
        email: c['email'] as String,
        phone: c['phone'] as String,
        address: c['address'] as String,
      );
    }
    return null;
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers');
    return maps
        .map((c) => Customer(
              id: c['id'] as String,
              name: c['name'] as String,
              email: c['email'] as String,
              phone: c['phone'] as String,
              address: c['address'] as String,
            ))
        .toList();
  }

  // ─────────────────────────────────────────────
  // CRUD for Product
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'stock': product.stock,
    });
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        stock: maps[i]['stock'],
      );
    });
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final p = maps.first;
      return Product(
        id: p['id'] as String,
        name: p['name'] as String,
        description: p['description'] as String,
        price: p['price'] as double,
        stock: p['stock'] as int,
      );
    }
    return null;
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'stock': product.stock,
      },
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

    return maps.map((map) => Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] as double,
      stock: map['stock'] as int,
    )).toList();
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
      'date': invoice.date.toIso8601String(),
      'notes': invoice.notes,
      'taxRate': invoice.taxRate,
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
    final invoiceData =
        await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (invoiceData.isEmpty) return null;

    final i = invoiceData.first;
    final customer = await getCustomerById(i['customer_id'] as String);

    final itemRows = await db
        .query('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    final items = <InvoiceItem>[];

    for (var row in itemRows) {
      final product = await getProductById(row['product_id'] as String);
      if (product != null) {
        items.add(InvoiceItem(
          product: product,
          quantity: row['quantity'] as int,
          discount: row['discount'] as double,
        ));
      }
    }

    return Invoice(
      id: id,
      customer: customer!,
      items: items,
      date: DateTime.parse(i['date'] as String),
      notes: i['notes'] as String?,
      taxRate: i['taxRate'] as double,
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
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'password': user.password,
    });
  }

  Future<User?> getUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      return User(
        id: user['id'] as String,
        username: user['username'] as String,
        password: user['password'] as String,
      );
    }

    return null;
  }

  // Get all invoices with customer and items
  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;

    final invoiceMaps = await db.query('invoices');
    List<Invoice> invoices = [];

    for (var map in invoiceMaps) {
      final customerId = map['customer_id'] as String?;
      final invoiceId = map['id'] as String?;
      final dateString = map['date'] as String?;
      final notes = map['notes'] as String?;
      final taxRateRaw = map['tax_rate'];

      if (customerId == null || invoiceId == null || dateString == null) {
        continue; // skip malformed rows
      }

      final customer = await getCustomerById(customerId);
      if (customer == null) continue;

      final items = await getInvoiceItemsByInvoiceId(invoiceId);

      invoices.add(
        Invoice(
          id: invoiceId,
          customer: customer,
          items: items,
          date: DateTime.tryParse(dateString) ?? DateTime.now(),
          notes: notes ?? '',
          taxRate: (taxRateRaw is int) ? taxRateRaw.toDouble() : (taxRateRaw as double? ?? 0.0),
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

  // ─────────────────────────────────────────────
  // Optional: Clear All Tables (For Debug)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('invoice_items');
    await db.delete('invoices');
    await db.delete('customers');
    await db.delete('products');
  }
}
