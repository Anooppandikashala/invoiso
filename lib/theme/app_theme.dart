import 'package:flutter/material.dart';

class AppTheme {
  // Non-Latin app-UI text (Nepali/Hindi Devanagari, Tibetan) falls back to
  // these bundled fonts instead of rendering as tofu boxes.
  static const _scriptFontFallback = ['NotoSansDevanagari', 'NotoSerifTibetan'];

  static ThemeData get light {
    final base = ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF002E78),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamilyFallback: _scriptFontFallback,
    );
    return base.copyWith(
      // Explicit split between the page canvas and card surfaces — cards
      // are pure white, the page sits on a very light grey behind them,
      // so cards actually stand out instead of blending into the page.
      scaffoldBackgroundColor: Colors.white,
      //cardColor: Colors.grey[50],
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      // App-wide dismiss (X) button on every SnackBar so users don't have
      // to wait one out.
      snackBarTheme: const SnackBarThemeData(
          showCloseIcon: true, closeIconColor: Colors.white),
      colorScheme: base.colorScheme.copyWith(
        surfaceContainer: Colors.grey[50]!,
        surface: Colors.grey[50]!,
        surfaceContainerHighest: Colors.white,
        outline: Colors.grey[400]!,
        outlineVariant: Colors.grey[300]!,
        onSurface: Colors.black,
        onSurfaceVariant: Colors.grey[600]!,
      ),
    );
  }

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF6B9BFF),
        fontFamilyFallback: _scriptFontFallback,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6B9BFF),
          surface: Color(0xFF1E1E1E),
          surfaceContainer: Color(0xFF1E1E1E),
          surfaceContainerHighest: Color(0xFF2A2A2A),
          outline: Color(0xFF4A4A4A),
          outlineVariant: Color(0xFF3A3A3A),
          onSurface: Color(0xFFCCCCCC),
          onSurfaceVariant: Color(0xFF9E9E9E),
        ),
        cardColor: const Color(0xFF1E1E1E),
        cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
        snackBarTheme: const SnackBarThemeData(
            showCloseIcon: true, closeIconColor: Colors.white),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF262626),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
}
