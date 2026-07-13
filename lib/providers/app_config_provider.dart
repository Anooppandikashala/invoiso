import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';

/// Edition-varying branding/config shared screens need to read. Each app's own
/// main.dart overrides this provider with its own values instead of duplicating
/// the screens that read them.
class AppEditionConfig {
  final String name;
  final String version;
  final String developer;
  final String supportEmail;
  final String website;
  final String license;
  final String description;
  final String additionalNote;
  final String thankYouNote;
  final bool enableUpdateCheck;
  final bool isCloud;

  const AppEditionConfig({
    required this.name,
    required this.version,
    required this.developer,
    required this.supportEmail,
    required this.website,
    required this.license,
    required this.description,
    required this.additionalNote,
    required this.thankYouNote,
    required this.enableUpdateCheck,
    required this.isCloud
  });
}

final appEditionConfigProvider = Provider<AppEditionConfig>((ref) => const AppEditionConfig(
      name: AppConfig.name,
      version: AppConfig.version,
      developer: AppConfig.developer,
      supportEmail: AppConfig.supportEmail,
      website: AppConfig.website,
      license: AppConfig.license,
      description: AppConfig.description,
      additionalNote: DefaultValues.additionalNote,
      thankYouNote: DefaultValues.thankYouNote,
      enableUpdateCheck: UpdateConfig.enableUpdateCheck,
      isCloud: AppConfig.kIsCloud
    ));
