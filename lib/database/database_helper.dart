import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:invoiso/utils/app_logger.dart';
import 'package:invoiso/utils/password_utils.dart';

const _tag = 'DatabaseHelper';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static String? _path;
  static String? get path => _path;
  static Database? _database;
  final dbVersion = 32;

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

  @visibleForTesting
  Future<void> createDbForTest(Database db, int version) =>
      _createDB(db, version);

  @visibleForTesting
  Future<void> upgradeDbForTest(Database db, int oldVersion, int newVersion) =>
      _upgradeDB(db, oldVersion, newVersion);

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        gstin TEXT,
        business_name TEXT DEFAULT ''
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
        tax_rate INTEGER,
        type TEXT DEFAULT 'product',
        default_discount REAL DEFAULT 0,
        purchase_price REAL DEFAULT 0.0,
        alias_name TEXT,
        unit TEXT DEFAULT ''
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
        customer_business_name TEXT DEFAULT '',
        date TEXT,
        notes TEXT,
        tax_rate REAL,
        type TEXT,
        currency_code TEXT DEFAULT 'INR',
        currency_symbol TEXT DEFAULT '₹',
        tax_mode TEXT DEFAULT 'global',
        deleted_at TEXT,
        upi_id TEXT,
        bank_account_id TEXT,
        due_date TEXT,
        quantity_label TEXT,
        additional_costs TEXT,
        previous_balance REAL DEFAULT 0.0,
        invoice_number TEXT
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
        quantity REAL,
        discount REAL,
        unit_price REAL,
        extra_cost REAL,
        discount_per_unit INTEGER DEFAULT 0,
        is_product_saved INTEGER DEFAULT 0,
        product_type TEXT DEFAULT 'product',
        product_purchase_price REAL DEFAULT 0.0,
        product_alias_name TEXT,
        product_unit TEXT DEFAULT '',
        unit TEXT,
        PRIMARY KEY (invoice_id, product_id)
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
        gstin TEXT,
        pan_number TEXT DEFAULT '',
        country TEXT DEFAULT 'India'
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
        notes            TEXT
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
            notes            TEXT
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

    if (oldVersion < 10) {
      await _runMigrationStep(db, 10, 'add_upi_id_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN upi_id TEXT',
        );
      });
    }

    if (oldVersion < 11) {
      await _runMigrationStep(db, 11, 'add_due_date_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN due_date TEXT',
        );
      });
    }

    if (oldVersion < 12) {
      await _runMigrationStep(db, 12, 'add_unit_price_to_invoice_items', () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN unit_price REAL',
        );
      });
    }

    if (oldVersion < 13) {
      await _runMigrationStep(db, 13, 'add_extra_cost_to_invoice_items', () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN extra_cost REAL',
        );
      });
      await _runMigrationStep(db, 13, 'add_quantity_label_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN quantity_label TEXT',
        );
      });
    }

    if (oldVersion < 14) {
      await _runMigrationStep(db, 14, 'add_discount_per_unit_to_invoice_items', () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN discount_per_unit INTEGER DEFAULT 0',
        );
      });
    }

    if (oldVersion < 15) {
      await _runMigrationStep(db, 15, 'add_additional_costs_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN additional_costs TEXT',
        );
      });
    }

    if (oldVersion < 16) {
      await _runMigrationStep(db, 16, 'add_business_name_to_customers', () async {
        await db.execute(
          "ALTER TABLE customers ADD COLUMN business_name TEXT DEFAULT ''",
        );
      });
      await _runMigrationStep(db, 16, 'add_customer_business_name_to_invoices', () async {
        await db.execute(
          "ALTER TABLE invoices ADD COLUMN customer_business_name TEXT DEFAULT ''",
        );
      });
      await _runMigrationStep(db, 16, 'add_country_to_company_info', () async {
        await db.execute(
          "ALTER TABLE company_info ADD COLUMN country TEXT DEFAULT 'India'",
        );
      });
    }

    if (oldVersion < 17) {
      await _runMigrationStep(db, 17, 'add_is_product_saved_to_invoice_items', () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN is_product_saved INTEGER DEFAULT 0',
        );
      });
    }

    if (oldVersion < 18) {
      await _runMigrationStep(db, 18, 'add_type_to_products', () async {
        await db.execute(
          "ALTER TABLE products ADD COLUMN type TEXT DEFAULT 'product'",
        );
      });
      await _runMigrationStep(db, 18, 'add_product_type_to_invoice_items', () async {
        await db.execute(
          "ALTER TABLE invoice_items ADD COLUMN product_type TEXT DEFAULT 'product'",
        );
      });
    }

    if (oldVersion < 19) {
      await _runMigrationStep(db, 19, 'add_default_discount_to_products', () async {
        await db.execute(
          'ALTER TABLE products ADD COLUMN default_discount REAL DEFAULT 0',
        );
      });
    }

    if (oldVersion < 20) {
      await _runMigrationStep(db, 20, 'add_bank_account_id_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN bank_account_id TEXT',
        );
      });
    }

    if (oldVersion < 21) {
      await _runMigrationStep(db, 21, 'add_previous_balance_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN previous_balance REAL DEFAULT 0.0',
        );
      });
    }

    if (oldVersion < 24) {
      await _runMigrationStep(
          db, 22, 'add_pan_number_to_company_info', () async {
        await db.execute(
          "ALTER TABLE company_info ADD COLUMN pan_number TEXT DEFAULT ''",
        );
      });
    }

    if (oldVersion < 25) {
      await _runMigrationStep(db, 23, 'add_invoice_number_to_invoices', () async {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN invoice_number TEXT',
        );
      });
    }

    if (oldVersion < 26) {
      await _runMigrationStep(db, 24, 'add_purchase_price_to_products', () async {
        await db.execute(
          'ALTER TABLE products ADD COLUMN purchase_price REAL DEFAULT 0.0',
        );
      });
      await _runMigrationStep(
          db, 25, 'add_product_purchase_price_to_invoice_items', () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN product_purchase_price REAL DEFAULT 0.0',
        );
      });
    }

    if (oldVersion < 30)
    {
      await _runMigrationStep(db, 30, 'add_unit_to_products', () async {
        await db.execute(
          "ALTER TABLE products ADD COLUMN unit TEXT DEFAULT ''",
        );
      });
      await _runMigrationStep(
          db, 30, 'add_product_unit_to_invoice_items', () async {
        await db.execute(
          "ALTER TABLE invoice_items ADD COLUMN product_unit TEXT DEFAULT ''",
        );
      });
      await _runMigrationStep(db, 30, 'add_unit_override_to_invoice_items',
          () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN unit TEXT',
        );
      });
    }

    if(oldVersion < 32)
    {
      await _runMigrationStep(db, 32, 'add_alias_name_to_products', () async {
        await db.execute(
          'ALTER TABLE products ADD COLUMN alias_name TEXT',
        );
      });
      await _runMigrationStep(
          db, 32, 'add_product_alias_name_to_invoice_items', () async {
        await db.execute(
          'ALTER TABLE invoice_items ADD COLUMN product_alias_name TEXT',
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
      // Treat already-applied schema changes as success so a partial prior run
      // doesn't block startup (e.g. column added but version not yet bumped).
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate column name') ||
          msg.contains('already exists')) {
        AppLogger.d(_tag, 'Migration v$version/$step: already applied, skipping');
        await db.insert('_migration_log', {
          'version': version,
          'step': step,
          'status': 'skipped',
          'message': e.toString(),
          'applied_at': DateTime.now().toIso8601String(),
        });
        return;
      }
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
