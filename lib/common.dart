
enum InvoiceTemplate
{
  classic,
  modern,
  minimal,
}

enum BackupType
{
  database,
  json
}

enum SettingKey {
  logoPosition,
  invoicePrefix,
  additionalInfo,
  thankYouNote,
  currency,
}

extension SettingKeyExtension on SettingKey
{
  String get key {
    switch (this) {
      case SettingKey.logoPosition:
        return 'logo_position';
      case SettingKey.invoicePrefix:
        return 'invoice_prefix';
      case SettingKey.additionalInfo:
        return 'additional_info';
      case SettingKey.thankYouNote:
        return 'thank_you_note';
      case SettingKey.currency:
        return 'currency';
    }
  }
}

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class SupportedCurrencies {
  static const List<CurrencyOption> all = [
    CurrencyOption(code: 'INR', symbol: '₹',   name: 'Indian Rupee'),
    CurrencyOption(code: 'USD', symbol: '\$',   name: 'US Dollar'),
    CurrencyOption(code: 'EUR', symbol: '€',   name: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '£',   name: 'British Pound'),
    CurrencyOption(code: 'JPY', symbol: '¥',   name: 'Japanese Yen'),
    CurrencyOption(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyOption(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  ];

  static CurrencyOption fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }
}

enum LogoPosition
{
  left,
  right
}

extension LogoPositionExtension on LogoPosition
{
  String get key {
    switch (this) {
      case LogoPosition.left:
        return 'left';
      case LogoPosition.right:
        return 'right';
    }
  }
}