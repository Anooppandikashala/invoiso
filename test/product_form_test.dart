// Shared "add product" form (Product Management panel + New product dialog on
// Create Invoice / Purchase Bill): validators, duplicate-name warning,
// admin-only stock, and the dialog returning the saved product. Same ffi
// sqflite harness as invoice_update_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/widgets/product_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_product_form_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  var dbCounter = 0;
  setUp(() async {
    await DatabaseHelper().switchToFile('product_form_${dbCounter++}.db');
  });

  final admin =
      User(id: 'u1', username: 'admin', password: '', userType: 'admin');
  final staff =
      User(id: 'u2', username: 'staff', password: '', userType: 'user');

  // DB work is real I/O — let it finish outside the fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 40)));
      await tester.pump();
    }
  }

  Future<GlobalKey<ProductFormState>> pumpForm(
      WidgetTester tester, User user) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final key = GlobalKey<ProductFormState>();
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
              child: ProductForm(key: key, user: user)),
        ),
      ),
    ));
    await settle(tester);
    return key;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<Product?> submit(
      WidgetTester tester, GlobalKey<ProductFormState> key) async {
    Product? saved;
    var done = false;
    key.currentState!.submit().then((p) {
      saved = p;
      done = true;
    });
    // Poll rather than await: the save is real I/O, which an await in the
    // fake clock can wait on forever under a busy full-suite run.
    for (var i = 0; i < 100 && !done; i++) {
      await settle(tester);
    }
    return saved;
  }

  testWidgets('required fields block saving', (tester) async {
    final key = await pumpForm(tester, admin);
    expect(await submit(tester, key), isNull);
    expect(find.text('Please enter Name'), findsOneWidget);
  });

  testWidgets('saves a product with the entered values', (tester) async {
    final key = await pumpForm(tester, admin);
    await tester.enterText(field('Name'), 'Blue Pen');
    await tester.enterText(field('Sale Price'), '12.50');
    await tester.enterText(field('Purchase Price'), '8');
    await tester.enterText(field('Stock'), '40');

    final product = await submit(tester, key);
    expect(product, isNotNull);
    await tester.runAsync(() async {
      final saved = (await ProductService.getProductById(product!.id))!;
      expect(saved.name, 'Blue Pen');
      expect(saved.price, 12.5);
      expect(saved.purchasePrice, 8);
      expect(saved.stock, 40);
      expect(saved.tax_rate, 18);
    });
  });

  testWidgets('a double submit saves one product', (tester) async {
    final key = await pumpForm(tester, admin);
    await tester.enterText(field('Name'), 'Red Pen');
    await tester.enterText(field('Sale Price'), '12');
    await tester.enterText(field('Purchase Price'), '8');

    Product? first;
    var done = false;
    key.currentState!.submit().then((p) {
      first = p;
      done = true;
    });
    Product? second = Product(
        id: 'x', name: '', description: '', price: 0, stock: 0,
        hsncode: '', tax_rate: 0);
    key.currentState!.submit().then((p) => second = p);
    for (var i = 0; i < 100 && !done; i++) {
      await settle(tester);
    }
    expect(first, isNotNull);
    expect(second, isNull);
    await tester.runAsync(() async {
      final db = await DatabaseHelper().database;
      expect(await db.query('products', where: "name = 'Red Pen'"),
          hasLength(1));
    });
  });

  testWidgets('duplicate name warns; Create anyway saves', (tester) async {
    await tester.runAsync(() => ProductService.insertProduct(Product(
          id: 'p1',
          name: 'Blue Pen',
          description: '',
          price: 10,
          stock: 1,
          hsncode: '',
          tax_rate: 0,
        )));
    final key = await pumpForm(tester, admin);
    await tester.enterText(field('Name'), 'blue pen');
    await tester.enterText(field('Sale Price'), '12');
    await tester.enterText(field('Purchase Price'), '8');

    Product? saved;
    key.currentState!.submit().then((p) => saved = p);
    await settle(tester);
    expect(find.text('Product already exists'), findsOneWidget);
    await tester.tap(find.text('Create anyway'));
    await settle(tester);
    expect(saved, isNotNull);
    expect(saved!.name, 'blue pen');
  });

  testWidgets('non-admin with stock locked saves stock 0', (tester) async {
    await tester.runAsync(() => SettingsService.setProductColumnsConfig(
        const ProductColumnsConfig(stockEditAdminOnly: true)));
    final key = await pumpForm(tester, staff);
    await tester.enterText(field('Name'), 'Locked Item');
    await tester.enterText(field('Sale Price'), '5');
    await tester.enterText(field('Purchase Price'), '3');

    final product = await submit(tester, key);
    expect(product, isNotNull);
    expect(product!.stock, 0);
  });

  testWidgets('New product dialog returns the saved product', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Product? result;
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showNewProductDialog(
                  context,
                  user: admin,
                  initialName: 'Notebook'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);

    // Typed search text prefills the name.
    expect(find.text('Notebook'), findsOneWidget);
    await tester.enterText(field('Sale Price'), '30');
    await tester.enterText(field('Purchase Price'), '20');
    await tester.tap(find.text('Save Product'));
    await settle(tester);

    expect(result, isNotNull);
    expect(result!.name, 'Notebook');
    expect(find.byType(AlertDialog), findsNothing);
  });
}
