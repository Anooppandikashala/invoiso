import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/setting_key.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/invoice_provider.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/purchase_bills_settings_provider.dart';
import 'package:invoiso/providers/product_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/screens/auth/login_screen.dart';
import 'package:invoiso/utils/post_auth_navigation.dart';

/// Call after switching, creating, or deleting a company post-login — the
/// active database file has already changed underneath the running app, so
/// this discards everything that's still holding the previous company's
/// state and lands back on Login to re-authenticate against the new one:
/// - [invoicesProvider]/[productsProvider] are `AsyncNotifierProvider`s that
///   cache their list once fetched; the container that holds them lives
///   above the Navigator, so simply pushing a new screen doesn't re-run
///   them — invalidate so the next read re-fetches from the now-active file.
/// - Theme/locale/Purchase Bills toggle are stored per-company (that company's own `settings`
///   table), so re-read them for whichever company is now active, same as
///   the pre-login switcher on the Login screen itself already does.
/// - Clearing the whole navigator stack down to Login disposes every
///   mounted screen's own local state too — including Dashboard's
///   `_currentUser`, which otherwise stays pinned to whoever was logged in
///   before the switch.
///
/// Cloud edition: same login across companies — no re-authentication; the
/// user is re-read for the new company's role and lands on its Dashboard
/// (or onboarding, for a brand-new company).
Future<void> returnToLoginAfterCompanyChange(
    BuildContext context, WidgetRef ref, {User? currentUser}) async {
  ref.invalidate(invoicesProvider);
  ref.invalidate(productsProvider);

  if (ref.read(appEditionConfigProvider).isCloud && currentUser != null) {
    final user =
        await ref.read(authRepositoryProvider).getUserById(currentUser.id);
    if (!context.mounted) return;
    if (user != null) {
      await navigateAfterAuth(context, ref, user, clearStack: true);
      return;
    }
  }

  await reloadCompanySettings(ref);
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Theme / language / Purchase Bills toggle live in each company's own
/// settings — re-read them for whichever company is now active.
Future<void> reloadCompanySettings(WidgetRef ref) async {
  final themeKey = await ref.read(settingsRepositoryProvider).getThemeMode();
  final localeKey = await ref.read(settingsRepositoryProvider).getAppLocale();
  final purchaseBills = await ref
      .read(settingsRepositoryProvider)
      .getSetting(SettingKey.enablePurchaseBillsAndSuppliers);
  if (!ref.context.mounted) return;
  ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
  applyAppLocale(ref, localeFromKey(localeKey));
  ref.read(enablePurchaseBillsAndSuppliersProvider.notifier).state =
      purchaseBills == 'true';
}
