import 'dart:io';
import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/screens/splash_screen.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Get the screen size
    WindowOptions options = const WindowOptions(
      minimumSize: Size(600, 400),
      center: true,
      backgroundColor: Colors.white,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(options, () async {
      // Use screen_retriever instead of windowManager.getPrimaryDisplay()
      final screen = await screenRetriever.getPrimaryDisplay();
      final screenSize = screen.size;

      final Size defaultSize = Size(screenSize.width * 0.8, screenSize.height * 0.8);
      final Size minSize = Size(screenSize.width * 0.75, screenSize.height * 0.75);

      //await windowManager.setSize(defaultSize);
      await windowManager.setMinimumSize(minSize);
      await windowManager.center();
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor:Color(0xFF002E78),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Start with splash screen
    );
  }
}