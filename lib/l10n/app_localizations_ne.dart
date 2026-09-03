// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'इनभोइसो';

  @override
  String get actionSave => 'सुरक्षित गर्नुहोस्';

  @override
  String get actionCancel => 'रद्द गर्नुहोस्';

  @override
  String get actionSkip => 'छोड्नुहोस्';

  @override
  String get actionNext => 'अर्को';

  @override
  String get actionBack => 'पछाडि';

  @override
  String get actionGetStarted => 'सुरु गर्नुहोस्';

  @override
  String get commonLanguage => 'भाषा';

  @override
  String get commonBeta => 'बिटा';

  @override
  String get commonSystemDefault => 'प्रणाली पूर्वनिर्धारित';

  @override
  String get commonTheme => 'थिम';

  @override
  String get themeLight => 'उज्यालो';

  @override
  String get themeDark => 'अँध्यारो';

  @override
  String get themeSystem => 'प्रणाली';

  @override
  String get onboardingStepCompanyTitle => 'कम्पनी';

  @override
  String get onboardingStepCompanySubtitle =>
      'आफ्नो व्यवसायको बारेमा बताउनुहोस्';

  @override
  String get onboardingStepInvoiceTitle => 'बीजक सेटिङ';

  @override
  String get onboardingStepInvoiceSubtitle =>
      'तपाईंको बीजक कसरी काम गर्छ भनी सेट गर्नुहोस्';

  @override
  String get onboardingStepAppearanceTitle => 'बीजक स्वरूप';

  @override
  String get onboardingStepAppearanceSubtitle =>
      'पृष्ठ साइज र टेम्प्लेट छान्नुहोस्';

  @override
  String get onboardingStepDoneTitle => 'सबै तयार';

  @override
  String get onboardingCompanyNameLabel => 'कम्पनीको नाम';

  @override
  String get onboardingCountryLabel => 'देश';

  @override
  String get onboardingLogoLabel => 'कम्पनी लोगो';

  @override
  String get onboardingCurrencyLabel => 'मुद्रा';

  @override
  String get onboardingDateFormatLabel => 'मिति ढाँचा';

  @override
  String get onboardingInvoiceStartingNumberLabel => 'बीजक सुरु नम्बर';

  @override
  String get onboardingLeadingZerosLabel => 'अग्रणी शून्य';

  @override
  String get onboardingLeadingZerosSubtitle =>
      'बीजक नम्बरलाई ८ अंकमा प्याड गर्नुहोस् (जस्तै 00000007)';

  @override
  String get onboardingDefaultTaxRateLabel => 'पूर्वनिर्धारित कर दर (%)';

  @override
  String get onboardingPageSizeLabel => 'पृष्ठ साइज';

  @override
  String get onboardingTemplateLabel => 'बीजक टेम्प्लेट';

  @override
  String get onboardingDoneHeadline => 'तपाईं तयार हुनुहुन्छ!';

  @override
  String get onboardingDoneBody =>
      'तपाईंको कम्पनी, बीजक र टेम्प्लेट विवरणहरू सुरक्षित छन्। तपाईं यीमध्ये कुनै पनि पछि सेटिङबाट परिवर्तन गर्न सक्नुहुन्छ।';

  @override
  String get splashInitErrorTitle => 'सुरुवात त्रुटि';

  @override
  String splashInitErrorMessage(String error) {
    return 'डेटाबेस सुरु गर्न असफल।\n\n$error';
  }

  @override
  String get actionRetry => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get splashInitializingMessage => 'एप सुरु हुँदैछ...';

  @override
  String get testGateNoInternetTitle =>
      'टेस्ट इन्स्टलरलाई प्रमाणित गर्न इन्टरनेट पहुँच चाहिन्छ।';

  @override
  String get testGateExpiredTitle => 'यो टेस्ट बिल्ड म्याद सकिएको छ।';

  @override
  String get testGateNoInternetSubtitle =>
      'इन्टरनेटमा जोडिनुहोस् र पुनः प्रयास गर्नुहोस्।';

  @override
  String testGateExpiredSubtitle(String email) {
    return 'सहयोगलाई सम्पर्क गर्नुहोस्: $email';
  }

  @override
  String get dashboardSessionExpiredMessage =>
      'निष्क्रियताको कारण सत्र समाप्त भयो।';

  @override
  String get dashboardUnknownTabLabel => 'अज्ञात ट्याब';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return 'बीजक लेआउट: $layout — जानकारीको लागि ट्याप गर्नुहोस्';
  }

  @override
  String get dashboardLayoutNew => 'नयाँ';

  @override
  String get dashboardLayoutClassic => 'क्लासिक';

  @override
  String get dashboardInvoiceLayoutDialogTitle => 'बीजक लेआउट';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return 'तपाईं $layout \"नयाँ बीजक\" लेआउट प्रयोग गर्दै हुनुहुन्छ। तपाईं यसलाई सेटिङ > पहुँचयोग्यताबाट परिवर्तन गर्न सक्नुहुन्छ। नोट: बीचमा बदल्दा यो फारमका असुरक्षित परिवर्तनहरू हराउँछन्।';
  }

  @override
  String get actionClose => 'बन्द गर्नुहोस्';

  @override
  String get dashboardOpenSettingsAction => 'सेटिङ खोल्नुहोस्';

  @override
  String get dashboardCollapseSidebarTooltip => 'साइडबार संक्षिप्त गर्नुहोस्';

  @override
  String get dashboardExpandSidebarTooltip => 'साइडबार विस्तार गर्नुहोस्';

  @override
  String get navDashboard => 'ड्यासबोर्ड';

  @override
  String get navNewInvoice => 'नयाँ बीजक';

  @override
  String get navInvoices => 'बीजकहरू';

  @override
  String get navQuotations => 'कोटेसनहरू';

  @override
  String get navReceipts => 'रसिदहरू';

  @override
  String get navCustomers => 'ग्राहकहरू';

  @override
  String get navProducts => 'उत्पादनहरू';

  @override
  String get navReports => 'रिपोर्टहरू';

  @override
  String get navSettings => 'सेटिङहरू';

  @override
  String get dashboardRoleAdmin => 'एडमिन';

  @override
  String get dashboardRoleUser => 'प्रयोगकर्ता';

  @override
  String get dashboardSupportTooltip => 'सहयोग';

  @override
  String get dashboardLogoutTooltip => 'लगआउट';

  @override
  String get dashboardTestBuildBadge => 'टेस्ट बिल्ड';

  @override
  String get dashboardTestBadgeShort => 'टेस्ट';

  @override
  String get dashboardKeyboardShortcutsTitle => 'किबोर्ड सर्टकटहरू';

  @override
  String get dashboardShortcutsBannerTitle => 'नयाँ: किबोर्ड सर्टकटहरू';

  @override
  String get dashboardShortcutsBannerSubtitle =>
      'नयाँ बीजकको लागि Ctrl+Q, सुरक्षित गर्न Ctrl+S, र थप धेरै।';

  @override
  String get dashboardViewAllAction => 'सबै हेर्नुहोस्';

  @override
  String get dashboardLayoutBannerTitle => 'नयाँ: बहु ड्यासबोर्ड लेआउटहरू';

  @override
  String get dashboardLayoutBannerSubtitle =>
      'माथि-दायाँ रहेको ग्रिड आइकन प्रयोग गरी डिफल्ट, क्लासिक, बेन्टो, र सिम्पल फिड बीच स्विच गर्नुहोस्।';

  @override
  String get actionGotIt => 'बुझें';

  @override
  String get dashboardThemeBannerTitle => 'नयाँ: डार्क मोड';

  @override
  String get dashboardThemeBannerSubtitle =>
      'हामी यसलाई अझै सुधार्दैछौं — सेटिङ > कम्पनी जानकारीबाट यसलाई सक्रिय गर्नुहोस् र के मिलेन भन्नुहोस्।';

  @override
  String dashboardSupportBannerTitle(String count) {
    return 'तपाईंले $count बीजकहरू बनाउनुभयो!';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      'Invoiso मन परिरहेको छ? एउटा छोटो समीक्षाले धेरै मद्दत गर्छ।';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      'Invoiso तपाईंको कामको हिस्सा भएजस्तो देखिन्छ। यदि यो उपयोगी भएको छ भने, उपयुक्त लागेको बेला प्रोजेक्टलाई सहयोग गर्ने विचार गर्नुहोस्।';

  @override
  String get dashboardReviewAction => 'समीक्षा गर्नुहोस्';

  @override
  String get dashboardSupportAction => 'सहयोग गर्नुहोस्';

  @override
  String get dashboardOverviewTitle => 'ड्यासबोर्ड अवलोकन';

  @override
  String get actionRefresh => 'रिफ्रेस गर्नुहोस्';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count स्टकमा छैन';
  }

  @override
  String get dashboardRevenueCollectedLabel => 'संकलित राजस्व';

  @override
  String get dashboardOutstandingLabel => 'बाँकी';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count म्याद नाघेको';
  }

  @override
  String get dashboardRecentInvoicesTitle => 'भर्खरका बीजकहरू';

  @override
  String get dashboardLastFiveInvoicesLabel => 'पछिल्लो ५ बीजकहरू';

  @override
  String get dashboardNoInvoicesYetTitle => 'अझै बीजक छैन';

  @override
  String get dashboardNoInvoicesYetSubtitle =>
      'यहाँ हेर्न आफ्नो पहिलो बीजक सिर्जना गर्नुहोस्';

  @override
  String get actionView => 'हेर्नुहोस्';

  @override
  String get actionEdit => 'सम्पादन गर्नुहोस्';

  @override
  String get actionDuplicate => 'नक्कल बनाउनुहोस्';

  @override
  String get actionPdfPreview => 'PDF पूर्वावलोकन';

  @override
  String get actionDownloadPdf => 'PDF डाउनलोड गर्नुहोस्';

  @override
  String get actionPrint => 'प्रिन्ट गर्नुहोस्';

  @override
  String get actionPayment => 'भुक्तानी';

  @override
  String get actionDelete => 'मेटाउनुहोस्';

  @override
  String get actionRecordPayment => 'भुक्तानी रेकर्ड गर्नुहोस्';

  @override
  String dashboardDueDateLabel(String date) {
    return 'म्याद: $date';
  }

  @override
  String get labelInvoice => 'बीजक';

  @override
  String get labelQuotation => 'कोटेसन';

  @override
  String get labelReceipt => 'रसिद';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return 'फेरि स्वागत छ, $username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle =>
      'तपाईंको व्यवसायको एक झलक यहाँ छ';

  @override
  String get dashboardDueSoonTitle => 'चाँडै म्याद सकिने';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू',
      one: '1 बीजक',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => 'आज र भोलि';

  @override
  String get dashboardDueTodayBadge => 'आज म्याद';

  @override
  String get dashboardDueTomorrowBadge => 'भोलि म्याद';

  @override
  String get dashboardOverdueSectionTitle => 'म्याद नाघेको';

  @override
  String get dashboardOldestFirstLabel => 'पुरानो पहिले';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन म्याद नाघेको',
      one: '1 दिन म्याद नाघेको',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => 'नयाँ स्टक परिमाण';

  @override
  String get actionUpdate => 'अपडेट गर्नुहोस्';

  @override
  String get labelService => 'सेवा';

  @override
  String get labelProduct => 'उत्पादन';

  @override
  String dashboardStockLabel(int count) {
    return 'स्टक: $count';
  }

  @override
  String get actionUpdateStock => 'स्टक अपडेट गर्नुहोस्';

  @override
  String get paymentStatusPaid => 'भुक्तानी भयो';

  @override
  String get paymentStatusPartial => 'आंशिक';

  @override
  String get paymentStatusUnpaid => 'भुक्तानी नभएको';

  @override
  String get dashboardDuplicateInvoiceTitle => 'बीजक नक्कल गर्नुहोस्';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return 'बीजक #$number\n($customerName) को प्रतिलिपि यसरी बनाउनुहोस्:';
  }

  @override
  String get dashboardDeleteInvoiceTitle => 'बीजक मेटाउनुहोस्';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return 'के तपाईं बीजक #$number मेटाउन निश्चित हुनुहुन्छ? यो कार्य पूर्ववत गर्न सकिँदैन।';
  }

  @override
  String get dashboardLayoutTooltip => 'ड्यासबोर्ड लेआउट';

  @override
  String get dashboardLayoutDefaultTitle => 'डिफल्ट';

  @override
  String get dashboardLayoutDefaultSubtitle => 'मूल लेआउट';

  @override
  String get dashboardLayoutClassicSubtitle => 'चार्ट + KPI ग्रिड';

  @override
  String get dashboardLayoutBentoTitle => 'बेन्टो';

  @override
  String get dashboardLayoutBentoSubtitle => 'मुख्य चार्ट + कार्ड ग्रिड';

  @override
  String get dashboardLayoutSimpleTitle => 'सिम्पल फिड';

  @override
  String get dashboardLayoutSimpleSubtitle => 'सफा सूची दृश्य';

  @override
  String get dashboardTotalInvoicesLabel => 'कुल बीजकहरू';

  @override
  String get dashboardRevenueLast6MonthsTitle => 'राजस्व — विगत ६ महिना';

  @override
  String get dashboardNoPaymentDataYetLabel => 'अझै भुक्तानी डेटा छैन';

  @override
  String get dashboardFinancialOverviewTitle => 'वित्तीय सिंहावलोकन';

  @override
  String get dashboardCollectedLabel => 'संकलित';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू म्याद नाघेको',
      one: '1 बीजक म्याद नाघेको',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return 'पछिल्लो $n';
  }

  @override
  String get labelCustomer => 'ग्राहक';

  @override
  String get labelAmount => 'रकम';

  @override
  String get dashboardZeroLeftLabel => '0 बाँकी';

  @override
  String get labelStock => 'स्टक';

  @override
  String get actionPay => 'तिर्नुहोस्';

  @override
  String get dashboardQuickActionsTitle => 'द्रुत कार्यहरू';

  @override
  String get dashboardPdfActionsTooltip => 'PDF कार्यहरू';

  @override
  String get dashboardActionsTooltip => 'कार्यहरू';

  @override
  String get dashboardTopCustomersTitle => 'शीर्ष ग्राहकहरू';

  @override
  String get dashboardTopProductsTitle => 'शीर्ष उत्पादनहरू';

  @override
  String dashboardUnitsLabel(String qty) {
    return '$qty इकाइ';
  }

  @override
  String get dashboardBetaBadge => 'बिटा';

  @override
  String get dashboardOutOfStockSectionTitle => 'स्टक सकिएको';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तुहरू',
      one: '1 वस्तु',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => 'पुनः स्टक गर्न ट्याप गर्नुहोस्';

  @override
  String get createInvoiceUnsavedChangesTitle => 'असुरक्षित परिवर्तनहरू';

  @override
  String get createInvoiceUnsavedChangesMessage =>
      'यस बीजकमा असुरक्षित परिवर्तनहरू छन्। बाहिर जानुअघि सुरक्षित गर्नुहोस्?';

  @override
  String get createInvoiceKeepEditingButton => 'सम्पादन जारी राख्नुहोस्';

  @override
  String get actionDiscard => 'त्याग्नुहोस्';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return 'डेटा लोड गर्दा त्रुटि: $e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => 'अपर्याप्त स्टक';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return 'केवल $stock इकाई उपलब्ध छ। फेरि पनि $qty थप्ने?';
  }

  @override
  String get createInvoiceAddAnywayButton => 'फेरि पनि थप्नुहोस्';

  @override
  String get createInvoiceOutOfStockTitle => 'स्टक सकियो';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name स्टकमा छैन। फेरि पनि थप्ने?';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => 'असीमित स्टक';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return 'उपलब्ध स्टक: $stock';
  }

  @override
  String get fieldDiscountLabel => 'छुट';

  @override
  String get fieldUnitPriceOverrideLabel => 'एकाइ मूल्य (ओभरराइड)';

  @override
  String get fieldExtraCostLabel => 'थप लागत (वैकल्पिक)';

  @override
  String get fieldInsertAtPositionLabel => 'यस स्थानमा राख्नुहोस्';

  @override
  String get actionAdd => 'थप्नुहोस्';

  @override
  String get createInvoiceProductAlreadyAddedMessage =>
      'यो उत्पादन पहिले नै थपिसकिएको छ';

  @override
  String get createInvoiceCustomerNameRequiredMessage =>
      'कृपया ग्राहकको नाम दिनुहोस्';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage =>
      'कृपया कम्तीमा एउटा वस्तु थप्नुहोस्';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सफलतापूर्वक सिर्जना गरियो!';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return 'बीजक सिर्जना गर्दा त्रुटि: $e';
  }

  @override
  String get createInvoiceEditItemTitle => 'वस्तु सम्पादन गर्नुहोस्';

  @override
  String get createInvoiceCustomItemTitle => 'अनुकूल वस्तु';

  @override
  String get fieldItemNameLabel => 'वस्तुको नाम';

  @override
  String get fieldAliasForPdfLabel => 'उपनाम (PDF का लागि)';

  @override
  String get fieldUnitPriceLabel => 'एकाइ मूल्य';

  @override
  String get fieldRateLabel => 'दर';

  @override
  String get fieldTaxRateLabel => 'कर दर (%)';

  @override
  String get fieldPriceIncludesTaxLabel => 'मूल्यमा कर समावेश छ';

  @override
  String get createInvoicePhoneAlreadyInUseTitle =>
      'फोन नम्बर पहिले नै प्रयोगमा छ';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return 'यो फोन नम्बर \"$ownerName\" को हो।\n\nयो ग्राहकलाई अरूको भइसकेको फोन नम्बरसँग सुरक्षित गर्न सकिँदैन।';
  }

  @override
  String get actionOk => 'ठिक छ';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      'सुरक्षित गर्नुअघि कृपया ग्राहकको नाम प्रविष्ट गर्नुहोस्';

  @override
  String get createInvoicePhoneChangedTitle => 'फोन नम्बर परिवर्तन भयो';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return '\"$name\" को फोन नम्बर परिवर्तन भयो।\n\nतिनको अवस्थित रेकर्ड अद्यावधिक गर्ने, वा यी विवरणहरूलाई नयाँ ग्राहकको रूपमा सुरक्षित गर्ने?';
  }

  @override
  String get createInvoiceSaveAsNewButton => 'नयाँको रूपमा सुरक्षित गर्नुहोस्';

  @override
  String get createInvoiceUpdateExistingButton => 'अवस्थित अद्यावधिक गर्नुहोस्';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '$name ग्राहक सूचीमा अद्यावधिक गरियो';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle =>
      'ग्राहक पहिले नै अवस्थित छ';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '\"$name\" यो फोन नम्बरसँग पहिले नै सुरक्षित छ।\n\nतिनको अवस्थित विवरण प्रयोग गर्ने, वा हालको जानकारीले रेकर्ड अद्यावधिक गर्ने?';
  }

  @override
  String get createInvoiceUseExistingButton => 'अवस्थित प्रयोग गर्नुहोस्';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return 'अवस्थित ग्राहक \"$name\" प्रयोग गर्दै';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name ग्राहक सूचीमा सुरक्षित गरियो';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage =>
      'ग्राहक रेकर्ड अब अवस्थित छैन';

  @override
  String get createInvoiceCustomerRefreshedMessage => 'ग्राहक विवरण ताजा गरियो';

  @override
  String get fieldLabelLabel => 'लेबल';

  @override
  String get hintLabelExample => 'जस्तै ढुवानी';

  @override
  String get tooltipRemove => 'हटाउनुहोस्';

  @override
  String get createInvoiceAddRowButton => 'पङ्क्ति थप्नुहोस्';

  @override
  String get fieldDiscountPerUnitLabel => 'प्रति एकाइ छुट';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn => '(मूल्य − छुट) × परिमाण';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff => '(मूल्य × परिमाण) − छुट';

  @override
  String get createInvoicePrevBalanceShortLabel => 'अघिल्लो बाँकी';

  @override
  String get createInvoicePreviousBalanceDueLabel => 'अघिल्लो बाँकी रकम';

  @override
  String get createInvoiceDueShortLabel => 'बाँकी';

  @override
  String get createInvoiceTotalDueLabel => 'कुल बाँकी';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सफलतापूर्वक अद्यावधिक गरियो!';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return 'बीजक अद्यावधिक गर्दा त्रुटि: $e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सफलतापूर्वक सिर्जना गरियो!';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return '$invoiceTypeLabel आईडी: $invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => 'विवरण हेर्नुहोस्';

  @override
  String get createInvoicePreviewPdfLabel => 'PDF पूर्वावलोकन';

  @override
  String get createInvoicePreviewPdfTooltip =>
      'PDF पूर्वावलोकन (सर्टकट: Ctrl+o)';

  @override
  String get createInvoicePrintPdfLabel => 'PDF प्रिन्ट गर्नुहोस्';

  @override
  String get createInvoicePrintPdfTooltip =>
      'PDF प्रिन्ट गर्नुहोस् (सर्टकट: Ctrl+p)';

  @override
  String get actionDismiss => 'खारेज गर्नुहोस्';

  @override
  String get createInvoiceCreateNewInvoiceButton =>
      'नयाँ बीजक सिर्जना गर्नुहोस् (सर्टकट: Ctrl+q)';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return 'नयाँ $invoiceTypeLabel सिर्जना गर्नुहोस्';
  }

  @override
  String get commonLoadingDataMessage => 'डेटा लोड हुँदैछ...';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage =>
      'बीजक सिर्जना गर्नुअघि कम्तीमा एउटा वस्तु थप्नुहोस्।';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सिर्जना गरियो';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सम्पादन गर्नुहोस्';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel को रूपमा नक्कल गर्नुहोस्';
  }

  @override
  String get createInvoiceNewShortLabel => 'नयाँ';

  @override
  String get createInvoiceNewInvoiceShortcutLabel =>
      'नयाँ बीजक (सर्टकट: Ctrl+q)';

  @override
  String get createInvoiceSavingEllipsisLabel => 'सुरक्षित गर्दै...';

  @override
  String get createInvoiceSaveCustomerLabel => 'ग्राहक सुरक्षित गर्नुहोस्';

  @override
  String get createInvoiceSelectExistingCustomerButton =>
      'अवस्थितबाट चयन गर्नुहोस्';

  @override
  String get createInvoiceRefreshCustomerTooltip =>
      'सुरक्षित ग्राहकबाट ताजा गर्नुहोस्';

  @override
  String get createInvoiceClearCustomerTooltip => 'ग्राहक चयन खाली गर्नुहोस्';

  @override
  String get fieldCustomerNameRequiredLabel => 'ग्राहकको नाम *';

  @override
  String get fieldBusinessNameLabel => 'व्यवसायको नाम';

  @override
  String get fieldPhoneLabel => 'फोन';

  @override
  String get fieldGstinVatLabel => 'जीएसटीआईएन / भ्याट';

  @override
  String get fieldEmailLabel => 'इमेल';

  @override
  String get fieldAddressLabel => 'ठेगाना';

  @override
  String get tooltipEditInLargerView => 'ठूलो दृश्यमा सम्पादन गर्नुहोस्';

  @override
  String get createInvoiceChooseCustomerTitle => 'ग्राहक छान्नुहोस्';

  @override
  String get createInvoiceSearchCustomerLabel => 'ग्राहक खोज्नुहोस्';

  @override
  String get createInvoiceNoCustomersFoundMessage => 'कुनै ग्राहक फेला परेन';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return '$invoiceTypeLabel विवरण';
  }

  @override
  String get createInvoiceTypeFieldLabel => 'बीजक प्रकार';

  @override
  String get createInvoiceTypeLockedHelperText =>
      'सिर्जना गरेपछि प्रकार परिवर्तन गर्न सकिँदैन';

  @override
  String get createInvoiceOrderDateLabel => 'अर्डर मिति';

  @override
  String get createInvoiceDueDateLabel => 'अन्तिम मिति';

  @override
  String get createInvoiceGstTitleLabel => 'जीएसटी शीर्षक';

  @override
  String get createInvoiceTaxTitleLabel => 'कर शीर्षक';

  @override
  String get gstTitleTaxInvoiceLabel => 'कर बीजक';

  @override
  String get gstTitleBillOfSupplyLabel => 'आपूर्ति बिल';

  @override
  String get gstTitleInvoiceCumBillLabel => 'बीजक-सह-आपूर्ति बिल';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => 'क्रेडिट नोट';

  @override
  String get gstTitleDebitNoteLabel => 'डेबिट नोट';

  @override
  String get gstTitleRevisedInvoiceLabel => 'संशोधित बीजक';

  @override
  String get createInvoiceSearchProductLabel =>
      'उत्पादन वा सेवा खोज्नुहोस् र थप्नुहोस् (Ctrl+F)';

  @override
  String get createInvoiceCustomItemButton => 'अनुकूल वस्तु (Ctrl+M)';

  @override
  String get createInvoiceNoProductsFoundMessage => 'कुनै उत्पादन फेला परेन';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '\"$name\" पहिले नै उत्पादन सूचीमा छ';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name उत्पादन सूचीमा सुरक्षित गरियो';
  }

  @override
  String get createInvoiceSaveToProductListTooltip =>
      'उत्पादन सूचीमा सुरक्षित गर्नुहोस्';

  @override
  String get tooltipEditItem => 'वस्तु सम्पादन गर्नुहोस्';

  @override
  String get tooltipRemoveItem => 'वस्तु हटाउनुहोस्';

  @override
  String get createInvoiceNoItemsAddedMessage =>
      'अहिलेसम्म कुनै वस्तु थपिएको छैन';

  @override
  String get createInvoiceSearchHintMessage =>
      'तल खोज्नुहोस् वा Ctrl+F थिच्नुहोस्';

  @override
  String get createInvoiceDiscountFieldLabel => 'बीजक छुट';

  @override
  String get discountTypeAmountShortLabel => 'रकम';

  @override
  String get createInvoiceNotesOptionalLabel => 'नोटहरू (वैकल्पिक)';

  @override
  String get createInvoiceNotesHint => 'भुक्तानी सर्तहरू, धन्यवाद सन्देश…';

  @override
  String get createInvoiceNotesTitle => 'नोटहरू';

  @override
  String get createInvoiceHideNumberInPdfLabel =>
      'PDF मा बीजक नम्बर लुकाउनुहोस्';

  @override
  String get createInvoiceCustomNumberLabel => 'अनुकूल नम्बर (वैकल्पिक)';

  @override
  String get createInvoiceCustomNumberHint =>
      'जस्तै QUO-2026-014 — यसको सट्टा PDF मा देखाइनेछ';

  @override
  String get createInvoiceEnableTaxLabel => 'कर सक्षम गर्नुहोस्';

  @override
  String get createInvoiceGlobalRateTooltip => 'विश्वव्यापी दर';

  @override
  String get createInvoicePerItemRateTooltip => 'प्रति वस्तु दर';

  @override
  String get createInvoiceDefaultTaxRateLabel => 'पूर्वनिर्धारित कर दर';

  @override
  String get createInvoiceTaxRateFromProductMessage =>
      'प्रत्येक उत्पादनबाट कर दर';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => 'भुक्तानी युपिआई खाता';

  @override
  String get commonNoneLabel => 'कुनै पनि होइन';

  @override
  String get createInvoiceBankAccountLabel => 'बैंक खाता';

  @override
  String get fieldSubtotalLabel => 'उप-जम्मा';

  @override
  String get createInvoiceDiscountColonLabel => 'छुट:';

  @override
  String get fieldTaxLabel => 'कर';

  @override
  String get createInvoiceExtraCostFallbackLabel => 'थप लागत';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return 'बीजक छुट ($toStringAsFixed%):';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel => 'बीजक छुट:';

  @override
  String get fieldTotalLabel => 'जम्मा';

  @override
  String get createInvoicePreviewLabel => 'पूर्वावलोकन';

  @override
  String get createInvoicePreviewTooltip => 'पूर्वावलोकन (सर्टकट: Ctrl+o)';

  @override
  String get createInvoiceDownloadLabel => 'डाउनलोड गर्नुहोस्';

  @override
  String get createInvoicePrintTooltip => 'प्रिन्ट गर्नुहोस् (सर्टकट: Ctrl+p)';

  @override
  String get fieldUnitOverrideLabel => 'एकाइ (ओभरराइड)';

  @override
  String get commonCustomEllipsisLabel => 'अनुकूल…';

  @override
  String get fieldCustomUnitLabel => 'अनुकूल एकाइ';

  @override
  String get invoiceMgmtMoveToTrashTitle => 'ट्र्यासमा सार्नुहोस्';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return 'बीजक #$number लाई ट्र्यासमा सार्ने हो?';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage => 'बीजक ट्र्यासमा सारियो।';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return 'बीजकहरू लोड गर्न असफल: $error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return '$type लाई CSV मा निर्यात गर्नुहोस्';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel => 'सबै रेकर्ड निर्यात गर्नुहोस्';

  @override
  String get invoiceMgmtFilterByDateRangeLabel =>
      'वा मिति दायराद्वारा फिल्टर गर्नुहोस्:';

  @override
  String get invoiceMgmtFromDateLabel => 'देखि मिति';

  @override
  String get invoiceMgmtToDateLabel => 'सम्म मिति';

  @override
  String get invoiceMgmtDateRangeInvalidMessage =>
      'सम्म मिति देखि मिति भन्दा पछि हुनुपर्छ।';

  @override
  String get actionExport => 'निर्यात गर्नुहोस्';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रेकर्डहरू यहाँ निर्यात गरियो: $path',
      one: '1 रेकर्ड यहाँ निर्यात गरियो: $path',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return 'निर्यात असफल: $error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू ट्र्यासमा सार्ने हो?',
      one: '1 बीजक ट्र्यासमा सार्ने हो?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू ट्र्यासमा सारियो।',
      one: '1 बीजक ट्र्यासमा सारियो।',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return 'बल्क मेटाउने कार्य असफल: $error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू CSV मा निर्यात गरियो',
      one: '1 बीजक CSV मा निर्यात गरियो',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'CSV निर्यात असफल: $error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => 'PDF हरू डाउनलोड गर्नुहोस्';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'तपाईं $count PDF हरू कसरी सुरक्षित गर्न चाहनुहुन्छ?',
      one: 'तपाईं 1 PDF कसरी सुरक्षित गर्न चाहनुहुन्छ?',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => 'फोल्डरमा सुरक्षित गर्नुहोस्';

  @override
  String get invoiceMgmtSaveAsZipLabel => 'ZIP का रूपमा सुरक्षित गर्नुहोस्';

  @override
  String get invoiceMgmtChooseFolderDialogTitle =>
      'PDF सुरक्षित गर्न फोल्डर छान्नुहोस्';

  @override
  String get invoiceMgmtSaveZipDialogTitle => 'ZIP फाइल सुरक्षित गर्नुहोस्';

  @override
  String get invoiceMgmtCreatingZipLabel => 'ZIP बनाउँदै';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => 'PDF हरू उत्पन्न गर्दै';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PDF हरू प्रक्रिया गर्दै...',
      one: '1 PDF प्रक्रिया गर्दै...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return 'यहाँ सुरक्षित गरियो: $path';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'PDF निर्यात असफल: $error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle =>
      'फिल्टरद्वारा PDF डाउनलोड गर्नुहोस्';

  @override
  String get invoiceMgmtByDateLabel => 'मितिद्वारा';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => 'बीजक नम्बरद्वारा';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => 'देखि बीजक #';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => 'सम्म बीजक #';

  @override
  String get invoiceMgmtCheckCountLabel => 'गणना जाँच गर्नुहोस्';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return '$count बीजकहरू — सीमा $limit भन्दा बढी';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू मेल खान्छन्',
      one: '1 बीजक मेल खान्छ',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return 'प्रति डाउनलोड बढीमा $limit PDF। आफ्नो फिल्टर साँघुरो बनाउनुहोस्।';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage =>
      'चयन गरिएको फिल्टरका लागि कुनै बीजक फेला परेन।';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return 'फिल्टरले $count बीजकहरू फर्कायो — अधिकतम $limit हो।';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => 'बीजकहरू फिल्टर गर्नुहोस्';

  @override
  String get invoiceMgmtHideFullyPaidLabel =>
      'पूर्ण भुक्तानी भएका बीजकहरू लुकाउनुहोस्';

  @override
  String get invoiceMgmtPaymentStatusLabel => 'भुक्तानी स्थिति';

  @override
  String get invoiceMgmtDueDateLabel => 'म्याद मिति';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => 'बीजक मिति दायरा';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel => 'बीजक # दायरा';

  @override
  String get invoiceMgmtFromHashLabel => 'देखि #';

  @override
  String get invoiceMgmtToHashLabel => 'सम्म #';

  @override
  String get actionReset => 'रिसेट गर्नुहोस्';

  @override
  String get actionApply => 'लागू गर्नुहोस्';

  @override
  String get invoiceMgmtSortByTitle => 'क्रमबद्ध गर्नुहोस्';

  @override
  String get invoiceMgmtSearchHintMessage =>
      'बीजक ID वा ग्राहकको नामद्वारा खोज्नुहोस्…';

  @override
  String get invoiceMgmtFilterLabel => 'फिल्टर';

  @override
  String get invoiceMgmtSortLabel => 'क्रमबद्ध';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return 'जम्मा: $total   ·   पृष्ठ $page/$totalPages';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '$count चयन गरियो';
  }

  @override
  String get invoiceMgmtDeselectLabel => 'चयन हटाउनुहोस्';

  @override
  String get invoiceMgmtSelectPageLabel => 'पृष्ठ चयन गर्नुहोस्';

  @override
  String get invoiceMgmtMarkPaidLabel => 'भुक्तानी भएको चिन्ह लगाउनुहोस्';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDF हरू';

  @override
  String get invoiceMgmtTrashLabel => 'ट्र्यास';

  @override
  String get actionApplyPayment => 'भुक्तानी लागू गर्नुहोस्';

  @override
  String get invoiceMgmtMoreActionsTooltip => 'थप कार्यहरू';

  @override
  String get invoiceMgmtColSlNo => 'क्र.सं.';

  @override
  String get invoiceMgmtColInvoiceCustomer => 'बीजक / ग्राहक';

  @override
  String get invoiceMgmtColTitle => 'शीर्षक';

  @override
  String get invoiceMgmtColDate => 'मिति';

  @override
  String get invoiceMgmtColItems => 'वस्तुहरू';

  @override
  String get invoiceMgmtColStatus => 'स्थिति';

  @override
  String get invoiceMgmtColOutstanding => 'बाँकी';

  @override
  String get invoiceMgmtColActions => 'कार्यहरू';

  @override
  String get invoiceMgmtRowsPerPageLabel => 'प्रति पृष्ठ पङ्क्तिहरू:';

  @override
  String get actionPrevious => 'अघिल्लो';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return 'पृष्ठ $page को $totalPages';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return '\"$query\" का लागि कुनै नतिजा फेला परेन';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return 'कुनै $type फेला परेन';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return 'यहाँ हेर्न आफ्नो पहिलो $type सिर्जना गर्नुहोस्';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage =>
      'आफ्नो खोज वा फिल्टर मिलाउने प्रयास गर्नुहोस्';

  @override
  String get invoiceMgmtDownloadByRangeTooltip =>
      'मिति वा बीजक दायराद्वारा PDF डाउनलोड गर्नुहोस्';

  @override
  String get invoiceMgmtExportAllCsvTooltip =>
      'सबैलाई CSV मा निर्यात गर्नुहोस्';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel =>
      'दायराद्वारा PDF डाउनलोड गर्नुहोस्';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return '$type व्यवस्थापन';
  }

  @override
  String get invoiceMgmtOverdueBadge => 'म्याद नाघेको';

  @override
  String get invoiceMgmtTodayBadge => 'आज';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => 'ट्र्यास खाली छ';

  @override
  String get actionRestore => 'पुनर्स्थापना गर्नुहोस्';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => 'स्थायी रूपमा मेटाउनुहोस्';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return 'बीजक #$number लाई स्थायी रूपमा मेटाउने हो? यो पूर्ववत गर्न सकिँदैन।';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage => 'बीजक पुनर्स्थापना गरियो।';

  @override
  String get invoiceMgmtAnyDateLabel => 'जुनसुकै';

  @override
  String get invoiceMgmtStatusAllLabel => 'सबै';

  @override
  String get invoiceMgmtDueAllLabel => 'सबै म्यादहरू';

  @override
  String get invoiceMgmtDueTodayLabel => 'आज म्याद';

  @override
  String get invoiceMgmtDueWeekLabel => 'यो हप्ता म्याद';

  @override
  String get invoiceMgmtDueMonthLabel => 'यो महिना म्याद';

  @override
  String get invoiceMgmtSortRecentlyAdded => 'भर्खरै थपिएको';

  @override
  String get invoiceMgmtSortOldestAdded => 'सबैभन्दा पुरानो थपिएको';

  @override
  String get invoiceMgmtSortDateNewest => 'बीजक मिति (नयाँ पहिले)';

  @override
  String get invoiceMgmtSortDateOldest => 'बीजक मिति (पुरानो पहिले)';

  @override
  String get invoiceMgmtSortCustomerAZ => 'ग्राहकको नाम (क-ज्ञ)';

  @override
  String get invoiceMgmtSortCustomerZA => 'ग्राहकको नाम (ज्ञ-क)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => 'भुक्तानी भएको चिन्ह लगाउनुहोस्';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरूलाई पूर्ण भुक्तानी भएको चिन्ह लगाउने हो?',
      one: '1 बीजकलाई पूर्ण भुक्तानी भएको चिन्ह लगाउने हो?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n($count पहिले नै भुक्तानी भइसकेको — छोडिनेछ)';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage =>
      'चयन गरिएका सबै बीजकहरू पहिले नै पूर्ण भुक्तानी भइसकेका छन्।';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बीजकहरू भुक्तानी भएको चिन्ह लगाइयो।',
      one: '1 बीजक भुक्तानी भएको चिन्ह लगाइयो।',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return 'भुक्तानी भएको चिन्ह लगाउन असफल: $error';
  }

  @override
  String get fieldNameLabel => 'नाम';

  @override
  String get customerMgmtEditCustomerTitle => 'ग्राहक सम्पादन गर्नुहोस्';

  @override
  String get customerMgmtViewCustomerTitle => 'ग्राहक हेर्नुहोस्';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / भ्याट नम्बर';
  }

  @override
  String get customerMgmtUpdatedMessage => 'ग्राहक सफलतापूर्वक अपडेट गरियो!';

  @override
  String fieldRequiredMessage(String field) {
    return 'कृपया $field प्रविष्ट गर्नुहोस्';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => 'मेटाउने पुष्टि गर्नुहोस्';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return 'के तपाईं वास्तवमै \"$name\" मेटाउन चाहनुहुन्छ?';
  }

  @override
  String get customerMgmtDeletedMessage => 'ग्राहक सफलतापूर्वक मेटाइयो!';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle =>
      'नमूना CSV सुरक्षित गर्नुहोस्';

  @override
  String get customerMgmtSampleSavedMessage =>
      'नमूना CSV सफलतापूर्वक सुरक्षित गरियो!';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return 'नमूना सुरक्षित गर्दा त्रुटि: $error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle =>
      'CSV बाट ग्राहकहरू आयात गर्नुहोस्';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      'तपाईंको CSV फाइलले निम्न स्तम्भ हेडरहरू प्रयोग गर्नुपर्छ (सटीक हिज्जे, कुनै पनि क्रममा):';

  @override
  String get customerMgmtCsvColColumnHeader => 'स्तम्भ';

  @override
  String get customerMgmtCsvColRequiredHeader => 'आवश्यक';

  @override
  String get customerMgmtCsvColDescriptionHeader => 'विवरण';

  @override
  String get commonYesLabel => 'हो';

  @override
  String get commonNoLabel => 'होइन';

  @override
  String get customerMgmtCsvDescName => 'ग्राहकको पूरा नाम';

  @override
  String get customerMgmtCsvDescEmail => 'इमेल ठेगाना';

  @override
  String get customerMgmtCsvDescPhone => 'फोन नम्बर';

  @override
  String get customerMgmtCsvDescAddress => 'पूरा ठेगाना';

  @override
  String get customerMgmtCsvDescBusinessName => 'कम्पनी / व्यवसायको नाम';

  @override
  String get customerMgmtCsvDescTaxNumber => 'कर / भ्याट / GSTIN नम्बर';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return 'प्रति आयात अधिकतम $max पङ्क्तिहरू।';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      'डुप्लिकेटहरू इमेल वा फोनद्वारा पत्ता लगाइन्छ। तपाईंलाई प्रत्येकलाई ओभरराइट वा छोड्न सोधिनेछ।';

  @override
  String get customerMgmtCsvMissingNameNote =>
      'नाम नभएका पङ्क्तिहरू छोडिन्छन् र अन्त्यमा रिपोर्ट गरिन्छ।';

  @override
  String get customerMgmtCsvEncodingNote =>
      'UTF-8 इन्कोडिङ सिफारिस गरिन्छ। Excel BOM स्वचालित रूपमा ह्यान्डल गरिन्छ।';

  @override
  String get customerMgmtDownloadSampleCsvButton =>
      'नमूना CSV डाउनलोड गर्नुहोस्';

  @override
  String get customerMgmtChooseFileButton => 'फाइल छान्नुहोस्';

  @override
  String get customerMgmtSelectCsvDialogTitle => 'ग्राहक CSV छान्नुहोस्';

  @override
  String get customerMgmtCsvEmptyMessage => 'CSV फाइल खाली छ।';

  @override
  String get customerMgmtCsvMissingNameColumnMessage =>
      'CSV मा आवश्यक स्तम्भ छैन: \"name\"';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return 'अज्ञात स्तम्भ \"$col\"। अपेक्षित: $expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'CSV मा $count पङ्क्तिहरू छन्। अधिकतम $max हो। कृपया फाइल विभाजन गर्नुहोस्।';
  }

  @override
  String get customerMgmtImportingTitle => 'ग्राहकहरू आयात हुँदैछन्';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'डुप्लिकेट जाँच र $count पङ्क्तिहरू प्रमाणित गर्दै...',
      one: 'डुप्लिकेट जाँच र 1 पङ्क्ति प्रमाणित गर्दै...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return 'पङ्क्ति $n: नाम छैन — छोडियो';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return 'CSV पढ्दा त्रुटि: $error';
  }

  @override
  String get customerMgmtImportPreviewTitle => 'आयात पूर्वावलोकन';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नयाँ',
      one: '1 नयाँ',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डुप्लिकेटहरू',
      one: '1 डुप्लिकेट',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count त्रुटिहरू',
      one: '1 त्रुटि',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel =>
      'डुप्लिकेटहरू (इमेल वा फोनद्वारा मिलाइएको):';

  @override
  String get customerMgmtOverwriteAllButton => 'सबै ओभरराइट गर्नुहोस्';

  @override
  String get customerMgmtSkipAllButton => 'सबै छोड्नुहोस्';

  @override
  String get customerMgmtOverwriteLabel => 'ओभरराइट';

  @override
  String get customerMgmtSkippedRowsLabel => 'छोडिएका पङ्क्तिहरू (त्रुटिहरू):';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total ग्राहकहरू आयात गरिनेछ।',
      one: '1 ग्राहक आयात गरिनेछ।',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return '$total आयात गर्नुहोस्';
  }

  @override
  String get customerMgmtDeleteAllTitle => 'सबै ग्राहक मेटाउनुहोस्';

  @override
  String get customerMgmtNoCustomersToDeleteMessage =>
      'मेटाउन कुनै ग्राहक छैन।';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यसले सबै $count ग्राहकहरूलाई स्थायी रूपमा मेटाउनेछ। भइरहेका बीजकहरूमा असर पर्दैन। यो पूर्ववत गर्न सकिँदैन।',
      one:
          'यसले सबै 1 ग्राहकलाई स्थायी रूपमा मेटाउनेछ। भइरहेका बीजकहरूमा असर पर्दैन। यो पूर्ववत गर्न सकिँदैन।',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => 'सबै मेटाउनुहोस्';

  @override
  String get customerMgmtAllDeletedMessage => 'सबै ग्राहकहरू मेटाइयो।';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return 'ग्राहकहरू मेटाउँदा त्रुटि: $error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => 'ग्राहक CSV सुरक्षित गर्नुहोस्';

  @override
  String get customerMgmtCsvExportedMessage => 'CSV सफलतापूर्वक निर्यात गरियो!';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return 'CSV निर्यात गर्दा त्रुटि: $error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => 'ग्राहक PDF सुरक्षित गर्नुहोस्';

  @override
  String get customerMgmtPdfExportedMessage => 'PDF सफलतापूर्वक निर्यात गरियो!';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return 'PDF निर्यात गर्दा त्रुटि: $error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => 'कुल ग्राहकहरू';

  @override
  String get customerMgmtAllCustomersSubtitle => 'सबै ग्राहकहरू';

  @override
  String get customerMgmtBusinessesLabel => 'व्यवसायहरू';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle =>
      'दर्ता भएका व्यवसायहरू';

  @override
  String get customerMgmtIndividualsLabel => 'व्यक्तिगत';

  @override
  String get customerMgmtIndividualCustomersSubtitle => 'व्यक्तिगत ग्राहकहरू';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '$taxWord दर्ता भएको';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return '$taxWord नम्बर सहित';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return '$taxWord बिना';
  }

  @override
  String get customerMgmtTitle => 'ग्राहक व्यवस्थापन';

  @override
  String get customerMgmtSubtitle =>
      'आफ्ना ग्राहकहरू र सम्पर्क विवरण व्यवस्थापन गर्नुहोस्';

  @override
  String get actionImport => 'आयात गर्नुहोस्';

  @override
  String get customerMgmtExportPdfMenuLabel => 'PDF निर्यात गर्नुहोस्';

  @override
  String get customerMgmtNewCustomerButton => 'नयाँ ग्राहक';

  @override
  String get customerMgmtSortNameAZ => 'नाम A-Z';

  @override
  String get customerMgmtSortNameZA => 'नाम Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID (पुरानो पहिले)';

  @override
  String get customerMgmtSortIdNewest => 'ID (नयाँ पहिले)';

  @override
  String get customerMgmtSortOutstandingHighLow => 'बाँकी (धेरैदेखि थोरै)';

  @override
  String get customerMgmtSortOutstandingLowHigh => 'बाँकी (थोरैदेखि धेरै)';

  @override
  String get customerMgmtWithOutstandingLabel => 'बाँकी भएका';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return 'नाम, व्यवसाय, फोन, $taxWord, इमेलद्वारा ग्राहक खोज्नुहोस्…';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return 'सबै $taxWord स्थितिहरू';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '$taxWord दर्ता भएको';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return 'क्रमबद्ध गर्नुहोस्: $label';
  }

  @override
  String get customerMgmtColumnsLabel => 'स्तम्भहरू';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / भ्याट नम्बर';
  }

  @override
  String get customerMgmtHideStatCardsTooltip =>
      'तथ्याङ्क कार्डहरू लुकाउनुहोस्';

  @override
  String get customerMgmtShowStatCardsTooltip =>
      'तथ्याङ्क कार्डहरू देखाउनुहोस्';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get customerMgmtColSlNo => 'क्र.सं.';

  @override
  String get customerMgmtColNameBusiness => 'नाम / व्यवसाय';

  @override
  String get customerMgmtColPhone => 'फोन';

  @override
  String get customerMgmtColEmail => 'इमेल';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / भ्याट नम्बर';
  }

  @override
  String get customerMgmtColAddress => 'ठेगाना';

  @override
  String get customerMgmtColActions => 'कार्यहरू';

  @override
  String get customerMgmtViewStatementTooltip =>
      'स्टेटमेन्ट हेर्नुहोस् (रिपोर्टमा)';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return '$total मध्ये $from देखि $to देखाउँदै';
  }

  @override
  String get customerMgmtRowsPerPageLabel => 'प्रति पृष्ठ पङ्क्तिहरू';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return '$totalPages मध्ये';
  }

  @override
  String get customerMgmtAddAnotherLabel => 'सुरक्षित गरेपछि अर्को थप्नुहोस्';

  @override
  String get customerMgmtSaveCustomerButton => 'ग्राहक सुरक्षित गर्नुहोस्';

  @override
  String get customerMgmtAddFirstCustomerSubtitle =>
      'सुरु गर्न आफ्नो पहिलो ग्राहक थप्नुहोस्';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle =>
      'आफ्नो खोज समायोजन गर्ने प्रयास गर्नुहोस्';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return 'ग्राहकहरू लोड गर्दा त्रुटि: $error';
  }

  @override
  String get customerMgmtAddedMessage => 'ग्राहक सफलतापूर्वक थपियो!';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return 'ग्राहक सुरक्षित गर्दा त्रुटि: $error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ग्राहकहरू सफलतापूर्वक आयात गरियो!',
      one: '1 ग्राहक सफलतापूर्वक आयात गरियो!',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return 'आयात त्रुटि: $error';
  }

  @override
  String get taxWordGst => 'जीएसटी';

  @override
  String get taxWordTax => 'कर';

  @override
  String get commonMoreLabel => 'थप';

  @override
  String get productMgmtSellingAtLossTitle => 'घाटामा बेच्दै';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return 'खरिद मूल्य ($purchase) बिक्री मूल्य ($sale) भन्दा बढी छ। जे भए पनि सुरक्षित गर्ने?';
  }

  @override
  String get actionSaveAnyway => 'जे भए पनि सुरक्षित गर्नुहोस्';

  @override
  String get productMgmtAdvancedInformationLabel => 'उन्नत जानकारी';

  @override
  String get productMgmtStorageLocationLabel => 'भण्डारण स्थान';

  @override
  String get productMgmtContainerNumberLabel => 'कन्टेनर नम्बर';

  @override
  String get productMgmtBatchNumberLabel => 'ब्याच नम्बर';

  @override
  String get productMgmtExpiryDateLabel => 'म्याद सकिने मिति';

  @override
  String get productMgmtManufactureDateLabel => 'उत्पादन मिति';

  @override
  String get productMgmtSupplierNameLabel => 'आपूर्तिकर्ताको नाम';

  @override
  String get productMgmtSkuCodeLabel => 'SKU कोड';

  @override
  String get productMgmtNotesLabel => 'टिप्पणीहरू';

  @override
  String get fieldEnterValidPriceMessage => 'मान्य मूल्य प्रविष्ट गर्नुहोस्';

  @override
  String get fieldEnterValidStockMessage => 'मान्य स्टक प्रविष्ट गर्नुहोस्';

  @override
  String get fieldTaxRangeMessage => 'कर ०-१०० बीचमा हुनुपर्छ';

  @override
  String get productMgmtImportProductsCsvTitle =>
      'CSV बाट उत्पादनहरू आयात गर्नुहोस्';

  @override
  String get productMgmtCsvDescName => 'उत्पादनको नाम';

  @override
  String get productMgmtCsvDescPrice => 'एकाइ मूल्य (संख्यात्मक)';

  @override
  String get productMgmtCsvDescHsnCode => 'HSN / SAC कोड';

  @override
  String get productMgmtCsvDescDescription => 'छोटो विवरण';

  @override
  String get productMgmtCsvDescTaxRate => 'कर % (०–१००), पूर्वनिर्धारित ०';

  @override
  String get productMgmtCsvDescStock => 'स्टक परिमाण, पूर्वनिर्धारित ०';

  @override
  String get productMgmtCsvDescType =>
      '\"product\" वा \"service\", पूर्वनिर्धारित product';

  @override
  String get productMgmtCsvDescDefaultDiscount =>
      'फ्ल्याट छुट रकम (मुद्रा), पूर्वनिर्धारित ०';

  @override
  String get productMgmtCsvDescPurchasePrice =>
      'लागत मूल्य (संख्यात्मक), पूर्वनिर्धारित ०';

  @override
  String get productMgmtCsvDescAliasName =>
      'PDF का लागि स्थानीय-भाषा प्रदर्शन नाम';

  @override
  String get productMgmtCsvDescUnit =>
      'मापन एकाइ (जस्तै kg, bag, pcs), पूर्वनिर्धारित pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock =>
      'असीमित स्टकको लागि 1/true, पूर्वनिर्धारित ०';

  @override
  String get productMgmtCsvDescPriceIncludesTax =>
      'मूल्यमा कर समावेश भए 1/true, पूर्वनिर्धारित ०';

  @override
  String get productMgmtCsvDescStorageLocation => 'गोदाम/दराज स्थान';

  @override
  String get productMgmtCsvDescContainerNumber => 'कन्टेनर/बक्स नम्बर';

  @override
  String get productMgmtCsvDescBatchNumber => 'ब्याच/लट नम्बर';

  @override
  String get productMgmtCsvDescExpiryDate => 'म्याद सकिने मिति';

  @override
  String get productMgmtCsvDescManufactureDate => 'उत्पादन मिति';

  @override
  String get productMgmtCsvDescSupplierName => 'आपूर्तिकर्ताको नाम';

  @override
  String get productMgmtCsvDescSkuCode => 'SKU कोड';

  @override
  String get productMgmtCsvDescNotes => 'स्वतन्त्र-पाठ टिप्पणीहरू';

  @override
  String get productMgmtCsvDuplicateNote =>
      'नक्कलहरू उत्पादनको नाम (केस-असंवेदनशील) द्वारा पत्ता लगाइन्छ। तपाईंलाई प्रत्येकलाई ओभरराइट वा छोड्न सोधिनेछ।';

  @override
  String get productMgmtCsvMissingRequiredNote =>
      'नाम वा मूल्य नभएका पङ्क्तिहरू छोडिन्छन् र रिपोर्ट गरिन्छन्।';

  @override
  String get productMgmtSelectCsvDialogTitle => 'उत्पादन CSV चयन गर्नुहोस्';

  @override
  String get productMgmtCsvMissingPriceColumnMessage =>
      'CSV मा आवश्यक स्तम्भ छैन: \"price\"';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return 'पङ्क्ति $n: अमान्य मूल्य \"$price\" — छोडियो';
  }

  @override
  String get productMgmtImportingTitle => 'उत्पादनहरू आयात गर्दै';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel =>
      'नक्कलहरू (नामद्वारा मिलाइएको):';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total उत्पादनहरू आयात गरिनेछन्।',
      one: '1 उत्पादन आयात गरिनेछ।',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage => 'मेटाउन कुनै उत्पादन छैन।';

  @override
  String get productMgmtDeleteAllTitle => 'सबै उत्पादनहरू मेटाउनुहोस्';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यसले सबै $count उत्पादनहरू स्थायी रूपमा मेटाउनेछ। अवस्थित बीजकहरू प्रभावित हुँदैनन्। यो पूर्ववत गर्न सकिँदैन।',
      one:
          'यसले सबै 1 उत्पाद स्थायी रूपमा मेटाउनेछ। अवस्थित बीजकहरू प्रभावित हुँदैनन्। यो पूर्ववत गर्न सकिँदैन।',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage => 'सबै उत्पादनहरू मेटाइयो।';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return 'उत्पादनहरू मेटाउँदा त्रुटि: $error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle =>
      'उत्पादन CSV सुरक्षित गर्नुहोस्';

  @override
  String get productMgmtExportToPdfTitle => 'PDF मा निर्यात गर्नुहोस्';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return 'हालको पृष्ठ ($pageSize उत्पादनहरू) वा सबै $allCount उत्पादनहरू निर्यात गर्ने?';
  }

  @override
  String get productMgmtCurrentPageLabel => 'हालको पृष्ठ';

  @override
  String get productMgmtAllProductsLabel => 'सबै उत्पादनहरू';

  @override
  String get productMgmtSaveProductsPdfDialogTitle =>
      'उत्पादन PDF सुरक्षित गर्नुहोस्';

  @override
  String get productMgmtTitle => 'उत्पादन व्यवस्थापन';

  @override
  String get productMgmtSubtitle =>
      'आफ्ना उत्पादन र सेवाहरू व्यवस्थापन गर्नुहोस्';

  @override
  String get productMgmtNewProductButton => 'नयाँ उत्पादन';

  @override
  String get productMgmtSearchHint =>
      'नाम, उपनाम, HSN/SAC, SKU द्वारा उत्पादनहरू खोज्नुहोस्…';

  @override
  String get productMgmtFilterByStockStatusTooltip =>
      'स्टक स्थितिद्वारा फिल्टर गर्नुहोस्';

  @override
  String get productMgmtAllStockLevelsLabel => 'सबै स्टक स्तरहरू';

  @override
  String get productMgmtLowStockLabel => 'कम स्टक';

  @override
  String get productMgmtLowStockTabLabel => 'कम स्टक';

  @override
  String get productMgmtOutOfStockLabel => 'स्टक सकियो';

  @override
  String get productMgmtOutOfStockTabLabel => 'स्टक सकियो';

  @override
  String get productMgmtExpiredLabel => 'म्याद सकिएको';

  @override
  String get productMgmtSortPriceLowHigh => 'मूल्य कम-बढी';

  @override
  String get productMgmtSortPriceHighLow => 'मूल्य बढी-कम';

  @override
  String get productMgmtSortStockLowHigh => 'स्टक कम-बढी';

  @override
  String get productMgmtSortStockHighLow => 'स्टक बढी-कम';

  @override
  String get productMgmtServicesTabLabel => 'सेवाहरू';

  @override
  String get productMgmtColSlNo => 'क्र.सं.';

  @override
  String get productMgmtColNameAlias => 'नाम / उपनाम';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => 'मूल्य';

  @override
  String get productMgmtColPurchase => 'खरिद';

  @override
  String get productMgmtColStock => 'स्टक';

  @override
  String get productMgmtColTaxPercent => 'कर %';

  @override
  String get productMgmtColExpiryDate => 'म्याद मिति';

  @override
  String get productMgmtCustomizeColumnsLabel => 'Customize Product Columns';

  @override
  String get productMgmtShowColumnsLabel => 'Show Columns';

  @override
  String productMgmtShowColumnsMaxHint(int max) {
    return 'Show up to $max columns';
  }

  @override
  String productMgmtShowingRangeLabel(int from, int to, int total) {
    return '$total उत्पादनहरूमध्ये $from देखि $to देखाइँदै';
  }

  @override
  String get productMgmtAddFirstProductSubtitle =>
      'सुरु गर्न आफ्नो पहिलो उत्पादन थप्नुहोस्';

  @override
  String get productMgmtColumnsBannerTitle =>
      'नयाँ: उत्पादन क्षेत्रहरू अनुकूलन गर्नुहोस्';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      'सरल क्याटलगका लागि कुन क्षेत्रहरू देखाउने छान्नुहोस्। सेटिङ > उत्पादन विवरण अनुकूलन गर्नुहोस्।';

  @override
  String get productMgmtConfigureAction => 'कन्फिगर गर्नुहोस्';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return 'नयाँ $type थप्नुहोस्';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle =>
      'उत्पादन विवरण प्रविष्ट गर्नुहोस्';

  @override
  String get productMgmtSaveProductButton => 'उत्पादन सुरक्षित गर्नुहोस्';

  @override
  String get productMgmtAliasNameLabel => 'उपनाम (बीजक PDF का लागि)';

  @override
  String get productMgmtAliasHelperText =>
      'वैकल्पिक स्थानीय-भाषा प्रदर्शन नाम जुन केवल PDF बीजकहरूमा प्रयोग हुन्छ।';

  @override
  String get productMgmtDescriptionLabel => 'विवरण';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => 'बिक्री मूल्य';

  @override
  String get productMgmtPurchasePriceLabel => 'खरिद मूल्य';

  @override
  String get productMgmtDefaultDiscountLabel => 'पूर्वनिर्धारित छुट';

  @override
  String get productMgmtTaxPercentLabel => 'कर (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel => 'प्रति-वस्तु कर मोड मात्र';

  @override
  String get productMgmtSectionGeneral => 'सामान्य';

  @override
  String get productMgmtSectionPricing => 'मूल्य निर्धारण';

  @override
  String get productMgmtSectionInventory => 'सूची';

  @override
  String get productMgmtUnlimitedStockLabel => 'असीमित स्टक';

  @override
  String get productMgmtTrackInfiniteStockSubtitle =>
      'यस उत्पादनको लागि असीमित स्टक ट्र्याक गर्नुहोस्';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      'सुझाव: थप विवरणहरू थप्न स्तम्भहरूबाट अनुकूलित क्षेत्रहरू सक्षम गर्नुहोस्।';

  @override
  String get productMgmtEditProductTitle => 'उत्पादन सम्पादन गर्नुहोस्';

  @override
  String get productMgmtViewProductTitle => 'उत्पादन हेर्नुहोस्';

  @override
  String get productMgmtUpdateProductDetailsSubtitle =>
      'उत्पादन विवरण अपडेट गर्नुहोस्';

  @override
  String get productMgmtProductDetailsSubtitle => 'उत्पादन विवरण';

  @override
  String get productMgmtUpdatedMessage => 'उत्पादन/सेवा सफलतापूर्वक अपडेट भयो!';

  @override
  String get productMgmtDeleteProductButton => 'उत्पादन मेटाउनुहोस्';

  @override
  String get productMgmtSaveChangesButton => 'परिवर्तनहरू सुरक्षित गर्नुहोस्';

  @override
  String get fieldUnitLabel => 'एकाइ';

  @override
  String get productMgmtAddedMessage => 'उत्पादन सफलतापूर्वक थपियो!';

  @override
  String productMgmtAddErrorMessage(String error) {
    return 'उत्पादन थप्दा त्रुटि: $error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return 'उत्पादनहरू लोड गर्दा त्रुटि: $error';
  }

  @override
  String get productMgmtDeletedMessage => 'उत्पादन सफलतापूर्वक मेटाइयो!';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count उत्पादनहरू सफलतापूर्वक आयात गरियो!',
      one: '1 उत्पादन सफलतापूर्वक आयात गरियो!',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => 'कुल वस्तुहरू';

  @override
  String get productMgmtTangibleProductsSubtitle => 'मूर्त उत्पादनहरू';

  @override
  String get productMgmtNonTangibleServicesSubtitle => 'अमूर्त सेवाहरू';

  @override
  String get productMgmtNeedAttentionSubtitle => 'ध्यान चाहिन्छ';

  @override
  String get productMgmtProductNameLabel => 'उत्पादनको नाम';

  @override
  String get productMgmtPriceLabel => 'मूल्य';

  @override
  String get actionClear => 'खाली गर्नुहोस्';

  @override
  String get reportsAboutConversionRateTitle => 'रूपान्तरण दर बारे';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return 'पुरानो प्राप्य ($count)';
  }

  @override
  String get reportsAllCurrenciesLabel => 'सबै मुद्राहरू';

  @override
  String get reportsAvgInvoiceValueLabel => 'औसत बीजक मूल्य';

  @override
  String get reportsBalanceColumnLabel => 'ब्यालेन्स';

  @override
  String get reportsBilledLabel => 'बिल गरिएको';

  @override
  String get reportsBucket0to30Label => '०–३० दिन';

  @override
  String get reportsBucket31to60Label => '३१–६० दिन';

  @override
  String get reportsBucket61to90Label => '६१–९० दिन';

  @override
  String get reportsBucket90PlusLabel => '९०+ दिन';

  @override
  String get reportsBucketLabel => 'समूह';

  @override
  String get reportsClosingLabel => 'अन्तिम मौज्दात';

  @override
  String get reportsCogsColumnLabel => 'बिक्री लागत';

  @override
  String get reportsConversionRateExplanationBody =>
      'रूपान्तरण दर = सिर्जना गरिएका बीजकहरू ÷ जारी कोटेसनहरू × १००।\nयदि दर १००% भन्दा बढी छ भने, चयन गरिएको अवधिमा कोटेसनभन्दा बढी बीजकहरू सिर्जना गरिएका थिए भन्ने बुझिन्छ (कोटेसन बिना सिधै बीजक बनाउँदा सामान्य)।\n\nनोट: यो अवधि-स्तरको अनुपात हो, व्यक्तिगत कोटेसन-देखि-बीजक ट्र्याकिङ होइन।';

  @override
  String get reportsConversionRateLabel => 'रूपान्तरण दर';

  @override
  String get reportsCreditColumnLabel => 'क्रेडिट';

  @override
  String get reportsCurrencySectionLabel => 'मुद्रा';

  @override
  String get reportsCurrentBucketLabel => 'हालको';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return 'हाल चयन गरिएको मुद्रा ($currency)';
  }

  @override
  String get reportsCustomRangeLabel => 'अनुकूल दायरा';

  @override
  String get reportsDailySalesProfitTitle => 'दैनिक बिक्री र नाफा';

  @override
  String reportsDaysCountLabel(int d) {
    return '$d दिन';
  }

  @override
  String get reportsDaysOverdueLabel => 'म्याद नाघेको दिन';

  @override
  String get reportsDebitColumnLabel => 'डेबिट';

  @override
  String get reportsDiscountGivenColumnLabel => 'दिइएको छुट';

  @override
  String get reportsExportCsvLabel => 'CSV निर्यात';

  @override
  String reportsFilteredToDateLabel(String date) {
    return '$date मा फिल्टर गरियो';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अवधिमा $countString बीजकहरू · $scope',
      one: 'अवधिमा १ बीजक · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => 'बीजक आईडी';

  @override
  String get reportsInvoicedLabel => 'बीजक गरिएको';

  @override
  String get reportsInvoicesColumnLabel => 'बीजकहरू';

  @override
  String get reportsInvoicesInPeriodLabel => 'अवधिमा बीजकहरू';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get reportsMarginColumnLabel => 'मार्जिन';

  @override
  String get reportsMaxRangeOneYearMessage =>
      'अधिकतम दायरा १ वर्ष हो। अन्तिम मिति सीमित गरियो।';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage =>
      'अधिकतम दायरा ३१ दिन हो। अन्तिम मिति सीमित गरियो।';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यस अवधिमा बिक्री भएका $count वस्तुहरूको खरिद मूल्य सेट गरिएको छैन — ती वस्तुहरूको लागि खरिद मूल्य नथपिएसम्म नाफा/मार्जिन कम देखाइन्छ।',
      one:
          'यस अवधिमा बिक्री भएको १ वस्तुको खरिद मूल्य सेट गरिएको छैन — त्यो वस्तुको लागि खरिद मूल्य नथपिएसम्म नाफा/मार्जिन कम देखाइन्छ।',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => 'महिना र वर्ष';

  @override
  String get reportsMonthlyRevenueTrendTitle => 'मासिक राजस्व प्रवृत्ति';

  @override
  String get reportsNavDailyReportLabel => 'दैनिक प्रतिवेदन';

  @override
  String get reportsNavInvoiceStatusLabel => 'बीजक स्थिति';

  @override
  String get reportsNavReceivablesLabel => 'प्राप्य रकम';

  @override
  String get reportsNavRevenueLabel => 'राजस्व';

  @override
  String get reportsNavTaxLabel => 'कर';

  @override
  String get reportsNoCustomerDataMessage => 'यस अवधिमा ग्राहक डेटा छैन';

  @override
  String get reportsNoCustomersMatchSearchMessage =>
      'यो खोजसँग कुनै ग्राहक मेल खाँदैन';

  @override
  String get reportsNoCustomersWithInvoicesMessage =>
      'बीजक भएका ग्राहकहरू छैनन्';

  @override
  String get reportsNoDueDateLabel => 'म्याद मिति छैन';

  @override
  String get reportsNoInvoiceDataMessage => 'यस अवधिमा बीजक डेटा छैन';

  @override
  String get reportsNoInvoicesInPeriodMessage => 'यस अवधिमा बीजकहरू छैनन्';

  @override
  String get reportsNoInvoicesMatchFilterMessage =>
      'यो फिल्टरसँग कुनै बीजक मेल खाँदैन';

  @override
  String get reportsNoOutstandingInvoicesMessage => 'बाँकी बीजकहरू छैनन्';

  @override
  String get reportsNoProductDataMessage => 'यस अवधिमा उत्पादन डेटा छैन';

  @override
  String get reportsNoSalesInPeriodMessage => 'यस अवधिमा बिक्री छैन';

  @override
  String get reportsNoStatementActivityMessage =>
      'यस ग्राहकको लागि स्टेटमेन्ट गतिविधि छैन';

  @override
  String get reportsNoTaxableItemsMessage =>
      'यस अवधिमा कर लाग्ने वस्तुहरू छैनन्';

  @override
  String get reportsNoTransactionsMessage => 'यस अवधिमा कारोबार छैन';

  @override
  String get reportsOpeningLabel => 'सुरुको मौज्दात';

  @override
  String get reportsOverviewLabel => 'सिंहावलोकन';

  @override
  String get reportsPaymentStatusBreakdownTitle => 'भुक्तानी स्थिति विश्लेषण';

  @override
  String get reportsPeriodSectionLabel => 'अवधि';

  @override
  String get reportsPresetLast30DaysLabel => 'पछिल्लो ३० दिन';

  @override
  String get reportsPresetLast3MonthsLabel => 'पछिल्लो ३ महिना';

  @override
  String get reportsPresetLast6MonthsLabel => 'पछिल्लो ६ महिना';

  @override
  String get reportsPresetLastFYLabel => 'गत आर्थिक वर्ष';

  @override
  String get reportsPresetThisFYLabel => 'यो आर्थिक वर्ष';

  @override
  String get reportsPresetThisYearLabel => 'यो वर्ष';

  @override
  String get reportsProductServiceColumnLabel => 'उत्पादन / सेवा';

  @override
  String get reportsProfitLabel => 'नाफा';

  @override
  String get reportsQuotationsIssuedLabel => 'जारी गरिएका कोटेसनहरू';

  @override
  String get reportsRankByProfitLabel => 'क्रम: नाफा';

  @override
  String get reportsRankByRevenueLabel => 'क्रम: राजस्व';

  @override
  String get reportsReferenceColumnLabel => 'सन्दर्भ';

  @override
  String get reportsSalesColumnLabel => 'बिक्री';

  @override
  String get reportsSaveCsvReportTitle => 'CSV प्रतिवेदन सुरक्षित गर्नुहोस्';

  @override
  String get reportsSavePdfReportTitle => 'PDF प्रतिवेदन सुरक्षित गर्नुहोस्';

  @override
  String reportsSavedAtMessage(String path) {
    return 'सुरक्षित गरियो: $path';
  }

  @override
  String get reportsSelectCustomerTitle => 'ग्राहक चयन गर्नुहोस्';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText =>
      'मिति वा मिति दायरा चयन गर्नुहोस् (अधिकतम ३१ दिन)';

  @override
  String get reportsSelectDateRangeMaxYearHelpText =>
      'मिति दायरा चयन गर्नुहोस् (अधिकतम १ वर्ष)';

  @override
  String get reportsShareLabel => 'हिस्सा';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return '$range का बीजकहरू देखाइँदै';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end / $total';
  }

  @override
  String get reportsSlColumnLabel => 'क्र.सं.';

  @override
  String get reportsStatementsLabel => 'स्टेटमेन्टहरू';

  @override
  String get reportsTaxCollectedByRateTitle => 'दर अनुसार संकलित कर';

  @override
  String get reportsTaxCollectedLabel => 'संकलित कर';

  @override
  String get reportsTaxRateBucketsLabel => 'कर दर समूहहरू';

  @override
  String get reportsTodayLabel => 'आज';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return 'राजस्व अनुसार शीर्ष $count ग्राहकहरू';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return '$metric अनुसार शीर्ष $count उत्पादन / सेवाहरू';
  }

  @override
  String get reportsTotalBilledLabel => 'कुल बिल गरिएको';

  @override
  String get reportsTotalCollectedLabel => 'कुल संकलित';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'कुल $countString बीजकहरू',
      one: 'कुल १ बीजक',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => 'कुल बीजकहरू';

  @override
  String get reportsTotalProfitLabel => 'कुल नाफा';

  @override
  String get reportsTotalTaxCollectedLabel => 'कुल संकलित कर';

  @override
  String get reportsTypeColumnLabel => 'प्रकार';

  @override
  String get reportsUnitsSoldColumnLabel => 'बिक्री भएको इकाई';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return 'प्रयोगकर्ता लोड गर्न त्रुटि: $error';
  }

  @override
  String get userMgmtAddedMessage => 'प्रयोगकर्ता सफलतापूर्वक थपियो';

  @override
  String get userMgmtUpdatedMessage => 'प्रयोगकर्ता सफलतापूर्वक अपडेट भयो';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return 'प्रयोगकर्ता सुरक्षित गर्न त्रुटि: $error';
  }

  @override
  String get userMgmtChangePasswordTitle => 'पासवर्ड परिवर्तन गर्नुहोस्';

  @override
  String userMgmtUserColonLabel(String username) {
    return 'प्रयोगकर्ता: $username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => 'हालको पासवर्ड';

  @override
  String get userMgmtCurrentPasswordRequiredMessage => 'हालको पासवर्ड आवश्यक छ';

  @override
  String get userMgmtNewPasswordLabel => 'नयाँ पासवर्ड';

  @override
  String get userMgmtNewPasswordRequiredMessage => 'नयाँ पासवर्ड आवश्यक छ';

  @override
  String get userMgmtPasswordMinLengthMessage =>
      'पासवर्ड कम्तिमा ६ अक्षरको हुनुपर्छ';

  @override
  String get userMgmtConfirmNewPasswordLabel => 'नयाँ पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get userMgmtConfirmPasswordRequiredMessage =>
      'कृपया आफ्नो पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get userMgmtPasswordsDoNotMatchMessage => 'पासवर्डहरू मेल खाँदैनन्';

  @override
  String get userMgmtPasswordChangedMessage =>
      'पासवर्ड सफलतापूर्वक परिवर्तन भयो';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage => 'हालको पासवर्ड गलत छ';

  @override
  String get userMgmtDeleteUserTitle => 'प्रयोगकर्ता मेटाउनुहोस्';

  @override
  String get userMgmtDeleteUserConfirmLabel =>
      'के तपाईं यो प्रयोगकर्ता मेटाउन निश्चित हुनुहुन्छ:';

  @override
  String get userMgmtActionCannotBeUndoneMessage =>
      'यो कार्य पूर्ववत गर्न सकिँदैन।';

  @override
  String get userMgmtDeletedMessage => 'प्रयोगकर्ता सफलतापूर्वक मेटाइयो';

  @override
  String get userMgmtCantDeleteOwnAccountMessage =>
      'तपाईं आफ्नो खाता मेटाउन सक्नुहुन्न';

  @override
  String get userMgmtCantDemoteLastAdminMessage =>
      'तपाईं एक मात्र एडमिनको भूमिका परिवर्तन गर्न सक्नुहुन्न';

  @override
  String get userMgmtCantChangeOwnRoleMessage =>
      'तपाईं आफ्नै भूमिका परिवर्तन गर्न सक्नुहुन्न';

  @override
  String get userMgmtUsernameTakenMessage =>
      'यो प्रयोगकर्ता नाम पहिले नै लिइएको छ';

  @override
  String get userMgmtDeleteSelectedTitle => 'चयनित प्रयोगकर्ताहरू मेटाउने हो?';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यसले $count प्रयोगकर्ताहरूलाई स्थायी रूपमा मेटाउनेछ। यो कार्य पूर्ववत गर्न सकिँदैन।',
      one:
          'यसले 1 प्रयोगकर्तालाई स्थायी रूपमा मेटाउनेछ। यो कार्य पूर्ववत गर्न सकिँदैन।',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage =>
      'तपाईंको आफ्नै खाता चयनमा थियो तर यसलाई छोडिनेछ।';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्रयोगकर्ताहरू मेटाइयो',
      one: '1 प्रयोगकर्ता मेटाइयो',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return 'प्रयोगकर्ताहरू मेटाउन त्रुटि: $error';
  }

  @override
  String get userMgmtTitle => 'प्रयोगकर्ता व्यवस्थापन';

  @override
  String get userMgmtSubtitle =>
      'एप्लिकेसन प्रयोगकर्ता र पहुँच अनुमतिहरू व्यवस्थापन गर्नुहोस्';

  @override
  String get userMgmtAddUserButton => 'प्रयोगकर्ता थप्नुहोस्';

  @override
  String get userMgmtSearchHint =>
      'नाम वा भूमिकाद्वारा प्रयोगकर्ता खोज्नुहोस्…';

  @override
  String get userMgmtFilterByRoleTooltip => 'भूमिकाद्वारा फिल्टर गर्नुहोस्';

  @override
  String get userMgmtAllRolesLabel => 'सबै भूमिकाहरू';

  @override
  String get userMgmtAllLabel => 'सबै';

  @override
  String userMgmtRoleColonLabel(String role) {
    return 'भूमिका: $role';
  }

  @override
  String get userMgmtColUser => 'प्रयोगकर्ता';

  @override
  String get userMgmtColRole => 'भूमिका';

  @override
  String get userMgmtYouBadgeLabel => 'तपाईं';

  @override
  String get userMgmtDeleteSelectedMenuLabel => 'चयनित मेटाउनुहोस्';

  @override
  String get userMgmtBulkActionsTooltip => 'थोक कार्यहरू';

  @override
  String get userMgmtBulkActionsLabel => 'थोक कार्यहरू';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return 'कुल $total प्रयोगकर्तामध्ये $from देखि $to देखाइँदै';
  }

  @override
  String get userMgmtNoUsersFoundMessage => 'कुनै प्रयोगकर्ता फेला परेन';

  @override
  String get userMgmtAddNewUserTitle => 'नयाँ प्रयोगकर्ता थप्नुहोस्';

  @override
  String get userMgmtEditUserTitle => 'प्रयोगकर्ता सम्पादन गर्नुहोस्';

  @override
  String get userMgmtUsernameRequiredLabel => 'प्रयोगकर्ता नाम *';

  @override
  String get userMgmtEnterUsernameHint => 'प्रयोगकर्ता नाम प्रविष्ट गर्नुहोस्';

  @override
  String get userMgmtUsernameRequiredMessage => 'प्रयोगकर्ता नाम आवश्यक छ';

  @override
  String get userMgmtUsernameMinLengthMessage =>
      'प्रयोगकर्ता नाम कम्तिमा ३ अक्षरको हुनुपर्छ';

  @override
  String get userMgmtPasswordRequiredLabel => 'पासवर्ड *';

  @override
  String get userMgmtEnterPasswordHint => 'पासवर्ड प्रविष्ट गर्नुहोस्';

  @override
  String get userMgmtPasswordRequiredMessage => 'पासवर्ड आवश्यक छ';

  @override
  String get userMgmtMinimum6CharsMessage => 'कम्तिमा ६ अक्षर';

  @override
  String get userMgmtRoleRequiredLabel => 'भूमिका *';

  @override
  String get userMgmtRoleRequiredMessage => 'भूमिका आवश्यक छ';

  @override
  String get userMgmtSaveUserButton => 'प्रयोगकर्ता सुरक्षित गर्नुहोस्';

  @override
  String get userMgmtThisIsYourAccountMessage => 'यो तपाईंको खाता हो';

  @override
  String get invoiceSettingsAppBarTitle => 'बीजक सेटिङहरू';

  @override
  String get invoiceSettingsSavedMessage =>
      'बीजक सेटिङहरू सफलतापूर्वक सुरक्षित भयो!';

  @override
  String get invoiceSettingsSignatureTooLargeMessage =>
      'हस्ताक्षर छवि २ MB भन्दा कम हुनुपर्छ।';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage =>
      'वाटरमार्क छवि २ MB भन्दा कम हुनुपर्छ।';

  @override
  String get invoiceSettingsSectionGeneral => 'सामान्य';

  @override
  String get invoiceSettingsSectionBranding => 'ब्रान्डिङ';

  @override
  String get invoiceSettingsSectionTax => 'कर र GST';

  @override
  String get invoiceSettingsSectionItems => 'बीजक वस्तुहरू';

  @override
  String get invoiceSettingsSectionCustomer => 'Customer Details';

  @override
  String get invoiceSettingsSectionColumns => 'Invoice Columns';

  @override
  String get invoiceSettingsColumnsSectionHint =>
      'Choose which columns appear in the invoice PDF items table. Item Name, Price and Total are always shown.';

  @override
  String get invoiceSettingsShowSlNoLabel => 'Sl No column';

  @override
  String get invoiceSettingsShowSlNoSubtitle =>
      'Print the serial-number column on A4/Letter invoices';

  @override
  String get invoiceSettingsColumnHsnLabel => 'HSN/SAC column';

  @override
  String get invoiceSettingsColumnHsnSubtitle =>
      'Print the HSN/SAC code column (tied to Show GST Fields)';

  @override
  String get invoiceSettingsColumnTaxLabel => 'Tax column';

  @override
  String get invoiceSettingsColumnTaxSubtitle =>
      'Print the per-item CGST/SGST, IGST % column';

  @override
  String get invoiceSettingsColumnRequiredSubtitle => 'Always shown';

  @override
  String get invoiceSettingsColumnItemNameLabel => 'Item Name column';

  @override
  String get invoiceSettingsColumnPriceLabel => 'Price / Rate column';

  @override
  String get invoiceSettingsColumnTotalLabel => 'Total column';

  @override
  String get invoiceSettingsCustomerSectionHint =>
      'Choose which customer details print on invoice PDFs and thermal receipts. A field only shows when it\'s enabled and the customer has a value for it. Customer name is always shown.';

  @override
  String get invoiceSettingsShowCustomerBusinessNameLabel =>
      'Show Business Name';

  @override
  String get invoiceSettingsShowCustomerBusinessNameSubtitle =>
      'Print the customer\'s business name under their name';

  @override
  String get invoiceSettingsShowCustomerAddressLabel => 'Show Address';

  @override
  String get invoiceSettingsShowCustomerAddressSubtitle =>
      'Print the customer\'s address in the Bill To block';

  @override
  String get invoiceSettingsShowCustomerPhoneLabel => 'Show Phone';

  @override
  String get invoiceSettingsShowCustomerPhoneSubtitle =>
      'Print the customer\'s phone number';

  @override
  String get invoiceSettingsShowCustomerEmailLabel => 'Show Email';

  @override
  String get invoiceSettingsShowCustomerEmailSubtitle =>
      'Print the customer\'s email address (not shown on thermal receipts)';

  @override
  String get invoiceSettingsShowCustomerGstinLabel => 'Show GSTIN / Tax ID';

  @override
  String get invoiceSettingsShowCustomerGstinSubtitle =>
      'Print the customer\'s GSTIN / tax id (requires GST fields on)';

  @override
  String get invoiceSettingsShowTimeInPdfLabel => 'Show Time on PDF';

  @override
  String get invoiceSettingsShowTimeInPdfSubtitle =>
      'Append the invoice creation time next to the date on PDFs and thermal receipts';

  @override
  String get invoiceSettingsTimeFormatLabel => 'Time Format';

  @override
  String get invoiceSettingsTimeFormat24 => '24-hour (14:30)';

  @override
  String get invoiceSettingsTimeFormat12 => '12-hour (2:30 PM)';

  @override
  String get invoiceSettingsPrefixLabel => 'बीजक उपसर्ग';

  @override
  String get invoiceSettingsStartingNumberHelper =>
      'पहिलो बीजक यो नम्बरबाट सुरु हुनेछ';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      'बीजकहरू अवस्थित रहेसम्म सुरु नम्बर परिवर्तन गर्न सकिँदैन। कृपया सबै बीजक/कोटेसन (ट्र्यास सहित) स्थायी रूपमा मेटाएर पुनः प्रयास गर्नुहोस्।';

  @override
  String get invoiceSettingsQuantityColumnLabel => 'परिमाण स्तम्भ लेबल';

  @override
  String get invoiceSettingsQuantityColumnHint => 'जस्तै Words, Hours, Units';

  @override
  String get invoiceSettingsQuantityColumnHelper =>
      'पूर्वनिर्धारित \"Qty\" प्रयोग गर्न खाली छोड्नुहोस्';

  @override
  String get invoiceSettingsAdditionalInfoLabel => 'थप जानकारी';

  @override
  String get invoiceSettingsThankYouNoteLabel => 'धन्यवाद टिप्पणी';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel =>
      'पूर्वनिर्धारित रूपमा बीजक नम्बर लुकाउनुहोस्';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      'नयाँ बीजक सिर्जना गर्दा पूर्वनिर्धारित रूपमा \"PDF मा बीजक नम्बर लुकाउनुहोस्\" सक्षम गर्नुहोस्।';

  @override
  String get invoiceSettingsTaxRateHint => 'जस्तै 18';

  @override
  String get invoiceSettingsTaxRateHelper => 'नयाँ बीजकहरूमा लागू हुन्छ';

  @override
  String get invoiceSettingsTaxEnabledLabel => 'पूर्वनिर्धारित रूपमा कर सक्षम';

  @override
  String get invoiceSettingsTaxEnabledSubtitle =>
      'नयाँ बीजक सिर्जना गर्दा पूर्वनिर्धारित रूपमा कर टगल सक्षम गर्नुहोस्।';

  @override
  String get invoiceSettingsTaxModeLabel => 'पूर्वनिर्धारित कर दर मोड';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly =>
      'नयाँ बीजकहरूमा मात्र लागू हुन्छ';

  @override
  String get invoiceSettingsTaxModeGlobal => 'समग्र';

  @override
  String get invoiceSettingsTaxModePerItem => 'प्रति वस्तु';

  @override
  String get invoiceSettingsShowGstFieldsLabel => 'GST फिल्डहरू देखाउनुहोस्';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      'बीजक, PDF, र CSV निर्यातमा GSTIN फिल्डहरू (HSN/SAC) देखाउनुहोस्';

  @override
  String get invoiceSettingsShowCgstSgstLabel => 'CGST/SGST देखाउनुहोस्';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      'बीजकहरूमा करलाई CGST + SGST मा विभाजन गर्नुहोस् (भारतमा मात्र)।';

  @override
  String get invoiceSettingsDefaultGstTitleLabel =>
      'पूर्वनिर्धारित GST बीजक शीर्षक';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel =>
      'पूर्वनिर्धारित कर बीजक शीर्षक';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      'नयाँ बीजकहरूमा पूर्वचयनित — जस्तै GST कम्पोजिसन स्किम व्यापारीहरूका लागि \"Bill of Supply\"';

  @override
  String get invoiceSettingsGstTitleHelperGeneric =>
      'नयाँ बीजकहरूमा पूर्वचयनित';

  @override
  String get invoiceSettingsShowRoundOffLabel => 'राउन्ड अफ देखाउनुहोस्';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      'बीजक PDF मा राउन्ड अफ पङ्क्ति + नेट रकम (नजिकको मानमा) र शब्दमा रकम देखाउनुहोस्।';

  @override
  String get invoiceSettingsShowAliasNameLabel => 'PDF मा उपनाम देखाउनुहोस्';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      'PDF मा उत्पादनको वास्तविक नामको सट्टा स्थानीय-भाषा उपनाम (यदि सेट गरिएको छ भने) छाप्नुहोस्';

  @override
  String get invoiceSettingsShowDescriptionLabel => 'उत्पादन विवरण देखाउनुहोस्';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      'प्रत्येक वस्तुको विवरण A4 PDF मा त्यसको मुनि एक पङ्क्तिको रूपमा छाप्नुहोस् (थर्मल रसिदमा होइन)';

  @override
  String get invoiceSettingsDescriptionNewLineLabel => 'विवरण नयाँ लाइनमा';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      'विवरणलाई वस्तुको नाम मुनिको लाइनको सट्टा वस्तु मुनि पूर्ण-चौडाइको पङ्क्तिको रूपमा छाप्नुहोस्';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel =>
      'दशमलव परिमाण अनुमति दिनुहोस्';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      'दशमलव परिमाण सक्षम गर्नुहोस् (जस्तै 1.5 घण्टा, 0.5 किलो)';

  @override
  String get invoiceSettingsShowQuantityLabel => 'परिमाण फिल्ड देखाउनुहोस्';

  @override
  String get invoiceSettingsShowQuantitySubtitle =>
      'सेवा-आधारित बिलिङका लागि परिमाण लुकाउनुहोस्; मूल्य स्तम्भ \"दर\" बन्छ';

  @override
  String get invoiceSettingsShowDiscountLabel => 'छुट स्तम्भ देखाउनुहोस्';

  @override
  String get invoiceSettingsShowDiscountSubtitle =>
      'वस्तु-स्तरको छुट प्रयोग नगर्ने ग्राहकहरूका लागि छुट स्तम्भ लुकाउनुहोस्';

  @override
  String get invoiceSettingsShowTypeTagLabel =>
      'उत्पादन/सेवा ट्याग देखाउनुहोस्';

  @override
  String get invoiceSettingsShowTypeTagSubtitle =>
      'प्रत्येक बीजक वस्तुमा उत्पादन/सेवा लेबल देखाउनुहोस् वा लुकाउनुहोस्';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel =>
      'डुप्लिकेट बीजक वस्तु अनुमति दिनुहोस्';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle =>
      'एउटै उत्पादन बीजकमा एकपटक भन्दा बढी थप्न अनुमति दिनुहोस्';

  @override
  String get invoiceSettingsShowPrevBalanceLabel =>
      'अघिल्लो बाँकी रकम देखाउनुहोस्';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle =>
      'बीजक PDF मा गणना गरिएको अघिल्लो बाँकी रकम देखाउनुहोस्';

  @override
  String get invoiceSettingsLogoPositionLabel => 'कम्पनी लोगो स्थिति';

  @override
  String get invoiceSettingsLogoSizeLabel => 'कम्पनी लोगो साइज';

  @override
  String get commonLeftLabel => 'बायाँ';

  @override
  String get commonRightLabel => 'दायाँ';

  @override
  String get invoiceSettingsSignatureImageLabel => 'हस्ताक्षर छवि';

  @override
  String get invoiceSettingsSignatureImageSubtitle =>
      'अधिकृत हस्ताक्षरको रूपमा बीजकमा छापिन्छ';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG, JPG वा JPEG — अधिकतम 2 MB';

  @override
  String get invoiceSettingsChangeSignatureButton =>
      'हस्ताक्षर परिवर्तन गर्नुहोस्';

  @override
  String get invoiceSettingsUploadSignatureButton =>
      'हस्ताक्षर अपलोड गर्नुहोस्';

  @override
  String get invoiceSettingsSignatureSizeLabel => 'हस्ताक्षर साइज';

  @override
  String get invoiceSettingsSignaturePositionLabel => 'हस्ताक्षर स्थिति';

  @override
  String get invoiceSettingsWatermarkImageLabel => 'वाटरमार्क छवि';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      'बीजक PDF मा वस्तु तालिका पछाडि देखाइन्छ (थर्मल रसिदमा छापिँदैन)';

  @override
  String get invoiceSettingsChangeWatermarkButton =>
      'वाटरमार्क परिवर्तन गर्नुहोस्';

  @override
  String get invoiceSettingsUploadWatermarkButton =>
      'वाटरमार्क अपलोड गर्नुहोस्';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return 'अस्पष्टता: $value%';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value%';
  }

  @override
  String get invoiceSettingsPromoTitle => 'तपाईंको बीजकमा थप फिल्डहरू चाहियो?';

  @override
  String get invoiceSettingsPromoBody =>
      'PO नम्बर, प्रोजेक्ट कोड, विभाग, वा कुनै पनि कस्टम फिल्ड थप्नुहोस्।';

  @override
  String get invoiceSettingsPromoButton => 'विकल्पहरू हेर्नुहोस्';

  @override
  String get pdfSettingsTitle => 'पीडीएफ सेटिङ';

  @override
  String get pdfSettingsSubtitle =>
      'इनभोइस, कोटेसन र रसिद पीडीएफ टेम्प्लेटहरू अनुकूलन गर्नुहोस्';

  @override
  String get pdfSettingsResetToDefaultButton =>
      'पूर्वनिर्धारितमा रिसेट गर्नुहोस्';

  @override
  String get pdfSettingsSaveSettingsButton => 'सेटिङहरू सुरक्षित गर्नुहोस्';

  @override
  String get pdfSettingsTemplatesLabel => 'टेम्प्लेटहरू';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return '$pageSize का लागि कुनै टेम्प्लेट छैन';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'पीडीएफ सेटिङहरू सुरक्षित गरियो';

  @override
  String get commonActiveLabel => 'सक्रिय';

  @override
  String get commonUnavailableLabel => 'उपलब्ध छैन';

  @override
  String get pdfSettingsDisplayOptionsLabel => 'प्रदर्शन विकल्पहरू';

  @override
  String get pdfSettingsShowTotalQtyRowLabel =>
      'कुल परिमाण पङ्क्ति देखाउनुहोस्';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => 'वस्तु लेआउट';

  @override
  String get pdfSettingsItemLayoutTableLabel => 'तालिका';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => 'विस्तृत';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      'तालिका: प्रति वस्तु एक लाइन (Sl/नाम/परिमाण/दर/कुल). विस्तृत: नाम आफ्नै लाइनमा, त्यसपछि परिमाण/दर/कुल तल।';

  @override
  String get pdfSettingsCompanyNameSizeLabel => 'कम्पनी नामको साइज';

  @override
  String get pdfSettingsThemeColorLabel => 'थिम रङ';

  @override
  String get pdfSettingsHexErrorText => '#RRGGBB प्रयोग गर्नुहोस्';

  @override
  String get pdfSettingsPickColorTooltip => 'रङ पिकर खोल्नुहोस्';

  @override
  String get pdfSettingsPickThemeColorDialogTitle => 'थिम रङ छान्नुहोस्';

  @override
  String get pdfSettingsPreviewDisclaimer =>
      'पूर्वावलोकन अन्तिम पीडीएफमा अलि फरक हुन सक्छ।';

  @override
  String get pdfSettingsCustomTemplatePromoTitle =>
      'अनुकूलित टेम्प्लेट चाहनुहुन्छ?';

  @override
  String get pdfSettingsCustomTemplatePromoBody =>
      'तपाईंको ब्रान्डसँग मेल खाने डिजाइन पाउनुहोस् — रङ, फन्ट, र लेआउट।';

  @override
  String get pdfSettingsCustomizationOptionsButton => 'अनुकूलन विकल्पहरू';

  @override
  String get pdfTemplateClassicName => 'क्लासिक';

  @override
  String get pdfTemplateClassicDescription =>
      'सफा संरचनासहितको परम्परागत लेआउट';

  @override
  String get pdfTemplateModernName => 'मोडर्न';

  @override
  String get pdfTemplateModernDescription =>
      'समकालीन स्टाइलिङसहितको बोल्ड हेडर';

  @override
  String get pdfTemplateMinimalName => 'मिनिमल';

  @override
  String get pdfTemplateMinimalDescription => 'सरल र ध्यान नभड्काउने';

  @override
  String get pdfTemplateExecutiveName => 'एक्जिक्युटिभ';

  @override
  String get pdfTemplateExecutiveDescription =>
      'संरचित बिलिङ ब्लकसहितको प्रिमियम व्यावसायिक लेआउट';

  @override
  String get pdfTemplateCompactName => 'कम्प्याक्ट';

  @override
  String get pdfTemplateCompactDescription =>
      'A6 प्रिन्टिङका लागि उपयुक्त, ठाउँ-कुशल रसिद लेआउट';

  @override
  String get pdfTemplateThermalName => 'थर्मल';

  @override
  String get pdfTemplateThermalDescription =>
      '80mm र 58mm थर्मल प्रिन्टरका लागि साँघुरो रसिद लेआउट';

  @override
  String get pdfTemplateGridClassicName => 'ग्रिड क्लासिक';

  @override
  String get pdfTemplateGridClassicDescription =>
      'A4, A5 र A6 का लागि पुरानो शैलीको बर्डर भएको ट्याबुलर बिल';

  @override
  String get companyInfoAppBarTitle => 'कम्पनी जानकारी';

  @override
  String get companyInfoUploadLogoLabel => 'लोगो अपलोड गर्नुहोस्';

  @override
  String get companyInfoClickToBrowseLabel => 'ब्राउज गर्न क्लिक गर्नुहोस्';

  @override
  String get companyInfoRemoveLogoButton => 'लोगो हटाउनुहोस्';

  @override
  String get companyInfoShowOnPdfLabel => 'PDF मा देखाउनुहोस्';

  @override
  String get companyInfoLogoRequirementsHint =>
      'अधिकतम 1080×1080 px · 2 MB\nPNG वा JPG मात्र';

  @override
  String get companyInfoLogoSectionLabel => 'कम्पनी लोगो';

  @override
  String get companyInfoDetailsSectionLabel => 'कम्पनी विवरण';

  @override
  String get companyInfoBusinessTypeSectionLabel => 'व्यवसाय प्रकार';

  @override
  String get companyInfoPaymentSettingsSectionLabel => 'भुक्तानी सेटिङ';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'UPI खाताहरू';

  @override
  String get companyInfoBankAccountsSectionLabel => 'बैंक खाताहरू';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => 'कर/भ्याट नम्बर';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'FSSAI कोड';

  @override
  String get companyInfoPhoneHelperText =>
      'धेरै नम्बरहरू: अल्पविरामले छुट्याउनुहोस्';

  @override
  String get fieldWebsiteLabel => 'वेबसाइट';

  @override
  String get companyInfoBusinessTypeTitle => 'व्यवसाय प्रकार';

  @override
  String get companyInfoBusinessTypeSubtitle =>
      'उत्पादन सूची र बीजकमा वस्तु प्रकार विकल्पहरू नियन्त्रण गर्छ';

  @override
  String get labelBoth => 'दुवै';

  @override
  String get companyInfoSetAsDefaultTooltip => 'पूर्वनिर्धारित बनाउनुहोस्';

  @override
  String get companyInfoUpiIdLabel => 'UPI ID';

  @override
  String get companyInfoAddUpiAccountButton => 'UPI खाता थप्नुहोस्';

  @override
  String get companyInfoShowQrToggleTitle => 'बीजकमा QR कोड देखाउनुहोस्';

  @override
  String get companyInfoShowQrToggleSubtitle =>
      'उत्पन्न PDF मा स्क्यान गर्न मिल्ने UPI भुक्तानी QR कोड थप्छ';

  @override
  String get companyInfoShowBankDetailsToggleTitle =>
      'बीजकमा बैंक विवरण देखाउनुहोस्';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle =>
      'उत्पन्न PDF मा बैंक खाता विवरण छाप्छ';

  @override
  String get fieldBankNameLabel => 'बैंकको नाम';

  @override
  String get fieldAccountNumberLabel => 'खाता नम्बर';

  @override
  String get fieldIfscCodeLabel => 'IFSC कोड';

  @override
  String get companyInfoAddBankAccountButton => 'बैंक खाता थप्नुहोस्';

  @override
  String get tooltipShowOnInvoicePdf => 'बीजक PDF मा देखाउनुहोस्';

  @override
  String get companyInfoSavedSuccessMessage =>
      'कम्पनी जानकारी सफलतापूर्वक सुरक्षित भयो';

  @override
  String get companyInfoImageTooLargeMessage =>
      'छवि फाइल 2 MB भन्दा कम हुनुपर्छ।';

  @override
  String get companyInfoInvalidImageMessage => 'अमान्य छवि फाइल।';

  @override
  String get companyInfoImageDimensionsMessage =>
      'छवि अधिकतम 1080x1080 पिक्सेल हुनुपर्छ।';

  @override
  String get companyInfoHintExampleBankName => 'जस्तै HDFC बैंक';

  @override
  String get companyInfoHintExampleAccountLabel => 'जस्तै मुख्य खाता';

  @override
  String get actionConfirm => 'पुष्टि गर्नुहोस्';

  @override
  String get actionShare => 'साझा गर्नुहोस्';

  @override
  String get appInfoTitle => 'सफ्टवेयर जानकारी';

  @override
  String get appInfoAppDetailsTitle => 'एप विवरण';

  @override
  String get appInfoAppNameLabel => 'एपको नाम';

  @override
  String get appInfoVersionLabel => 'संस्करण';

  @override
  String get appInfoLicenseLabel => 'लाइसेन्स';

  @override
  String get appInfoDeveloperTitle => 'विकासकर्ता';

  @override
  String get appInfoDeveloperLabel => 'विकासकर्ता';

  @override
  String get appInfoSupportEmailLabel => 'सहयोग इमेल';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  $license लाइसेन्स अन्तर्गत जारी';
  }

  @override
  String get appInfoCheckingLabel => 'जाँच हुँदैछ...';

  @override
  String get appInfoUpdateAvailableLabel => 'अपडेट उपलब्ध छ';

  @override
  String get appInfoUpToDateLabel => 'अद्यावधिक';

  @override
  String get appInfoCheckFailedLabel => 'जाँच असफल';

  @override
  String get appInfoUpdatesTitle => 'अपडेटहरू';

  @override
  String get appInfoCurrentVersionLabel => 'हालको संस्करण';

  @override
  String get appInfoLatestVersionLabel => 'नवीनतम संस्करण';

  @override
  String get appInfoCheckNowButton => 'अहिले जाँच गर्नुहोस्';

  @override
  String get backupManagementTitle => 'ब्याकअप व्यवस्थापन';

  @override
  String get backupCreateDbButton => 'DB ब्याकअप बनाउनुहोस्';

  @override
  String get backupExportJsonButton => 'JSON निर्यात गर्नुहोस्';

  @override
  String get backupImportButton => 'ब्याकअप आयात गर्नुहोस्';

  @override
  String get backupNoBackupsFoundMessage => 'कुनै ब्याकअप फेला परेन';

  @override
  String backupSizeLabel(String size) {
    return 'साइज: $size';
  }

  @override
  String backupCreatedLabel(String date) {
    return 'बनाइयो: $date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return 'ब्याकअपहरू लोड गर्न असफल: $error';
  }

  @override
  String get backupCreatedSuccessMessage => 'ब्याकअप सफलतापूर्वक बनाइयो!';

  @override
  String backupCreateErrorMessage(String error) {
    return 'ब्याकअप बनाउन असफल: $error';
  }

  @override
  String get backupRestoreConfirmTitle => 'ब्याकअप पुनर्स्थापना गर्नुहोस्';

  @override
  String get backupRestoreConfirmBody =>
      'यसले हालका सबै डेटालाई ब्याकअपले प्रतिस्थापन गर्नेछ। के तपाईं निश्चित हुनुहुन्छ?';

  @override
  String backupRestoreErrorMessage(String error) {
    return 'ब्याकअप पुनर्स्थापना गर्न असफल: $error';
  }

  @override
  String get backupDeleteConfirmTitle => 'ब्याकअप मेटाउनुहोस्';

  @override
  String get backupDeleteConfirmBody =>
      'के तपाईं यो ब्याकअप मेटाउन निश्चित हुनुहुन्छ?';

  @override
  String get backupDeletedSuccessMessage => 'ब्याकअप सफलतापूर्वक मेटाइयो!';

  @override
  String get backupDeleteFailedMessage => 'ब्याकअप मेटाउन असफल';

  @override
  String backupDeleteErrorMessage(String error) {
    return 'ब्याकअप मेटाउन असफल: $error';
  }

  @override
  String get backupSavedToDownloadsMessage =>
      'ब्याकअप डाउनलोड फोल्डरमा सुरक्षित गरियो।';

  @override
  String backupDownloadErrorMessage(String error) {
    return 'ब्याकअप डाउनलोड गर्न असफल: $error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return 'ब्याकअप साझा गर्न असफल: $error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return 'ब्याकअप आयात गर्न असफल: $error';
  }

  @override
  String get backupRestoreSuccessTitle => 'पुनर्स्थापना सफल';

  @override
  String get backupRestoreSuccessBody =>
      'डाटाबेस सफलतापूर्वक पुनर्स्थापना भयो।\n\nपरिवर्तनहरू लागू गर्न एपलाई पुनः सुरु गर्नुपर्छ। कृपया एप्लिकेसन बन्द गरी फेरि खोल्नुहोस्।';

  @override
  String get backupCloseLaterButton => 'पछि बन्द गर्नुहोस्';

  @override
  String get backupCloseAppNowButton => 'अहिले एप बन्द गर्नुहोस्';

  @override
  String get commonSuccessTitle => 'सफल';

  @override
  String get commonErrorTitle => 'त्रुटि';

  @override
  String get productColumnsScreenTitle => 'उत्पादन विवरण अनुकूलन गर्नुहोस्';

  @override
  String get productColumnsSavedMessage => 'उत्पादन स्तम्भहरू सुरक्षित गरियो।';

  @override
  String get productColumnsIntroText =>
      'उत्पादन थप्ने/सम्पादन फारम, उत्पादन सूची, र बीजक लाइन आइटममा कुन फिल्डहरू देखिने भनी छान्नुहोस्। नाम र मूल्य सधैं आवश्यक हुन्छ।';

  @override
  String get productColumnsNameLabel => 'नाम';

  @override
  String get productColumnsPriceLabel => 'मूल्य';

  @override
  String get productColumnsAlwaysRequiredSubtitle => 'सधैं देखाइन्छ — आवश्यक।';

  @override
  String get productColumnsStockLabel => 'स्टक';

  @override
  String get productColumnsStockSubtitle =>
      'यदि तपाईं कहिल्यै स्टक ट्र्याक गर्नुहुन्न भने बन्द गर्नुहोस् — उत्पादनहरूले पूर्वनिर्धारित रूपमा असीमित स्टक मान्छन्।';

  @override
  String get productColumnsProductFieldsSectionTitle => 'उत्पादन फिल्डहरू';

  @override
  String get productColumnsAliasNameLabel => 'उपनाम';

  @override
  String get productColumnsAliasNameSubtitle =>
      'PDF/प्रिन्टिङका लागि स्थानीय-भाषा प्रदर्शन नाम।';

  @override
  String get productColumnsTaxRateLabel => 'कर दर';

  @override
  String get productColumnsTaxRateSubtitle => 'प्रति-उत्पादन कर प्रतिशत।';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'HSN वा SAC कोड फिल्ड।';

  @override
  String get productColumnsDescriptionLabel => 'विवरण';

  @override
  String get productColumnsDescriptionSubtitle =>
      'स्वतन्त्र-पाठ उत्पादन विवरण।';

  @override
  String get productColumnsPurchasePriceLabel => 'खरिद मूल्य';

  @override
  String get productColumnsPurchasePriceSubtitle =>
      'मार्जिन ट्र्याकिङका लागि लागत मूल्य।';

  @override
  String get productColumnsDefaultDiscountLabel => 'पूर्वनिर्धारित छुट';

  @override
  String get productColumnsDefaultDiscountSubtitle =>
      'यो उत्पादन बीजकमा थप्दा पहिले-भरिएको छुट।';

  @override
  String get productColumnsUnitLabel => 'एकाइ';

  @override
  String get productColumnsUnitSubtitle => 'मापनको एकाइ (पिस, केजी, घण्टा...)।';

  @override
  String get productColumnsProductServiceTypeLabel => 'उत्पादन/सेवा प्रकार';

  @override
  String get productColumnsProductServiceTypeSubtitle =>
      'खण्डित उत्पादन बनाम सेवा चयनकर्ता।';

  @override
  String get productColumnsMetadataLabel => 'उत्पादन मेटाडेटा';

  @override
  String get productColumnsMetadataSubtitle =>
      'भण्डारण स्थान, कन्टेनर/ब्याच नम्बर, म्याद सकिने, निर्माण मिति, आपूर्तिकर्ता, SKU, नोटहरू।';

  @override
  String get productColumnsMetaStorageLocationLabel => 'भण्डारण स्थान';

  @override
  String get productColumnsMetaContainerNumberLabel => 'कन्टेनर नम्बर';

  @override
  String get productColumnsMetaBatchNumberLabel => 'ब्याच नम्बर';

  @override
  String get productColumnsMetaExpiryDateLabel => 'म्याद सकिने मिति';

  @override
  String get productColumnsMetaManufactureDateLabel => 'निर्माण मिति';

  @override
  String get productColumnsMetaSupplierNameLabel => 'आपूर्तिकर्ता नाम';

  @override
  String get productColumnsMetaSkuCodeLabel => 'SKU कोड';

  @override
  String get productColumnsMetaNotesLabel => 'नोटहरू';

  @override
  String get productColumnsExtraCostLabel => 'अतिरिक्त लागत';

  @override
  String get productColumnsExtraCostSubtitle =>
      'बीजक लाइन आइटममा वैकल्पिक फ्ल्याट अतिरिक्त शुल्क।';

  @override
  String get settingsOptionsComingSoonMessage => 'विकल्पहरू छिट्टै आउँदैछन्...';

  @override
  String get settingsNavCompanyInfoLabel => 'कम्पनी जानकारी';

  @override
  String get settingsNavTeamLabel => 'टिम';

  @override
  String get settingsNavBackupLabel => 'ब्याकअप';

  @override
  String get settingsNavUsersLabel => 'प्रयोगकर्ताहरू';

  @override
  String get settingsNavProductDetailsLabel => 'उत्पादन विवरण';

  @override
  String get settingsNavCustomizeLabel => 'अनुकूलन गर्नुहोस्';

  @override
  String get settingsNavAccessibilityLabel => 'पहुँचयोग्यता';

  @override
  String get settingsNavSoftwareInfoLabel => 'सफ्टवेयर जानकारी';

  @override
  String get customizationEyebrowLabel => 'अनुकूलन';

  @override
  String get customizationHeadline => 'तपाईंको व्यवसायको लागि अनुकूलित';

  @override
  String get customizationSubtitle =>
      'आफूलाई चाहिने कुरा छान्नुहोस् र अनुरोध पठाउनुहोस्। हामी २४ घण्टाभित्र सम्पर्क गर्नेछौं।';

  @override
  String get customizationRecommendedBadge => 'सिफारिस गरिएको';

  @override
  String customizationDeliveryLabel(String delivery) {
    return 'डेलिभरी: $delivery';
  }

  @override
  String get customizationRequestButton => 'अनुरोध गर्नुहोस्';

  @override
  String get customizationFormOpenErrorMessage =>
      'फारम खोल्न सकिएन। कृपया आफ्नो ब्राउजरमा forms.gle/LyX6Z2kBNR2BpwVu7 भ्रमण गर्नुहोस्।';

  @override
  String get customizationDisclaimerMessage =>
      'मूल्यहरू सांकेतिक हुन्। जटिलताको आधारमा अन्तिम मूल्य फरक हुन सक्छ। दायरा सहमति पछि भुक्तानी लिइन्छ।';

  @override
  String get customizationPdfTemplateTitle => 'अनुकूलित PDF टेम्प्लेट';

  @override
  String get customizationPdfTemplateDescription =>
      'तपाईंको ब्रान्डसँग मिल्ने बीजक टेम्प्लेट पाउनुहोस् — तपाईंको रंगहरू, फन्टहरू, लोगो स्थान, र लेआउट।';

  @override
  String get customizationPdfTemplateDelivery => '२–५ दिन';

  @override
  String get customizationCustomFieldsTitle => 'अनुकूलित फिल्डहरू';

  @override
  String get customizationCustomFieldsDescription =>
      'तपाईंको बीजकहरूमा अतिरिक्त फिल्डहरू चाहिन्छ? (PO नम्बर, प्रोजेक्ट कोड, विभाग, आदि) हामी तपाईंको लागि थप्नेछौं।';

  @override
  String get customizationCustomFieldsDelivery => '१–३ दिन';

  @override
  String get customizationWhiteLabelTitle =>
      'व्हाइट-लेबल / ब्रान्डिङ हटाउनुहोस्';

  @override
  String get customizationWhiteLabelDescription =>
      'एपबाट सबै Invoiso ब्रान्डिङ र PDF आउटपुटहरू हटाउनुहोस्, र यसलाई आफ्नै कम्पनी परिचयले प्रतिस्थापन गर्नुहोस्।';

  @override
  String get customizationWhiteLabelDelivery => '३–६ दिन';

  @override
  String get customizationIndustryBuildTitle => 'उद्योग-विशिष्ट निर्माण';

  @override
  String get customizationIndustryBuildDescription =>
      'आफ्नो उद्योगको लागि अनुकूलित संस्करण चाहिन्छ? (निर्माण, परामर्श, खुद्रा, आदि) हामी तपाईंको आवश्यकता अनुसार कार्यप्रवाह अनुकूलित गर्नेछौं।';

  @override
  String get customizationIndustryBuildDelivery => '५–१० दिन';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle =>
      'नयाँ बीजक सिर्जना पृष्ठ लेआउट';

  @override
  String get accessibilityClassicLayoutLabel => 'क्लासिक लेआउट';

  @override
  String get accessibilityNewLayoutLabel => 'नयाँ लेआउट';

  @override
  String get accessibilityLayoutDescription =>
      'कुन \"नयाँ बीजक\" स्क्रिन डिजाइन प्रयोग गर्ने छान्नुहोस्।';

  @override
  String get accessibilityShortcutsSubtitle =>
      'माउस नछोई बीजक सिर्जना छिटो बनाउनुहोस्।';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => 'बीजक जम्मा';

  @override
  String get paymentDialogAmountPaidLabel => 'तिरेको रकम';

  @override
  String get paymentDialogHistoryTitle => 'भुक्तानी इतिहास';

  @override
  String get paymentDialogNoPaymentsMessage =>
      'अहिलेसम्म कुनै भुक्तानी रेकर्ड गरिएको छैन';

  @override
  String get paymentDialogFullyPaidExclaimMessage => 'बीजक पूर्ण रूपमा तिरियो!';

  @override
  String get paymentDialogFullyPaidBannerLabel => 'बीजक पूर्ण रूपमा तिरियो';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return 'भुक्तानी रेकर्ड गरियो। बाँकी: $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return 'भुक्तानी रेकर्ड गर्न असफल: $error';
  }

  @override
  String get paymentDialogDeleteTitle => 'भुक्तानी मेटाउनुहोस्';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return 'रसिद $receiptNumber मेटाउने हो?\n\nयो पूर्ववत गर्न सकिँदैन।';
  }

  @override
  String get paymentDialogNewPaymentTitle => 'नयाँ भुक्तानी';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return 'रकम ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return 'अधिकतम: $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError => 'मान्य रकम प्रविष्ट गर्नुहोस्';

  @override
  String get paymentDialogExceedsOutstandingError => 'बाँकी रकमभन्दा बढी छ';

  @override
  String get paymentDialogMethodFieldLabel => 'भुक्तानी विधि';

  @override
  String get paymentDialogSelectMethodHint => 'विधि छान्नुहोस्';

  @override
  String get paymentDialogTaxCoveredLabel => 'कर समावेश';

  @override
  String get paymentDialogAutoCalculatedHelper => 'स्वतः गणना गरिएको';

  @override
  String get paymentDialogNotesFieldLabel => 'सन्दर्भ / टिप्पणी (वैकल्पिक)';

  @override
  String get paymentDialogNotesHint => 'जस्तै: चेक नं., लेनदेन आईडी...';

  @override
  String get paymentDialogReceiptColLabel => 'रसिद #';

  @override
  String get paymentDialogMethodColLabel => 'विधि';

  @override
  String get paymentDialogDownloadReceiptTooltip => 'रसिद डाउनलोड गर्नुहोस्';

  @override
  String get paymentDialogDeletePaymentTooltip => 'भुक्तानी मेटाउनुहोस्';

  @override
  String get paymentMethodCash => 'नगद';

  @override
  String get paymentMethodBankTransfer => 'बैंक स्थानान्तरण';

  @override
  String get paymentMethodCheck => 'चेक';

  @override
  String get paymentMethodOnline => 'अनलाइन';

  @override
  String get paymentMethodOther => 'अन्य';

  @override
  String get customerInfoButtonTooltip => 'सम्पर्क विवरण हेर्नुहोस्';

  @override
  String get customerInfoButtonNoContactMessage =>
      'कुनै सम्पर्क विवरण उपलब्ध छैन।';

  @override
  String get updateDialogTitle => 'अपडेट उपलब्ध';

  @override
  String get updateDialogBodyMessage =>
      'invoiso को नयाँ संस्करण उपलब्ध छ। नयाँ रिलीज प्राप्त गर्न डाउनलोड पृष्ठमा जानुहोस्।';

  @override
  String get pageSizeA4Label => 'मानक A4';

  @override
  String get pageSizeA5Label => 'मानक A5';

  @override
  String get pageSizeA6Label => 'मानक A6';

  @override
  String get pageSizeThermal80Label => 'थर्मल पेपर 80mm';

  @override
  String get pageSizeThermal58Label => 'थर्मल पेपर 58mm';

  @override
  String get dateFormatDdmmyyyyLabel => 'DD/MM/YYYY  (जस्तै 15/04/2026)';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/DD/YYYY  (जस्तै 04/15/2026)';

  @override
  String get dateFormatDdMmmyyyyLabel => 'DD MMM YYYY  (जस्तै 15 Apr 2026)';

  @override
  String get dateFormatYyyymmddLabel => 'YYYY-MM-DD  (जस्तै 2026-04-15)';

  @override
  String get sizeXSmallLabel => 'अति सानो';

  @override
  String get sizeSmallLabel => 'सानो';

  @override
  String get sizeMediumLabel => 'मध्यम';

  @override
  String get sizeLargeLabel => 'ठूलो';

  @override
  String get shortcutNewInvoiceDescription =>
      'नयाँ बीजक (ड्यासबोर्डबाट) / फारम रिसेट गर्नुहोस् (बीजक सिर्जना गर्नुमा)';

  @override
  String get shortcutSaveInvoiceDescription =>
      'बीजक सुरक्षित/सिर्जना गर्नुहोस्';

  @override
  String get shortcutAddProductDescription => 'बीजकमा उत्पादन थप्नुहोस्';

  @override
  String get shortcutAddCustomItemDescription => 'कस्टम वस्तु थप्नुहोस्';

  @override
  String get shortcutPreviewPdfDescription => 'बीजक PDF पूर्वावलोकन गर्नुहोस्';

  @override
  String get shortcutPrintPdfDescription =>
      'बीजक PDF जेनेरेट/प्रिन्ट गर्नुहोस्';
}
