import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
  final dbVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // _path = join(await getDatabasesPath(), 'invoice_manager.db');
    // _path = join(Directory.current.path, 'invoice_manager.db');
    final dbDir = await getApplicationSupportDirectory(); // from path_provider
    _path = join(dbDir.path, 'invoice_manager.db');
    return await openDatabase(
      _path!,
      version: dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        product_name TEXT,
        product_description TEXT,
        product_price REAL,
        product_tax_rate INTEGER,
        product_hsn_code TEXT,
        quantity INTEGER,
        discount REAL,
        PRIMARY KEY (invoice_id, product_id),
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
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

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async
  {
    print('Upgrading database from $oldVersion to $newVersion');

    // TODO

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

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
