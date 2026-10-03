import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/invoice_provider.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/product_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/screens/auth/login_screen.dart';

/// Call after switching, creating, or deleting a company post-login — the
/// active database file has already changed underneath the running app, so
/// this discards everything that's still holding the previous company's
/// state and lands back on Login to re-authenticate against the new one:
/// - [invoicesProvider]/[productsProvider] are `AsyncNotifierProvider`s that
///   cache their list once fetched; the container that holds them lives
///   above the Navigator, so simply pushing a new screen doesn't re-run
///   them — invalidate so the next read re-fetches from the now-active file.
/// - Theme/locale are stored per-company (that company's own `settings`
///   table), so re-read them for whichever company is now active, same as
///   the pre-login switcher on the Login screen itself already does.
/// - Clearing the whole navigator stack down to Login disposes every
///   mounted screen's own local state too — including Dashboard's
///   `_currentUser`, which otherwise stays pinned to whoever was logged in
///   before the switch.
Future<void> returnToLoginAfterCompanyChange(
    BuildContext context, WidgetRef ref) async {
  ref.invalidate(invoicesProvider);
  ref.invalidate(productsProvider);

  final themeKey = await ref.read(settingsRepositoryProvider).getThemeMode();
  final localeKey = await ref.read(settingsRepositoryProvider).getAppLocale();
  if (!context.mounted) return;
  ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
  applyAppLocale(ref, localeFromKey(localeKey));

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
