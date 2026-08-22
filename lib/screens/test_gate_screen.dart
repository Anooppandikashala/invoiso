import 'package:flutter/material.dart';
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/common/constants.dart';

enum TestGateReason { noInternet, expired }

class TestGateScreen extends StatelessWidget {
  final TestGateReason reason;
  final VoidCallback? onRetry;

  const TestGateScreen({super.key, required this.reason, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNoInternet = reason == TestGateReason.noInternet;
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
                isNoInternet
                    ? 'Test installer needs internet access to verify.'
                    : 'This test build has expired.',
                style: const TextStyle(fontSize: AppFontSize.xlarge),
                textAlign: TextAlign.center,
              ),
              AppSpacing.hMedium,
              Text(
                isNoInternet
                    ? 'Connect to the internet and retry.'
                    : 'Contact support: ${AppConfig.supportEmail}',
                textAlign: TextAlign.center,
              ),
              AppSpacing.hLarge,
              if (isNoInternet && onRetry != null)
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
