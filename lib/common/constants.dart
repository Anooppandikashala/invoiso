// constants.dart
import 'package:flutter/material.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';

class AppSpacing {
  static const baseValue = 8.0;
  static const hSmall = SizedBox(height: baseValue);
  static const hMedium = SizedBox(height: 2 * baseValue);
  static const hLarge = SizedBox(height: 3 * baseValue);
  static const hXlarge = SizedBox(height: 4 * baseValue);

  static const wSmall = SizedBox(width: baseValue);
  static const wMedium = SizedBox(width: 2 * baseValue);
  static const wLarge = SizedBox(width: 3 * baseValue);
  static const wXlarge = SizedBox(width: 4 * baseValue);
}

class AppFontSize {
  static const xsmall = 12.0;
  static const small = 14.0;
  static const medium = 16.0;
  static const large = 18.0;
  static const xlarge = 20.0;
  static const xxlarge = 22.0;
  static const xxxlarge = 24.0;
}

class AppPadding {
  static const xxxsmall = 4.0;
  static const xxsmall = 6.0;
  static const xsmall = 8.0;
  static const small = 10.0;
  static const medium = 12.0;
  static const large = 14.0;
  static const xlarge = 16.0;
  static const xxlarge = 18.0;
  static const xxxlarge = 20.0;
}

class AppMargin {
  static const xxxsmall = 4.0;
  static const xxsmall = 6.0;
  static const xsmall = 8.0;
  static const small = 10.0;
  static const medium = 12.0;
  static const large = 14.0;
  static const xlarge = 16.0;
  static const xxlarge = 18.0;
  static const xxxlarge = 20.0;
}

class AppBorderRadius {
  static const xsmall = 10.0;
  static const small = 12.0;
  static const medium = 14.0;
  static const large = 16.0;
}

class Tax {
  static const defaultTaxRate = 0.18;
}

class AppLayout {
  static const double maxWidthNarrow =
      900.0; // settings, backup, customer, product screens
  static const double maxWidthNormal = 1600.0; // dashboard
  static const double maxWidthWide =
      1900.0; // create invoice (dense multi-panel form)
}

class DefaultValues {
  static const String additionalNote = "";
  static const String thankYouNote = "";
  static const LogoPosition logoPosition = LogoPosition.left;
  static const int additionalNotesLength = 1000;
}

class AppShortcuts {
  /// Key combo + localized description pairs. Key combos themselves are
  /// universal (not language content), only the descriptions are localized.
  static List<(String, String)> all(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ('Ctrl + Q', l10n.shortcutNewInvoiceDescription),
      ('Ctrl + S', l10n.shortcutSaveInvoiceDescription),
      ('Ctrl + F', l10n.shortcutAddProductDescription),
      ('Ctrl + M', l10n.shortcutAddCustomItemDescription),
      ('Ctrl + O', l10n.shortcutPreviewPdfDescription),
      ('Ctrl + P', l10n.shortcutPrintPdfDescription),
    ];
  }
}

class PdfLayout {
  static double defaultHMargin = 20;
  static double defaultVMargin = 12;
  static double thankYouNoteFontSize = 10;
  static double footerBrandingFontSize = 8;
  static const double thermalPrinterItemFontSize = 28;
  static const double thermalPrinterHeadFontSize = 38;
}

class UpdateConfig {
  static const enableUpdateCheck = true;
}

class TestBuildConfig {
  // Replaced by CI (sed) only for test-v* tags; stays literal on local/prod builds.
  static const _isTestBuildFlag = "__IS_TEST_BUILD__"; // test true
  static bool get isTestBuild => _isTestBuildFlag == "true";

  static const _buildTimestampRaw = "__BUILD_TIMESTAMP__"; // test 1785818736
  static int get buildEpochSeconds => int.tryParse(_buildTimestampRaw) ?? 0;

  static const testExpiryDays = 7;
}

class AnalyticsConfig {
  static const heartbeatUrl =
      "__HEARTBEAT_URL__"; // test https://www.google.com;
}
