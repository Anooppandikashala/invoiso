import 'package:flutter/material.dart';
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';

enum TestGateReason { noInternet, expired }

class TestGateScreen extends StatelessWidget {
  final TestGateReason reason;
  final VoidCallback? onRetry;

  const TestGateScreen({super.key, required this.reason, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNoInternet = reason == TestGateReason.noInternet;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.xxxlarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isNoInternet ? Icons.wifi_off : Icons.timer_off, size: 64),
              AppSpacing.hLarge,
              Text(
                isNoInternet ? l10n.testGateNoInternetTitle : l10n.testGateExpiredTitle,
                style: const TextStyle(fontSize: AppFontSize.xlarge),
                textAlign: TextAlign.center,
              ),
              AppSpacing.hMedium,
              Text(
                isNoInternet
                    ? l10n.testGateNoInternetSubtitle
                    : l10n.testGateExpiredSubtitle(AppConfig.supportEmail),
                textAlign: TextAlign.center,
              ),
              AppSpacing.hLarge,
              if (isNoInternet && onRetry != null)
                ElevatedButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
            ],
          ),
        ),
      ),
    );
  }
}
