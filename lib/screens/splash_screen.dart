import 'package:flutter/material.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/screens/login_screen.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/utils/app_logger.dart';

const _tag = 'SplashScreen';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Initialization Error'),
          content: Text('Failed to initialize the database.\n\n$e'),
          actions: [
            ElevatedButton(
              onPressed: () => _initializeApp(),
              child: const Text('Retry'),
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Initializing App...', style: TextStyle(fontSize: 18)),
            AppSpacing.hXlarge,
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
