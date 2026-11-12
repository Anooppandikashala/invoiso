import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/dashboard_screen.dart';
import 'package:invoiso/screens/onboarding/onboarding_screen.dart';
import 'package:invoiso/utils/company_switch_navigation.dart';

/// Routes to the onboarding wizard on a user's first login, else straight
/// to the dashboard. Shared by every post-auth navigation call site so the
/// "show once" gate lives in exactly one place.
///
/// Also applies the company's theme / language / Purchase Bills toggle — the
/// cloud edition can only read them once signed in. [clearStack] drops every
/// route below (cloud company switch from deep inside Settings).
Future<void> navigateAfterAuth(
    BuildContext context, WidgetRef ref, User user,
    {bool clearStack = false}) async {
  await reloadCompanySettings(ref);
  final completed = await ref
      .read(settingsRepositoryProvider)
      .getSetting(SettingKey.onboardingCompleted);
  if (!context.mounted) return;
  final route = MaterialPageRoute(
    builder: (context) =>
        completed == 'true' ? DashboardScreen(user) : OnboardingScreen(user),
  );
  if (clearStack) {
    Navigator.pushAndRemoveUntil(context, route, (route) => false);
  } else {
    Navigator.pushReplacement(context, route);
  }
}
