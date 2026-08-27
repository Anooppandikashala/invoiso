import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/dashboard_screen.dart';
import 'package:invoiso/screens/onboarding/onboarding_screen.dart';

/// Routes to the onboarding wizard on a user's first login, else straight
/// to the dashboard. Shared by every post-auth navigation call site so the
/// "show once" gate lives in exactly one place.
Future<void> navigateAfterAuth(
    BuildContext context, WidgetRef ref, User user) async {
  final completed = await ref
      .read(settingsRepositoryProvider)
      .getSetting(SettingKey.onboardingCompleted);
  if (!context.mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) =>
          completed == 'true' ? DashboardScreen(user) : OnboardingScreen(user),
    ),
  );
}
