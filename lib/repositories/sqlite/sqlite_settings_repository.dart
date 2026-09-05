import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/custom_field_def.dart';
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
  Future<List<CustomFieldDef>> getCustomFieldDefs() => SettingsService.getCustomFieldDefs();
  @override
  Future<void> setCustomFieldDefs(List<CustomFieldDef> defs) => SettingsService.setCustomFieldDefs(defs);
  @override
  Future<List<BankAccount>> getBankAccounts() => SettingsService.getBankAccounts();
  @override
  Future<void> setBankAccounts(List<BankAccount> accounts) => SettingsService.setBankAccounts(accounts);
  @override
  Future<ProductColumnsConfig> getProductColumnsConfig() => SettingsService.getProductColumnsConfig();
  @override
  Future<void> setProductColumnsConfig(ProductColumnsConfig config) => SettingsService.setProductColumnsConfig(config);
  @override
  Future<Map<String, bool>> getProductListColumns() => SettingsService.getProductListColumns();
  @override
  Future<void> setProductListColumns(Map<String, bool> cols) => SettingsService.setProductListColumns(cols);
  @override
  Future<bool> getShowBankDetails() => SettingsService.getShowBankDetails();
  @override
  Future<void> setShowBankDetails(bool show) => SettingsService.setShowBankDetails(show);
  @override
  Future<bool> getShowPhone() => SettingsService.getShowPhone();
  @override
  Future<void> setShowPhone(bool show) => SettingsService.setShowPhone(show);
  @override
  Future<bool> getShowEmail() => SettingsService.getShowEmail();
  @override
  Future<void> setShowEmail(bool show) => SettingsService.setShowEmail(show);
  @override
  Future<bool> getShowCompanyName() => SettingsService.getShowCompanyName();
  @override
  Future<void> setShowCompanyName(bool show) => SettingsService.setShowCompanyName(show);
  @override
  Future<bool> getShowPan() => SettingsService.getShowPan();
  @override
  Future<void> setShowPan(bool show) => SettingsService.setShowPan(show);
  @override
  Future<bool> getShowFssai() => SettingsService.getShowFssai();
  @override
  Future<void> setShowFssai(bool show) => SettingsService.setShowFssai(show);
  @override
  Future<bool> getShowWebsite() => SettingsService.getShowWebsite();
  @override
  Future<void> setShowWebsite(bool show) => SettingsService.setShowWebsite(show);
  @override
  Future<bool> getShowAddress() => SettingsService.getShowAddress();
  @override
  Future<void> setShowAddress(bool show) => SettingsService.setShowAddress(show);
  @override
  Future<bool> getShowLogo() => SettingsService.getShowLogo();
  @override
  Future<void> setShowLogo(bool show) => SettingsService.setShowLogo(show);
  @override
  Future<bool> getShowCustomerBusinessName() =>
      SettingsService.getShowCustomerBusinessName();
  @override
  Future<void> setShowCustomerBusinessName(bool show) =>
      SettingsService.setShowCustomerBusinessName(show);
  @override
  Future<bool> getShowCustomerAddress() =>
      SettingsService.getShowCustomerAddress();
  @override
  Future<void> setShowCustomerAddress(bool show) =>
      SettingsService.setShowCustomerAddress(show);
  @override
  Future<bool> getShowCustomerPhone() =>
      SettingsService.getShowCustomerPhone();
  @override
  Future<void> setShowCustomerPhone(bool show) =>
      SettingsService.setShowCustomerPhone(show);
  @override
  Future<bool> getShowCustomerEmail() =>
      SettingsService.getShowCustomerEmail();
  @override
  Future<void> setShowCustomerEmail(bool show) =>
      SettingsService.setShowCustomerEmail(show);
  @override
  Future<bool> getShowCustomerGstin() =>
      SettingsService.getShowCustomerGstin();
  @override
  Future<void> setShowCustomerGstin(bool show) =>
      SettingsService.setShowCustomerGstin(show);
  @override
  Future<bool> getShowTimeInPdf() => SettingsService.getShowTimeInPdf();
  @override
  Future<void> setShowTimeInPdf(bool show) =>
      SettingsService.setShowTimeInPdf(show);
  @override
  Future<String> getPdfTimeFormat() => SettingsService.getPdfTimeFormat();
  @override
  Future<void> setPdfTimeFormat(String format) =>
      SettingsService.setPdfTimeFormat(format);
  @override
  Future<bool> getShowSlNoInPdf() => SettingsService.getShowSlNoInPdf();
  @override
  Future<void> setShowSlNoInPdf(bool show) =>
      SettingsService.setShowSlNoInPdf(show);
  @override
  Future<bool> getPdfLandscape() => SettingsService.getPdfLandscape();
  @override
  Future<void> setPdfLandscape(bool landscape) =>
      SettingsService.setPdfLandscape(landscape);
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
  Future<void> setWatermarkImage(String base64Image) => SettingsService.setWatermarkImage(base64Image);
  @override
  Future<String?> getWatermarkImage() => SettingsService.getWatermarkImage();
  @override
  Future<void> setWatermarkOpacity(double opacity) => SettingsService.setWatermarkOpacity(opacity);
  @override
  Future<double> getWatermarkOpacity() => SettingsService.getWatermarkOpacity();

  @override
  Future<void> setDefaultInvoiceTitle(String? title) => SettingsService.setDefaultInvoiceTitle(title);

  @override
  Future<String?> getDefaultInvoiceTitle() => SettingsService.getDefaultInvoiceTitle();
  @override
  Future<String> getSignaturePosition() => SettingsService.getSignaturePosition();
  @override
  Future<String> getDefaultTaxMode() => SettingsService.getDefaultTaxMode();
  @override
  Future<String> getSignatureSize() => SettingsService.getSignatureSize();
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
  @override
  Future<bool> getShowAliasNameInPdf() => SettingsService.getShowAliasNameInPdf();
  @override
  Future<bool> getShowTaxButtonInInvoicePage() => SettingsService.getShowTaxButtonInInvoicePage();
  @override
  Future<bool> getHideInvoiceNumberByDefault() => SettingsService.getHideInvoiceNumberByDefault();
  @override
  Future<String> getThemeMode() => SettingsService.getThemeMode();
  @override
  Future<void> setThemeMode(String mode) => SettingsService.setThemeMode(mode);
  @override
  Future<String?> getAppLocale() => SettingsService.getAppLocale();
  @override
  Future<void> setAppLocale(String? languageCode) => SettingsService.setAppLocale(languageCode);
  @override
  Future<bool> getAllowDuplicateInvoiceItems() => SettingsService.getAllowDuplicateInvoiceItems();
  @override
  Future<void> setAllowDuplicateInvoiceItems(bool allow) => SettingsService.setAllowDuplicateInvoiceItems(allow);
}
