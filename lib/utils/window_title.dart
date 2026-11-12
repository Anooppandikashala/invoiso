import 'dart:io';

import 'package:window_manager/window_manager.dart';

import 'package:invoiso/services/backend_services.dart';

/// Keeps the desktop window title showing which company is active — only
/// meaningful once more than one company is registered (a single-company
/// install keeps the plain default title). Call this after anything that
/// can change the active company's name: renaming it in Company Info,
/// switching companies, or creating a new one.
Future<void> refreshWindowTitle() async {
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

  final companies = await BackendServices.companyRegistry.listCompanies();
  if (companies.length <= 1) return;

  final activeId = await BackendServices.companyRegistry.getActiveCompanyId();
  final active = companies.where((c) => c.id == activeId).firstOrNull;
  if (active == null) return;

  await windowManager.setTitle('Invoiso — ${active.name}');
}
