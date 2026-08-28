import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/theme/app_theme.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/screens/splash_screen.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  // Set up error handlers BEFORE runApp
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[PlatformDispatcher] Unhandled error: $error');
      debugPrint('Stack: $stack');
    }
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              kDebugMode ? details.exceptionAsString() : 'Please restart the app.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  };

  if (!Platform.isAndroid) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  BackendServices.configure(
    settings: SqliteSettingsRepository(),
    companyInfo: SqliteCompanyInfoRepository(),
    invoices: SqliteInvoiceRepository(),
    payments: SqlitePaymentRepository(),
    installation: SqliteInstallationRepository()
  );

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const WindowOptions options = WindowOptions(
      minimumSize: Size(600, 400),
      center: true,
      backgroundColor: Colors.white,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.center();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(ProviderScope(
    overrides: sqliteRepositoryOverrides,
    child: const MyApp()
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadAppLocale();
  }

  Future<void> _loadThemeMode() async {
    final key = await ref.read(settingsRepositoryProvider).getThemeMode();
    if (!mounted) return;
    ref.read(themeModeProvider.notifier).state = themeModeFromKey(key);
  }

  Future<void> _loadAppLocale() async {
    final key = await ref.read(settingsRepositoryProvider).getAppLocale();
    if (!mounted) return;
    applyAppLocale(ref, localeFromKey(key));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FallbackLocalizationsDelegate<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
        FallbackLocalizationsDelegate<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
        FallbackLocalizationsDelegate<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
      ],
      home: const SplashScreen(),
    );
  }
}
