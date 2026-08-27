import 'package:flutter/material.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/screens/auth/login_screen.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/utils/app_logger.dart';

const _tag = 'SplashScreen';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await DatabaseHelper().database;
    } catch (e, stack) {
      AppLogger.e(_tag, 'Database initialization failed', e, stack);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.splashInitErrorTitle),
          content: Text(l10n.splashInitErrorMessage('$e')),
          actions: [
            ElevatedButton(
              onPressed: () => _initializeApp(),
              child: Text(l10n.actionRetry),
            ),
          ],
        ),
      );
      return;
    }

    AppLogger.d(_tag, 'DB path: ${DatabaseHelper.path}');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.splashInitializingMessage,
                style: const TextStyle(fontSize: 18)),
            AppSpacing.hXlarge,
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
