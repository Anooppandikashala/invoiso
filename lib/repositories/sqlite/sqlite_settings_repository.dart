import 'package:invoiso/common.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/repositories/settings_repository.dart';

class SqliteSettingsRepository implements SettingsRepository {
  @override
  Future<void> setSetting(SettingKey key, String value) => SettingsService.setSetting(key, value);
  @override
  Future<String?> getSetting(SettingKey key) => SettingsService.getSetting(key);
  @override
  Future<void> deleteSetting(SettingKey key) => SettingsService.deleteSetting(key);
  @override
  Future<void> setInvoiceTemplate(InvoiceTemplate template) => SettingsService.setInvoiceTemplate(template);
  @override
  Future<InvoiceTemplate> getInvoiceTemplate() => SettingsService.getInvoiceTemplate();
  @override
  Future<void> setPdfThemeColor(String hexColor) => SettingsService.setPdfThemeColor(hexColor);
  @override
  Future<void> clearPdfThemeColor() => SettingsService.clearPdfThemeColor();
  @override
  Future<String?> getPdfThemeColor() => SettingsService.getPdfThemeColor();
  @override
  Future<void> setCompanyLogo(String base64Logo) => SettingsService.setCompanyLogo(base64Logo);
  @override
  Future<String?> getCompanyLogo() => SettingsService.getCompanyLogo();
  @override
  Future<LogoPosition> getLogoPosition() => SettingsService.getLogoPosition();
  @override
  Future<String> getLogoSize() => SettingsService.getLogoSize();
  @override
  Future<void> setCurrency(String currencyCode) => SettingsService.setCurrency(currencyCode);
  @override
  Future<CurrencyOption> getCurrency() => SettingsService.getCurrency();
  @override
  Future<List<UpiEntry>> getUpiIds() => SettingsService.getUpiIds();
  @override
  Future<void> setUpiIds(List<UpiEntry> entries) => SettingsService.setUpiIds(entries);
  @override
  Future<List<BankAccount>> getBankAccounts() => SettingsService.getBankAccounts();
  @override
  Future<void> setBankAccounts(List<BankAccount> accounts) => SettingsService.setBankAccounts(accounts);
  @override
  Future<bool> getShowBankDetails() => SettingsService.getShowBankDetails();
  @override
  Future<void> setShowBankDetails(bool show) => SettingsService.setShowBankDetails(show);
  @override
  Future<bool> getShowGstFields() => SettingsService.getShowGstFields();
  @override
  Future<bool> getShowInvoiceFooterBranding() => SettingsService.getShowInvoiceFooterBranding();
  @override
  Future<bool> getFractionalQuantity() => SettingsService.getFractionalQuantity();
  @override
  Future<String> getQuantityLabel() => SettingsService.getQuantityLabel();
  @override
  Future<bool> getShowQuantity() => SettingsService.getShowQuantity();
  @override
  Future<void> setShowQuantity(bool show) => SettingsService.setShowQuantity(show);
  @override
  Future<bool> getShowDiscount() => SettingsService.getShowDiscount();
  @override
  Future<void> setShowDiscount(bool show) => SettingsService.setShowDiscount(show);
  @override
  Future<bool> getShowTypeTag() => SettingsService.getShowTypeTag();
  @override
  Future<void> setShowTypeTag(bool show) => SettingsService.setShowTypeTag(show);
  @override
  Future<bool> getShowTotalQuantity() => SettingsService.getShowTotalQuantity();
  @override
  Future<void> setShowTotalQuantity(bool show) => SettingsService.setShowTotalQuantity(show);
  @override
  Future<bool> getShowPreviousBalance() => SettingsService.getShowPreviousBalance();
  @override
  Future<void> setShowPreviousBalance(bool show) => SettingsService.setShowPreviousBalance(show);
  @override
  Future<void> setSignatureImage(String base64Image) => SettingsService.setSignatureImage(base64Image);
  @override
  Future<String?> getSignatureImage() => SettingsService.getSignatureImage();
  @override
  Future<String> getSignaturePosition() => SettingsService.getSignaturePosition();
  @override
  Future<BusinessType> getBusinessType() => SettingsService.getBusinessType();
  @override
  Future<void> setBusinessType(BusinessType type) => SettingsService.setBusinessType(type);
  @override
  Future<DateFormatOption> getDateFormat() => SettingsService.getDateFormat();
  @override
  Future<void> setDateFormat(DateFormatOption option) => SettingsService.setDateFormat(option);
  @override
  Future<PageSize> getPageSize() => SettingsService.getPageSize();
  @override
  Future<void> setPageSize(PageSize size) => SettingsService.setPageSize(size);
}
