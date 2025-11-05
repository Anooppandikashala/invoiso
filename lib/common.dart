
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
    }
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