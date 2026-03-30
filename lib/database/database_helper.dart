import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import '../utils/password_utils.dart';

const _tag = 'DatabaseHelper';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static String? _path;
  static String? get path => _path;
  static Database? _database;
  final dbVersion = 9;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbDir = await getApplicationSupportDirectory();
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
        type TEXT,
        currency_code TEXT DEFAULT 'INR',
        currency_symbol TEXT DEFAULT '₹',
        tax_mode TEXT DEFAULT 'global',
        deleted_at TEXT
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
        user_type TEXT,
        salt TEXT,
        password_changed INTEGER NOT NULL DEFAULT 1
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

    await db.execute('''
      CREATE TABLE _migration_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version INTEGER,
        step TEXT,
        status TEXT,
        message TEXT,
        applied_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_payments (
        id               TEXT PRIMARY KEY,
        invoice_id       TEXT NOT NULL,
        invoice_number   TEXT NOT NULL,
        receipt_number   TEXT NOT NULL,
        amount_paid      REAL NOT NULL,
        tax_amount_paid  REAL NOT NULL DEFAULT 0,
        previously_paid  REAL NOT NULL DEFAULT 0,
        balance_after    REAL NOT NULL,
        date_paid        TEXT NOT NULL,
        payment_method   TEXT,
        notes            TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_invoices_customer ON invoices(customer_name)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(date)');
    await db.execute('CREATE INDEX idx_invoices_type ON invoices(type)');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)');
    await db.execute('CREATE INDEX idx_payments_invoice ON invoice_payments(invoice_id)');
    await db.execute('CREATE INDEX idx_payments_date ON invoice_payments(date_paid)');

    // Insert dummy company info
    await db.insert('company_info', {
      'name': 'Your Company Name',
      'address': '123 Street \nCity, State 12345',
      'phone': '9876543210',
      'email': 'info@yourcompany.com',
      'website': 'www.yourcompany.com',
      'gstin': ''
    });

    // Insert default admin user with salted hash
    final salt = PasswordUtils.generateSalt();
    final hashedPw = PasswordUtils.hashWithSalt('admin', salt);
    await db.insert('users', {
      'id': 'user-001',
      'username': 'admin',
      'password': hashedPw,
      'user_type': 'admin',
      'salt': salt,
      'password_changed': 0,
    });

    // Insert default template
    await db.insert('settings', {'key': 'invoice_template', 'value': 'classic'});

    // Insert default currency
    await db.insert('settings', {'key': 'currency', 'value': 'INR'});
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.d(_tag, 'Upgrading database from $oldVersion to $newVersion');

    // Ensure migration log table exists before logging anything
    await db.execute('''
      CREATE TABLE IF NOT EXISTS _migration_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version INTEGER,
        step TEXT,
        status TEXT,
        message TEXT,
        applied_at TEXT
      )
    ''');

    if (oldVersion < 5) {
      await _runMigrationStep(db, 5, 'add_currency_columns', () async {
        await db.execute(
          "ALTER TABLE invoices ADD COLUMN currency_code TEXT DEFAULT 'INR'",
        );
        await db.execute(
          "ALTER TABLE invoices ADD COLUMN currency_symbol TEXT DEFAULT '₹'",
        );
        await db.insert(
          'settings',
          {'key': 'currency', 'value': 'INR'},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      });
    }

    if (oldVersion < 6) {
      await _runMigrationStep(db, 6, 'add_tax_mode_column', () async {
        await db.execute(
          "ALTER TABLE invoices ADD COLUMN tax_mode TEXT DEFAULT 'global'",
        );
      });
    }

    if (oldVersion < 7) {
      await _runMigrationStep(db, 7, 'hash_plain_passwords', () async {
        final users = await db.query('users');
        for (final user in users) {
          final plainPw = user['password'] as String;
          if (plainPw.length != 64) {
            await db.update(
              'users',
              {'password': PasswordUtils.hash(plainPw)},
              where: 'id = ?',
              whereArgs: [user['id']],
            );
          }
        }
      });
    }

    if (oldVersion < 8) {
      await _runMigrationStep(db, 8, 'add_salt_and_password_changed', () async {
        await db.execute(
          'ALTER TABLE users ADD COLUMN salt TEXT',
        );
        await db.execute(
          'ALTER TABLE users ADD COLUMN password_changed INTEGER NOT NULL DEFAULT 1',
        );
        // Force admin to reset password on next login
        await db.execute(
          "UPDATE users SET password_changed = 0 WHERE username = 'admin'",
        );
      });

      await _runMigrationStep(db, 8, 'add_deleted_at_column', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN deleted_at TEXT',
        );
      });

      await _runMigrationStep(db, 8, 'add_indexes', () async {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_name)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(date)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_invoices_type ON invoices(type)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id)',
        );
      });
    }

    if (oldVersion < 9) {
      await _runMigrationStep(db, 9, 'create_invoice_payments_table', () async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS invoice_payments (
            id               TEXT PRIMARY KEY,
            invoice_id       TEXT NOT NULL,
            invoice_number   TEXT NOT NULL,
            receipt_number   TEXT NOT NULL,
            amount_paid      REAL NOT NULL,
            tax_amount_paid  REAL NOT NULL DEFAULT 0,
            previously_paid  REAL NOT NULL DEFAULT 0,
            balance_after    REAL NOT NULL,
            date_paid        TEXT NOT NULL,
            payment_method   TEXT,
            notes            TEXT,
            FOREIGN KEY (invoice_id) REFERENCES invoices(id)
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_invoice ON invoice_payments(invoice_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_date ON invoice_payments(date_paid)',
        );
      });
    }
  }

  Future<void> _runMigrationStep(
    Database db,
    int version,
    String step,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      await db.insert('_migration_log', {
        'version': version,
        'step': step,
        'status': 'success',
        'message': null,
        'applied_at': DateTime.now().toIso8601String(),
      });
      AppLogger.d(_tag, 'Migration v$version/$step: success');
    } catch (e, stack) {
      AppLogger.e(_tag, 'Migration v$version/$step failed', e, stack);
      await db.insert('_migration_log', {
        'version': version,
        'step': step,
        'status': 'failure',
        'message': e.toString(),
        'applied_at': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
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

  /// Closes the current connection, clears the singleton reference, and
  /// re-opens a fresh connection. Call this after the DB file is replaced
  /// (e.g. after a backup restore).
  Future<Database> reinitialize() async {
    await close();
    _database = await _initDB();
    return _database!;
  }
}
