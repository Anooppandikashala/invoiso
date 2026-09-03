// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'इनवॉइसो';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionSkip => 'छोड़ें';

  @override
  String get actionNext => 'अगला';

  @override
  String get actionBack => 'पीछे';

  @override
  String get actionGetStarted => 'शुरू करें';

  @override
  String get commonLanguage => 'भाषा';

  @override
  String get commonBeta => 'बीटा';

  @override
  String get commonSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get commonTheme => 'थीम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get onboardingStepCompanyTitle => 'कंपनी';

  @override
  String get onboardingStepCompanySubtitle => 'अपने व्यवसाय के बारे में बताएं';

  @override
  String get onboardingStepInvoiceTitle => 'इनवॉइस सेटिंग्स';

  @override
  String get onboardingStepInvoiceSubtitle => 'अपने इनवॉइस की सेटिंग करें';

  @override
  String get onboardingStepAppearanceTitle => 'इनवॉइस स्वरूप';

  @override
  String get onboardingStepAppearanceSubtitle => 'पेज साइज़ और टेम्पलेट चुनें';

  @override
  String get onboardingStepDoneTitle => 'सब तैयार';

  @override
  String get onboardingCompanyNameLabel => 'कंपनी का नाम';

  @override
  String get onboardingCountryLabel => 'देश';

  @override
  String get onboardingLogoLabel => 'कंपनी लोगो';

  @override
  String get onboardingCurrencyLabel => 'मुद्रा';

  @override
  String get onboardingDateFormatLabel => 'तारीख़ प्रारूप';

  @override
  String get onboardingInvoiceStartingNumberLabel => 'इनवॉइस प्रारंभ संख्या';

  @override
  String get onboardingLeadingZerosLabel => 'अग्रणी शून्य';

  @override
  String get onboardingLeadingZerosSubtitle =>
      'इनवॉइस नंबर को 8 अंकों तक पैड करें (जैसे 00000007)';

  @override
  String get onboardingDefaultTaxRateLabel => 'डिफ़ॉल्ट टैक्स दर (%)';

  @override
  String get onboardingPageSizeLabel => 'पेज साइज़';

  @override
  String get onboardingTemplateLabel => 'इनवॉइस टेम्पलेट';

  @override
  String get onboardingDoneHeadline => 'सब तैयार है!';

  @override
  String get onboardingDoneBody =>
      'आपकी कंपनी, इनवॉइस और टेम्पलेट का विवरण सहेजा जा चुका है। आप इन्हें बाद में सेटिंग्स से बदल सकते हैं।';

  @override
  String get splashInitErrorTitle => 'आरंभीकरण त्रुटि';

  @override
  String splashInitErrorMessage(String error) {
    return 'डेटाबेस आरंभ करने में विफल।\n\n$error';
  }

  @override
  String get actionRetry => 'पुनः प्रयास करें';

  @override
  String get splashInitializingMessage => 'ऐप आरंभ हो रहा है...';

  @override
  String get testGateNoInternetTitle =>
      'टेस्ट इंस्टॉलर को सत्यापन के लिए इंटरनेट एक्सेस चाहिए।';

  @override
  String get testGateExpiredTitle => 'यह टेस्ट बिल्ड समाप्त हो चुका है।';

  @override
  String get testGateNoInternetSubtitle =>
      'इंटरनेट से जुड़ें और पुनः प्रयास करें।';

  @override
  String testGateExpiredSubtitle(String email) {
    return 'सहायता से संपर्क करें: $email';
  }

  @override
  String get dashboardSessionExpiredMessage =>
      'निष्क्रियता के कारण सत्र समाप्त हो गया।';

  @override
  String get dashboardUnknownTabLabel => 'अज्ञात टैब';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return 'इनवॉइस लेआउट: $layout — जानकारी के लिए टैप करें';
  }

  @override
  String get dashboardLayoutNew => 'नया';

  @override
  String get dashboardLayoutClassic => 'क्लासिक';

  @override
  String get dashboardInvoiceLayoutDialogTitle => 'इनवॉइस लेआउट';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return 'आप $layout \"नया इनवॉइस\" लेआउट उपयोग कर रहे हैं। आप इसे सेटिंग्स > एक्सेसिबिलिटी से बदल सकते हैं। ध्यान दें: बीच में बदलने से इस फ़ॉर्म के असहेजे बदलाव हट जाएंगे।';
  }

  @override
  String get actionClose => 'बंद करें';

  @override
  String get dashboardOpenSettingsAction => 'सेटिंग्स खोलें';

  @override
  String get dashboardCollapseSidebarTooltip => 'साइडबार संक्षिप्त करें';

  @override
  String get dashboardExpandSidebarTooltip => 'साइडबार विस्तृत करें';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navNewInvoice => 'नया इनवॉइस';

  @override
  String get navInvoices => 'इनवॉइस';

  @override
  String get navQuotations => 'कोटेशन';

  @override
  String get navReceipts => 'रसीदें';

  @override
  String get navCustomers => 'ग्राहक';

  @override
  String get navProducts => 'उत्पाद';

  @override
  String get navReports => 'रिपोर्ट';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get dashboardRoleAdmin => 'एडमिन';

  @override
  String get dashboardRoleUser => 'उपयोगकर्ता';

  @override
  String get dashboardSupportTooltip => 'सहायता';

  @override
  String get dashboardLogoutTooltip => 'लॉगआउट';

  @override
  String get dashboardTestBuildBadge => 'टेस्ट बिल्ड';

  @override
  String get dashboardTestBadgeShort => 'टेस्ट';

  @override
  String get dashboardKeyboardShortcutsTitle => 'कीबोर्ड शॉर्टकट';

  @override
  String get dashboardShortcutsBannerTitle => 'नया: कीबोर्ड शॉर्टकट';

  @override
  String get dashboardShortcutsBannerSubtitle =>
      'नए इनवॉइस के लिए Ctrl+Q, सहेजने के लिए Ctrl+S, और भी बहुत कुछ।';

  @override
  String get dashboardViewAllAction => 'सभी देखें';

  @override
  String get dashboardLayoutBannerTitle => 'नया: कई डैशबोर्ड लेआउट';

  @override
  String get dashboardLayoutBannerSubtitle =>
      'ऊपर-दाईं ओर ग्रिड आइकन का उपयोग करके डिफ़ॉल्ट, क्लासिक, बेंटो और सिंपल फीड के बीच स्विच करें।';

  @override
  String get actionGotIt => 'समझ गया';

  @override
  String get dashboardThemeBannerTitle => 'नया: डार्क मोड';

  @override
  String get dashboardThemeBannerSubtitle =>
      'हम इसे अभी और बेहतर बना रहे हैं — सेटिंग्स > कंपनी जानकारी से इसे चालू करें और बताएं कि क्या ठीक नहीं लग रहा।';

  @override
  String dashboardSupportBannerTitle(String count) {
    return 'आपने $count इनवॉइस बनाए हैं!';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      'Invoiso पसंद आ रहा है? एक त्वरित समीक्षा बहुत मदद करती है।';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      'लगता है Invoiso आपके काम का हिस्सा बन गया है। अगर यह मददगार रहा हो, तो जब उचित लगे प्रोजेक्ट को सपोर्ट करने पर विचार करें।';

  @override
  String get dashboardReviewAction => 'समीक्षा करें';

  @override
  String get dashboardSupportAction => 'सहयोग करें';

  @override
  String get dashboardOverviewTitle => 'डैशबोर्ड अवलोकन';

  @override
  String get actionRefresh => 'रीफ्रेश करें';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count स्टॉक में नहीं';
  }

  @override
  String get dashboardRevenueCollectedLabel => 'प्राप्त राजस्व';

  @override
  String get dashboardOutstandingLabel => 'बकाया';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count अतिदेय';
  }

  @override
  String get dashboardRecentInvoicesTitle => 'हाल के इनवॉइस';

  @override
  String get dashboardLastFiveInvoicesLabel => 'पिछले 5 इनवॉइस';

  @override
  String get dashboardNoInvoicesYetTitle => 'अभी तक कोई इनवॉइस नहीं';

  @override
  String get dashboardNoInvoicesYetSubtitle =>
      'यहाँ देखने के लिए अपना पहला इनवॉइस बनाएं';

  @override
  String get actionView => 'देखें';

  @override
  String get actionEdit => 'संपादित करें';

  @override
  String get actionDuplicate => 'डुप्लिकेट करें';

  @override
  String get actionPdfPreview => 'PDF पूर्वावलोकन';

  @override
  String get actionDownloadPdf => 'PDF डाउनलोड करें';

  @override
  String get actionPrint => 'प्रिंट करें';

  @override
  String get actionPayment => 'भुगतान';

  @override
  String get actionDelete => 'हटाएं';

  @override
  String get actionRecordPayment => 'भुगतान दर्ज करें';

  @override
  String dashboardDueDateLabel(String date) {
    return 'देय: $date';
  }

  @override
  String get labelInvoice => 'इनवॉइस';

  @override
  String get labelQuotation => 'कोटेशन';

  @override
  String get labelReceipt => 'रसीद';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return 'वापसी पर स्वागत है, $username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle =>
      'यहाँ आपके व्यवसाय की एक झलक है';

  @override
  String get dashboardDueSoonTitle => 'जल्द देय';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count इनवॉइस',
      one: '1 इनवॉइस',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => 'आज और कल';

  @override
  String get dashboardDueTodayBadge => 'आज देय';

  @override
  String get dashboardDueTomorrowBadge => 'कल देय';

  @override
  String get dashboardOverdueSectionTitle => 'अतिदेय';

  @override
  String get dashboardOldestFirstLabel => 'सबसे पुराना पहले';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन से अतिदेय',
      one: '1 दिन से अतिदेय',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => 'नई स्टॉक मात्रा';

  @override
  String get actionUpdate => 'अपडेट करें';

  @override
  String get labelService => 'सेवा';

  @override
  String get labelProduct => 'उत्पाद';

  @override
  String dashboardStockLabel(int count) {
    return 'स्टॉक: $count';
  }

  @override
  String get actionUpdateStock => 'स्टॉक अपडेट करें';

  @override
  String get paymentStatusPaid => 'भुगतान किया गया';

  @override
  String get paymentStatusPartial => 'आंशिक';

  @override
  String get paymentStatusUnpaid => 'अवैतनिक';

  @override
  String get dashboardDuplicateInvoiceTitle => 'इनवॉइस डुप्लिकेट करें';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return 'इनवॉइस #$number\n($customerName) की प्रतिलिपि इस रूप में बनाएं:';
  }

  @override
  String get dashboardDeleteInvoiceTitle => 'इनवॉइस हटाएं';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return 'क्या आप वाकई इनवॉइस #$number हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';
  }

  @override
  String get dashboardLayoutTooltip => 'डैशबोर्ड लेआउट';

  @override
  String get dashboardLayoutDefaultTitle => 'डिफ़ॉल्ट';

  @override
  String get dashboardLayoutDefaultSubtitle => 'मूल लेआउट';

  @override
  String get dashboardLayoutClassicSubtitle => 'चार्ट + KPI ग्रिड';

  @override
  String get dashboardLayoutBentoTitle => 'बेंटो';

  @override
  String get dashboardLayoutBentoSubtitle => 'मुख्य चार्ट + कार्ड ग्रिड';

  @override
  String get dashboardLayoutSimpleTitle => 'सिंपल फीड';

  @override
  String get dashboardLayoutSimpleSubtitle => 'साफ़ सूची दृश्य';

  @override
  String get dashboardTotalInvoicesLabel => 'कुल इनवॉइस';

  @override
  String get dashboardRevenueLast6MonthsTitle => 'राजस्व — पिछले 6 महीने';

  @override
  String get dashboardNoPaymentDataYetLabel => 'अभी तक भुगतान डेटा नहीं';

  @override
  String get dashboardFinancialOverviewTitle => 'वित्तीय अवलोकन';

  @override
  String get dashboardCollectedLabel => 'प्राप्त';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count इनवॉइस अतिदेय',
      one: '1 इनवॉइस अतिदेय',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return 'पिछले $n';
  }

  @override
  String get labelCustomer => 'ग्राहक';

  @override
  String get labelAmount => 'राशि';

  @override
  String get dashboardZeroLeftLabel => '0 बचे';

  @override
  String get labelStock => 'स्टॉक';

  @override
  String get actionPay => 'भुगतान करें';

  @override
  String get dashboardQuickActionsTitle => 'त्वरित कार्रवाइयां';

  @override
  String get dashboardPdfActionsTooltip => 'PDF कार्रवाइयां';

  @override
  String get dashboardActionsTooltip => 'कार्रवाइयां';

  @override
  String get dashboardTopCustomersTitle => 'शीर्ष ग्राहक';

  @override
  String get dashboardTopProductsTitle => 'शीर्ष उत्पाद';

  @override
  String dashboardUnitsLabel(String qty) {
    return '$qty इकाइयां';
  }

  @override
  String get dashboardBetaBadge => 'बीटा';

  @override
  String get dashboardOutOfStockSectionTitle => 'स्टॉक खत्म';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count वस्तुएं',
      one: '1 वस्तु',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => 'पुनः स्टॉक करने के लिए टैप करें';

  @override
  String get createInvoiceUnsavedChangesTitle => 'असहेजे परिवर्तन';

  @override
  String get createInvoiceUnsavedChangesMessage =>
      'इस इनवॉइस में असहेजे परिवर्तन हैं। बाहर जाने से पहले सहेजें?';

  @override
  String get createInvoiceKeepEditingButton => 'संपादन जारी रखें';

  @override
  String get actionDiscard => 'छोड़ दें';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return 'डेटा लोड करने में त्रुटि: $e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => 'अपर्याप्त स्टॉक';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return 'केवल $stock इकाई(यां) उपलब्ध हैं। फिर भी $qty जोड़ें?';
  }

  @override
  String get createInvoiceAddAnywayButton => 'फिर भी जोड़ें';

  @override
  String get createInvoiceOutOfStockTitle => 'स्टॉक में नहीं';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name स्टॉक में नहीं है। फिर भी जोड़ें?';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => 'असीमित स्टॉक';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return 'उपलब्ध स्टॉक: $stock';
  }

  @override
  String get fieldDiscountLabel => 'छूट';

  @override
  String get fieldUnitPriceOverrideLabel => 'इकाई मूल्य (ओवरराइड)';

  @override
  String get fieldExtraCostLabel => 'अतिरिक्त लागत (वैकल्पिक)';

  @override
  String get fieldInsertAtPositionLabel => 'इस स्थिति पर जोड़ें';

  @override
  String get actionAdd => 'जोड़ें';

  @override
  String get createInvoiceProductAlreadyAddedMessage =>
      'यह उत्पाद पहले से जोड़ा जा चुका है';

  @override
  String get createInvoiceCustomerNameRequiredMessage =>
      'कृपया ग्राहक का नाम दर्ज करें';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage =>
      'कृपया कम से कम एक आइटम जोड़ें';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सफलतापूर्वक बनाया गया!';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return 'इनवॉइस बनाने में त्रुटि: $e';
  }

  @override
  String get createInvoiceEditItemTitle => 'आइटम संपादित करें';

  @override
  String get createInvoiceCustomItemTitle => 'कस्टम आइटम';

  @override
  String get fieldItemNameLabel => 'आइटम का नाम';

  @override
  String get fieldAliasForPdfLabel => 'उपनाम (PDF के लिए)';

  @override
  String get fieldUnitPriceLabel => 'इकाई मूल्य';

  @override
  String get fieldRateLabel => 'दर';

  @override
  String get fieldTaxRateLabel => 'टैक्स दर (%)';

  @override
  String get fieldPriceIncludesTaxLabel => 'मूल्य में टैक्स शामिल है';

  @override
  String get createInvoicePhoneAlreadyInUseTitle =>
      'फ़ोन नंबर पहले से उपयोग में है';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return 'यह फ़ोन नंबर \"$ownerName\" का है।\n\nइस ग्राहक को ऐसे फ़ोन नंबर से सहेजा नहीं जा सकता जो पहले से किसी और का है।';
  }

  @override
  String get actionOk => 'ठीक है';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      'सहेजने से पहले कृपया ग्राहक का नाम दर्ज करें';

  @override
  String get createInvoicePhoneChangedTitle => 'फ़ोन नंबर बदला गया';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return '\"$name\" का फ़ोन नंबर बदल गया है।\n\nक्या उनका मौजूदा रिकॉर्ड अपडेट करें, या इसे नए ग्राहक के रूप में सहेजें?';
  }

  @override
  String get createInvoiceSaveAsNewButton => 'नए के रूप में सहेजें';

  @override
  String get createInvoiceUpdateExistingButton => 'मौजूदा अपडेट करें';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '$name ग्राहक सूची में अपडेट किया गया';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle =>
      'ग्राहक पहले से मौजूद है';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '\"$name\" इस फ़ोन नंबर के साथ पहले से सहेजा गया है।\n\nक्या उनका मौजूदा विवरण उपयोग करें, या वर्तमान जानकारी से रिकॉर्ड अपडेट करें?';
  }

  @override
  String get createInvoiceUseExistingButton => 'मौजूदा उपयोग करें';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return 'मौजूदा ग्राहक \"$name\" का उपयोग किया जा रहा है';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name ग्राहक सूची में सहेजा गया';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage =>
      'ग्राहक रिकॉर्ड अब मौजूद नहीं है';

  @override
  String get createInvoiceCustomerRefreshedMessage =>
      'ग्राहक विवरण ताज़ा किया गया';

  @override
  String get fieldLabelLabel => 'लेबल';

  @override
  String get hintLabelExample => 'जैसे शिपिंग';

  @override
  String get tooltipRemove => 'हटाएं';

  @override
  String get createInvoiceAddRowButton => 'पंक्ति जोड़ें';

  @override
  String get fieldDiscountPerUnitLabel => 'प्रति इकाई छूट';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn => '(मूल्य − छूट) × मात्रा';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff => '(मूल्य × मात्रा) − छूट';

  @override
  String get createInvoicePrevBalanceShortLabel => 'पिछला शेष';

  @override
  String get createInvoicePreviousBalanceDueLabel => 'पिछला बकाया शेष';

  @override
  String get createInvoiceDueShortLabel => 'बकाया';

  @override
  String get createInvoiceTotalDueLabel => 'कुल बकाया';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सफलतापूर्वक अपडेट किया गया!';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return 'इनवॉइस अपडेट करने में त्रुटि: $e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '$invoiceTypeLabel सफलतापूर्वक बनाया गया!';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return '$invoiceTypeLabel आईडी: $invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => 'विवरण देखें';

  @override
  String get createInvoicePreviewPdfLabel => 'PDF पूर्वावलोकन';

  @override
  String get createInvoicePreviewPdfTooltip =>
      'PDF पूर्वावलोकन (शॉर्टकट: Ctrl+o)';

  @override
  String get createInvoicePrintPdfLabel => 'PDF प्रिंट करें';

  @override
  String get createInvoicePrintPdfTooltip =>
      'PDF प्रिंट करें (शॉर्टकट: Ctrl+p)';

  @override
  String get actionDismiss => 'खारिज करें';

  @override
  String get createInvoiceCreateNewInvoiceButton =>
      'नया इनवॉइस बनाएं (शॉर्टकट: Ctrl+q)';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return 'नया $invoiceTypeLabel बनाएं';
  }

  @override
  String get commonLoadingDataMessage => 'डेटा लोड हो रहा है...';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage =>
      'इनवॉइस बनाने से पहले कम से कम एक आइटम जोड़ें।';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel बनाया गया';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel संपादित करें';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel के रूप में डुप्लिकेट करें';
  }

  @override
  String get createInvoiceNewShortLabel => 'नया';

  @override
  String get createInvoiceNewInvoiceShortcutLabel =>
      'नया इनवॉइस (शॉर्टकट: Ctrl+q)';

  @override
  String get createInvoiceSavingEllipsisLabel => 'सहेजा जा रहा है...';

  @override
  String get createInvoiceSaveCustomerLabel => 'ग्राहक सहेजें';

  @override
  String get createInvoiceSelectExistingCustomerButton => 'मौजूदा में से चुनें';

  @override
  String get createInvoiceRefreshCustomerTooltip =>
      'सहेजे गए ग्राहक से ताज़ा करें';

  @override
  String get createInvoiceClearCustomerTooltip => 'ग्राहक चयन साफ़ करें';

  @override
  String get fieldCustomerNameRequiredLabel => 'ग्राहक का नाम *';

  @override
  String get fieldBusinessNameLabel => 'व्यवसाय का नाम';

  @override
  String get fieldPhoneLabel => 'फ़ोन';

  @override
  String get fieldGstinVatLabel => 'जीएसटीआईएन / वैट';

  @override
  String get fieldEmailLabel => 'ईमेल';

  @override
  String get fieldAddressLabel => 'पता';

  @override
  String get tooltipEditInLargerView => 'बड़े दृश्य में संपादित करें';

  @override
  String get createInvoiceChooseCustomerTitle => 'ग्राहक चुनें';

  @override
  String get createInvoiceSearchCustomerLabel => 'ग्राहक खोजें';

  @override
  String get createInvoiceNoCustomersFoundMessage => 'कोई ग्राहक नहीं मिला';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return '$invoiceTypeLabel विवरण';
  }

  @override
  String get createInvoiceTypeFieldLabel => 'इनवॉइस प्रकार';

  @override
  String get createInvoiceTypeLockedHelperText =>
      'बनने के बाद प्रकार बदला नहीं जा सकता';

  @override
  String get createInvoiceOrderDateLabel => 'ऑर्डर तिथि';

  @override
  String get createInvoiceDueDateLabel => 'देय तिथि';

  @override
  String get createInvoiceGstTitleLabel => 'जीएसटी शीर्षक';

  @override
  String get createInvoiceTaxTitleLabel => 'टैक्स शीर्षक';

  @override
  String get gstTitleTaxInvoiceLabel => 'कर चालान';

  @override
  String get gstTitleBillOfSupplyLabel => 'आपूर्ति बिल';

  @override
  String get gstTitleInvoiceCumBillLabel => 'इनवॉइस-सह-आपूर्ति बिल';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => 'क्रेडिट नोट';

  @override
  String get gstTitleDebitNoteLabel => 'डेबिट नोट';

  @override
  String get gstTitleRevisedInvoiceLabel => 'संशोधित इनवॉइस';

  @override
  String get createInvoiceSearchProductLabel =>
      'उत्पाद या सेवा खोजें और जोड़ें (Ctrl+F)';

  @override
  String get createInvoiceCustomItemButton => 'कस्टम आइटम (Ctrl+M)';

  @override
  String get createInvoiceNoProductsFoundMessage => 'कोई उत्पाद नहीं मिला';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '\"$name\" पहले से उत्पाद सूची में मौजूद है';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name उत्पाद सूची में सहेजा गया';
  }

  @override
  String get createInvoiceSaveToProductListTooltip => 'उत्पाद सूची में सहेजें';

  @override
  String get tooltipEditItem => 'आइटम संपादित करें';

  @override
  String get tooltipRemoveItem => 'आइटम हटाएं';

  @override
  String get createInvoiceNoItemsAddedMessage =>
      'अभी तक कोई आइटम नहीं जोड़ा गया';

  @override
  String get createInvoiceSearchHintMessage => 'नीचे खोजें या Ctrl+F दबाएं';

  @override
  String get createInvoiceDiscountFieldLabel => 'इनवॉइस छूट';

  @override
  String get discountTypeAmountShortLabel => 'राशि';

  @override
  String get createInvoiceNotesOptionalLabel => 'नोट्स (वैकल्पिक)';

  @override
  String get createInvoiceNotesHint => 'भुगतान शर्तें, धन्यवाद संदेश…';

  @override
  String get createInvoiceNotesTitle => 'नोट्स';

  @override
  String get createInvoiceHideNumberInPdfLabel => 'PDF में इनवॉइस नंबर छिपाएं';

  @override
  String get createInvoiceCustomNumberLabel => 'कस्टम नंबर (वैकल्पिक)';

  @override
  String get createInvoiceCustomNumberHint =>
      'जैसे QUO-2026-014 — इसके बजाय PDF में दिखाया जाएगा';

  @override
  String get createInvoiceEnableTaxLabel => 'टैक्स सक्षम करें';

  @override
  String get createInvoiceGlobalRateTooltip => 'वैश्विक दर';

  @override
  String get createInvoicePerItemRateTooltip => 'प्रति आइटम दर';

  @override
  String get createInvoiceDefaultTaxRateLabel => 'डिफ़ॉल्ट टैक्स दर';

  @override
  String get createInvoiceTaxRateFromProductMessage =>
      'प्रत्येक उत्पाद से टैक्स दर';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => 'भुगतान यूपीआई खाता';

  @override
  String get commonNoneLabel => 'कोई नहीं';

  @override
  String get createInvoiceBankAccountLabel => 'बैंक खाता';

  @override
  String get fieldSubtotalLabel => 'उप-योग';

  @override
  String get createInvoiceDiscountColonLabel => 'छूट:';

  @override
  String get fieldTaxLabel => 'टैक्स';

  @override
  String get createInvoiceExtraCostFallbackLabel => 'अतिरिक्त लागत';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return 'इनवॉइस छूट ($toStringAsFixed%):';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel => 'इनवॉइस छूट:';

  @override
  String get fieldTotalLabel => 'कुल';

  @override
  String get createInvoicePreviewLabel => 'पूर्वावलोकन';

  @override
  String get createInvoicePreviewTooltip => 'पूर्वावलोकन (शॉर्टकट: Ctrl+o)';

  @override
  String get createInvoiceDownloadLabel => 'डाउनलोड करें';

  @override
  String get createInvoicePrintTooltip => 'प्रिंट करें (शॉर्टकट: Ctrl+p)';

  @override
  String get fieldUnitOverrideLabel => 'इकाई (ओवरराइड)';

  @override
  String get commonCustomEllipsisLabel => 'कस्टम…';

  @override
  String get fieldCustomUnitLabel => 'कस्टम इकाई';

  @override
  String get invoiceMgmtMoveToTrashTitle => 'ट्रैश में ले जाएँ';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return 'चालान #$number को ट्रैश में ले जाएँ?';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage => 'चालान ट्रैश में ले जाया गया।';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return 'चालान लोड करने में विफल: $error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return '$type को CSV में निर्यात करें';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel => 'सभी रिकॉर्ड निर्यात करें';

  @override
  String get invoiceMgmtFilterByDateRangeLabel =>
      'या दिनांक सीमा के अनुसार फ़िल्टर करें:';

  @override
  String get invoiceMgmtFromDateLabel => 'प्रारंभ तिथि';

  @override
  String get invoiceMgmtToDateLabel => 'अंतिम तिथि';

  @override
  String get invoiceMgmtDateRangeInvalidMessage =>
      'अंतिम तिथि प्रारंभ तिथि के बाद होनी चाहिए।';

  @override
  String get actionExport => 'निर्यात करें';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिकॉर्ड यहाँ निर्यात किए गए: $path',
      one: '1 रिकॉर्ड यहाँ निर्यात किया गया: $path',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return 'निर्यात विफल: $error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालानों को ट्रैश में ले जाएँ?',
      one: '1 चालान को ट्रैश में ले जाएँ?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालान ट्रैश में ले जाए गए।',
      one: '1 चालान ट्रैश में ले जाया गया।',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return 'बल्क डिलीट विफल: $error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालान CSV में निर्यात किए गए',
      one: '1 चालान CSV में निर्यात किया गया',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'CSV निर्यात विफल: $error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => 'PDF डाउनलोड करें';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आप $count PDF कैसे सहेजना चाहते हैं?',
      one: 'आप 1 PDF कैसे सहेजना चाहते हैं?',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => 'फ़ोल्डर में सहेजें';

  @override
  String get invoiceMgmtSaveAsZipLabel => 'ZIP के रूप में सहेजें';

  @override
  String get invoiceMgmtChooseFolderDialogTitle =>
      'PDF सहेजने के लिए फ़ोल्डर चुनें';

  @override
  String get invoiceMgmtSaveZipDialogTitle => 'ZIP फ़ाइल सहेजें';

  @override
  String get invoiceMgmtCreatingZipLabel => 'ZIP बनाई जा रही है';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => 'PDF तैयार की जा रही हैं';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PDF संसाधित हो रहे हैं...',
      one: '1 PDF संसाधित हो रहा है...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return 'यहाँ सहेजा गया: $path';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'PDF निर्यात विफल: $error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle =>
      'फ़िल्टर द्वारा PDF डाउनलोड करें';

  @override
  String get invoiceMgmtByDateLabel => 'दिनांक द्वारा';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => 'चालान संख्या द्वारा';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => 'प्रारंभ चालान #';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => 'अंतिम चालान #';

  @override
  String get invoiceMgmtCheckCountLabel => 'संख्या जाँचें';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return '$count चालान — $limit की सीमा से अधिक';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालान मेल खाते हैं',
      one: '1 चालान मेल खाता है',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return 'प्रति डाउनलोड अधिकतम $limit PDF। अपना फ़िल्टर सीमित करें।';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage =>
      'चयनित फ़िल्टर के लिए कोई चालान नहीं मिला।';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return 'फ़िल्टर ने $count चालान लौटाए — अधिकतम $limit है।';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => 'चालान फ़िल्टर करें';

  @override
  String get invoiceMgmtHideFullyPaidLabel =>
      'पूरी तरह भुगतान किए गए चालान छिपाएँ';

  @override
  String get invoiceMgmtPaymentStatusLabel => 'भुगतान स्थिति';

  @override
  String get invoiceMgmtDueDateLabel => 'देय तिथि';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => 'चालान तिथि सीमा';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel => 'चालान # सीमा';

  @override
  String get invoiceMgmtFromHashLabel => 'प्रारंभ #';

  @override
  String get invoiceMgmtToHashLabel => 'अंतिम #';

  @override
  String get actionReset => 'रीसेट करें';

  @override
  String get actionApply => 'लागू करें';

  @override
  String get invoiceMgmtSortByTitle => 'क्रमबद्ध करें';

  @override
  String get invoiceMgmtSearchHintMessage =>
      'चालान ID या ग्राहक के नाम से खोजें…';

  @override
  String get invoiceMgmtFilterLabel => 'फ़िल्टर';

  @override
  String get invoiceMgmtSortLabel => 'क्रमबद्ध करें';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return 'कुल: $total   ·   पृष्ठ $page/$totalPages';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '$count चयनित';
  }

  @override
  String get invoiceMgmtDeselectLabel => 'चयन हटाएँ';

  @override
  String get invoiceMgmtSelectPageLabel => 'पृष्ठ चुनें';

  @override
  String get invoiceMgmtMarkPaidLabel => 'भुगतान के रूप में चिह्नित करें';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDF';

  @override
  String get invoiceMgmtTrashLabel => 'ट्रैश';

  @override
  String get actionApplyPayment => 'भुगतान लागू करें';

  @override
  String get invoiceMgmtMoreActionsTooltip => 'अधिक कार्य';

  @override
  String get invoiceMgmtColSlNo => 'क्र.सं.';

  @override
  String get invoiceMgmtColInvoiceCustomer => 'चालान / ग्राहक';

  @override
  String get invoiceMgmtColTitle => 'शीर्षक';

  @override
  String get invoiceMgmtColDate => 'तिथि';

  @override
  String get invoiceMgmtColItems => 'आइटम';

  @override
  String get invoiceMgmtColStatus => 'स्थिति';

  @override
  String get invoiceMgmtColOutstanding => 'बकाया';

  @override
  String get invoiceMgmtColActions => 'कार्य';

  @override
  String get invoiceMgmtRowsPerPageLabel => 'प्रति पृष्ठ पंक्तियाँ:';

  @override
  String get actionPrevious => 'पिछला';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return 'पृष्ठ $page / $totalPages';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return '\"$query\" के लिए कोई परिणाम नहीं';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return 'कोई $type नहीं मिला';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return 'यहाँ देखने के लिए अपना पहला $type बनाएँ';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage =>
      'अपनी खोज या फ़िल्टर समायोजित करने का प्रयास करें';

  @override
  String get invoiceMgmtDownloadByRangeTooltip =>
      'दिनांक या चालान सीमा के अनुसार PDF डाउनलोड करें';

  @override
  String get invoiceMgmtExportAllCsvTooltip => 'सभी को CSV में निर्यात करें';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel =>
      'सीमा के अनुसार PDF डाउनलोड करें';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return '$type प्रबंधन';
  }

  @override
  String get invoiceMgmtOverdueBadge => 'अतिदेय';

  @override
  String get invoiceMgmtTodayBadge => 'आज';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => 'ट्रैश खाली है';

  @override
  String get actionRestore => 'पुनर्स्थापित करें';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => 'स्थायी रूप से हटाएँ';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return 'चालान #$number को स्थायी रूप से हटाएँ? इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage =>
      'चालान पुनर्स्थापित किया गया।';

  @override
  String get invoiceMgmtAnyDateLabel => 'कोई भी';

  @override
  String get invoiceMgmtStatusAllLabel => 'सभी';

  @override
  String get invoiceMgmtDueAllLabel => 'सभी देय';

  @override
  String get invoiceMgmtDueTodayLabel => 'आज देय';

  @override
  String get invoiceMgmtDueWeekLabel => 'इस सप्ताह देय';

  @override
  String get invoiceMgmtDueMonthLabel => 'इस महीने देय';

  @override
  String get invoiceMgmtSortRecentlyAdded => 'हाल ही में जोड़ा गया';

  @override
  String get invoiceMgmtSortOldestAdded => 'सबसे पहले जोड़ा गया';

  @override
  String get invoiceMgmtSortDateNewest => 'चालान तिथि (नवीनतम पहले)';

  @override
  String get invoiceMgmtSortDateOldest => 'चालान तिथि (सबसे पुराना पहले)';

  @override
  String get invoiceMgmtSortCustomerAZ => 'ग्राहक का नाम (A–Z)';

  @override
  String get invoiceMgmtSortCustomerZA => 'ग्राहक का नाम (Z–A)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => 'भुगतान के रूप में चिह्नित करें';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालानों को पूर्ण भुगतान के रूप में चिह्नित करें?',
      one: '1 चालान को पूर्ण भुगतान के रूप में चिह्नित करें?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n($count पहले से ही भुगतान किए गए — छोड़े जाएँगे)';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage =>
      'चयनित सभी चालान पहले से ही पूरी तरह भुगतान किए जा चुके हैं।';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालान भुगतान के रूप में चिह्नित किए गए।',
      one: '1 चालान भुगतान के रूप में चिह्नित किया गया।',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return 'भुगतान के रूप में चिह्नित करने में विफल: $error';
  }

  @override
  String get fieldNameLabel => 'नाम';

  @override
  String get customerMgmtEditCustomerTitle => 'ग्राहक संपादित करें';

  @override
  String get customerMgmtViewCustomerTitle => 'ग्राहक देखें';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / वैट नंबर';
  }

  @override
  String get customerMgmtUpdatedMessage => 'ग्राहक सफलतापूर्वक अपडेट किया गया!';

  @override
  String fieldRequiredMessage(String field) {
    return 'कृपया $field दर्ज करें';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => 'हटाने की पुष्टि करें';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return 'क्या आप वाकई \"$name\" को हटाना चाहते हैं?';
  }

  @override
  String get customerMgmtDeletedMessage => 'ग्राहक सफलतापूर्वक हटाया गया!';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle => 'नमूना CSV सहेजें';

  @override
  String get customerMgmtSampleSavedMessage =>
      'नमूना CSV सफलतापूर्वक सहेजा गया!';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return 'नमूना सहेजने में त्रुटि: $error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle => 'CSV से ग्राहक आयात करें';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      'आपकी CSV फ़ाइल में निम्न कॉलम हेडर होने चाहिए (सटीक वर्तनी, किसी भी क्रम में):';

  @override
  String get customerMgmtCsvColColumnHeader => 'कॉलम';

  @override
  String get customerMgmtCsvColRequiredHeader => 'आवश्यक';

  @override
  String get customerMgmtCsvColDescriptionHeader => 'विवरण';

  @override
  String get commonYesLabel => 'हाँ';

  @override
  String get commonNoLabel => 'नहीं';

  @override
  String get customerMgmtCsvDescName => 'ग्राहक का पूरा नाम';

  @override
  String get customerMgmtCsvDescEmail => 'ईमेल पता';

  @override
  String get customerMgmtCsvDescPhone => 'फ़ोन नंबर';

  @override
  String get customerMgmtCsvDescAddress => 'पूरा पता';

  @override
  String get customerMgmtCsvDescBusinessName => 'कंपनी / व्यवसाय का नाम';

  @override
  String get customerMgmtCsvDescTaxNumber => 'टैक्स / वैट / GSTIN नंबर';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return 'प्रति आयात अधिकतम $max पंक्तियाँ।';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      'डुप्लिकेट ईमेल या फ़ोन द्वारा पहचाने जाते हैं। आपसे प्रत्येक को अधिलेखित करने या छोड़ने के लिए कहा जाएगा।';

  @override
  String get customerMgmtCsvMissingNameNote =>
      'नाम रहित पंक्तियों को छोड़ दिया जाता है और अंत में रिपोर्ट किया जाता है।';

  @override
  String get customerMgmtCsvEncodingNote =>
      'UTF-8 एन्कोडिंग की सिफारिश की जाती है। Excel BOM स्वचालित रूप से संभाला जाता है।';

  @override
  String get customerMgmtDownloadSampleCsvButton => 'नमूना CSV डाउनलोड करें';

  @override
  String get customerMgmtChooseFileButton => 'फ़ाइल चुनें';

  @override
  String get customerMgmtSelectCsvDialogTitle => 'ग्राहक CSV चुनें';

  @override
  String get customerMgmtCsvEmptyMessage => 'CSV फ़ाइल खाली है।';

  @override
  String get customerMgmtCsvMissingNameColumnMessage =>
      'CSV में आवश्यक कॉलम गायब है: \"name\"';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return 'अज्ञात कॉलम \"$col\"। अपेक्षित: $expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'CSV में $count पंक्तियाँ हैं। अधिकतम $max है। कृपया फ़ाइल को विभाजित करें।';
  }

  @override
  String get customerMgmtImportingTitle => 'ग्राहक आयात हो रहे हैं';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'डुप्लिकेट जाँच रहे हैं और $count पंक्तियाँ सत्यापित कर रहे हैं...',
      one: 'डुप्लिकेट जाँच रहे हैं और 1 पंक्ति सत्यापित कर रहे हैं...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return 'पंक्ति $n: नाम गायब है — छोड़ी गई';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return 'CSV पढ़ने में त्रुटि: $error';
  }

  @override
  String get customerMgmtImportPreviewTitle => 'आयात पूर्वावलोकन';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नए',
      one: '1 नया',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डुप्लिकेट',
      one: '1 डुप्लिकेट',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count त्रुटियाँ',
      one: '1 त्रुटि',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel =>
      'डुप्लिकेट (ईमेल या फ़ोन से मिलान):';

  @override
  String get customerMgmtOverwriteAllButton => 'सभी अधिलेखित करें';

  @override
  String get customerMgmtSkipAllButton => 'सभी छोड़ें';

  @override
  String get customerMgmtOverwriteLabel => 'अधिलेखित करें';

  @override
  String get customerMgmtSkippedRowsLabel => 'छोड़ी गई पंक्तियाँ (त्रुटियाँ):';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total ग्राहक आयात किए जाएँगे।',
      one: '1 ग्राहक आयात किया जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return '$total आयात करें';
  }

  @override
  String get customerMgmtDeleteAllTitle => 'सभी ग्राहक हटाएं';

  @override
  String get customerMgmtNoCustomersToDeleteMessage =>
      'हटाने के लिए कोई ग्राहक नहीं है।';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यह सभी $count ग्राहकों को स्थायी रूप से हटा देगा। मौजूदा चालान प्रभावित नहीं होंगे। यह पूर्ववत नहीं किया जा सकता।',
      one:
          'यह सभी 1 ग्राहक को स्थायी रूप से हटा देगा। मौजूदा चालान प्रभावित नहीं होंगे। यह पूर्ववत नहीं किया जा सकता।',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => 'सभी हटाएं';

  @override
  String get customerMgmtAllDeletedMessage => 'सभी ग्राहक हटा दिए गए।';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return 'ग्राहकों को हटाने में त्रुटि: $error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => 'ग्राहक CSV सहेजें';

  @override
  String get customerMgmtCsvExportedMessage =>
      'CSV सफलतापूर्वक निर्यात किया गया!';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return 'CSV निर्यात करने में त्रुटि: $error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => 'ग्राहक PDF सहेजें';

  @override
  String get customerMgmtPdfExportedMessage =>
      'PDF सफलतापूर्वक निर्यात किया गया!';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return 'PDF निर्यात करने में त्रुटि: $error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => 'कुल ग्राहक';

  @override
  String get customerMgmtAllCustomersSubtitle => 'सभी ग्राहक';

  @override
  String get customerMgmtBusinessesLabel => 'व्यवसाय';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle => 'पंजीकृत व्यवसाय';

  @override
  String get customerMgmtIndividualsLabel => 'व्यक्तिगत';

  @override
  String get customerMgmtIndividualCustomersSubtitle => 'व्यक्तिगत ग्राहक';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '$taxWord पंजीकृत';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return '$taxWord नंबर के साथ';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return '$taxWord रहित';
  }

  @override
  String get customerMgmtTitle => 'ग्राहक प्रबंधन';

  @override
  String get customerMgmtSubtitle =>
      'अपने ग्राहकों और संपर्क विवरण प्रबंधित करें';

  @override
  String get actionImport => 'आयात करें';

  @override
  String get customerMgmtExportPdfMenuLabel => 'PDF निर्यात करें';

  @override
  String get customerMgmtNewCustomerButton => 'नया ग्राहक';

  @override
  String get customerMgmtSortNameAZ => 'नाम A-Z';

  @override
  String get customerMgmtSortNameZA => 'नाम Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID (सबसे पुराना पहले)';

  @override
  String get customerMgmtSortIdNewest => 'ID (सबसे नया पहले)';

  @override
  String get customerMgmtSortOutstandingHighLow => 'बकाया (अधिक से कम)';

  @override
  String get customerMgmtSortOutstandingLowHigh => 'बकाया (कम से अधिक)';

  @override
  String get customerMgmtWithOutstandingLabel => 'बकाया वाले';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return 'नाम, व्यवसाय, फ़ोन, $taxWord, ईमेल से ग्राहक खोजें…';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return 'सभी $taxWord स्थितियाँ';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '$taxWord पंजीकृत';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return 'क्रमबद्ध करें: $label';
  }

  @override
  String get customerMgmtColumnsLabel => 'कॉलम';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / वैट नंबर';
  }

  @override
  String get customerMgmtHideStatCardsTooltip => 'आँकड़े कार्ड छिपाएं';

  @override
  String get customerMgmtShowStatCardsTooltip => 'आँकड़े कार्ड दिखाएं';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get customerMgmtColSlNo => 'क्र. सं.';

  @override
  String get customerMgmtColNameBusiness => 'नाम / व्यवसाय';

  @override
  String get customerMgmtColPhone => 'फ़ोन';

  @override
  String get customerMgmtColEmail => 'ईमेल';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / वैट नंबर';
  }

  @override
  String get customerMgmtColAddress => 'पता';

  @override
  String get customerMgmtColActions => 'कार्रवाइयां';

  @override
  String get customerMgmtViewStatementTooltip =>
      'स्टेटमेंट देखें (रिपोर्ट में)';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return '$total में से $from से $to दिखा रहे हैं';
  }

  @override
  String get customerMgmtRowsPerPageLabel => 'प्रति पृष्ठ पंक्तियाँ';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return '$totalPages में से';
  }

  @override
  String get customerMgmtAddAnotherLabel => 'सहेजने के बाद एक और जोड़ें';

  @override
  String get customerMgmtSaveCustomerButton => 'ग्राहक सहेजें';

  @override
  String get customerMgmtAddFirstCustomerSubtitle =>
      'शुरू करने के लिए अपना पहला ग्राहक जोड़ें';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle =>
      'अपनी खोज समायोजित करने का प्रयास करें';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return 'ग्राहकों को लोड करने में त्रुटि: $error';
  }

  @override
  String get customerMgmtAddedMessage => 'ग्राहक सफलतापूर्वक जोड़ा गया!';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return 'ग्राहक सहेजने में त्रुटि: $error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ग्राहक सफलतापूर्वक आयात किए गए!',
      one: '1 ग्राहक सफलतापूर्वक आयात किया गया!',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return 'आयात त्रुटि: $error';
  }

  @override
  String get taxWordGst => 'GST';

  @override
  String get taxWordTax => 'टैक्स';

  @override
  String get commonMoreLabel => 'अधिक';

  @override
  String get productMgmtSellingAtLossTitle => 'घाटे पर बिक्री';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return 'खरीद मूल्य ($purchase) बिक्री मूल्य ($sale) से अधिक है। फिर भी सहेजें?';
  }

  @override
  String get actionSaveAnyway => 'फिर भी सहेजें';

  @override
  String get productMgmtAdvancedInformationLabel => 'उन्नत जानकारी';

  @override
  String get productMgmtStorageLocationLabel => 'भंडारण स्थान';

  @override
  String get productMgmtContainerNumberLabel => 'कंटेनर नंबर';

  @override
  String get productMgmtBatchNumberLabel => 'बैच नंबर';

  @override
  String get productMgmtExpiryDateLabel => 'समाप्ति तिथि';

  @override
  String get productMgmtManufactureDateLabel => 'निर्माण तिथि';

  @override
  String get productMgmtSupplierNameLabel => 'आपूर्तिकर्ता का नाम';

  @override
  String get productMgmtSkuCodeLabel => 'SKU कोड';

  @override
  String get productMgmtNotesLabel => 'नोट्स';

  @override
  String get fieldEnterValidPriceMessage => 'मान्य मूल्य दर्ज करें';

  @override
  String get fieldEnterValidStockMessage => 'मान्य स्टॉक दर्ज करें';

  @override
  String get fieldTaxRangeMessage => 'टैक्स 0-100 के बीच होना चाहिए';

  @override
  String get productMgmtImportProductsCsvTitle => 'CSV से उत्पाद आयात करें';

  @override
  String get productMgmtCsvDescName => 'उत्पाद का नाम';

  @override
  String get productMgmtCsvDescPrice => 'इकाई मूल्य (संख्यात्मक)';

  @override
  String get productMgmtCsvDescHsnCode => 'HSN / SAC कोड';

  @override
  String get productMgmtCsvDescDescription => 'संक्षिप्त विवरण';

  @override
  String get productMgmtCsvDescTaxRate => 'टैक्स % (0–100), डिफ़ॉल्ट 0';

  @override
  String get productMgmtCsvDescStock => 'स्टॉक मात्रा, डिफ़ॉल्ट 0';

  @override
  String get productMgmtCsvDescType =>
      '\"product\" या \"service\", डिफ़ॉल्ट product';

  @override
  String get productMgmtCsvDescDefaultDiscount =>
      'फ्लैट छूट राशि (मुद्रा), डिफ़ॉल्ट 0';

  @override
  String get productMgmtCsvDescPurchasePrice =>
      'लागत मूल्य (संख्यात्मक), डिफ़ॉल्ट 0';

  @override
  String get productMgmtCsvDescAliasName =>
      'PDF के लिए स्थानीय-भाषा प्रदर्शन नाम';

  @override
  String get productMgmtCsvDescUnit =>
      'मापन इकाई (जैसे kg, bag, pcs), डिफ़ॉल्ट pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock =>
      'असीमित स्टॉक के लिए 1/true, डिफ़ॉल्ट 0';

  @override
  String get productMgmtCsvDescPriceIncludesTax =>
      'यदि मूल्य में टैक्स शामिल है तो 1/true, डिफ़ॉल्ट 0';

  @override
  String get productMgmtCsvDescStorageLocation => 'गोदाम/शेल्फ स्थान';

  @override
  String get productMgmtCsvDescContainerNumber => 'कंटेनर/बॉक्स नंबर';

  @override
  String get productMgmtCsvDescBatchNumber => 'बैच/लॉट नंबर';

  @override
  String get productMgmtCsvDescExpiryDate => 'समाप्ति तिथि';

  @override
  String get productMgmtCsvDescManufactureDate => 'निर्माण तिथि';

  @override
  String get productMgmtCsvDescSupplierName => 'आपूर्तिकर्ता का नाम';

  @override
  String get productMgmtCsvDescSkuCode => 'SKU कोड';

  @override
  String get productMgmtCsvDescNotes => 'स्वतंत्र-पाठ टिप्पणियां';

  @override
  String get productMgmtCsvDuplicateNote =>
      'डुप्लिकेट उत्पाद नाम (केस-असंवेदनशील) से पहचाने जाते हैं। आपसे प्रत्येक को अधिलेखित करने या छोड़ने के लिए पूछा जाएगा।';

  @override
  String get productMgmtCsvMissingRequiredNote =>
      'नाम या मूल्य के बिना पंक्तियों को छोड़ दिया जाता है और रिपोर्ट किया जाता है।';

  @override
  String get productMgmtSelectCsvDialogTitle => 'उत्पाद CSV चुनें';

  @override
  String get productMgmtCsvMissingPriceColumnMessage =>
      'CSV में आवश्यक कॉलम गायब है: \"price\"';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return 'पंक्ति $n: अमान्य मूल्य \"$price\" — छोड़ा गया';
  }

  @override
  String get productMgmtImportingTitle => 'उत्पाद आयात हो रहे हैं';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel =>
      'डुप्लिकेट (नाम से मिलान):';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total उत्पाद आयात किए जाएंगे।',
      one: '1 उत्पाद आयात किया जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage =>
      'हटाने के लिए कोई उत्पाद नहीं।';

  @override
  String get productMgmtDeleteAllTitle => 'सभी उत्पाद हटाएं';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यह सभी $count उत्पादों को स्थायी रूप से हटा देगा। मौजूदा इनवॉइस प्रभावित नहीं होंगे। इसे पूर्ववत नहीं किया जा सकता।',
      one:
          'यह सभी 1 उत्पाद को स्थायी रूप से हटा देगा। मौजूदा इनवॉइस प्रभावित नहीं होंगे। इसे पूर्ववत नहीं किया जा सकता।',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage => 'सभी उत्पाद हटा दिए गए।';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return 'उत्पाद हटाने में त्रुटि: $error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle => 'उत्पाद CSV सहेजें';

  @override
  String get productMgmtExportToPdfTitle => 'PDF में निर्यात करें';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return 'वर्तमान पृष्ठ ($pageSize उत्पाद) या सभी $allCount उत्पाद निर्यात करें?';
  }

  @override
  String get productMgmtCurrentPageLabel => 'वर्तमान पृष्ठ';

  @override
  String get productMgmtAllProductsLabel => 'सभी उत्पाद';

  @override
  String get productMgmtSaveProductsPdfDialogTitle => 'उत्पाद PDF सहेजें';

  @override
  String get productMgmtTitle => 'उत्पाद प्रबंधन';

  @override
  String get productMgmtSubtitle => 'अपने उत्पाद और सेवाएं प्रबंधित करें';

  @override
  String get productMgmtNewProductButton => 'नया उत्पाद';

  @override
  String get productMgmtSearchHint =>
      'नाम, उपनाम, HSN/SAC, SKU से उत्पाद खोजें…';

  @override
  String get productMgmtFilterByStockStatusTooltip =>
      'स्टॉक स्थिति के अनुसार फ़िल्टर करें';

  @override
  String get productMgmtAllStockLevelsLabel => 'सभी स्टॉक स्तर';

  @override
  String get productMgmtLowStockLabel => 'कम स्टॉक';

  @override
  String get productMgmtLowStockTabLabel => 'कम स्टॉक';

  @override
  String get productMgmtOutOfStockLabel => 'स्टॉक समाप्त';

  @override
  String get productMgmtOutOfStockTabLabel => 'स्टॉक समाप्त';

  @override
  String get productMgmtExpiredLabel => 'समाप्त';

  @override
  String get productMgmtSortPriceLowHigh => 'मूल्य कम-अधिक';

  @override
  String get productMgmtSortPriceHighLow => 'मूल्य अधिक-कम';

  @override
  String get productMgmtSortStockLowHigh => 'स्टॉक कम-अधिक';

  @override
  String get productMgmtSortStockHighLow => 'स्टॉक अधिक-कम';

  @override
  String get productMgmtServicesTabLabel => 'सेवाएं';

  @override
  String get productMgmtColSlNo => 'क्र.सं.';

  @override
  String get productMgmtColNameAlias => 'नाम / उपनाम';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => 'मूल्य';

  @override
  String get productMgmtColPurchase => 'खरीद';

  @override
  String get productMgmtColStock => 'स्टॉक';

  @override
  String get productMgmtColTaxPercent => 'टैक्स %';

  @override
  String get productMgmtColExpiryDate => 'समाप्ति तिथि';

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
    return '$total उत्पादों में से $from से $to दिखाया जा रहा है';
  }

  @override
  String get productMgmtAddFirstProductSubtitle =>
      'शुरू करने के लिए अपना पहला उत्पाद जोड़ें';

  @override
  String get productMgmtColumnsBannerTitle =>
      'नया: उत्पाद फ़ील्ड अनुकूलित करें';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      'सरल कैटलॉग के लिए कौन से फ़ील्ड दिखाने हैं चुनें। सेटिंग्स > उत्पाद विवरण अनुकूलित करें।';

  @override
  String get productMgmtConfigureAction => 'कॉन्फ़िगर करें';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return 'नया $type जोड़ें';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle => 'उत्पाद विवरण दर्ज करें';

  @override
  String get productMgmtSaveProductButton => 'उत्पाद सहेजें';

  @override
  String get productMgmtAliasNameLabel => 'उपनाम (इनवॉइस PDF के लिए)';

  @override
  String get productMgmtAliasHelperText =>
      'वैकल्पिक स्थानीय-भाषा प्रदर्शन नाम जो केवल PDF इनवॉइस पर उपयोग होता है।';

  @override
  String get productMgmtDescriptionLabel => 'विवरण';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => 'बिक्री मूल्य';

  @override
  String get productMgmtPurchasePriceLabel => 'खरीद मूल्य';

  @override
  String get productMgmtDefaultDiscountLabel => 'डिफ़ॉल्ट छूट';

  @override
  String get productMgmtTaxPercentLabel => 'टैक्स (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel => 'केवल प्रति-आइटम टैक्स मोड';

  @override
  String get productMgmtSectionGeneral => 'सामान्य';

  @override
  String get productMgmtSectionPricing => 'मूल्य निर्धारण';

  @override
  String get productMgmtSectionInventory => 'इन्वेंट्री';

  @override
  String get productMgmtUnlimitedStockLabel => 'असीमित स्टॉक';

  @override
  String get productMgmtTrackInfiniteStockSubtitle =>
      'इस उत्पाद के लिए असीमित स्टॉक ट्रैक करें';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      'सुझाव: अधिक विवरण जोड़ने के लिए कॉलम से कस्टम फ़ील्ड सक्षम करें।';

  @override
  String get productMgmtEditProductTitle => 'उत्पाद संपादित करें';

  @override
  String get productMgmtViewProductTitle => 'उत्पाद देखें';

  @override
  String get productMgmtUpdateProductDetailsSubtitle =>
      'उत्पाद विवरण अपडेट करें';

  @override
  String get productMgmtProductDetailsSubtitle => 'उत्पाद विवरण';

  @override
  String get productMgmtUpdatedMessage => 'उत्पाद/सेवा सफलतापूर्वक अपडेट हुई!';

  @override
  String get productMgmtDeleteProductButton => 'उत्पाद हटाएं';

  @override
  String get productMgmtSaveChangesButton => 'परिवर्तन सहेजें';

  @override
  String get fieldUnitLabel => 'इकाई';

  @override
  String get productMgmtAddedMessage => 'उत्पाद सफलतापूर्वक जोड़ा गया!';

  @override
  String productMgmtAddErrorMessage(String error) {
    return 'उत्पाद जोड़ने में त्रुटि: $error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return 'उत्पाद लोड करने में त्रुटि: $error';
  }

  @override
  String get productMgmtDeletedMessage => 'उत्पाद सफलतापूर्वक हटाया गया!';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count उत्पाद सफलतापूर्वक आयात किए गए!',
      one: '1 उत्पाद सफलतापूर्वक आयात किया गया!',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => 'कुल आइटम';

  @override
  String get productMgmtTangibleProductsSubtitle => 'मूर्त उत्पाद';

  @override
  String get productMgmtNonTangibleServicesSubtitle => 'अमूर्त सेवाएं';

  @override
  String get productMgmtNeedAttentionSubtitle => 'ध्यान देने की आवश्यकता है';

  @override
  String get productMgmtProductNameLabel => 'उत्पाद का नाम';

  @override
  String get productMgmtPriceLabel => 'मूल्य';

  @override
  String get actionClear => 'साफ़ करें';

  @override
  String get reportsAboutConversionRateTitle => 'रूपांतरण दर के बारे में';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return 'पुराने प्राप्य ($count)';
  }

  @override
  String get reportsAllCurrenciesLabel => 'सभी मुद्राएं';

  @override
  String get reportsAvgInvoiceValueLabel => 'औसत इनवॉइस मूल्य';

  @override
  String get reportsBalanceColumnLabel => 'बैलेंस';

  @override
  String get reportsBilledLabel => 'बिल किया गया';

  @override
  String get reportsBucket0to30Label => '0–30 दिन';

  @override
  String get reportsBucket31to60Label => '31–60 दिन';

  @override
  String get reportsBucket61to90Label => '61–90 दिन';

  @override
  String get reportsBucket90PlusLabel => '90+ दिन';

  @override
  String get reportsBucketLabel => 'समूह';

  @override
  String get reportsClosingLabel => 'समापन शेष';

  @override
  String get reportsCogsColumnLabel => 'बिक्री लागत';

  @override
  String get reportsConversionRateExplanationBody =>
      'रूपांतरण दर = बनाए गए इनवॉइस ÷ जारी किए गए कोटेशन × 100।\n100% से अधिक दर का मतलब है कि चयनित अवधि में कोटेशन से अधिक इनवॉइस बनाए गए (जब बिना पूर्व कोटेशन के सीधे इनवॉइस बनाए जाते हैं तो यह सामान्य है)।\n\nनोट: यह अवधि-स्तर का अनुपात है, व्यक्तिगत कोटेशन-से-इनवॉइस ट्रैकिंग नहीं।';

  @override
  String get reportsConversionRateLabel => 'रूपांतरण दर';

  @override
  String get reportsCreditColumnLabel => 'क्रेडिट';

  @override
  String get reportsCurrencySectionLabel => 'मुद्रा';

  @override
  String get reportsCurrentBucketLabel => 'वर्तमान';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return 'वर्तमान चयनित मुद्रा ($currency)';
  }

  @override
  String get reportsCustomRangeLabel => 'कस्टम रेंज';

  @override
  String get reportsDailySalesProfitTitle => 'दैनिक बिक्री और लाभ';

  @override
  String reportsDaysCountLabel(int d) {
    return '$d दिन';
  }

  @override
  String get reportsDaysOverdueLabel => 'अतिदेय दिन';

  @override
  String get reportsDebitColumnLabel => 'डेबिट';

  @override
  String get reportsDiscountGivenColumnLabel => 'दी गई छूट';

  @override
  String get reportsExportCsvLabel => 'CSV निर्यात करें';

  @override
  String reportsFilteredToDateLabel(String date) {
    return '$date तक फ़िल्टर किया गया';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अवधि में $countString इनवॉइस · $scope',
      one: 'अवधि में 1 इनवॉइस · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => 'इनवॉइस आईडी';

  @override
  String get reportsInvoicedLabel => 'इनवॉइस किया गया';

  @override
  String get reportsInvoicesColumnLabel => 'इनवॉइस';

  @override
  String get reportsInvoicesInPeriodLabel => 'अवधि में इनवॉइस';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get reportsMarginColumnLabel => 'मार्जिन';

  @override
  String get reportsMaxRangeOneYearMessage =>
      'अधिकतम सीमा 1 वर्ष है। अंतिम तिथि सीमित कर दी गई।';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage =>
      'अधिकतम सीमा 31 दिन है। अंतिम तिथि सीमित कर दी गई।';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'इस अवधि में बेची गई $count वस्तुओं का खरीद मूल्य सेट नहीं है — जब तक उत्पाद में खरीद मूल्य नहीं जोड़ा जाता तब तक उन वस्तुओं के लिए लाभ/मार्जिन कम दिखाया जाएगा।',
      one:
          'इस अवधि में बेची गई 1 वस्तु का खरीद मूल्य सेट नहीं है — जब तक उत्पाद में खरीद मूल्य नहीं जोड़ा जाता तब तक उस वस्तु के लिए लाभ/मार्जिन कम दिखाया जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => 'महीना और वर्ष';

  @override
  String get reportsMonthlyRevenueTrendTitle => 'मासिक राजस्व रुझान';

  @override
  String get reportsNavDailyReportLabel => 'दैनिक रिपोर्ट';

  @override
  String get reportsNavInvoiceStatusLabel => 'इनवॉइस स्थिति';

  @override
  String get reportsNavReceivablesLabel => 'प्राप्य';

  @override
  String get reportsNavRevenueLabel => 'राजस्व';

  @override
  String get reportsNavTaxLabel => 'टैक्स';

  @override
  String get reportsNoCustomerDataMessage => 'इस अवधि में कोई ग्राहक डेटा नहीं';

  @override
  String get reportsNoCustomersMatchSearchMessage =>
      'इस खोज से कोई ग्राहक मेल नहीं खाता';

  @override
  String get reportsNoCustomersWithInvoicesMessage =>
      'इनवॉइस वाले कोई ग्राहक नहीं';

  @override
  String get reportsNoDueDateLabel => 'कोई देय तिथि नहीं';

  @override
  String get reportsNoInvoiceDataMessage => 'इस अवधि में कोई इनवॉइस डेटा नहीं';

  @override
  String get reportsNoInvoicesInPeriodMessage => 'इस अवधि में कोई इनवॉइस नहीं';

  @override
  String get reportsNoInvoicesMatchFilterMessage =>
      'इस फ़िल्टर से कोई इनवॉइस मेल नहीं खाता';

  @override
  String get reportsNoOutstandingInvoicesMessage => 'कोई बकाया इनवॉइस नहीं';

  @override
  String get reportsNoProductDataMessage => 'इस अवधि में कोई उत्पाद डेटा नहीं';

  @override
  String get reportsNoSalesInPeriodMessage => 'इस अवधि में कोई बिक्री नहीं';

  @override
  String get reportsNoStatementActivityMessage =>
      'इस ग्राहक के लिए कोई स्टेटमेंट गतिविधि नहीं';

  @override
  String get reportsNoTaxableItemsMessage =>
      'इस अवधि में कोई कर योग्य वस्तु नहीं';

  @override
  String get reportsNoTransactionsMessage => 'इस अवधि में कोई लेन-देन नहीं';

  @override
  String get reportsOpeningLabel => 'प्रारंभिक शेष';

  @override
  String get reportsOverviewLabel => 'अवलोकन';

  @override
  String get reportsPaymentStatusBreakdownTitle => 'भुगतान स्थिति विवरण';

  @override
  String get reportsPeriodSectionLabel => 'अवधि';

  @override
  String get reportsPresetLast30DaysLabel => 'पिछले 30 दिन';

  @override
  String get reportsPresetLast3MonthsLabel => 'पिछले 3 महीने';

  @override
  String get reportsPresetLast6MonthsLabel => 'पिछले 6 महीने';

  @override
  String get reportsPresetLastFYLabel => 'पिछला वित्त वर्ष';

  @override
  String get reportsPresetThisFYLabel => 'इस वित्त वर्ष';

  @override
  String get reportsPresetThisYearLabel => 'इस वर्ष';

  @override
  String get reportsProductServiceColumnLabel => 'उत्पाद / सेवा';

  @override
  String get reportsProfitLabel => 'लाभ';

  @override
  String get reportsQuotationsIssuedLabel => 'जारी किए गए कोटेशन';

  @override
  String get reportsRankByProfitLabel => 'रैंक: लाभ';

  @override
  String get reportsRankByRevenueLabel => 'रैंक: राजस्व';

  @override
  String get reportsReferenceColumnLabel => 'संदर्भ';

  @override
  String get reportsSalesColumnLabel => 'बिक्री';

  @override
  String get reportsSaveCsvReportTitle => 'CSV रिपोर्ट सहेजें';

  @override
  String get reportsSavePdfReportTitle => 'PDF रिपोर्ट सहेजें';

  @override
  String reportsSavedAtMessage(String path) {
    return 'सहेजा गया: $path';
  }

  @override
  String get reportsSelectCustomerTitle => 'ग्राहक चुनें';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText =>
      'तिथि या तिथि सीमा चुनें (अधिकतम 31 दिन)';

  @override
  String get reportsSelectDateRangeMaxYearHelpText =>
      'तिथि सीमा चुनें (अधिकतम 1 वर्ष)';

  @override
  String get reportsShareLabel => 'हिस्सा';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return '$range की तिथि वाले इनवॉइस दिखाए जा रहे हैं';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end / $total';
  }

  @override
  String get reportsSlColumnLabel => 'क्र.सं.';

  @override
  String get reportsStatementsLabel => 'स्टेटमेंट';

  @override
  String get reportsTaxCollectedByRateTitle => 'दर के अनुसार एकत्रित कर';

  @override
  String get reportsTaxCollectedLabel => 'एकत्रित कर';

  @override
  String get reportsTaxRateBucketsLabel => 'कर दर समूह';

  @override
  String get reportsTodayLabel => 'आज';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return 'राजस्व के अनुसार शीर्ष $count ग्राहक';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return '$metric के अनुसार शीर्ष $count उत्पाद / सेवाएं';
  }

  @override
  String get reportsTotalBilledLabel => 'कुल बिल किया गया';

  @override
  String get reportsTotalCollectedLabel => 'कुल एकत्रित';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'कुल $countString इनवॉइस',
      one: 'कुल 1 इनवॉइस',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => 'कुल इनवॉइस';

  @override
  String get reportsTotalProfitLabel => 'कुल लाभ';

  @override
  String get reportsTotalTaxCollectedLabel => 'कुल एकत्रित कर';

  @override
  String get reportsTypeColumnLabel => 'प्रकार';

  @override
  String get reportsUnitsSoldColumnLabel => 'बेची गई इकाइयां';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return 'उपयोगकर्ता लोड करने में त्रुटि: $error';
  }

  @override
  String get userMgmtAddedMessage => 'उपयोगकर्ता सफलतापूर्वक जोड़ा गया';

  @override
  String get userMgmtUpdatedMessage => 'उपयोगकर्ता सफलतापूर्वक अपडेट किया गया';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return 'उपयोगकर्ता सहेजने में त्रुटि: $error';
  }

  @override
  String get userMgmtChangePasswordTitle => 'पासवर्ड बदलें';

  @override
  String userMgmtUserColonLabel(String username) {
    return 'उपयोगकर्ता: $username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => 'वर्तमान पासवर्ड';

  @override
  String get userMgmtCurrentPasswordRequiredMessage =>
      'वर्तमान पासवर्ड आवश्यक है';

  @override
  String get userMgmtNewPasswordLabel => 'नया पासवर्ड';

  @override
  String get userMgmtNewPasswordRequiredMessage => 'नया पासवर्ड आवश्यक है';

  @override
  String get userMgmtPasswordMinLengthMessage =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get userMgmtConfirmNewPasswordLabel => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get userMgmtConfirmPasswordRequiredMessage =>
      'कृपया अपने पासवर्ड की पुष्टि करें';

  @override
  String get userMgmtPasswordsDoNotMatchMessage => 'पासवर्ड मेल नहीं खाते';

  @override
  String get userMgmtPasswordChangedMessage => 'पासवर्ड सफलतापूर्वक बदला गया';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage =>
      'वर्तमान पासवर्ड गलत है';

  @override
  String get userMgmtDeleteUserTitle => 'उपयोगकर्ता हटाएं';

  @override
  String get userMgmtDeleteUserConfirmLabel =>
      'क्या आप वाकई इस उपयोगकर्ता को हटाना चाहते हैं:';

  @override
  String get userMgmtActionCannotBeUndoneMessage =>
      'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get userMgmtDeletedMessage => 'उपयोगकर्ता सफलतापूर्वक हटाया गया';

  @override
  String get userMgmtCantDeleteOwnAccountMessage =>
      'आप अपना खुद का खाता नहीं हटा सकते';

  @override
  String get userMgmtCantDemoteLastAdminMessage =>
      'आप एकमात्र एडमिन की भूमिका नहीं बदल सकते';

  @override
  String get userMgmtCantChangeOwnRoleMessage =>
      'आप अपनी खुद की भूमिका नहीं बदल सकते';

  @override
  String get userMgmtUsernameTakenMessage =>
      'यह उपयोगकर्ता नाम पहले से मौजूद है';

  @override
  String get userMgmtDeleteSelectedTitle => 'चयनित उपयोगकर्ताओं को हटाएं?';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'यह स्थायी रूप से $count उपयोगकर्ताओं को हटा देगा। यह क्रिया पूर्ववत नहीं की जा सकती।',
      one:
          'यह स्थायी रूप से 1 उपयोगकर्ता को हटा देगा। यह क्रिया पूर्ववत नहीं की जा सकती।',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage =>
      'आपका अपना खाता चयन में था लेकिन इसे छोड़ दिया जाएगा।';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count उपयोगकर्ता हटाए गए',
      one: '1 उपयोगकर्ता हटाया गया',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return 'उपयोगकर्ताओं को हटाने में त्रुटि: $error';
  }

  @override
  String get userMgmtTitle => 'उपयोगकर्ता प्रबंधन';

  @override
  String get userMgmtSubtitle =>
      'एप्लिकेशन उपयोगकर्ताओं और एक्सेस अनुमतियों का प्रबंधन करें';

  @override
  String get userMgmtAddUserButton => 'उपयोगकर्ता जोड़ें';

  @override
  String get userMgmtSearchHint => 'नाम या भूमिका द्वारा उपयोगकर्ता खोजें…';

  @override
  String get userMgmtFilterByRoleTooltip => 'भूमिका के अनुसार फ़िल्टर करें';

  @override
  String get userMgmtAllRolesLabel => 'सभी भूमिकाएं';

  @override
  String get userMgmtAllLabel => 'सभी';

  @override
  String userMgmtRoleColonLabel(String role) {
    return 'भूमिका: $role';
  }

  @override
  String get userMgmtColUser => 'उपयोगकर्ता';

  @override
  String get userMgmtColRole => 'भूमिका';

  @override
  String get userMgmtYouBadgeLabel => 'आप';

  @override
  String get userMgmtDeleteSelectedMenuLabel => 'चयनित हटाएं';

  @override
  String get userMgmtBulkActionsTooltip => 'बल्क क्रियाएं';

  @override
  String get userMgmtBulkActionsLabel => 'बल्क क्रियाएं';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return 'कुल $total उपयोगकर्ताओं में से $from से $to दिखा रहे हैं';
  }

  @override
  String get userMgmtNoUsersFoundMessage => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get userMgmtAddNewUserTitle => 'नया उपयोगकर्ता जोड़ें';

  @override
  String get userMgmtEditUserTitle => 'उपयोगकर्ता संपादित करें';

  @override
  String get userMgmtUsernameRequiredLabel => 'उपयोगकर्ता नाम *';

  @override
  String get userMgmtEnterUsernameHint => 'उपयोगकर्ता नाम दर्ज करें';

  @override
  String get userMgmtUsernameRequiredMessage => 'उपयोगकर्ता नाम आवश्यक है';

  @override
  String get userMgmtUsernameMinLengthMessage =>
      'उपयोगकर्ता नाम कम से कम 3 अक्षरों का होना चाहिए';

  @override
  String get userMgmtPasswordRequiredLabel => 'पासवर्ड *';

  @override
  String get userMgmtEnterPasswordHint => 'पासवर्ड दर्ज करें';

  @override
  String get userMgmtPasswordRequiredMessage => 'पासवर्ड आवश्यक है';

  @override
  String get userMgmtMinimum6CharsMessage => 'न्यूनतम 6 अक्षर';

  @override
  String get userMgmtRoleRequiredLabel => 'भूमिका *';

  @override
  String get userMgmtRoleRequiredMessage => 'भूमिका आवश्यक है';

  @override
  String get userMgmtSaveUserButton => 'उपयोगकर्ता सहेजें';

  @override
  String get userMgmtThisIsYourAccountMessage => 'यह आपका खाता है';

  @override
  String get invoiceSettingsAppBarTitle => 'इनवॉइस सेटिंग्स';

  @override
  String get invoiceSettingsSavedMessage =>
      'इनवॉइस सेटिंग्स सफलतापूर्वक सहेजी गईं!';

  @override
  String get invoiceSettingsSignatureTooLargeMessage =>
      'हस्ताक्षर छवि 2 MB से कम होनी चाहिए।';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage =>
      'वॉटरमार्क छवि 2 MB से कम होनी चाहिए।';

  @override
  String get invoiceSettingsSectionGeneral => 'सामान्य';

  @override
  String get invoiceSettingsSectionBranding => 'ब्रांडिंग';

  @override
  String get invoiceSettingsSectionTax => 'टैक्स और GST';

  @override
  String get invoiceSettingsSectionItems => 'इनवॉइस आइटम';

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
  String get invoiceSettingsPrefixLabel => 'इनवॉइस प्रीफ़िक्स';

  @override
  String get invoiceSettingsStartingNumberHelper =>
      'पहला इनवॉइस इस नंबर से शुरू होगा';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      'इनवॉइस मौजूद रहते हुए प्रारंभ संख्या नहीं बदली जा सकती। कृपया सभी इनवॉइस/कोटेशन (ट्रैश सहित) स्थायी रूप से हटाएं और पुनः प्रयास करें।';

  @override
  String get invoiceSettingsQuantityColumnLabel => 'मात्रा कॉलम लेबल';

  @override
  String get invoiceSettingsQuantityColumnHint => 'जैसे Words, Hours, Units';

  @override
  String get invoiceSettingsQuantityColumnHelper =>
      'डिफ़ॉल्ट \"Qty\" उपयोग करने के लिए खाली छोड़ें';

  @override
  String get invoiceSettingsAdditionalInfoLabel => 'अतिरिक्त जानकारी';

  @override
  String get invoiceSettingsThankYouNoteLabel => 'धन्यवाद नोट';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel =>
      'डिफ़ॉल्ट रूप से इनवॉइस नंबर छिपाएं';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      'नया इनवॉइस बनाते समय डिफ़ॉल्ट रूप से \"PDF में इनवॉइस नंबर छिपाएं\" सक्षम करें।';

  @override
  String get invoiceSettingsTaxRateHint => 'जैसे 18';

  @override
  String get invoiceSettingsTaxRateHelper => 'नए इनवॉइस पर लागू होता है';

  @override
  String get invoiceSettingsTaxEnabledLabel => 'डिफ़ॉल्ट रूप से टैक्स सक्षम';

  @override
  String get invoiceSettingsTaxEnabledSubtitle =>
      'नया इनवॉइस बनाते समय डिफ़ॉल्ट रूप से टैक्स टॉगल सक्षम करें।';

  @override
  String get invoiceSettingsTaxModeLabel => 'डिफ़ॉल्ट टैक्स दर मोड';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly =>
      'केवल नए इनवॉइस पर लागू होता है';

  @override
  String get invoiceSettingsTaxModeGlobal => 'समग्र';

  @override
  String get invoiceSettingsTaxModePerItem => 'प्रति आइटम';

  @override
  String get invoiceSettingsShowGstFieldsLabel => 'GST फ़ील्ड दिखाएं';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      'इनवॉइस, PDF और CSV एक्सपोर्ट पर GSTIN फ़ील्ड (HSN/SAC) दिखाएं';

  @override
  String get invoiceSettingsShowCgstSgstLabel => 'CGST/SGST दिखाएं';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      'इनवॉइस पर टैक्स को CGST + SGST में विभाजित करें (केवल भारत)।';

  @override
  String get invoiceSettingsDefaultGstTitleLabel =>
      'डिफ़ॉल्ट GST इनवॉइस शीर्षक';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel =>
      'डिफ़ॉल्ट टैक्स इनवॉइस शीर्षक';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      'नए इनवॉइस पर पूर्व-चयनित — जैसे GST कंपोज़िशन स्कीम व्यापारियों के लिए \"Bill of Supply\"';

  @override
  String get invoiceSettingsGstTitleHelperGeneric => 'नए इनवॉइस पर पूर्व-चयनित';

  @override
  String get invoiceSettingsShowRoundOffLabel => 'राउंड ऑफ दिखाएं';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      'इनवॉइस PDF पर राउंड ऑफ पंक्ति + नेट राशि (निकटतम तक) और शब्दों में राशि दिखाएं।';

  @override
  String get invoiceSettingsShowAliasNameLabel => 'PDF में उपनाम दिखाएं';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      'PDF पर उत्पाद के वास्तविक नाम के बजाय उसका स्थानीय-भाषा उपनाम (यदि सेट है) प्रिंट करें';

  @override
  String get invoiceSettingsShowDescriptionLabel => 'उत्पाद विवरण दिखाएं';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      'प्रत्येक आइटम का विवरण A4 PDF में उसके नीचे एक पंक्ति के रूप में छापें (थर्मल रसीदों पर नहीं)';

  @override
  String get invoiceSettingsDescriptionNewLineLabel => 'विवरण नई पंक्ति में';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      'विवरण को आइटम के नाम के नीचे एक पंक्ति के बजाय आइटम के नीचे पूरी-चौड़ाई की पंक्ति के रूप में छापें';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel =>
      'भिन्नात्मक मात्रा की अनुमति दें';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      'दशमलव मात्रा सक्षम करें (जैसे 1.5 घंटे, 0.5 किग्रा)';

  @override
  String get invoiceSettingsShowQuantityLabel => 'मात्रा फ़ील्ड दिखाएं';

  @override
  String get invoiceSettingsShowQuantitySubtitle =>
      'सेवा-आधारित बिलिंग के लिए मात्रा छिपाएं; मूल्य कॉलम \"दर\" बन जाता है';

  @override
  String get invoiceSettingsShowDiscountLabel => 'छूट कॉलम दिखाएं';

  @override
  String get invoiceSettingsShowDiscountSubtitle =>
      'आइटम-स्तरीय छूट का उपयोग न करने वाले ग्राहकों के लिए छूट कॉलम छिपाएं';

  @override
  String get invoiceSettingsShowTypeTagLabel => 'उत्पाद/सेवा टैग दिखाएं';

  @override
  String get invoiceSettingsShowTypeTagSubtitle =>
      'प्रत्येक इनवॉइस आइटम पर उत्पाद/सेवा लेबल दिखाएं या छिपाएं';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel =>
      'डुप्लिकेट इनवॉइस आइटम की अनुमति दें';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle =>
      'एक ही उत्पाद को इनवॉइस में एक से अधिक बार जोड़ने की अनुमति दें';

  @override
  String get invoiceSettingsShowPrevBalanceLabel => 'पिछला बकाया शेष दिखाएं';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle =>
      'इनवॉइस PDF पर गणना की गई पिछली बकाया राशि दिखाएं';

  @override
  String get invoiceSettingsLogoPositionLabel => 'कंपनी लोगो स्थिति';

  @override
  String get invoiceSettingsLogoSizeLabel => 'कंपनी लोगो आकार';

  @override
  String get commonLeftLabel => 'बाएं';

  @override
  String get commonRightLabel => 'दाएं';

  @override
  String get invoiceSettingsSignatureImageLabel => 'हस्ताक्षर छवि';

  @override
  String get invoiceSettingsSignatureImageSubtitle =>
      'इनवॉइस पर अधिकृत हस्ताक्षर के रूप में मुद्रित';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG, JPG या JPEG — अधिकतम 2 MB';

  @override
  String get invoiceSettingsChangeSignatureButton => 'हस्ताक्षर बदलें';

  @override
  String get invoiceSettingsUploadSignatureButton => 'हस्ताक्षर अपलोड करें';

  @override
  String get invoiceSettingsSignatureSizeLabel => 'हस्ताक्षर आकार';

  @override
  String get invoiceSettingsSignaturePositionLabel => 'हस्ताक्षर स्थिति';

  @override
  String get invoiceSettingsWatermarkImageLabel => 'वॉटरमार्क छवि';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      'इनवॉइस PDF पर आइटम तालिका के पीछे दिखाया जाता है (थर्मल रसीदों पर मुद्रित नहीं)';

  @override
  String get invoiceSettingsChangeWatermarkButton => 'वॉटरमार्क बदलें';

  @override
  String get invoiceSettingsUploadWatermarkButton => 'वॉटरमार्क अपलोड करें';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return 'अपारदर्शिता: $value%';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value%';
  }

  @override
  String get invoiceSettingsPromoTitle => 'अपने इनवॉइस पर और फ़ील्ड चाहिए?';

  @override
  String get invoiceSettingsPromoBody =>
      'PO नंबर, प्रोजेक्ट कोड, विभाग या कोई भी कस्टम फ़ील्ड जोड़ें।';

  @override
  String get invoiceSettingsPromoButton => 'विकल्प देखें';

  @override
  String get pdfSettingsTitle => 'पीडीएफ सेटिंग्स';

  @override
  String get pdfSettingsSubtitle =>
      'इनवॉइस, कोटेशन और रसीद पीडीएफ टेम्पलेट्स को अनुकूलित करें';

  @override
  String get pdfSettingsResetToDefaultButton => 'डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get pdfSettingsSaveSettingsButton => 'सेटिंग्स सहेजें';

  @override
  String get pdfSettingsTemplatesLabel => 'टेम्पलेट्स';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return '$pageSize के लिए कोई टेम्पलेट नहीं';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'पीडीएफ सेटिंग्स सहेजी गईं';

  @override
  String get commonActiveLabel => 'सक्रिय';

  @override
  String get commonUnavailableLabel => 'अनुपलब्ध';

  @override
  String get pdfSettingsDisplayOptionsLabel => 'प्रदर्शन विकल्प';

  @override
  String get pdfSettingsShowTotalQtyRowLabel => 'कुल मात्रा पंक्ति दिखाएं';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => 'आइटम लेआउट';

  @override
  String get pdfSettingsItemLayoutTableLabel => 'तालिका';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => 'विस्तृत';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      'तालिका: प्रति आइटम एक पंक्ति (Sl/नाम/मात्रा/दर/कुल)। विस्तृत: नाम अपनी पंक्ति में, फिर नीचे मात्रा/दर/कुल।';

  @override
  String get pdfSettingsCompanyNameSizeLabel => 'कंपनी नाम का आकार';

  @override
  String get pdfSettingsThemeColorLabel => 'थीम रंग';

  @override
  String get pdfSettingsHexErrorText => '#RRGGBB का उपयोग करें';

  @override
  String get pdfSettingsPickColorTooltip => 'रंग चयनकर्ता खोलें';

  @override
  String get pdfSettingsPickThemeColorDialogTitle => 'थीम रंग चुनें';

  @override
  String get pdfSettingsPreviewDisclaimer =>
      'पूर्वावलोकन अंतिम पीडीएफ से थोड़ा भिन्न हो सकता है।';

  @override
  String get pdfSettingsCustomTemplatePromoTitle => 'कस्टम टेम्पलेट चाहिए?';

  @override
  String get pdfSettingsCustomTemplatePromoBody =>
      'अपने ब्रांड से मेल खाता डिज़ाइन पाएं — रंग, फ़ॉन्ट और लेआउट।';

  @override
  String get pdfSettingsCustomizationOptionsButton => 'कस्टमाइज़ेशन विकल्प';

  @override
  String get pdfTemplateClassicName => 'क्लासिक';

  @override
  String get pdfTemplateClassicDescription =>
      'साफ़ संरचना के साथ पारंपरिक लेआउट';

  @override
  String get pdfTemplateModernName => 'मॉडर्न';

  @override
  String get pdfTemplateModernDescription =>
      'समकालीन स्टाइलिंग के साथ बोल्ड हेडर';

  @override
  String get pdfTemplateMinimalName => 'मिनिमल';

  @override
  String get pdfTemplateMinimalDescription => 'सरल और ध्यान भंग न करने वाला';

  @override
  String get pdfTemplateExecutiveName => 'एक्ज़ीक्यूटिव';

  @override
  String get pdfTemplateExecutiveDescription =>
      'संरचित बिलिंग ब्लॉक्स के साथ प्रीमियम व्यावसायिक लेआउट';

  @override
  String get pdfTemplateCompactName => 'कॉम्पैक्ट';

  @override
  String get pdfTemplateCompactDescription =>
      'A6 प्रिंटिंग के लिए आदर्श, स्थान-कुशल रसीद लेआउट';

  @override
  String get pdfTemplateThermalName => 'थर्मल';

  @override
  String get pdfTemplateThermalDescription =>
      '80mm और 58mm थर्मल प्रिंटर के लिए संकरा रसीद लेआउट';

  @override
  String get pdfTemplateGridClassicName => 'ग्रिड क्लासिक';

  @override
  String get pdfTemplateGridClassicDescription =>
      'A4, A5 और A6 के लिए पुराने ढंग की बॉर्डर वाली तालिका बिल';

  @override
  String get companyInfoAppBarTitle => 'कंपनी जानकारी';

  @override
  String get companyInfoUploadLogoLabel => 'लोगो अपलोड करें';

  @override
  String get companyInfoClickToBrowseLabel => 'ब्राउज़ करने के लिए क्लिक करें';

  @override
  String get companyInfoRemoveLogoButton => 'लोगो हटाएं';

  @override
  String get companyInfoShowOnPdfLabel => 'PDF पर दिखाएं';

  @override
  String get companyInfoLogoRequirementsHint =>
      'अधिकतम 1080×1080 px · 2 MB\nकेवल PNG या JPG';

  @override
  String get companyInfoLogoSectionLabel => 'कंपनी लोगो';

  @override
  String get companyInfoDetailsSectionLabel => 'कंपनी विवरण';

  @override
  String get companyInfoBusinessTypeSectionLabel => 'व्यवसाय प्रकार';

  @override
  String get companyInfoPaymentSettingsSectionLabel => 'भुगतान सेटिंग्स';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'UPI खाते';

  @override
  String get companyInfoBankAccountsSectionLabel => 'बैंक खाते';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => 'कर/वैट नंबर';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'FSSAI कोड';

  @override
  String get companyInfoPhoneHelperText => 'कई नंबर: अल्पविराम से अलग करें';

  @override
  String get fieldWebsiteLabel => 'वेबसाइट';

  @override
  String get companyInfoBusinessTypeTitle => 'व्यवसाय प्रकार';

  @override
  String get companyInfoBusinessTypeSubtitle =>
      'उत्पाद सूची और इनवॉइस में आइटम प्रकार विकल्पों को नियंत्रित करता है';

  @override
  String get labelBoth => 'दोनों';

  @override
  String get companyInfoSetAsDefaultTooltip => 'डिफ़ॉल्ट के रूप में सेट करें';

  @override
  String get companyInfoUpiIdLabel => 'UPI ID';

  @override
  String get companyInfoAddUpiAccountButton => 'UPI खाता जोड़ें';

  @override
  String get companyInfoShowQrToggleTitle => 'इनवॉइस पर QR कोड दिखाएं';

  @override
  String get companyInfoShowQrToggleSubtitle =>
      'जनरेट किए गए PDF में स्कैन करने योग्य UPI भुगतान QR कोड जोड़ता है';

  @override
  String get companyInfoShowBankDetailsToggleTitle =>
      'इनवॉइस पर बैंक विवरण दिखाएं';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle =>
      'जनरेट किए गए PDF पर बैंक खाता विवरण प्रिंट करता है';

  @override
  String get fieldBankNameLabel => 'बैंक का नाम';

  @override
  String get fieldAccountNumberLabel => 'खाता संख्या';

  @override
  String get fieldIfscCodeLabel => 'IFSC कोड';

  @override
  String get companyInfoAddBankAccountButton => 'बैंक खाता जोड़ें';

  @override
  String get tooltipShowOnInvoicePdf => 'इनवॉइस PDF पर दिखाएं';

  @override
  String get companyInfoSavedSuccessMessage =>
      'कंपनी की जानकारी सफलतापूर्वक सहेजी गई';

  @override
  String get companyInfoImageTooLargeMessage =>
      'छवि फ़ाइल 2 MB से कम होनी चाहिए।';

  @override
  String get companyInfoInvalidImageMessage => 'अमान्य छवि फ़ाइल।';

  @override
  String get companyInfoImageDimensionsMessage =>
      'छवि अधिकतम 1080x1080 पिक्सेल होनी चाहिए।';

  @override
  String get companyInfoHintExampleBankName => 'जैसे HDFC बैंक';

  @override
  String get companyInfoHintExampleAccountLabel => 'जैसे मुख्य खाता';

  @override
  String get actionConfirm => 'पुष्टि करें';

  @override
  String get actionShare => 'साझा करें';

  @override
  String get appInfoTitle => 'सॉफ़्टवेयर जानकारी';

  @override
  String get appInfoAppDetailsTitle => 'ऐप विवरण';

  @override
  String get appInfoAppNameLabel => 'ऐप का नाम';

  @override
  String get appInfoVersionLabel => 'संस्करण';

  @override
  String get appInfoLicenseLabel => 'लाइसेंस';

  @override
  String get appInfoDeveloperTitle => 'डेवलपर';

  @override
  String get appInfoDeveloperLabel => 'डेवलपर';

  @override
  String get appInfoSupportEmailLabel => 'सहायता ईमेल';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  $license लाइसेंस के तहत जारी';
  }

  @override
  String get appInfoCheckingLabel => 'जाँच हो रही है...';

  @override
  String get appInfoUpdateAvailableLabel => 'अपडेट उपलब्ध है';

  @override
  String get appInfoUpToDateLabel => 'अद्यतन';

  @override
  String get appInfoCheckFailedLabel => 'जाँच विफल';

  @override
  String get appInfoUpdatesTitle => 'अपडेट';

  @override
  String get appInfoCurrentVersionLabel => 'वर्तमान संस्करण';

  @override
  String get appInfoLatestVersionLabel => 'नवीनतम संस्करण';

  @override
  String get appInfoCheckNowButton => 'अभी जाँचें';

  @override
  String get backupManagementTitle => 'बैकअप प्रबंधन';

  @override
  String get backupCreateDbButton => 'DB बैकअप बनाएं';

  @override
  String get backupExportJsonButton => 'JSON निर्यात करें';

  @override
  String get backupImportButton => 'बैकअप आयात करें';

  @override
  String get backupNoBackupsFoundMessage => 'कोई बैकअप नहीं मिला';

  @override
  String backupSizeLabel(String size) {
    return 'आकार: $size';
  }

  @override
  String backupCreatedLabel(String date) {
    return 'बनाया गया: $date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return 'बैकअप लोड करने में विफल: $error';
  }

  @override
  String get backupCreatedSuccessMessage => 'बैकअप सफलतापूर्वक बनाया गया!';

  @override
  String backupCreateErrorMessage(String error) {
    return 'बैकअप बनाने में विफल: $error';
  }

  @override
  String get backupRestoreConfirmTitle => 'बैकअप पुनर्स्थापित करें';

  @override
  String get backupRestoreConfirmBody =>
      'यह सभी वर्तमान डेटा को बैकअप से बदल देगा। क्या आप सुनिश्चित हैं?';

  @override
  String backupRestoreErrorMessage(String error) {
    return 'बैकअप पुनर्स्थापित करने में विफल: $error';
  }

  @override
  String get backupDeleteConfirmTitle => 'बैकअप हटाएं';

  @override
  String get backupDeleteConfirmBody =>
      'क्या आप वाकई इस बैकअप को हटाना चाहते हैं?';

  @override
  String get backupDeletedSuccessMessage => 'बैकअप सफलतापूर्वक हटाया गया!';

  @override
  String get backupDeleteFailedMessage => 'बैकअप हटाने में विफल';

  @override
  String backupDeleteErrorMessage(String error) {
    return 'बैकअप हटाने में विफल: $error';
  }

  @override
  String get backupSavedToDownloadsMessage =>
      'बैकअप डाउनलोड फ़ोल्डर में सहेजा गया।';

  @override
  String backupDownloadErrorMessage(String error) {
    return 'बैकअप डाउनलोड करने में विफल: $error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return 'बैकअप साझा करने में विफल: $error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return 'बैकअप आयात करने में विफल: $error';
  }

  @override
  String get backupRestoreSuccessTitle => 'पुनर्स्थापन सफल';

  @override
  String get backupRestoreSuccessBody =>
      'डेटाबेस सफलतापूर्वक पुनर्स्थापित हो गया है।\n\nपरिवर्तनों को लागू करने के लिए ऐप को पुनः आरंभ करना होगा। कृपया एप्लिकेशन बंद करें और फिर से खोलें।';

  @override
  String get backupCloseLaterButton => 'बाद में बंद करें';

  @override
  String get backupCloseAppNowButton => 'अभी ऐप बंद करें';

  @override
  String get commonSuccessTitle => 'सफलता';

  @override
  String get commonErrorTitle => 'त्रुटि';

  @override
  String get productColumnsScreenTitle => 'उत्पाद विवरण अनुकूलित करें';

  @override
  String get productColumnsSavedMessage => 'उत्पाद कॉलम सहेजे गए।';

  @override
  String get productColumnsIntroText =>
      'चुनें कि उत्पाद जोड़ें/संपादित करें फ़ॉर्म, उत्पाद सूची और इनवॉइस लाइन आइटम में कौन से फ़ील्ड दिखाई दें। नाम और मूल्य हमेशा आवश्यक हैं।';

  @override
  String get productColumnsNameLabel => 'नाम';

  @override
  String get productColumnsPriceLabel => 'मूल्य';

  @override
  String get productColumnsAlwaysRequiredSubtitle =>
      'हमेशा दिखाया जाता है — आवश्यक।';

  @override
  String get productColumnsStockLabel => 'स्टॉक';

  @override
  String get productColumnsStockSubtitle =>
      'यदि आप कभी स्टॉक ट्रैक नहीं करते हैं तो बंद करें — उत्पाद डिफ़ॉल्ट रूप से असीमित स्टॉक मानते हैं।';

  @override
  String get productColumnsProductFieldsSectionTitle => 'उत्पाद फ़ील्ड';

  @override
  String get productColumnsAliasNameLabel => 'उपनाम';

  @override
  String get productColumnsAliasNameSubtitle =>
      'PDF/प्रिंटिंग के लिए स्थानीय-भाषा प्रदर्शन नाम।';

  @override
  String get productColumnsTaxRateLabel => 'कर दर';

  @override
  String get productColumnsTaxRateSubtitle => 'प्रति-उत्पाद कर प्रतिशत।';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'HSN या SAC कोड फ़ील्ड।';

  @override
  String get productColumnsDescriptionLabel => 'विवरण';

  @override
  String get productColumnsDescriptionSubtitle => 'स्वतंत्र-पाठ उत्पाद विवरण।';

  @override
  String get productColumnsPurchasePriceLabel => 'खरीद मूल्य';

  @override
  String get productColumnsPurchasePriceSubtitle =>
      'मार्जिन ट्रैकिंग के लिए लागत मूल्य।';

  @override
  String get productColumnsDefaultDiscountLabel => 'डिफ़ॉल्ट छूट';

  @override
  String get productColumnsDefaultDiscountSubtitle =>
      'इस उत्पाद को इनवॉइस में जोड़ते समय पूर्व-भरी छूट।';

  @override
  String get productColumnsUnitLabel => 'इकाई';

  @override
  String get productColumnsUnitSubtitle =>
      'माप की इकाई (पीस, किग्रा, घंटे...)।';

  @override
  String get productColumnsProductServiceTypeLabel => 'उत्पाद/सेवा प्रकार';

  @override
  String get productColumnsProductServiceTypeSubtitle =>
      'खंडित उत्पाद बनाम सेवा चयनकर्ता।';

  @override
  String get productColumnsMetadataLabel => 'उत्पाद मेटाडेटा';

  @override
  String get productColumnsMetadataSubtitle =>
      'भंडारण स्थान, कंटेनर/बैच संख्या, समाप्ति, निर्माण तिथि, आपूर्तिकर्ता, SKU, नोट्स।';

  @override
  String get productColumnsMetaStorageLocationLabel => 'भंडारण स्थान';

  @override
  String get productColumnsMetaContainerNumberLabel => 'कंटेनर संख्या';

  @override
  String get productColumnsMetaBatchNumberLabel => 'बैच संख्या';

  @override
  String get productColumnsMetaExpiryDateLabel => 'समाप्ति तिथि';

  @override
  String get productColumnsMetaManufactureDateLabel => 'निर्माण तिथि';

  @override
  String get productColumnsMetaSupplierNameLabel => 'आपूर्तिकर्ता नाम';

  @override
  String get productColumnsMetaSkuCodeLabel => 'SKU कोड';

  @override
  String get productColumnsMetaNotesLabel => 'नोट्स';

  @override
  String get productColumnsExtraCostLabel => 'अतिरिक्त लागत';

  @override
  String get productColumnsExtraCostSubtitle =>
      'इनवॉइस लाइन आइटम पर वैकल्पिक फ्लैट अतिरिक्त शुल्क।';

  @override
  String get settingsOptionsComingSoonMessage => 'विकल्प जल्द आ रहे हैं...';

  @override
  String get settingsNavCompanyInfoLabel => 'कंपनी जानकारी';

  @override
  String get settingsNavTeamLabel => 'टीम';

  @override
  String get settingsNavBackupLabel => 'बैकअप';

  @override
  String get settingsNavUsersLabel => 'उपयोगकर्ता';

  @override
  String get settingsNavProductDetailsLabel => 'उत्पाद विवरण';

  @override
  String get settingsNavCustomizeLabel => 'कस्टमाइज़ करें';

  @override
  String get settingsNavAccessibilityLabel => 'सुगम्यता';

  @override
  String get settingsNavSoftwareInfoLabel => 'सॉफ़्टवेयर जानकारी';

  @override
  String get customizationEyebrowLabel => 'कस्टमाइज़ेशन';

  @override
  String get customizationHeadline => 'आपके व्यवसाय के लिए अनुकूलित';

  @override
  String get customizationSubtitle =>
      'जो चाहिए वह चुनें और अनुरोध भेजें। हम 24 घंटे के भीतर संपर्क करेंगे।';

  @override
  String get customizationRecommendedBadge => 'अनुशंसित';

  @override
  String customizationDeliveryLabel(String delivery) {
    return 'डिलीवरी: $delivery';
  }

  @override
  String get customizationRequestButton => 'अनुरोध करें';

  @override
  String get customizationFormOpenErrorMessage =>
      'फॉर्म नहीं खुल सका। कृपया अपने ब्राउज़र में forms.gle/LyX6Z2kBNR2BpwVu7 खोलें।';

  @override
  String get customizationDisclaimerMessage =>
      'कीमतें सांकेतिक हैं। जटिलता के आधार पर अंतिम कोट भिन्न हो सकता है। दायरे पर सहमति के बाद भुगतान लिया जाता है।';

  @override
  String get customizationPdfTemplateTitle => 'कस्टम PDF टेम्पलेट';

  @override
  String get customizationPdfTemplateDescription =>
      'अपने ब्रांड से मेल खाता इनवॉइस टेम्पलेट पाएं — आपके रंग, फ़ॉन्ट, लोगो प्लेसमेंट और लेआउट।';

  @override
  String get customizationPdfTemplateDelivery => '2–5 दिन';

  @override
  String get customizationCustomFieldsTitle => 'कस्टम फ़ील्ड्स';

  @override
  String get customizationCustomFieldsDescription =>
      'अपने इनवॉइस पर अतिरिक्त फ़ील्ड चाहिए? (PO नंबर, प्रोजेक्ट कोड, विभाग, आदि) हम आपके लिए जोड़ देंगे।';

  @override
  String get customizationCustomFieldsDelivery => '1–3 दिन';

  @override
  String get customizationWhiteLabelTitle => 'व्हाइट-लेबल / ब्रांडिंग हटाएं';

  @override
  String get customizationWhiteLabelDescription =>
      'ऐप और PDF आउटपुट से सारी Invoiso ब्रांडिंग हटाएं, और इसे अपनी कंपनी की पहचान से बदलें।';

  @override
  String get customizationWhiteLabelDelivery => '3–6 दिन';

  @override
  String get customizationIndustryBuildTitle => 'उद्योग-विशिष्ट निर्माण';

  @override
  String get customizationIndustryBuildDescription =>
      'अपने उद्योग के लिए अनुकूलित संस्करण चाहिए? (निर्माण, परामर्श, खुदरा, आदि) हम आपकी ज़रूरत के अनुसार वर्कफ़्लो कस्टमाइज़ करेंगे।';

  @override
  String get customizationIndustryBuildDelivery => '5–10 दिन';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle =>
      'नया इनवॉइस बनाएँ पृष्ठ लेआउट';

  @override
  String get accessibilityClassicLayoutLabel => 'क्लासिक लेआउट';

  @override
  String get accessibilityNewLayoutLabel => 'नया लेआउट';

  @override
  String get accessibilityLayoutDescription =>
      'कौन सा \"नया इनवॉइस\" स्क्रीन डिज़ाइन उपयोग करना है चुनें।';

  @override
  String get accessibilityShortcutsSubtitle =>
      'माउस छुए बिना इनवॉइस बनाना तेज़ करें।';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => 'इनवॉइस कुल';

  @override
  String get paymentDialogAmountPaidLabel => 'भुगतान की गई राशि';

  @override
  String get paymentDialogHistoryTitle => 'भुगतान इतिहास';

  @override
  String get paymentDialogNoPaymentsMessage =>
      'अभी तक कोई भुगतान दर्ज नहीं किया गया';

  @override
  String get paymentDialogFullyPaidExclaimMessage =>
      'इनवॉइस पूरी तरह भुगतान हो गया!';

  @override
  String get paymentDialogFullyPaidBannerLabel =>
      'इनवॉइस पूरी तरह भुगतान हो गया';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return 'भुगतान दर्ज किया गया। बकाया: $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return 'भुगतान दर्ज करने में विफल: $error';
  }

  @override
  String get paymentDialogDeleteTitle => 'भुगतान हटाएं';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return 'रसीद $receiptNumber हटाएं?\n\nइसे वापस नहीं लिया जा सकता।';
  }

  @override
  String get paymentDialogNewPaymentTitle => 'नया भुगतान';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return 'राशि ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return 'अधिकतम: $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError => 'मान्य राशि दर्ज करें';

  @override
  String get paymentDialogExceedsOutstandingError => 'बकाया राशि से अधिक है';

  @override
  String get paymentDialogMethodFieldLabel => 'भुगतान विधि';

  @override
  String get paymentDialogSelectMethodHint => 'विधि चुनें';

  @override
  String get paymentDialogTaxCoveredLabel => 'कर शामिल';

  @override
  String get paymentDialogAutoCalculatedHelper => 'स्वतः गणना की गई';

  @override
  String get paymentDialogNotesFieldLabel => 'संदर्भ / टिप्पणी (वैकल्पिक)';

  @override
  String get paymentDialogNotesHint => 'जैसे: चेक नंबर, लेनदेन आईडी...';

  @override
  String get paymentDialogReceiptColLabel => 'रसीद #';

  @override
  String get paymentDialogMethodColLabel => 'विधि';

  @override
  String get paymentDialogDownloadReceiptTooltip => 'रसीद डाउनलोड करें';

  @override
  String get paymentDialogDeletePaymentTooltip => 'भुगतान हटाएं';

  @override
  String get paymentMethodCash => 'नकद';

  @override
  String get paymentMethodBankTransfer => 'बैंक ट्रांसफर';

  @override
  String get paymentMethodCheck => 'चेक';

  @override
  String get paymentMethodOnline => 'ऑनलाइन';

  @override
  String get paymentMethodOther => 'अन्य';

  @override
  String get customerInfoButtonTooltip => 'संपर्क विवरण देखें';

  @override
  String get customerInfoButtonNoContactMessage =>
      'कोई संपर्क विवरण उपलब्ध नहीं है।';

  @override
  String get updateDialogTitle => 'अपडेट उपलब्ध है';

  @override
  String get updateDialogBodyMessage =>
      'invoiso का नया संस्करण उपलब्ध है। नवीनतम रिलीज़ पाने के लिए डाउनलोड पेज पर जाएं।';

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
  String get dateFormatDdmmyyyyLabel => 'DD/MM/YYYY  (उदा. 15/04/2026)';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/DD/YYYY  (उदा. 04/15/2026)';

  @override
  String get dateFormatDdMmmyyyyLabel => 'DD MMM YYYY  (उदा. 15 Apr 2026)';

  @override
  String get dateFormatYyyymmddLabel => 'YYYY-MM-DD  (उदा. 2026-04-15)';

  @override
  String get sizeXSmallLabel => 'बहुत छोटा';

  @override
  String get sizeSmallLabel => 'छोटा';

  @override
  String get sizeMediumLabel => 'मध्यम';

  @override
  String get sizeLargeLabel => 'बड़ा';

  @override
  String get shortcutNewInvoiceDescription =>
      'नया इनवॉइस (डैशबोर्ड से) / फ़ॉर्म रीसेट करें (इनवॉइस बनाएं में)';

  @override
  String get shortcutSaveInvoiceDescription => 'इनवॉइस सहेजें / बनाएं';

  @override
  String get shortcutAddProductDescription => 'इनवॉइस में उत्पाद जोड़ें';

  @override
  String get shortcutAddCustomItemDescription => 'कस्टम आइटम जोड़ें';

  @override
  String get shortcutPreviewPdfDescription => 'इनवॉइस PDF पूर्वावलोकन करें';

  @override
  String get shortcutPrintPdfDescription => 'इनवॉइस PDF जनरेट/प्रिंट करें';
}
