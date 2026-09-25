import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/common/setting_key.dart';
import 'package:invoiso/models/company_profile.dart';

const defaultCompanyId = 'default';
const _defaultDbFileName = 'invoice_manager.db';
const _registryPrefsKey = 'company_registry';
const _activeCompanyIdPrefsKey = 'active_company_id';
const _installationIdPrefsKey = 'installation_id';

/// Device-level registry of companies (each backed by its own SQLite file —
/// see `DatabaseHelper`), plus the device-level data that must NOT live
/// inside any single company's database: which company is currently active,
/// and this installation's anonymous id. Stored in `shared_preferences`,
/// entirely separate from any company's own `settings` table.
class CompanyRegistryService {
  static Future<String> _dbDirPath() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  static Future<List<CompanyProfile>> _readRegistry(SharedPreferences prefs) async {
    final raw = prefs.getString(_registryPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CompanyProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _writeRegistry(
      SharedPreferences prefs, List<CompanyProfile> companies) async {
    final raw = jsonEncode(companies.map((c) => c.toJson()).toList());
    await prefs.setString(_registryPrefsKey, raw);
  }

  /// Call once at startup, before anything reads "active company". Seeds a
  /// single registry entry pointing at the existing default database file so
  /// the migration is invisible to installs that predate multi-company
  /// support — no file is moved or renamed.
  static Future<void> ensureDefaultCompanyRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _readRegistry(prefs);
    if (existing.isNotEmpty) return;

    final name = await _readDefaultCompanyName() ?? 'My Company';
    final profile = CompanyProfile(
      id: defaultCompanyId,
      name: name,
      dbFileName: _defaultDbFileName,
      createdAt: DateTime.now(),
    );
    await _writeRegistry(prefs, [profile]);
    await prefs.setString(_activeCompanyIdPrefsKey, defaultCompanyId);
  }

  /// Reads `company_info.name` from the default company's file via a
  /// throwaway read-only connection — never touches the `DatabaseHelper`
  /// singleton. Returns null if the file doesn't exist yet (true first-run)
  /// or anything about it can't be read.
  static Future<String?> _readDefaultCompanyName() =>
      _readFromDefaultDbIfExists((db) async {
        final rows = await db.query('company_info', limit: 1);
        if (rows.isEmpty) return null;
        final name = rows.first['name'] as String?;
        return (name == null || name.isEmpty) ? null : name;
      });

  static Future<T?> _readFromDefaultDbIfExists<T>(
      Future<T?> Function(Database db) reader) async {
    final path = join(await _dbDirPath(), _defaultDbFileName);
    if (!await File(path).exists()) return null;
    // singleInstance: false — otherwise sqflite hands back DatabaseHelper's
    // already-open connection for this path, and the close() below kills it.
    final db = await openDatabase(path, readOnly: true, singleInstance: false);
    try {
      return await reader(db);
    } catch (_) {
      return null;
    } finally {
      await db.close();
    }
  }

  static Future<List<CompanyProfile>> listCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await _readRegistry(prefs);
    final activeId = prefs.getString(_activeCompanyIdPrefsKey);
    if (activeId == null) return companies;

    // The active company's label can drift from what it was called at
    // creation time (onboarding writes the real business name into that
    // company's own `company_info`, not into this registry) — resolve it
    // live so it never looks stale. Non-active companies keep their stored
    // label; their database isn't open, so there's nothing fresher to read.
    final activeInfo = await CompanyInfoService.getCompanyInfo();
    final activeName = activeInfo?.name;
    if (activeName == null || activeName.isEmpty) return companies;

    return [
      for (final c in companies)
        c.id == activeId ? c.copyWith(name: activeName) : c,
    ];
  }

  static Future<String?> getActiveCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeCompanyIdPrefsKey);
  }

  /// Active company's display name, live-resolved the same way
  /// [listCompanies] resolves it for the active entry.
  static Future<String> getActiveCompanyName() async {
    final companies = await listCompanies();
    final activeId = await getActiveCompanyId();
    return companies.where((c) => c.id == activeId).firstOrNull?.name ??
        'My Company';
  }

  static Future<void> setActiveCompanyId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCompanyIdPrefsKey, id);
  }

  /// Registers a new company and its own database file. Does not switch to
  /// it — call `switchToCompany` afterwards.
  static Future<CompanyProfile> createCompany(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await _readRegistry(prefs);
    final id = const Uuid().v4();
    final profile = CompanyProfile(
      id: id,
      name: name,
      dbFileName: 'invoice_manager_$id.db',
      createdAt: DateTime.now(),
    );
    await _writeRegistry(prefs, [...companies, profile]);
    return profile;
  }

  static Future<void> renameCompany(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await _readRegistry(prefs);
    await _writeRegistry(prefs, [
      for (final c in companies) c.id == id ? c.copyWith(name: name) : c,
    ]);
  }

  /// Refuses to delete the active company or the last remaining one —
  /// callers are expected to check `canDelete` first and disable the action,
  /// this is the hard guarantee.
  static Future<void> deleteCompany(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await _readRegistry(prefs);
    final activeId = prefs.getString(_activeCompanyIdPrefsKey);
    if (id == activeId) {
      throw StateError('Cannot delete the active company.');
    }
    if (companies.length <= 1) {
      throw StateError('Cannot delete the only remaining company.');
    }
    final target = companies.where((c) => c.id == id).firstOrNull;
    if (target == null) return;

    await _writeRegistry(prefs, [
      for (final c in companies) if (c.id != id) c,
    ]);

    final path = join(await _dbDirPath(), target.dbFileName);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Points `DatabaseHelper` at the given company's file and marks it
  /// active. Safe to call whether or not a connection is already open.
  static Future<void> switchToCompany(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await _readRegistry(prefs);
    final profile = companies.where((c) => c.id == id).firstOrNull;
    if (profile == null) {
      throw ArgumentError('Unknown company id: $id');
    }
    await DatabaseHelper().switchToFile(profile.dbFileName);
    await prefs.setString(_activeCompanyIdPrefsKey, id);
  }

  /// The active company's own file name, for pointing `DatabaseHelper` at
  /// the right file before it's opened for the very first time at startup.
  static Future<String> getActiveCompanyDbFileName() async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await _readRegistry(prefs);
    final activeId = prefs.getString(_activeCompanyIdPrefsKey);
    final profile = companies.where((c) => c.id == activeId).firstOrNull;
    return profile?.dbFileName ?? _defaultDbFileName;
  }

  /// Unique identifier for this installation — device-level, so it stays
  /// stable across company switches. Used for anonymous analytics and the
  /// offline forgot-password reset-code scheme, both of which need one
  /// consistent id regardless of which company is currently active.
  static Future<String> getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationIdPrefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Pre-multi-company installs already generated one, stored inside the
    // default company's own settings table — migrate it forward so nobody's
    // reset-code identity or analytics id changes underneath them.
    final legacy = await _readFromDefaultDbIfExists((db) async {
      final rows = await db.query('settings',
          where: 'key = ?', whereArgs: [SettingKey.installationId.key]);
      if (rows.isEmpty) return null;
      return rows.first['value'] as String?;
    });

    final id = (legacy != null && legacy.isNotEmpty) ? legacy : const Uuid().v4();
    await prefs.setString(_installationIdPrefsKey, id);
    return id;
  }
}
