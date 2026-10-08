// Company picker labels vs. a company DB that only carries the seed
// placeholder name, including a registered company whose file went missing
// (Issues.md #74, #75). Real CompanyRegistryService + DatabaseHelper against
// ffi sqflite files in a temp dir; shared_preferences is mocked.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/company_registry_service.dart';
import 'package:invoiso/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_registry_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  // Registry: default company + "ANOOP P" (file `anoop_<n>.db`, not on disk).
  var counter = 0;
  late String anoopFile;
  setUp(() async {
    await DatabaseHelper().close();
    anoopFile = 'anoop_${counter++}.db';
    SharedPreferences.setMockInitialValues({
      'company_registry': jsonEncode([
        {
          'id': defaultCompanyId,
          'name': 'Your Company Name',
          'dbFileName': 'default_$counter.db',
          'createdAt': '2026-09-18T13:28:47.000',
        },
        {
          'id': 'anoop',
          'name': 'ANOOP P',
          'dbFileName': anoopFile,
          'createdAt': '2026-09-18T13:34:14.000',
        },
      ]),
      'active_company_id': defaultCompanyId,
    });
  });

  test('switching to a company whose file is missing names it from the registry',
      () async {
    await CompanyRegistryService.switchToCompany('anoop');

    expect((await CompanyInfoService.getCompanyInfo())!.name, 'ANOOP P');
    final active = (await CompanyRegistryService.listCompanies())
        .firstWhere((c) => c.id == 'anoop');
    expect(active.name, 'ANOOP P');
  });

  test('startup names a missing active company file from the registry',
      () async {
    await CompanyRegistryService.setActiveCompanyId('anoop');
    DatabaseHelper().setActiveFileNameBeforeFirstOpen(anoopFile);
    await CompanyRegistryService.nameActiveDbIfMissing();

    expect((await CompanyInfoService.getCompanyInfo())!.name, 'ANOOP P');
  });

  test('picker keeps the registry label while the DB has the placeholder',
      () async {
    await CompanyRegistryService.switchToCompany('anoop');
    final db = await DatabaseHelper().database;
    await db.update('company_info', {'name': seedCompanyName});

    final active = (await CompanyRegistryService.listCompanies())
        .firstWhere((c) => c.id == 'anoop');
    expect(active.name, 'ANOOP P');
  });

  test('picker shows the live name once the company is renamed in its DB',
      () async {
    await CompanyRegistryService.switchToCompany('anoop');
    final db = await DatabaseHelper().database;
    await db.update('company_info', {'name': 'Anoop Traders'});

    final active = (await CompanyRegistryService.listCompanies())
        .firstWhere((c) => c.id == 'anoop');
    expect(active.name, 'Anoop Traders');
  });

  test('renaming to the placeholder or an empty name keeps the real label',
      () async {
    await CompanyRegistryService.renameCompany('anoop', seedCompanyName);
    await CompanyRegistryService.renameCompany('anoop', '  ');

    final anoop = (await CompanyRegistryService.listCompanies())
        .firstWhere((c) => c.id == 'anoop');
    expect(anoop.name, 'ANOOP P');
  });

  test('a missing default company file keeps the seed placeholder', () async {
    await CompanyRegistryService.switchToCompany(defaultCompanyId);

    expect((await CompanyInfoService.getCompanyInfo())!.name, seedCompanyName);
  });
}
