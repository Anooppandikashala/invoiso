// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tibetan (`bo`).
class AppLocalizationsBo extends AppLocalizations {
  AppLocalizationsBo([String locale = 'bo']) : super(locale);

  @override
  String get appTitle => 'Invoiso';

  @override
  String get actionSave => 'ཉར་ཚགས།';

  @override
  String get actionCancel => 'ཕྱིར་འཐེན།';

  @override
  String get actionSkip => 'གོམ་པ་གཅིག་གྱོགས།';

  @override
  String get actionNext => 'རྗེས་མ།';

  @override
  String get actionBack => 'ཕྱིར་ལོག';

  @override
  String get actionGetStarted => 'འགོ་བཙུགས།';

  @override
  String get commonLanguage => 'སྐད་ཡིག';

  @override
  String get commonBeta => 'བེ་ཊ།';

  @override
  String get commonSystemDefault => 'མ་ལག་སྔར་སྒྲིག';

  @override
  String get commonTheme => 'བཀོད་པ།';

  @override
  String get themeLight => 'སྣང་བ།';

  @override
  String get themeDark => 'མུན་ནག';

  @override
  String get themeSystem => 'མ་ལག';

  @override
  String get onboardingStepCompanyTitle => 'ཚོང་ལས།';

  @override
  String get onboardingStepCompanySubtitle => 'ཁྱེད་ཀྱི་ཚོང་ལས་སྐོར་བཤད་རོགས།';

  @override
  String get onboardingStepInvoiceTitle => 'ཁྲལ་ཤོག་སྒྲིག་འགོད།';

  @override
  String get onboardingStepInvoiceSubtitle =>
      'ཁྱེད་ཀྱི་ཁྲལ་ཤོག་ཇི་ལྟར་བྱེད་མིན་སྒྲིག་རོགས།';

  @override
  String get onboardingStepAppearanceTitle => 'ཁྲལ་ཤོག་བཀོད་པ།';

  @override
  String get onboardingStepAppearanceSubtitle =>
      'ཤོག་ངོས་ཚད་དང་དཔེ་གཞི་འདེམས་རོགས།';

  @override
  String get onboardingStepDoneTitle => 'ཚང་མ་གྲུབ།';

  @override
  String get onboardingCompanyNameLabel => 'ཚོང་ལས་མིང་།';

  @override
  String get onboardingCountryLabel => 'རྒྱལ་ཁབ།';

  @override
  String get onboardingLogoLabel => 'ཚོང་ལས་མཚོན་རྟགས།';

  @override
  String get onboardingCurrencyLabel => 'དངུལ་རིགས།';

  @override
  String get onboardingDateFormatLabel => 'ཚེས་གྲངས་བཀོད་པ།';

  @override
  String get onboardingInvoiceStartingNumberLabel => 'ཁྲལ་ཤོག་འགོ་ཙམ་གྲངས།';

  @override
  String get onboardingLeadingZerosLabel => 'སྔོན་གྱི་ཀླད་ཀོར།';

  @override
  String get onboardingLeadingZerosSubtitle =>
      'ཁྲལ་ཤོག་གྲངས་ཀ་བརྒྱད་དུ་བཀང་བ (དཔེར་ན 00000007)';

  @override
  String get onboardingDefaultTaxRateLabel => 'སྔར་སྒྲིག་ཁྲལ་ཚད (%)';

  @override
  String get onboardingPageSizeLabel => 'ཤོག་ངོས་ཚད།';

  @override
  String get onboardingTemplateLabel => 'ཁྲལ་ཤོག་དཔེ་གཞི།';

  @override
  String get onboardingDoneHeadline => 'ཁྱེད་ཚང་མ་གྲུབ་སོང་།';

  @override
  String get onboardingDoneBody =>
      'ཁྱེད་ཀྱི་ཚོང་ལས་དང་ཁྲལ་ཤོག་དཔེ་གཞིའི་ཞིབ་ཕྲ་ཉར་ཚགས་བྱས་ཟིན། ཕྱིས་སུ་སྒྲིག་འགོད་ནང་བཟོ་བཅོས་བྱེད་ཆོག';

  @override
  String get splashInitErrorTitle => 'འགོ་འཛུགས་འཛོལ་བ།';

  @override
  String splashInitErrorMessage(String error) {
    return 'གནས་ཚུལ་མཛོད་འགོ་འཛུགས་མ་ཐུབ།\n\n$error';
  }

  @override
  String get actionRetry => 'སླར་ཚོད་ལྟ།';

  @override
  String get splashInitializingMessage => 'ཉེར་སྤྱོད་འགོ་འཛུགས་བཞིན་པ...';

  @override
  String get testGateNoInternetTitle =>
      'ཚོད་ལྟའི་སྒྲིག་འཇུག་ལ་དྲྭ་རྒྱའི་འབྲེལ་མཐུད་དགོས།';

  @override
  String get testGateExpiredTitle => 'ཚོད་ལྟའི་པར་གཞི་འདིའི་དུས་ཚོད་ཟིན་སོང་།';

  @override
  String get testGateNoInternetSubtitle =>
      'དྲྭ་རྒྱར་འབྲེལ་མཐུད་བྱས་ནས་སླར་ཚོད་ལྟོས།';

  @override
  String testGateExpiredSubtitle(String email) {
    return 'རོགས་སྐྱོར་ལ་འབྲེལ་བ་བྱོས: $email';
  }

  @override
  String get dashboardSessionExpiredMessage =>
      'ལས་མི་བྱས་པའི་རྐྱེན་གྱིས་གནས་སྐབས་ཟིན་སོང་།';

  @override
  String get dashboardUnknownTabLabel => 'ཤེས་མེད་ཨིངག་ལེབ།';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return 'ཁྲལ་ཤོག་བཀོད་པ: $layout — གནས་ཚུལ་ཆེད་མནན་རོགས།';
  }

  @override
  String get dashboardLayoutNew => 'གསར་པ།';

  @override
  String get dashboardLayoutClassic => 'རྙིང་པའི།';

  @override
  String get dashboardInvoiceLayoutDialogTitle => 'ཁྲལ་ཤོག་བཀོད་པ།';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return 'ཁྱེད་ཀྱིས $layout \"ཁྲལ་ཤོག་གསར་པ\" བཀོད་པ་བེད་སྤྱོད་བྱེད་བཞིན་འདུག ཁྱེད་ཀྱིས་འདི་སྒྲིག་འགོད > འཇུག་བདེ་ནས་བརྗེ་ཆོག ཐུགས་འཇགས: བར་སྐབས་སུ་བརྗེ་ན་གློག་ཤོག་འདིའི་མ་ཉར་བའི་བཟོ་བཅོས་ཤོར་ངེས།';
  }

  @override
  String get actionClose => 'ཁ་རྒྱག';

  @override
  String get dashboardOpenSettingsAction => 'སྒྲིག་འགོད་ཁ་ཕྱེ།';

  @override
  String get dashboardCollapseSidebarTooltip => 'ཟུར་ཐིག་བསྡུས།';

  @override
  String get dashboardExpandSidebarTooltip => 'ཟུར་ཐིག་རྒྱ་བསྐྱེད།';

  @override
  String get navDashboard => 'ཚོད་ལྟའི་ངོས།';

  @override
  String get navNewInvoice => 'ཁྲལ་ཤོག་གསར་པ།';

  @override
  String get navInvoices => 'ཁྲལ་ཤོག་རྣམས།';

  @override
  String get navQuotations => 'རིན་གྲངས།';

  @override
  String get navReceipts => 'ལག་ཁྱེར།';

  @override
  String get navCustomers => 'ཉོ་མཁན།';

  @override
  String get navProducts => 'ཐོན་རྫས།';

  @override
  String get navReports => 'སྙན་ཐོ།';

  @override
  String get navSettings => 'སྒྲིག་འགོད།';

  @override
  String get dashboardRoleAdmin => 'དོ་དམ་པ།';

  @override
  String get dashboardRoleUser => 'བེད་སྤྱོད་མཁན།';

  @override
  String get dashboardSupportTooltip => 'རོགས་སྐྱོར།';

  @override
  String get dashboardLogoutTooltip => 'ཕྱིར་འཐོན།';

  @override
  String get dashboardTestBuildBadge => 'ཚོད་ལྟའི་པར་གཞི།';

  @override
  String get dashboardTestBadgeShort => 'ཚོད་ལྟ།';

  @override
  String get dashboardKeyboardShortcutsTitle => 'མཐེབ་གཞོང་མགྱོགས་ལམ།';

  @override
  String get dashboardShortcutsBannerTitle => 'གསར་པ: མཐེབ་གཞོང་མགྱོགས་ལམ།';

  @override
  String get dashboardShortcutsBannerSubtitle =>
      'ཁྲལ་ཤོག་གསར་པར Ctrl+Q, ཉར་ཚགས་ལ Ctrl+S, སོགས།';

  @override
  String get dashboardViewAllAction => 'ཡོངས་རྫོགས་ལྟ།';

  @override
  String get dashboardLayoutBannerTitle =>
      'གསར་པ: ཚོད་ལྟའི་ངོས་ཀྱི་བཀོད་པ་མང་པོ།';

  @override
  String get dashboardLayoutBannerSubtitle =>
      'སྟེང་གཡས་ཀྱི་དྲྭ་བའི་རི་མོ་བེད་སྤྱོད་ཀྱིས་སྔར་སྒྲིག, རྙིང་པའི, Bento, དང་འཕྲིན་ཕྲན་ཡང་ཡང་བར་བརྗེ།';

  @override
  String get actionGotIt => 'གོ་སོང་།';

  @override
  String get dashboardThemeBannerTitle => 'གསར་པ: མུན་ནག་བཀོད་པ།';

  @override
  String get dashboardThemeBannerSubtitle =>
      'ང་ཚོས་ད་དུང་ལེགས་བཅོས་བྱེད་བཞིན་ཡོད — སྒྲིག་འགོད > ཚོང་ལས་གནས་ཚུལ་ནས་ཁ་ཕྱེ་ནས་ཅི་ཞིག་མི་འགྲིག་པ་ང་ཚོར་ཤོད་རོགས།';

  @override
  String dashboardSupportBannerTitle(String count) {
    return 'ཁྱེད་ཀྱིས་ཁྲལ་ཤོག $count བཟོས་ཟིན!';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      'Invoiso ལ་དགའ་བོ་ཡོད་དམ? མྱུར་བའི་བསྐྱར་ཞིབ་ཅིག་གིས་ཕན་ཐོགས་ཆེན་པོ་ཡོད།';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      'Invoiso ཁྱེད་ཀྱི་ལས་ཀའི་ཆ་ཤས་ཤིག་ཏུ་གྱུར་འདུག ཕན་ཐོགས་བྱུང་ན, དུས་ཚོད་འགྲིག་པའི་སྐབས་ལས་གཞི་ལ་རོགས་སྐྱོར་བསམ་བློ་གཏོང་རོགས།';

  @override
  String get dashboardReviewAction => 'བསྐྱར་ཞིབ།';

  @override
  String get dashboardSupportAction => 'རོགས་སྐྱོར།';

  @override
  String get dashboardOverviewTitle => 'ཚོད་ལྟའི་ངོས་སྤྱི་བཤད།';

  @override
  String get actionRefresh => 'གསར་སྒྱུར།';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count ཚོང་ཟོག་ཟད་སོང་།';
  }

  @override
  String get dashboardRevenueCollectedLabel => 'བསྡུས་པའི་འབབ་འོང་།';

  @override
  String get dashboardOutstandingLabel => 'ཐེབས་ཆག';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count དུས་ཚོད་འགལ།';
  }

  @override
  String get dashboardRecentInvoicesTitle => 'ད་ལྟའི་ཁྲལ་ཤོག';

  @override
  String get dashboardLastFiveInvoicesLabel => 'མཐའ་མའི་ཁྲལ་ཤོག 5';

  @override
  String get dashboardNoInvoicesYetTitle => 'ད་དུང་ཁྲལ་ཤོག་མེད།';

  @override
  String get dashboardNoInvoicesYetSubtitle =>
      'འདིར་མཐོང་ཆེད་ཁྱེད་ཀྱི་ཁྲལ་ཤོག་དང་པོ་བཟོས་རོགས།';

  @override
  String get actionView => 'ལྟ་བ།';

  @override
  String get actionEdit => 'ཞུ་དག';

  @override
  String get actionDuplicate => 'འདྲ་བཤུས།';

  @override
  String get actionPdfPreview => 'PDF སྔོན་ལྟ།';

  @override
  String get actionDownloadPdf => 'PDF ཕབ་ལེན།';

  @override
  String get actionPrint => 'པར་སྐྲུན།';

  @override
  String get actionPayment => 'འཇལ་བ།';

  @override
  String get actionDelete => 'བསུབ།';

  @override
  String get actionRecordPayment => 'འཇལ་བ་ཐོ་འགོད།';

  @override
  String dashboardDueDateLabel(String date) {
    return 'དུས་ཚོད: $date';
  }

  @override
  String get labelInvoice => 'ཁྲལ་ཤོག';

  @override
  String get labelQuotation => 'རིན་གྲངས།';

  @override
  String get labelReceipt => 'ལག་ཁྱེར།';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return 'ཡང་བསུ་བ, $username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle =>
      'འདིར་ཁྱེད་ཀྱི་ཚོང་ལས་ཀྱི་མཐོང་ཆུང་ཡོད།';

  @override
  String get dashboardDueSoonTitle => 'མགྱོགས་པོར་དུས་ཚོད།';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག $count',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => 'དེ་རིང་དང་སང་ཉིན།';

  @override
  String get dashboardDueTodayBadge => 'དེ་རིང་དུས་ཚོད།';

  @override
  String get dashboardDueTomorrowBadge => 'སང་ཉིན་དུས་ཚོད།';

  @override
  String get dashboardOverdueSectionTitle => 'དུས་ཚོད་འགལ།';

  @override
  String get dashboardOldestFirstLabel => 'རྙིང་ཤོས་དང་པོ།';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ཉིན་ $days དུས་ཚོད་འགལ',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => 'ཚོང་ཟོག་གྲངས་གསར་པ།';

  @override
  String get actionUpdate => 'གསར་སྒྱུར།';

  @override
  String get labelService => 'ཞབས་ཞུ།';

  @override
  String get labelProduct => 'ཐོན་རྫས།';

  @override
  String dashboardStockLabel(int count) {
    return 'ཚོང་ཟོག: $count';
  }

  @override
  String get actionUpdateStock => 'ཚོང་ཟོག་གསར་སྒྱུར།';

  @override
  String get paymentStatusPaid => 'འཇལ་ཟིན།';

  @override
  String get paymentStatusPartial => 'ཆ་ཤས།';

  @override
  String get paymentStatusUnpaid => 'མ་འཇལ།';

  @override
  String get dashboardDuplicateInvoiceTitle => 'ཁྲལ་ཤོག་འདྲ་བཤུས།';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return 'ཁྲལ་ཤོག #$number\n($customerName) གི་འདྲ་བཤུས་འདི་ལྟར་བཟོ་རོགས:';
  }

  @override
  String get dashboardDeleteInvoiceTitle => 'ཁྲལ_ཤོག་བསུབ།';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return 'ཁྱེད་ཀྱིས་ཁྲལ་ཤོག #$number བསུབ་ངེས་སམ? འདི་སླར་ལོག་མི་ཐུབ།';
  }

  @override
  String get dashboardLayoutTooltip => 'ཚོད་ལྟའི་ངོས་བཀོད་པ།';

  @override
  String get dashboardLayoutDefaultTitle => 'སྔར་སྒྲིག';

  @override
  String get dashboardLayoutDefaultSubtitle => 'ཐོག་མའི་བཀོད་པ།';

  @override
  String get dashboardLayoutClassicSubtitle => 'རི་མོ + KPI';

  @override
  String get dashboardLayoutBentoTitle => 'Bento';

  @override
  String get dashboardLayoutBentoSubtitle => 'གཙོ་བོའི་རི་མོ + ཤོག་གྲངས།';

  @override
  String get dashboardLayoutSimpleTitle => 'འཕྲིན་ཕྲན་ཡང་ཡང་།';

  @override
  String get dashboardLayoutSimpleSubtitle => 'ཐོ་གཞུང་གསལ་པོ།';

  @override
  String get dashboardTotalInvoicesLabel => 'ཁྲལ་ཤོག་བསྡོམས།';

  @override
  String get dashboardRevenueLast6MonthsTitle => 'འབབ་འོང་ — ཟླ་བ 6 སྔོན་མ།';

  @override
  String get dashboardNoPaymentDataYetLabel => 'ད་དུང་འཇལ་གནས་ཚུལ་མེད།';

  @override
  String get dashboardFinancialOverviewTitle => 'དངུལ_དོན་སྤྱི་བཤད།';

  @override
  String get dashboardCollectedLabel => 'བསྡུས་པ།';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག $count དུས་ཚོད་འགལ',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return 'མཐའ་མའི $n';
  }

  @override
  String get labelCustomer => 'ཉོ་མཁན།';

  @override
  String get labelAmount => 'གྲངས་འབོར།';

  @override
  String get dashboardZeroLeftLabel => '0 ལྷག';

  @override
  String get labelStock => 'ཚོང་ཟོག';

  @override
  String get actionPay => 'འཇལ།';

  @override
  String get dashboardQuickActionsTitle => 'མགྱོགས་བྱ།';

  @override
  String get dashboardPdfActionsTooltip => 'PDF བྱ་བ།';

  @override
  String get dashboardActionsTooltip => 'བྱ་བ།';

  @override
  String get dashboardTopCustomersTitle => 'ཉོ་མཁན་གཙོ་བོ།';

  @override
  String get dashboardTopProductsTitle => 'ཐོན་རྫས་གཙོ་བོ།';

  @override
  String dashboardUnitsLabel(String qty) {
    return 'ཆ $qty';
  }

  @override
  String get dashboardBetaBadge => 'BETA';

  @override
  String get dashboardOutOfStockSectionTitle => 'ཚོང་ཟོག་ཟད་སོང་།';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཅ་ལག $count',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => 'བསྐྱར་གསོག་ཆེད་མནན་རོགས།';

  @override
  String get createInvoiceUnsavedChangesTitle => 'མ་ཉར་བའི་བཟོ་བཅོས།';

  @override
  String get createInvoiceUnsavedChangesMessage =>
      'ཁྲལ་ཤོག་འདིར་མ་ཉར་བའི་བཟོ་བཅོས་ཡོད། ཕྱིར་འཐོན་སྔོན་ལ་ཉར་ཚགས་བྱེད་དམ།';

  @override
  String get createInvoiceKeepEditingButton => 'བཟོ་བཅོས་མུ་མཐུད།';

  @override
  String get actionDiscard => 'སྤོང་བ།';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return 'གྲངས་སྙིགས་འདྲེན་འཛུགས་ནོར་འཁྲུལ།: $e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => 'ཉར་ཚགས་མི་འདང་བ།';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return 'ཆ་ཚང $stock ཙམ་ཞིག་ཡོད། ཡིན་ནའང $qty སྤར་རམ།';
  }

  @override
  String get createInvoiceAddAnywayButton => 'ཡིན་ནའང་སྤར།';

  @override
  String get createInvoiceOutOfStockTitle => 'ཉར་ཚགས་ཟད་པ།';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name ཉར་ཚགས་ཟད་སོང་། ཡིན་ནའང་སྤར་རམ།';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => 'ཚད་མེད་ཉར་ཚགས།';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return 'ཉར་ཚགས་ཡོད་པ: $stock';
  }

  @override
  String get fieldDiscountLabel => 'ཐོ་ཆད།';

  @override
  String get fieldUnitPriceOverrideLabel => 'ཆ་རེའི་རིན་གོང་ (སྐྱོན་བཅོས)';

  @override
  String get fieldExtraCostLabel => 'ཐོབ་འོས་གོང་ཚད་ (འདེམས་ཐང་)';

  @override
  String get fieldInsertAtPositionLabel => 'གནས་ས་འདིར་སྣོན།';

  @override
  String get actionAdd => 'སྣོན་པ།';

  @override
  String get createInvoiceProductAlreadyAddedMessage =>
      'ཐོན་རྫས་འདི་སྔོན་ནས་སྣོན་ཟིན།';

  @override
  String get createInvoiceCustomerNameRequiredMessage =>
      'ཉོ་མཁན་གྱི་མིང་གནང་རོགས།';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage =>
      'ཉུང་མཐར་རྫས་གཅིག་སྣོན་རོགས།';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel ལེགས་འགྲུབ་བྱུང་།';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return 'ཁྲལ་ཤོག་བཟོ་བར་ནོར་འཁྲུལ།: $e';
  }

  @override
  String get createInvoiceEditItemTitle => 'རྫས་བཟོ་བཅོས།';

  @override
  String get createInvoiceCustomItemTitle => 'རང་བཟོའི་རྫས།';

  @override
  String get fieldItemNameLabel => 'རྫས་མིང་།';

  @override
  String get fieldAliasForPdfLabel => 'མིང་གཞན་ (PDF ལ)';

  @override
  String get fieldUnitPriceLabel => 'ཆ་རེའི་རིན་གོང་།';

  @override
  String get fieldRateLabel => 'ཚད་གཞི།';

  @override
  String get fieldTaxRateLabel => 'ཁྲལ་ཚད (%)';

  @override
  String get fieldPriceIncludesTaxLabel => 'རིན་གོང་ནང་ཁྲལ་ཚུད།';

  @override
  String get createInvoicePhoneAlreadyInUseTitle =>
      'ཁ་པར་གྲངས་ཀ་སྔར་ནས་བེད་སྤྱོད་བྱེད་བཞིན་པ།';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return 'ཁ་པར་གྲངས་ཀ་འདི \"$ownerName\" གི་ཡིན།\n\nམི་གཞན་ལ་ཡོད་པའི་ཁ་པར་གྲངས་ཀས་ཉོ་མཁན་འདི་ཉར་ཚགས་མི་ཐུབ།';
  }

  @override
  String get actionOk => 'འགྲིགས།';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      'ཉར་ཚགས་སྔོན་ལ་ཉོ་མཁན་གྱི་མིང་འཇུག་རོགས།';

  @override
  String get createInvoicePhoneChangedTitle => 'ཁ་པར་གྲངས་ཀ་བརྗེས་སོང་།';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return '\"$name\" གི་ཁ་པར་གྲངས་ཀ་བརྗེས་སོང་།\n\nཡོད་བཞིན་པའི་ཐོ་གཞུང་གསར་བཅོས་བྱེད་དམ། ཡང་ན་གྲངས་སྙིགས་འདི་ཉོ་མཁན་གསར་པར་ཉར་ཚགས་བྱེད་དམ།';
  }

  @override
  String get createInvoiceSaveAsNewButton => 'གསར་པར་ཉར་ཚགས།';

  @override
  String get createInvoiceUpdateExistingButton => 'ཡོད་བཞིན་པ་གསར་བཅོས།';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '$name ཉོ་མཁན་ཐོ་གཞུང་ནང་གསར་བཅོས་བྱས།';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle => 'ཉོ་མཁན་སྔོན་ནས་ཡོད།';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '\"$name\" ཁ་པར་གྲངས་ཀ་འདིས་སྔོན་ནས་ཉར་ཚགས་ཟིན།\n\nཡོད་བཞིན་པའི་ཞིབ་ཕྲ་བེད་སྤྱོད་བྱེད་དམ། ཡང་ན་ད་ལྟའི་གྲངས་སྙིགས་ཀྱིས་ཐོ་གཞུང་གསར་བཅོས་བྱེད་དམ།';
  }

  @override
  String get createInvoiceUseExistingButton => 'ཡོད་བཞིན་པ་བེད་སྤྱོད།';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return 'ཡོད་བཞིན་པའི་ཉོ་མཁན \"$name\" བེད་སྤྱོད་བྱེད་བཞིན།';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name ཉོ་མཁན་ཐོ་གཞུང་ནང་ཉར་ཚགས་བྱས།';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage =>
      'ཉོ་མཁན་གྱི་ཐོ་གཞུང་མི་གནས།';

  @override
  String get createInvoiceCustomerRefreshedMessage =>
      'ཉོ་མཁན་ཞིབ་ཕྲ་གསར་བཅོས་བྱས།';

  @override
  String get fieldLabelLabel => 'བརྡ་མིང་།';

  @override
  String get hintLabelExample => 'དཔེར་ན་འཁྱེར་འགྲེམས།';

  @override
  String get tooltipRemove => 'འདོར་བ།';

  @override
  String get createInvoiceAddRowButton => 'ཐིག་གྲངས་སྣོན།';

  @override
  String get fieldDiscountPerUnitLabel => 'ཆ་རེའི་ཐོ་ཆད།';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn =>
      '(རིན་གོང − ཐོ་ཆད) × གྲངས་ཚད';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff =>
      '(རིན་གོང × གྲངས་ཚད) − ཐོ་ཆད';

  @override
  String get createInvoicePrevBalanceShortLabel => 'སྔོན་ལྷག';

  @override
  String get createInvoicePreviousBalanceDueLabel => 'སྔོན་གྱི་ཁེ་ལྷག';

  @override
  String get createInvoiceDueShortLabel => 'འབབ།';

  @override
  String get createInvoiceTotalDueLabel => 'འབབ་ཆ་ཚང་།';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel ལེགས་གསར་བཅོས་བྱུང་།';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return 'ཁྲལ་ཤོག་གསར་བཅོས་བྱེད་པར་ནོར་འཁྲུལ།: $e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '$invoiceTypeLabel ལེགས་འགྲུབ་བྱུང་།';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return '$invoiceTypeLabel ཨང་གྲངས: $invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => 'ཞིབ་ཕྲ་ལྟ་བ།';

  @override
  String get createInvoicePreviewPdfLabel => 'PDF སྔོན་ལྟ།';

  @override
  String get createInvoicePreviewPdfTooltip =>
      'PDF སྔོན་ལྟ (མགྱོགས་ལམ: Ctrl+o)';

  @override
  String get createInvoicePrintPdfLabel => 'PDF པར་སྐྲུན།';

  @override
  String get createInvoicePrintPdfTooltip => 'PDF པར་སྐྲུན (མགྱོགས་ལམ: Ctrl+p)';

  @override
  String get actionDismiss => 'ཁེགས་བཀོག';

  @override
  String get createInvoiceCreateNewInvoiceButton =>
      'ཁྲལ་ཤོག་གསར་པ་བཟོ (མགྱོགས་ལམ: Ctrl+q)';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel གསར་པ་བཟོ།';
  }

  @override
  String get commonLoadingDataMessage => 'གྲངས་སྙིགས་འདྲེན་འཛུགས་བྱེད་བཞིན...';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage =>
      'ཁྲལ་ཤོག་བཟོ་བའི་སྔོན་ལ་ཉུང་མཐར་རྫས་གཅིག་སྣོན་རོགས།';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel བཟོས་ཟིན།';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel བཟོ་བཅོས།';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return '$invoiceTypeLabel ལྟར་འདྲ་བཤུས།';
  }

  @override
  String get createInvoiceNewShortLabel => 'གསར་པ།';

  @override
  String get createInvoiceNewInvoiceShortcutLabel =>
      'ཁྲལ་ཤོག་གསར་པ (མགྱོགས་ལམ: Ctrl+q)';

  @override
  String get createInvoiceSavingEllipsisLabel => 'ཉར་ཚགས་བྱེད་བཞིན...';

  @override
  String get createInvoiceSaveCustomerLabel => 'ཉོ་མཁན་ཉར་ཚགས།';

  @override
  String get createInvoiceSelectExistingCustomerButton =>
      'ཡོད་བཞིན་པ་ནས་འདེམས།';

  @override
  String get createInvoiceRefreshCustomerTooltip =>
      'ཉར་ཚགས་ཡོད་པའི་ཉོ་མཁན་ནས་གསར་བཅོས།';

  @override
  String get createInvoiceClearCustomerTooltip => 'ཉོ་མཁན་འདེམས་པ་གསལ་བཤིག';

  @override
  String get fieldCustomerNameRequiredLabel => 'ཉོ་མཁན་མིང་ *';

  @override
  String get fieldBusinessNameLabel => 'ཚོང་ལས་མིང་།';

  @override
  String get fieldPhoneLabel => 'ཁ་པར།';

  @override
  String get fieldGstinVatLabel => 'GSTIN / ཁྲལ་ཨང་།';

  @override
  String get fieldEmailLabel => 'གློག་འཕྲིན།';

  @override
  String get fieldAddressLabel => 'གནས་ཡུལ།';

  @override
  String get tooltipEditInLargerView => 'ཆེ་བའི་མཐོང་ཚུལ་ནང་བཟོ་བཅོས།';

  @override
  String get createInvoiceChooseCustomerTitle => 'ཉོ་མཁན་འདེམས་པ།';

  @override
  String get createInvoiceSearchCustomerLabel => 'ཉོ་མཁན་འཚོལ་བ།';

  @override
  String get createInvoiceNoCustomersFoundMessage => 'ཉོ་མཁན་མ་རྙེད།';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return '$invoiceTypeLabel ཞིབ་ཕྲ།';
  }

  @override
  String get createInvoiceTypeFieldLabel => 'ཁྲལ་ཤོག་རིགས།';

  @override
  String get createInvoiceTypeLockedHelperText => 'བཟོས་རྗེས་རིགས་བརྗེ་མི་ཐུབ།';

  @override
  String get createInvoiceOrderDateLabel => 'མངགས་ཞུའི་ཚེས་གྲངས།';

  @override
  String get createInvoiceDueDateLabel => 'འབབ་ཚེས།';

  @override
  String get createInvoiceGstTitleLabel => 'GST མགོ་མིང་།';

  @override
  String get createInvoiceTaxTitleLabel => 'ཁྲལ་མགོ་མིང་།';

  @override
  String get gstTitleTaxInvoiceLabel => 'ཁྲལ་ཤོག';

  @override
  String get gstTitleBillOfSupplyLabel => 'སྤྲོད་ཐོ།';

  @override
  String get gstTitleInvoiceCumBillLabel => 'ཁྲལ་ཤོག-སྤྲོད་ཐོ།';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => 'སྐྱོན་བཅོས་ཐོ (ཡར)';

  @override
  String get gstTitleDebitNoteLabel => 'སྐྱོན་བཅོས་ཐོ (མར)';

  @override
  String get gstTitleRevisedInvoiceLabel => 'བཅོས་བསྒྱུར་ཁྲལ་ཤོག';

  @override
  String get createInvoiceSearchProductLabel =>
      'ཐོན་རྫས་ཡང་ན་ཞབས་ཞུ་འཚོལ་ཞིང་སྣོན (Ctrl+F)';

  @override
  String get createInvoiceCustomItemButton => 'རང་བཟོའི་རྫས (Ctrl+M)';

  @override
  String get createInvoiceNoProductsFoundMessage => 'ཐོན་རྫས་མ་རྙེད།';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '\"$name\" སྔོན་ནས་ཐོན་རྫས་ཐོ་གཞུང་ནང་ཡོད།';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name ཐོན་རྫས་ཐོ་གཞུང་ནང་ཉར་ཚགས་བྱས།';
  }

  @override
  String get createInvoiceSaveToProductListTooltip =>
      'ཐོན་རྫས་ཐོ་གཞུང་ནང་ཉར་ཚགས།';

  @override
  String get tooltipEditItem => 'རྫས་བཟོ་བཅོས།';

  @override
  String get tooltipRemoveItem => 'རྫས་འདོར་བ།';

  @override
  String get createInvoiceNoItemsAddedMessage => 'ད་བར་རྫས་སྣོན་མེད།';

  @override
  String get createInvoiceSearchHintMessage =>
      'འོག་ཏུ་འཚོལ་ཞིབ་བྱེད་ཡང་ན Ctrl+F མནན་རོགས།';

  @override
  String get createInvoiceDiscountFieldLabel => 'ཁྲལ་ཤོག་ཐོ་ཆད།';

  @override
  String get discountTypeAmountShortLabel => 'གྲངས།';

  @override
  String get createInvoiceNotesOptionalLabel => 'ཟིན་བྲིས (འདེམས་ཐང་)';

  @override
  String get createInvoiceNotesHint =>
      'འཇལ་བའི་ཆ་རྐྱེན, ཐུགས་རྗེ་ཆེའི་འབྲི་ཤོག…';

  @override
  String get createInvoiceNotesTitle => 'ཟིན་བྲིས།';

  @override
  String get createInvoiceHideNumberInPdfLabel =>
      'PDF ནང་ཁྲལ་ཤོག་ཨང་གྲངས་སྦེད།';

  @override
  String get createInvoiceCustomNumberLabel => 'རང་བཟོའི་ཨང་གྲངས (འདེམས་ཐང་)';

  @override
  String get createInvoiceCustomNumberHint =>
      'དཔེར་ན QUO-2026-014 — དེའི་ཚབ་ཏུ PDF ནང་སྟོན།';

  @override
  String get createInvoiceEnableTaxLabel => 'ཁྲལ་ལྕོགས་ཅན་བཟོ།';

  @override
  String get createInvoiceGlobalRateTooltip => 'སྤྱི་ཡོངས་ཚད་གཞི།';

  @override
  String get createInvoicePerItemRateTooltip => 'རྫས་རེའི་ཚད་གཞི།';

  @override
  String get createInvoiceDefaultTaxRateLabel => 'སྔར་སྒྲིག་ཁྲལ་ཚད།';

  @override
  String get createInvoiceTaxRateFromProductMessage =>
      'ཐོན་རྫས་སོ་སོའི་ཁྲལ་ཚད།';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => 'འཇལ་བའི UPI རྩིས་ཐོ།';

  @override
  String get commonNoneLabel => 'གང་ཡང་མེད།';

  @override
  String get createInvoiceBankAccountLabel => 'དངུལ་ཁང་རྩིས་ཐོ།';

  @override
  String get fieldSubtotalLabel => 'ཡན་ལག་བསྡོམས།';

  @override
  String get createInvoiceDiscountColonLabel => 'ཐོ་ཆད:';

  @override
  String get fieldTaxLabel => 'ཁྲལ།';

  @override
  String get createInvoiceExtraCostFallbackLabel => 'ཐོབ་འོས་གོང་ཚད།';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return 'ཁྲལ་ཤོག་ཐོ་ཆད ($toStringAsFixed%):';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel => 'ཁྲལ་ཤོག་ཐོ་ཆད:';

  @override
  String get fieldTotalLabel => 'བསྡོམས།';

  @override
  String get createInvoicePreviewLabel => 'སྔོན་ལྟ།';

  @override
  String get createInvoicePreviewTooltip => 'སྔོན་ལྟ (མགྱོགས་ལམ: Ctrl+o)';

  @override
  String get createInvoiceDownloadLabel => 'ཕབ་ལེན།';

  @override
  String get createInvoicePrintTooltip => 'པར་སྐྲུན (མགྱོགས་ལམ: Ctrl+p)';

  @override
  String get fieldUnitOverrideLabel => 'ཆ་ཤས (སྐྱོན་བཅོས)';

  @override
  String get commonCustomEllipsisLabel => 'རང་བཟོ…';

  @override
  String get fieldCustomUnitLabel => 'རང་བཟོའི་ཆ་ཤས།';

  @override
  String get invoiceMgmtMoveToTrashTitle => 'ཕྱགས་སྣོད་དུ་སྤོ།';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return 'ཁྲལ་ཤོག་ #$number ཕྱགས་སྣོད་དུ་སྤོ་དགོས་སམ།';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage => 'ཁྲལ་ཤོག་ཕྱགས་སྣོད་དུ་སྤོས་ཟིན།';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return 'ཁྲལ་ཤོག་ཁྲིད་མི་ཐུབ: $error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return '$type CSV ལ་འདོན་སྤེལ།';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel => 'ཟིན་ཐོ་ཡོངས་རྫོགས་འདོན་སྤེལ།';

  @override
  String get invoiceMgmtFilterByDateRangeLabel =>
      'ཡང་ན་ཚེས་གྲངས་ཁྱོན་ལས་འདེམས་སྒྲུག';

  @override
  String get invoiceMgmtFromDateLabel => 'འགོ་ཚེས།';

  @override
  String get invoiceMgmtToDateLabel => 'མཐའ་ཚེས།';

  @override
  String get invoiceMgmtDateRangeInvalidMessage =>
      'མཐའ་ཚེས་འགོ་ཚེས་ལས་རྗེས་སུ་དགོས།';

  @override
  String get actionExport => 'འདོན་སྤེལ།';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཟིན་ཐོ་ $count ཐད་ $path ལ་འདོན་སྤེལ་ཟིན',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return 'འདོན་སྤེལ་མི་ཐུབ: $error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་ $count ཕྱགས་སྣོད་དུ་སྤོ་དགོས་སམ།',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་ $count ཕྱགས་སྣོད་དུ་སྤོས་ཟིན།',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return 'ཚང་མར་སུབ་པ་མི་ཐུབ: $error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་ $count CSV ལ་འདོན་སྤེལ་ཟིན',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'CSV འདོན་སྤེལ་མི་ཐུབ: $error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => 'PDF ཕབ་ལེན།';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PDF $count ག་འདྲ་ཞིག་ཉར་འདོད་དམ།',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => 'ཡིག་སྣོད་དུ་ཉར།';

  @override
  String get invoiceMgmtSaveAsZipLabel => 'ZIP སུ་ཉར།';

  @override
  String get invoiceMgmtChooseFolderDialogTitle =>
      'PDF ཉར་ས་ཡི་ཡིག་སྣོད་འདེམས།';

  @override
  String get invoiceMgmtSaveZipDialogTitle => 'ZIP ཡིག་ཆ་ཉར།';

  @override
  String get invoiceMgmtCreatingZipLabel => 'ZIP བཟོ་བཞིན་པ།';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => 'PDF བཟོ་བཞིན་པ།';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PDF $count སྤྲོད་བཞིན་པ...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return '$path ལ་ཉར་ཟིན།';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'PDF འདོན་སྤེལ་མི་ཐུབ: $error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle => 'འདེམས་སྒྲུག་གིས་ PDF ཕབ་ལེན།';

  @override
  String get invoiceMgmtByDateLabel => 'ཚེས་གྲངས་ཀྱིས།';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => 'ཁྲལ་ཤོག་གྲངས་ཀྱིས།';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => 'འགོ་ཁྲལ་ཤོག་ #';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => 'མཐའ་ཁྲལ་ཤོག་ #';

  @override
  String get invoiceMgmtCheckCountLabel => 'གྲངས་ཀ་ཞིབ་བཤེར།';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return 'ཁྲལ་ཤོག་ $count — ཚད་ $limit ལས་བརྒལ།';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་ $count མཐུན་པ།',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return 'རེ་རེར་ PDF མང་ཤོས་ $limit། འདེམས་སྒྲུག་ཆུང་དུ་བཟོས།';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage =>
      'འདེམས་སྒྲུག་འདིར་ཁྲལ་ཤོག་མི་འདུག';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return 'འདེམས་སྒྲུག་གིས་ཁྲལ་ཤོག་ $count བྱུང་། མང་ཤོས་ $limit།';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => 'ཁྲལ་ཤོག་འདེམས་སྒྲུག';

  @override
  String get invoiceMgmtHideFullyPaidLabel => 'ཁྲལ་ཤོག་ཚང་མར་སྤྲད་ཟིན་པ་སྦེད།';

  @override
  String get invoiceMgmtPaymentStatusLabel => 'སྤྲོད་ཆད་གནས་བབ།';

  @override
  String get invoiceMgmtDueDateLabel => 'ཐག་ཆོད་ཚེས་གྲངས།';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => 'ཁྲལ་ཤོག་ཚེས་གྲངས་ཁྱོན།';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel => 'ཁྲལ་ཤོག་ # ཁྱོན།';

  @override
  String get invoiceMgmtFromHashLabel => 'འགོ་ #';

  @override
  String get invoiceMgmtToHashLabel => 'མཐའ་ #';

  @override
  String get actionReset => 'སླར་སྒྲིག';

  @override
  String get actionApply => 'སྤྱོད།';

  @override
  String get invoiceMgmtSortByTitle => 'གོ་རིམ་སྒྲིག';

  @override
  String get invoiceMgmtSearchHintMessage =>
      'ཁྲལ་ཤོག་ ID འམ་མཉོགས་མཁན་གྱི་མིང་གིས་འཚོལ...';

  @override
  String get invoiceMgmtFilterLabel => 'འདེམས་སྒྲུག';

  @override
  String get invoiceMgmtSortLabel => 'གོ་རིམ';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return 'བསྡོམས: $total   ·   ཤོག་ངོས་ $page/$totalPages';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '$count འདེམས་ཟིན།';
  }

  @override
  String get invoiceMgmtDeselectLabel => 'འདེམས་མེད་བཟོ།';

  @override
  String get invoiceMgmtSelectPageLabel => 'ཤོག་ངོས་འདེམས།';

  @override
  String get invoiceMgmtMarkPaidLabel => 'སྤྲད་ཟིན་པའི་རྟགས།';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDF';

  @override
  String get invoiceMgmtTrashLabel => 'ཕྱགས་སྣོད།';

  @override
  String get actionApplyPayment => 'སྤྲོད་ཆད་སྤྱོད།';

  @override
  String get invoiceMgmtMoreActionsTooltip => 'བྱ་བ་གཞན།';

  @override
  String get invoiceMgmtColSlNo => 'གྲངས།';

  @override
  String get invoiceMgmtColInvoiceCustomer => 'ཁྲལ་ཤོག་/མཉོགས་མཁན།';

  @override
  String get invoiceMgmtColTitle => 'མགོ་མིང་།';

  @override
  String get invoiceMgmtColDate => 'ཚེས་གྲངས།';

  @override
  String get invoiceMgmtColItems => 'རས་ཆས།';

  @override
  String get invoiceMgmtColStatus => 'གནས་བབ།';

  @override
  String get invoiceMgmtColOutstanding => 'ལྷག་ལུས།';

  @override
  String get invoiceMgmtColActions => 'བྱ་བ།';

  @override
  String get invoiceMgmtRowsPerPageLabel => 'ཤོག་ངོས་རེའི་ཐིག་གྲངས།';

  @override
  String get actionPrevious => 'སྔོན་མ།';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return 'ཤོག་ངོས་ $page / $totalPages';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return '\"$query\" ལ་འབྲས་བུ་མི་འདུག';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return '$type མི་འདུག';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return 'འདིར་མཐོང་ཆེད་ $type དང་པོ་བཟོས།';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage =>
      'འཚོལ་བ་འམ་འདེམས་སྒྲུག་བཟོ་བཅོས་གྱིས།';

  @override
  String get invoiceMgmtDownloadByRangeTooltip =>
      'ཚེས་གྲངས་འམ་ཁྲལ་ཤོག་ཁྱོན་གྱིས་ PDF ཕབ་ལེན།';

  @override
  String get invoiceMgmtExportAllCsvTooltip => 'ཡོངས་རྫོགས་ CSV ལ་འདོན་སྤེལ།';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel => 'ཁྱོན་གྱིས་ PDF ཕབ་ལེན།';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return '$type དོ་དམ།';
  }

  @override
  String get invoiceMgmtOverdueBadge => 'དུས་འགོར།';

  @override
  String get invoiceMgmtTodayBadge => 'དེ་རིང་།';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => 'ཕྱགས་སྣོད་སྟོང་པ།';

  @override
  String get actionRestore => 'སླར་གསོ།';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => 'རྟག་ཏུ་སུབ།';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return 'ཁྲལ་ཤོག་ #$number རྟག་ཏུ་སུབ་དགོས་སམ། འདི་ཕྱིར་ལོག་མི་ཐུབ།';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage => 'ཁྲལ་ཤོག་སླར་གསོས་ཟིན།';

  @override
  String get invoiceMgmtAnyDateLabel => 'གང་རུང་།';

  @override
  String get invoiceMgmtStatusAllLabel => 'ཚང་མ།';

  @override
  String get invoiceMgmtDueAllLabel => 'ཐག་ཆོད་ཚང་མ།';

  @override
  String get invoiceMgmtDueTodayLabel => 'དེ་རིང་ཐག་ཆོད།';

  @override
  String get invoiceMgmtDueWeekLabel => 'བདུན་ཕྲག་འདིའི་ཐག་ཆོད།';

  @override
  String get invoiceMgmtDueMonthLabel => 'ཟླ་བ་འདིའི་ཐག་ཆོད།';

  @override
  String get invoiceMgmtSortRecentlyAdded => 'གསར་དུ་སྣོན་པ།';

  @override
  String get invoiceMgmtSortOldestAdded => 'སྔར་མོས་སྣོན་པ།';

  @override
  String get invoiceMgmtSortDateNewest => 'ཁྲལ་ཤོག་ཚེས་ (གསར་ཤོས་སྔོན།)';

  @override
  String get invoiceMgmtSortDateOldest => 'ཁྲལ་ཤོག་ཚེས་ (རྙིང་ཤོས་སྔོན།)';

  @override
  String get invoiceMgmtSortCustomerAZ => 'མཉོགས་མཁན་མིང་ (A–Z)';

  @override
  String get invoiceMgmtSortCustomerZA => 'མཉོགས་མཁན་མིང་ (Z–A)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => 'སྤྲད་ཟིན་པའི་རྟགས།';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་ $count ཚང་མར་སྤྲད་ཟིན་པའི་རྟགས་བརྒྱབ་དགོས་སམ།',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n($count སྔར་སྤྲད་ཟིན — གོམ་པ་གྱོགས་འགྲོ།)';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage =>
      'འདེམས་པའི་ཁྲལ་ཤོག་ཚང་མ་སྔར་ཚང་མར་སྤྲད་ཟིན།';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་ $count སྤྲད་ཟིན་པའི་རྟགས་བརྒྱབ་ཟིན།',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return 'སྤྲད་ཟིན་པའི་རྟགས་རྒྱག་མི་ཐུབ: $error';
  }

  @override
  String get fieldNameLabel => 'མིང་།';

  @override
  String get customerMgmtEditCustomerTitle => 'མཉོགས་མིར་ཞུ་བཅོས།';

  @override
  String get customerMgmtViewCustomerTitle => 'མཉོགས་མི་ལྟ་བ།';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / ཝི་ཨེ་ཊི་ཨང་གྲངས།';
  }

  @override
  String get customerMgmtUpdatedMessage => 'མཉོགས་མི་གསར་བཅོས་ལེགས་གྲུབ་བྱུང་།';

  @override
  String fieldRequiredMessage(String field) {
    return '$field བཀོད་རོགས།';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => 'བསུབ་པ་ངེས་གཏན།';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return 'ཁྱེད་ \"$name\" བསུབ་འདོད་པ་ངེས་གཏན་ཡིན་ནམ།';
  }

  @override
  String get customerMgmtDeletedMessage => 'མཉོགས་མི་ལེགས་གྲུབ་ངང་བསུབས་སོང་།';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle => 'དཔེ་མཚོན་ CSV ཉར་ཚགས།';

  @override
  String get customerMgmtSampleSavedMessage =>
      'དཔེ་མཚོན་ CSV ལེགས་གྲུབ་ངང་ཉར་ཚགས་བྱུང་།';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return 'དཔེ་མཚོན་ཉར་ཚགས་བྱེད་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle => 'CSV ནས་མཉོགས་མི་ནང་འདྲེན།';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      'ཁྱེད་ཀྱི་ CSV ཡིག་ཆར་འོག་གི་སྟེང་མིང་དེ་དག་བེད་སྤྱོད་དགོས (ཡིག་འབྲུ་ཟུར་མི་ཆོག, གོ་རིམ་གང་རུང):';

  @override
  String get customerMgmtCsvColColumnHeader => 'སྟེང་།';

  @override
  String get customerMgmtCsvColRequiredHeader => 'དགོས་ངེས།';

  @override
  String get customerMgmtCsvColDescriptionHeader => 'འགྲེལ་བཤད།';

  @override
  String get commonYesLabel => 'རེད།';

  @override
  String get commonNoLabel => 'མིན།';

  @override
  String get customerMgmtCsvDescName => 'མཉོགས་མིའི་མིང་ཚང་མ།';

  @override
  String get customerMgmtCsvDescEmail => 'གློག་འཕྲིན་ཁ་བྱང་།';

  @override
  String get customerMgmtCsvDescPhone => 'ཁ་པར་ཨང་གྲངས།';

  @override
  String get customerMgmtCsvDescAddress => 'ཁ་བྱང་ཚང་མ།';

  @override
  String get customerMgmtCsvDescBusinessName => 'ཚོང་ལས་མིང་།';

  @override
  String get customerMgmtCsvDescTaxNumber =>
      'ཁྲལ་ / ཝི་ཨེ་ཊི་ / GSTIN ཨང་གྲངས།';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return 'ནང་འདྲེན་རེ་རེར་མང་མཐའ་གྲངས་ $max ཡོད།';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      'ཟླ་འདྲ་གློག་འཕྲིན་ཡང་ན་ཁ་པར་ཐོག་ནས་རྙེད་བྱེད། རེ་རེར་ཚབ་བརྗེ་བྱེད་དམ་གོམ་པ་གྱོགས་བྱེད་དྲི་བ་བྱེད།';

  @override
  String get customerMgmtCsvMissingNameNote =>
      'མིང་མེད་པའི་ཐིག་ཕྲེང་གོམ་པ་གྱོགས་ཤིང་མཐའ་མར་སྙན་ཞུ་བྱེད།';

  @override
  String get customerMgmtCsvEncodingNote =>
      'UTF-8 ཨིན་ཀོ་ཌིང་བཀོལ་སྤྱོད་གནང་རོགས། Excel BOM རང་འགུལ་གྱིས་སྒྲིག་ཐུབ།';

  @override
  String get customerMgmtDownloadSampleCsvButton => 'དཔེ་མཚོན་ CSV ཕབ་ལེན།';

  @override
  String get customerMgmtChooseFileButton => 'ཡིག་ཆ་འདེམས།';

  @override
  String get customerMgmtSelectCsvDialogTitle => 'མཉོགས་མིའི་ CSV འདེམས།';

  @override
  String get customerMgmtCsvEmptyMessage => 'CSV ཡིག་ཆ་སྟོང་པ་རེད།';

  @override
  String get customerMgmtCsvMissingNameColumnMessage =>
      'CSV ནང་དགོས་ངེས་ཀྱི་སྟེང་ \"name\" མེད།';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return 'སྟེང་མི་ཤེས་པ་ \"$col\"། རེ་བ་: $expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'CSV ལ་ཐིག་ཕྲེང་ $count ཡོད། མང་མཐའ་ $max རེད། ཡིག་ཆ་ཁ་བགོས་གནང་རོགས།';
  }

  @override
  String get customerMgmtImportingTitle => 'མཉོགས་མི་ནང་འདྲེན་བྱེད་བཞིན།';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཟླ་འདྲ་ཞིབ་བཤེར་དང་ཐིག་ཕྲེང་ $count ར་སྤྲོད་བྱེད་བཞིན...',
      one: 'ཟླ་འདྲ་ཞིབ་བཤེར་དང་ཐིག་ཕྲེང་ 1 ར་སྤྲོད་བྱེད་བཞིན...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return 'ཐིག་ཕྲེང་ $n: མིང་མེད་— གོམ་པ་གྱོགས་སོང་།';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return 'CSV ཀློག་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get customerMgmtImportPreviewTitle => 'ནང་འདྲེན་སྔོན་བལྟ།';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'གསར་པ་ $count',
      one: 'གསར་པ་ 1',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཟླ་འདྲ་ $count',
      one: 'ཟླ་འདྲ་ 1',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ནོར་འཁྲུལ་ $count',
      one: 'ནོར་འཁྲུལ་ 1',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel =>
      'ཟླ་འདྲ་ (གློག་འཕྲིན་ཡང་ན་ཁ་པར་ཐོག་ནས་མཐུན་པ)：';

  @override
  String get customerMgmtOverwriteAllButton => 'ཚང་མ་ཚབ་བརྗེ།';

  @override
  String get customerMgmtSkipAllButton => 'ཚང་མ་གོམ་པ་གྱོགས།';

  @override
  String get customerMgmtOverwriteLabel => 'ཚབ་བརྗེ།';

  @override
  String get customerMgmtSkippedRowsLabel =>
      'གོམ་པ་གྱོགས་པའི་ཐིག་ཕྲེང་ (ནོར་འཁྲུལ)：';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'མཉོགས་མི་ $total ནང་འདྲེན་བྱེད།',
      one: 'མཉོགས་མི་ 1 ནང་འདྲེན་བྱེད།',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return '$total ནང་འདྲེན།';
  }

  @override
  String get customerMgmtDeleteAllTitle => 'མཉོགས་མི་ཚང་མ་བསུབ།';

  @override
  String get customerMgmtNoCustomersToDeleteMessage =>
      'བསུབ་རྒྱུའི་མཉོགས་མི་མེད།';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'འདིས་མཉོགས་མི་ $count གཏན་གྱིས་བསུབ་ངེས། ད་ཡོད་ཁྲལ་ཤོག་ལ་ཤུགས་རྐྱེན་མེད། འདི་ཕྱིར་ལོག་མི་ཐུབ།',
      one:
          'འདིས་མཉོགས་མི་ 1 གཏན་གྱིས་བསུབ་ངེས། ད་ཡོད་ཁྲལ་ཤོག་ལ་ཤུགས་རྐྱེན་མེད། འདི་ཕྱིར་ལོག་མི་ཐུབ།',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => 'ཚང་མ་བསུབ།';

  @override
  String get customerMgmtAllDeletedMessage => 'མཉོགས་མི་ཚང་མ་བསུབས་སོང་།';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return 'མཉོགས་མི་བསུབ་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => 'མཉོགས་མིའི་ CSV ཉར་ཚགས།';

  @override
  String get customerMgmtCsvExportedMessage =>
      'CSV ལེགས་གྲུབ་ངང་ཕྱིར་འདྲེན་བྱུང་།';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return 'CSV ཕྱིར་འདྲེན་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => 'མཉོགས་མིའི་ PDF ཉར་ཚགས།';

  @override
  String get customerMgmtPdfExportedMessage =>
      'PDF ལེགས་གྲུབ་ངང་ཕྱིར་འདྲེན་བྱུང་།';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return 'PDF ཕྱིར་འདྲེན་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => 'མཉོགས་མི་བསྡོམས།';

  @override
  String get customerMgmtAllCustomersSubtitle => 'མཉོགས་མི་ཚང་མ།';

  @override
  String get customerMgmtBusinessesLabel => 'ཚོང་ལས།';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle => 'ཐོ་འགོད་ཚོང་ལས།';

  @override
  String get customerMgmtIndividualsLabel => 'སྒེར་མི།';

  @override
  String get customerMgmtIndividualCustomersSubtitle => 'སྒེར་མི་མཉོགས་མི།';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '$taxWord ཐོ་འགོད་ཡོད།';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return '$taxWord ཨང་གྲངས་དང་བཅས།';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return '$taxWord མེད་པ།';
  }

  @override
  String get customerMgmtTitle => 'མཉོགས་མི་དོ་དམ།';

  @override
  String get customerMgmtSubtitle =>
      'ཁྱེད་ཀྱི་མཉོགས་མི་དང་འབྲེལ་གནས་ཞིབ་ཕྲ་དོ་དམ།';

  @override
  String get actionImport => 'ནང་འདྲེན།';

  @override
  String get customerMgmtExportPdfMenuLabel => 'PDF ཕྱིར་འདྲེན།';

  @override
  String get customerMgmtNewCustomerButton => 'མཉོགས་མི་གསར་པ།';

  @override
  String get customerMgmtSortNameAZ => 'མིང་ A-Z';

  @override
  String get customerMgmtSortNameZA => 'མིང་ Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID (རྙིང་ཤོས་ཐོག་མར)';

  @override
  String get customerMgmtSortIdNewest => 'ID (གསར་ཤོས་ཐོག་མར)';

  @override
  String get customerMgmtSortOutstandingHighLow => 'ལྷག་ལུས། (མང་ཤོས་ཐོག་མར)';

  @override
  String get customerMgmtSortOutstandingLowHigh => 'ལྷག་ལུས། (ཉུང་ཤོས་ཐོག་མར)';

  @override
  String get customerMgmtWithOutstandingLabel => 'ལྷག་ལུས་ཡོད་པ';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return 'མིང་, ཚོང་ལས་, ཁ་པར་, $taxWord, གློག་འཕྲིན་ཐོག་ནས་མཉོགས་མི་འཚོལ...';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return '$taxWord གནས་ཚུལ་ཚང་མ།';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '$taxWord ཐོ་འགོད་ཡོད།';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return 'སྒྲིག་འགོད: $label';
  }

  @override
  String get customerMgmtColumnsLabel => 'སྟེང་།';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / ཝི་ཨེ་ཊི་ཨང་།';
  }

  @override
  String get customerMgmtHideStatCardsTooltip => 'ཨང་གྲངས་ཤོག་ལེབ་སྦེད།';

  @override
  String get customerMgmtShowStatCardsTooltip => 'ཨང་གྲངས་ཤོག་ལེབ་སྟོན།';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get customerMgmtColSlNo => 'ཨང་གྲངས།';

  @override
  String get customerMgmtColNameBusiness => 'མིང་ / ཚོང་ལས།';

  @override
  String get customerMgmtColPhone => 'ཁ་པར།';

  @override
  String get customerMgmtColEmail => 'གློག་འཕྲིན།';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / ཝི་ཨེ་ཊི་ཨང་།';
  }

  @override
  String get customerMgmtColAddress => 'ཁ་བྱང་།';

  @override
  String get customerMgmtColActions => 'བྱ་བ།';

  @override
  String get customerMgmtViewStatementTooltip => 'རེ་ཁུངས་ལྟ་བ (སྙན་ཞུའི་ནང་)';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return '$total ནང་ནས་ $from ནས་ $to བར་སྟོན་བཞིན།';
  }

  @override
  String get customerMgmtRowsPerPageLabel => 'ཤོག་ངོས་རེར་ཐིག་ཕྲེང་།';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return '$totalPages ནང་ནས།';
  }

  @override
  String get customerMgmtAddAnotherLabel => 'ཉར་ཚགས་རྗེས་གཞན་ཞིག་སྣོན།';

  @override
  String get customerMgmtSaveCustomerButton => 'མཉོགས་མི་ཉར་ཚགས།';

  @override
  String get customerMgmtAddFirstCustomerSubtitle =>
      'འགོ་བཙུགས་ཆེད་མཉོགས་མི་དང་པོ་སྣོན་རོགས།';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle =>
      'ཁྱེད་ཀྱི་འཚོལ་བཤེར་བཟོ་བཅོས་གནང་རོགས།';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return 'མཉོགས་མི་འདྲེན་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get customerMgmtAddedMessage => 'མཉོགས་མི་ལེགས་གྲུབ་ངང་སྣོན་སོང་།';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return 'མཉོགས་མི་ཉར་ཚགས་སྐབས་ནོར་འཁྲུལ།: $error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'མཉོགས་མི་ $count ལེགས་གྲུབ་ངང་ནང་འདྲེན་བྱུང་།',
      one: 'མཉོགས་མི་ 1 ལེགས་གྲུབ་ངང་ནང་འདྲེན་བྱུང་།',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return 'ནང་འདྲེན་ནོར་འཁྲུལ།: $error';
  }

  @override
  String get taxWordGst => 'ཇི་ཨེསི་ཊི།';

  @override
  String get taxWordTax => 'ཁྲལ།';

  @override
  String get commonMoreLabel => 'མང་བ།';

  @override
  String get productMgmtSellingAtLossTitle => 'གླ་ཆག་ཐོག་ཚོང་བ།';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return 'ཉོ་གོང ($purchase) ཚོང་གོང ($sale) ལས་མཐོ་བ་རེད། ཡིན་ནའང་ཉར་ཚགས་བྱེད་དམ།';
  }

  @override
  String get actionSaveAnyway => 'ཡིན་ནའང་ཉར་ཚགས།';

  @override
  String get productMgmtAdvancedInformationLabel => 'མཐོ་རིམ་ཆ་འཕྲིན།';

  @override
  String get productMgmtStorageLocationLabel => 'ཉར་ཚགས་ས་ཆ།';

  @override
  String get productMgmtContainerNumberLabel => 'སྣོད་ཨང་།';

  @override
  String get productMgmtBatchNumberLabel => 'ཚན་ཨང་།';

  @override
  String get productMgmtExpiryDateLabel => 'དུས་ཚད་ཟིན་ཉིན།';

  @override
  String get productMgmtManufactureDateLabel => 'བཟོ་སྐྲུན་ཉིན་ཚེས།';

  @override
  String get productMgmtSupplierNameLabel => 'སྐྱེལ་འདྲེན་པའི་མིང་།';

  @override
  String get productMgmtSkuCodeLabel => 'SKU ཨང་གྲངས།';

  @override
  String get productMgmtNotesLabel => 'ཟིན་བྲིས།';

  @override
  String get fieldEnterValidPriceMessage => 'ནུས་ལྡན་གྱི་གོང་ཚད་འཇུག་རོགས།';

  @override
  String get fieldEnterValidStockMessage => 'ནུས་ལྡན་གྱི་ཉར་ཚད་འཇུག་རོགས།';

  @override
  String get fieldTaxRangeMessage => 'ཁྲལ་ནི 0-100 བར་ཡིན་དགོས།';

  @override
  String get productMgmtImportProductsCsvTitle =>
      'CSV ནས་ཐོན་ཟོག་ནང་འདྲེན་བྱེད།';

  @override
  String get productMgmtCsvDescName => 'ཐོན་ཟོག་མིང་།';

  @override
  String get productMgmtCsvDescPrice => 'ཆ་ཚན་གོང་ཚད (ཨང་ཀི)';

  @override
  String get productMgmtCsvDescHsnCode => 'HSN / SAC ཨང་གྲངས།';

  @override
  String get productMgmtCsvDescDescription => 'འགྲེལ་བཤད་ཐུང་ངུ།';

  @override
  String get productMgmtCsvDescTaxRate => 'ཁྲལ% (0–100), སྔར་སྒྲིག 0';

  @override
  String get productMgmtCsvDescStock => 'ཉར་ཚད, སྔར་སྒྲིག 0';

  @override
  String get productMgmtCsvDescType =>
      '\"product\" ཡང་ན \"service\", སྔར་སྒྲིག product';

  @override
  String get productMgmtCsvDescDefaultDiscount =>
      'ཐད་ཀར་ཆག་གོང (དངུལ), སྔར་སྒྲིག 0';

  @override
  String get productMgmtCsvDescPurchasePrice => 'ཉོ་གོང (ཨང་ཀི), སྔར་སྒྲིག 0';

  @override
  String get productMgmtCsvDescAliasName => 'PDF ལ་ཐོན་ཁུངས་སྐད་ཀྱི་མིང་སྟོན།';

  @override
  String get productMgmtCsvDescUnit => 'ཚད་གཞི (kg, bag, pcs), སྔར་སྒྲིག pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock =>
      'ཚད་མེད་ཉར་ཚད་ལ 1/true, སྔར་སྒྲིག 0';

  @override
  String get productMgmtCsvDescPriceIncludesTax =>
      'གོང་ཚད་ནང་ཁྲལ་ཚུད་ན 1/true, སྔར་སྒྲིག 0';

  @override
  String get productMgmtCsvDescStorageLocation => 'མཛོད་ཁང་། /དབང་ཤོག་ས་ཆ།';

  @override
  String get productMgmtCsvDescContainerNumber => 'སྣོད། /སྒམ་ཨང་།';

  @override
  String get productMgmtCsvDescBatchNumber => 'ཚན། /ཚོགས་ཨང་།';

  @override
  String get productMgmtCsvDescExpiryDate => 'དུས་ཚད་ཟིན་ཉིན།';

  @override
  String get productMgmtCsvDescManufactureDate => 'བཟོ་སྐྲུན་ཉིན་ཚེས།';

  @override
  String get productMgmtCsvDescSupplierName => 'སྐྱེལ་འདྲེན་པའི་མིང་།';

  @override
  String get productMgmtCsvDescSkuCode => 'SKU ཨང་གྲངས།';

  @override
  String get productMgmtCsvDescNotes => 'ཡིག་ཟིན་ཐོར་བུ།';

  @override
  String get productMgmtCsvDuplicateNote =>
      'ཟུར་བཟོ་ཐོན་ཟོག་མིང (ཡིག་འབྲུ་ཆེ་ཆུང་མི་དབྱེ) ཐོག་ངོས་འཛིན་བྱེད། རེ་རེ་བཞིན་ཚབ་བཞག་གམ་གྱོགས་དགོས་མིན་དྲི་བ་བྱས་ངེས།';

  @override
  String get productMgmtCsvMissingRequiredNote =>
      'མིང་ངམ་གོང་ཚད་མེད་པའི་ཐིག་སྒྲིག་གྱོགས་ཤིང་སྙན་ཞུ་བྱེད།';

  @override
  String get productMgmtSelectCsvDialogTitle => 'ཐོན་ཟོག CSV འདེམས།';

  @override
  String get productMgmtCsvMissingPriceColumnMessage =>
      'CSV ནང་དགོས་པའི་ཐིག་མེད: \"price\"';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return 'ཐིག $n: ནུས་མེད་གོང་ཚད \"$price\" — གྱོགས་སོང་།';
  }

  @override
  String get productMgmtImportingTitle => 'ཐོན་ཟོག་ནང་འདྲེན་བྱེད་བཞིན་པ།';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel =>
      'ཟུར་བཟོ (མིང་གིས་མཐུན་སྒྲིག):';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'ཐོན་ཟོག $total ནང་འདྲེན་བྱེད་རྒྱུ།',
      one: 'ཐོན་ཟོག 1 ནང་འདྲེན་བྱེད་རྒྱུ།',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage => 'བསུབ་བྱར་ཐོན་ཟོག་མེད།';

  @override
  String get productMgmtDeleteAllTitle => 'ཐོན་ཟོག་ཡོངས་རྫོགས་བསུབ།';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'འདིས་ཐོན་ཟོག $count ཡོངས་རྫོགས་གཏན་འཁེལ་བསུབ་ངེས། ཡོད་བཞིན་པའི་ཁྲལ་ཤོག་ལ་ཤུགས་རྐྱེན་མེད། འདི་ཕྱིར་བསྒྱུར་མི་ཐུབ།',
      one:
          'འདིས་ཐོན་ཟོག 1 ཡོངས་རྫོགས་གཏན་འཁེལ་བསུབ་ངེས། ཡོད་བཞིན་པའི་ཁྲལ་ཤོག་ལ་ཤུགས་རྐྱེན་མེད། འདི་ཕྱིར་བསྒྱུར་མི་ཐུབ།',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage => 'ཐོན་ཟོག་ཡོངས་རྫོགས་བསུབས་ཟིན།';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return 'ཐོན་ཟོག་བསུབ་སྐབས་ནོར: $error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle => 'ཐོན་ཟོག CSV ཉར་ཚགས།';

  @override
  String get productMgmtExportToPdfTitle => 'PDF ལ་ཕྱིར་འདྲེན།';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return 'ད་ལྟའི་ཤོག་ངོས ($pageSize ཐོན་ཟོག) ཡང་ན ཐོན་ཟོག $allCount ཡོངས་རྫོགས་ཕྱིར་འདྲེན་བྱེད་དམ།';
  }

  @override
  String get productMgmtCurrentPageLabel => 'ད་ལྟའི་ཤོག་ངོས།';

  @override
  String get productMgmtAllProductsLabel => 'ཐོན་ཟོག་ཡོངས་རྫོགས།';

  @override
  String get productMgmtSaveProductsPdfDialogTitle => 'ཐོན་ཟོག PDF ཉར་ཚགས།';

  @override
  String get productMgmtTitle => 'ཐོན་ཟོག་དོ་དམ།';

  @override
  String get productMgmtSubtitle => 'ཁྱེད་ཀྱི་ཐོན་ཟོག་དང་ཞབས་ཏོག་དོ་དམ་བྱེད།';

  @override
  String get productMgmtNewProductButton => 'ཐོན་ཟོག་གསར་པ།';

  @override
  String get productMgmtSearchHint =>
      'མིང་། མིང་གཞན། HSN/SAC། SKU་ཐོག་ནས་ཐོན་ཟོག་འཚོལ...';

  @override
  String get productMgmtFilterByStockStatusTooltip =>
      'ཉར་ཚད་གནས་སྟངས་ཐོག་ནས་འཚག';

  @override
  String get productMgmtAllStockLevelsLabel => 'ཉར་ཚད་རིམ་པ་ཡོངས་རྫོགས།';

  @override
  String get productMgmtLowStockLabel => 'ཉར་ཚད་ཉུང་ངུ།';

  @override
  String get productMgmtLowStockTabLabel => 'ཉར་ཚད་ཉུང་ངུ།';

  @override
  String get productMgmtOutOfStockLabel => 'ཉར་ཚད་ཟད་སོང་།';

  @override
  String get productMgmtOutOfStockTabLabel => 'ཉར་ཚད་ཟད་སོང་།';

  @override
  String get productMgmtExpiredLabel => 'དུས་ཚད་ཟིན་པ།';

  @override
  String get productMgmtSortPriceLowHigh => 'གོང་ཚད་དམའ་མཐོ།';

  @override
  String get productMgmtSortPriceHighLow => 'གོང་ཚད་མཐོ་དམའ།';

  @override
  String get productMgmtSortStockLowHigh => 'ཉར་ཚད་དམའ་མཐོ།';

  @override
  String get productMgmtSortStockHighLow => 'ཉར་ཚད་མཐོ་དམའ།';

  @override
  String get productMgmtServicesTabLabel => 'ཞབས་ཏོག།';

  @override
  String get productMgmtColSlNo => 'ཨང་གྲངས།';

  @override
  String get productMgmtColNameAlias => 'མིང་། /མིང་གཞན།';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => 'གོང་ཚད།';

  @override
  String get productMgmtColPurchase => 'ཉོ།';

  @override
  String get productMgmtColStock => 'ཉར་ཚད།';

  @override
  String get productMgmtColTaxPercent => 'ཁྲལ %';

  @override
  String get productMgmtColExpiryDate => 'དུས་ཚད་ཉིན།';

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
    return 'ཐོན་ཟོག $total ནང་ནས $from ནས $to བར་སྟོན་བཞིན།';
  }

  @override
  String get productMgmtAddFirstProductSubtitle =>
      'འགོ་བཙུགས་པར་ཁྱེད་ཀྱི་ཐོན་ཟོག་དང་པོ་སྣོན་རོགས།';

  @override
  String get productMgmtColumnsBannerTitle => 'གསར་པ: ཐོན་ཟོག་ཆ་ཤས་སྒེར་སྒྲིག';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      'ཡང་སྙིང་ཐོ་གཞུང་ཞིག་ལ་ཆ་ཤས་གང་སྟོན་དགོས་མིན་འདེམས། སྒྲིག་འགོད > ཐོན་ཟོག་ཞིབ་ཕྲ་སྒེར་སྒྲིག';

  @override
  String get productMgmtConfigureAction => 'སྒྲིག་འགོད།';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return '$type གསར་པ་སྣོན།';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle =>
      'ཐོན་ཟོག་ཞིབ་ཕྲ་འཇུག་རོགས།';

  @override
  String get productMgmtSaveProductButton => 'ཐོན་ཟོག་ཉར་ཚགས།';

  @override
  String get productMgmtAliasNameLabel => 'མིང་གཞན (ཁྲལ་ཤོག PDF ལ)';

  @override
  String get productMgmtAliasHelperText =>
      'PDF ཁྲལ་ཤོག་ཁོ་ནར་བེད་སྤྱོད་བྱེད་པའི་གདམ་ཁ་ཅན་གྱི་ཐོན་ཁུངས་སྐད་ཀྱི་མིང་སྟོན།';

  @override
  String get productMgmtDescriptionLabel => 'འགྲེལ་བཤད།';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => 'ཚོང་གོང་།';

  @override
  String get productMgmtPurchasePriceLabel => 'ཉོ་གོང་།';

  @override
  String get productMgmtDefaultDiscountLabel => 'སྔར་སྒྲིག་ཆག་གོང་།';

  @override
  String get productMgmtTaxPercentLabel => 'ཁྲལ (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel => 'རས་རེར་ཁྲལ་ཐབས་ཁོ་ན།';

  @override
  String get productMgmtSectionGeneral => 'སྤྱིར་བཏང་།';

  @override
  String get productMgmtSectionPricing => 'གོང་ཚད་གཞིགས་འཛིན།';

  @override
  String get productMgmtSectionInventory => 'ཉར་ཚད་ཐོ་གཞུང་།';

  @override
  String get productMgmtUnlimitedStockLabel => 'ཚད་མེད་ཉར་ཚད།';

  @override
  String get productMgmtTrackInfiniteStockSubtitle =>
      'ཐོན་ཟོག་འདིའི་ཚད་མེད་ཉར་ཚད་རྗེས་འདེད།';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      'བརྡ་འཕྲིན: ཞིབ་ཕྲ་མང་སྣོན་པར་ཐིག་ནས་སྒེར་སྒྲིག་ཆ་ཤས་ལྕོགས་ཅན་བཟོ།';

  @override
  String get productMgmtEditProductTitle => 'ཐོན་ཟོག་ཞུ་དག';

  @override
  String get productMgmtViewProductTitle => 'ཐོན་ཟོག་ལྟ།';

  @override
  String get productMgmtUpdateProductDetailsSubtitle =>
      'ཐོན་ཟོག་ཞིབ་ཕྲ་གསར་སྒྱུར།';

  @override
  String get productMgmtProductDetailsSubtitle => 'ཐོན་ཟོག་ཞིབ་ཕྲ།';

  @override
  String get productMgmtUpdatedMessage =>
      'ཐོན་ཟོག /ཞབས་ཏོག་ལེགས་པར་གསར་སྒྱུར་བྱུང་།';

  @override
  String get productMgmtDeleteProductButton => 'ཐོན་ཟོག་བསུབ།';

  @override
  String get productMgmtSaveChangesButton => 'བཟོ་བཅོས་ཉར་ཚགས།';

  @override
  String get fieldUnitLabel => 'ཚད་གཞི།';

  @override
  String get productMgmtAddedMessage => 'ཐོན་ཟོག་ལེགས་པར་སྣོན་ཟིན།';

  @override
  String productMgmtAddErrorMessage(String error) {
    return 'ཐོན་ཟོག་སྣོན་སྐབས་ནོར: $error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return 'ཐོན་ཟོག་འདྲེན་སྐབས་ནོར: $error';
  }

  @override
  String get productMgmtDeletedMessage => 'ཐོན་ཟོག་ལེགས་པར་བསུབས་ཟིན།';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཐོན་ཟོག $count ལེགས་པར་ནང་འདྲེན་བྱུང་།',
      one: 'ཐོན་ཟོག 1 ལེགས་པར་ནང་འདྲེན་བྱུང་།',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => 'བརྒྱུད་ཡོངས་རྫོགས།';

  @override
  String get productMgmtTangibleProductsSubtitle => 'ལག་ཟིན་ཐོན་ཟོག';

  @override
  String get productMgmtNonTangibleServicesSubtitle => 'ལག་མི་ཟིན་པའི་ཞབས་ཏོག';

  @override
  String get productMgmtNeedAttentionSubtitle => 'དོ་སྣང་དགོས།';

  @override
  String get productMgmtProductNameLabel => 'ཐོན་ཟོག་མིང་།';

  @override
  String get productMgmtPriceLabel => 'གོང་ཚད།';

  @override
  String get actionClear => 'གསལ་བོར་བཟོ།';

  @override
  String get reportsAboutConversionRateTitle => 'བསྒྱུར་མང་ཚད་སྐོར།';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return 'རྙིང་པའི་ལེན་འོས ($count)';
  }

  @override
  String get reportsAllCurrenciesLabel => 'དངུལ་རིགས་ཚང་མ།';

  @override
  String get reportsAvgInvoiceValueLabel => 'ཁྲལ་ཤོག་ཐུན་མོང་གོང་ཚད།';

  @override
  String get reportsBalanceColumnLabel => 'ལྷག་མ།';

  @override
  String get reportsBilledLabel => 'ཁྲལ་ཤོག་བཏང་བ།';

  @override
  String get reportsBucket0to30Label => '༠–༣༠ཉིན།';

  @override
  String get reportsBucket31to60Label => '༣༡–༦༠ཉིན།';

  @override
  String get reportsBucket61to90Label => '༦༡–༩༠ཉིན།';

  @override
  String get reportsBucket90PlusLabel => '༩༠+ཉིན།';

  @override
  String get reportsBucketLabel => 'སྡེ་ཚན།';

  @override
  String get reportsClosingLabel => 'མཇུག་སྒྲིལ།';

  @override
  String get reportsCogsColumnLabel => 'ཚོང་གྲོགས་བརྒྱུད་རིན།';

  @override
  String get reportsConversionRateExplanationBody =>
      'བསྒྱུར་མང་ཚད། = བཟོས་པའི་ཁྲལ་ཤོག ÷ སྤེལ་བའི་གོང་ཚིགས་ x ༡༠༠།\nཚད་གྲངས་༡༠༠% ལས་མཐོ་ན་དུས་ཡུན་དེའི་ནང་གོང་ཚིགས་ལས་ཁྲལ་ཤོག་མང་བ་བཟོས་པའི་དོན་དག་ཡིན།\n\nམཛོད་དོན། འདི་དུས་ཡུན་ཐོག་གི་ཚད་གྲངས་ཤིག་ཡིན་གྱི་སོ་སོའི་གོང་ཚིགས་ནས་ཁྲལ་ཤོག་བར་གྱི་རྗེས་འདེད་མིན།';

  @override
  String get reportsConversionRateLabel => 'བསྒྱུར་མང་ཚད།';

  @override
  String get reportsCreditColumnLabel => 'སྐྱེལ་འདེབས།';

  @override
  String get reportsCurrencySectionLabel => 'དངུལ་རིགས།';

  @override
  String get reportsCurrentBucketLabel => 'ད་ལྟའི།';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return 'ད་ལྟ་འདེམས་པའི་དངུལ་རིགས ($currency)';
  }

  @override
  String get reportsCustomRangeLabel => 'རང་སྒྲིག་ཁྱོན་ཚད།';

  @override
  String get reportsDailySalesProfitTitle => 'ཉིན་རེའི་ཚོང་འབྲེལ་དང་ཁེ་སྐྱེད།';

  @override
  String reportsDaysCountLabel(int d) {
    return 'ཉིན་$d';
  }

  @override
  String get reportsDaysOverdueLabel => 'དུས་འགོར་ཉིན་གྲངས།';

  @override
  String get reportsDebitColumnLabel => 'འབུལ་འདེབས།';

  @override
  String get reportsDiscountGivenColumnLabel => 'སྤྲོད་པའི་ཉུང་བཅོལ།';

  @override
  String get reportsExportCsvLabel => 'CSV ཕྱིར་འདྲེན།';

  @override
  String reportsFilteredToDateLabel(String date) {
    return '$date ལ་འཚང་བཤེར་བྱས།';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'དུས་ཡུན་ནང་ཁྲལ་ཤོག་$countString · $scope',
      one: 'དུས་ཡུན་ནང་ཁྲལ་ཤོག་༡ · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => 'ཁྲལ་ཤོག་ཨང་།';

  @override
  String get reportsInvoicedLabel => 'ཁྲལ་ཤོག་བཏང་བ།';

  @override
  String get reportsInvoicesColumnLabel => 'ཁྲལ་ཤོག་ཚོ།';

  @override
  String get reportsInvoicesInPeriodLabel => 'དུས་ཡུན་ནང་ཁྲལ་ཤོག';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get reportsMarginColumnLabel => 'ཟོང་ཆད།';

  @override
  String get reportsMaxRangeOneYearMessage =>
      'ཁྱོན་ཚད་མང་ཤོས་ལོ་༡། མཇུག་ཚེས་ཚད་བཅད་བྱས།';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage =>
      'ཁྱོན་ཚད་མང་ཤོས་ཉིན་༣༡། མཇུག་ཚེས་ཚད་བཅད་བྱས།';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'དུས་ཡུན་འདིར་བཙོང་བའི་རས་ཟོག་$countཀྱི་ཉོ་རིན་མ་བཀོད་པས་ཉོ་རིན་མ་སྣོན་བར་ཁེ་སྐྱེད/ཟོང་ཆད་དམའ་རུ་སྟོན།',
      one:
          'དུས་ཡུན་འདིར་བཙོང་བའི་རས་ཟོག་༡ཀྱི་ཉོ་རིན་མ་བཀོད་པས་ཉོ་རིན་མ་སྣོན་བར་ཁེ་སྐྱེད/ཟོང་ཆད་དམའ་རུ་སྟོན།',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => 'ཟླ་བ་དང་ལོ།';

  @override
  String get reportsMonthlyRevenueTrendTitle => 'ཟླ་རེའི་འབབ་འོང་འགྱུར་རིམ།';

  @override
  String get reportsNavDailyReportLabel => 'ཉིན་རེའི་སྙན་ཞུ།';

  @override
  String get reportsNavInvoiceStatusLabel => 'ཁྲལ་ཤོག་གནས་ཚུལ།';

  @override
  String get reportsNavReceivablesLabel => 'ལེན་འོས་དངུལ།';

  @override
  String get reportsNavRevenueLabel => 'འབབ་འོང་།';

  @override
  String get reportsNavTaxLabel => 'ཁྲལ།';

  @override
  String get reportsNoCustomerDataMessage => 'དུས་ཡུན་འདིར་ཉོ་མཁན་གནས་ཚུལ་མེད།';

  @override
  String get reportsNoCustomersMatchSearchMessage =>
      'འཚོལ་བཤེར་འདིར་མཐུན་པའི་ཉོ་མཁན་མེད།';

  @override
  String get reportsNoCustomersWithInvoicesMessage =>
      'ཁྲལ་ཤོག་ཡོད་པའི་ཉོ་མཁན་མེད།';

  @override
  String get reportsNoDueDateLabel => 'དུས་ཚེས་མེད།';

  @override
  String get reportsNoInvoiceDataMessage => 'དུས་ཡུན་འདིར་ཁྲལ་ཤོག་གནས་ཚུལ་མེད།';

  @override
  String get reportsNoInvoicesInPeriodMessage => 'དུས་ཡུན་འདིར་ཁྲལ་ཤོག་མེད།';

  @override
  String get reportsNoInvoicesMatchFilterMessage =>
      'འཚང་བཤེར་འདིར་མཐུན་པའི་ཁྲལ་ཤོག་མེད།';

  @override
  String get reportsNoOutstandingInvoicesMessage => 'ལྷག་བཅོལ་ཁྲལ་ཤོག་མེད།';

  @override
  String get reportsNoProductDataMessage => 'དུས་ཡུན་འདིར་ཐོན་རྫས་གནས་ཚུལ་མེད།';

  @override
  String get reportsNoSalesInPeriodMessage => 'དུས་ཡུན་འདིར་ཚོང་འབྲེལ་མེད།';

  @override
  String get reportsNoStatementActivityMessage =>
      'ཉོ་མཁན་འདིའི་ཐོ་དེབ་བྱ་སྤྱོད་མེད།';

  @override
  String get reportsNoTaxableItemsMessage =>
      'དུས་ཡུན་འདིར་ཁྲལ་འབབ་ཅན་གྱི་རས་ཟོག་མེད།';

  @override
  String get reportsNoTransactionsMessage => 'དུས་ཡུན་འདིར་ལས་འགན་མེད།';

  @override
  String get reportsOpeningLabel => 'འགོ་བརྩམས།';

  @override
  String get reportsOverviewLabel => 'སྤྱི་མཐོང་།';

  @override
  String get reportsPaymentStatusBreakdownTitle => 'འབུལ་བའི་གནས་ཚུལ་དབྱེ་ཞིབ།';

  @override
  String get reportsPeriodSectionLabel => 'དུས་ཡུན།';

  @override
  String get reportsPresetLast30DaysLabel => 'འདས་པའི་ཉིན་༣༠';

  @override
  String get reportsPresetLast3MonthsLabel => 'འདས་པའི་ཟླ་༣';

  @override
  String get reportsPresetLast6MonthsLabel => 'འདས་པའི་ཟླ་༦';

  @override
  String get reportsPresetLastFYLabel => 'འདས་པའི་དངུལ་ལོ།';

  @override
  String get reportsPresetThisFYLabel => 'ད་ལྟའི་དངུལ་ལོ།';

  @override
  String get reportsPresetThisYearLabel => 'ད་ལྟའི་ལོ།';

  @override
  String get reportsProductServiceColumnLabel => 'ཐོན་རྫས/ཞབས་ཞུ།';

  @override
  String get reportsProfitLabel => 'ཁེ་སྐྱེད།';

  @override
  String get reportsQuotationsIssuedLabel => 'སྤེལ་བའི་གོང་ཚིགས།';

  @override
  String get reportsRankByProfitLabel => 'གོ་རིམ། ཁེ་སྐྱེད།';

  @override
  String get reportsRankByRevenueLabel => 'གོ་རིམ། འབབ་འོང་།';

  @override
  String get reportsReferenceColumnLabel => 'གཞི་བསྟུན།';

  @override
  String get reportsSalesColumnLabel => 'ཚོང་འབྲེལ།';

  @override
  String get reportsSaveCsvReportTitle => 'CSV སྙན་ཞུ་ཉར་ཚགས།';

  @override
  String get reportsSavePdfReportTitle => 'PDF སྙན་ཞུ་ཉར་ཚགས།';

  @override
  String reportsSavedAtMessage(String path) {
    return 'ཉར་ཚགས་བྱས། $path';
  }

  @override
  String get reportsSelectCustomerTitle => 'ཉོ་མཁན་འདེམས་རོགས།';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText =>
      'ཚེས་གྲངས་སམ་ཁྱོན་ཚད་འདེམས་རོགས (མང་ཤོས་ཉིན་༣༡)';

  @override
  String get reportsSelectDateRangeMaxYearHelpText =>
      'ཚེས་གྲངས་ཁྱོན་ཚད་འདེམས་རོགས (མང་ཤོས་ལོ་༡)';

  @override
  String get reportsShareLabel => 'ཆ་བགོས།';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return '$rangeཀྱི་ཁྲལ་ཤོག་སྟོན་བཞིན་ཡོད།';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end / $total';
  }

  @override
  String get reportsSlColumnLabel => 'ཨང་གྲངས།';

  @override
  String get reportsStatementsLabel => 'ཐོ་དེབ་ཚོ།';

  @override
  String get reportsTaxCollectedByRateTitle => 'ཐང་གིས་བསྡུས་པའི་ཁྲལ།';

  @override
  String get reportsTaxCollectedLabel => 'བསྡུས་པའི་ཁྲལ།';

  @override
  String get reportsTaxRateBucketsLabel => 'ཁྲལ་ཐང་སྡེ་ཚན།';

  @override
  String get reportsTodayLabel => 'དེ་རིང་།';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return 'འབབ་འོང་གིས་མཐོ་ཤོས་ཉོ་མཁན་$count';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return '$metricགིས་མཐོ་ཤོས་ཐོན་རྫས/ཞབས་ཞུ་$count';
  }

  @override
  String get reportsTotalBilledLabel => 'ཁྲལ་ཤོག་སྤྱིའི་གྲངས།';

  @override
  String get reportsTotalCollectedLabel => 'སྤྱིར་བསྡུས།';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ཁྲལ་ཤོག་སྤྱི་$countString',
      one: 'ཁྲལ་ཤོག་སྤྱི་༡',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => 'ཁྲལ་ཤོག་སྤྱིའི་གྲངས།';

  @override
  String get reportsTotalProfitLabel => 'ཁེ་སྐྱེད་སྤྱི།';

  @override
  String get reportsTotalTaxCollectedLabel => 'བསྡུས་པའི་ཁྲལ་སྤྱི།';

  @override
  String get reportsTypeColumnLabel => 'རིགས།';

  @override
  String get reportsUnitsSoldColumnLabel => 'བཙོང་བའི་ཆ་ཚན།';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return 'སྤྱོད་མཁན་ལོཌ་བྱེད་སྐབས་ནོར་འཁྲུལ: $error';
  }

  @override
  String get userMgmtAddedMessage => 'སྤྱོད་མཁན་ལེགས་གྲུབ་བསྣན་ཟིན།';

  @override
  String get userMgmtUpdatedMessage => 'སྤྱོད་མཁན་ལེགས་གྲུབ་གསར་སྒྱུར་བྱས་ཟིན།';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return 'སྤྱོད་མཁན་ཉར་ཚགས་སྐབས་ནོར་འཁྲུལ: $error';
  }

  @override
  String get userMgmtChangePasswordTitle => 'གསང་ཨང་བརྗེ་བ།';

  @override
  String userMgmtUserColonLabel(String username) {
    return 'སྤྱོད་མཁན: $username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => 'ད་ལྟའི་གསང་ཨང་།';

  @override
  String get userMgmtCurrentPasswordRequiredMessage => 'ད་ལྟའི་གསང་ཨང་དགོས།';

  @override
  String get userMgmtNewPasswordLabel => 'གསང་ཨང་གསར་པ།';

  @override
  String get userMgmtNewPasswordRequiredMessage => 'གསང་ཨང་གསར་པ་དགོས།';

  @override
  String get userMgmtPasswordMinLengthMessage =>
      'གསང་ཨང་ཉུང་མཐར་ཡིག་འབྲུ་དྲུག་དགོས།';

  @override
  String get userMgmtConfirmNewPasswordLabel => 'གསང་ཨང་གསར་པ་གཏན་འཁེལ་བྱེད།';

  @override
  String get userMgmtConfirmPasswordRequiredMessage =>
      'ཁྱེད་ཀྱི་གསང་ཨང་གཏན་འཁེལ་བྱེད་རོགས།';

  @override
  String get userMgmtPasswordsDoNotMatchMessage => 'གསང་ཨང་མཐུན་མིན།';

  @override
  String get userMgmtPasswordChangedMessage => 'གསང་ཨང་ལེགས་གྲུབ་བརྗེས་ཟིན།';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage => 'ད་ལྟའི་གསང་ཨང་ནོར་བ།';

  @override
  String get userMgmtDeleteUserTitle => 'སྤྱོད་མཁན་བསུབ།';

  @override
  String get userMgmtDeleteUserConfirmLabel =>
      'ཁྱེད་ཀྱིས་སྤྱོད་མཁན་འདི་བསུབ་ངེས་ཡིན་ནམ:';

  @override
  String get userMgmtActionCannotBeUndoneMessage =>
      'བྱ་བ་འདི་ཕྱིར་བསྒྱུར་མི་ཐུབ།';

  @override
  String get userMgmtDeletedMessage => 'སྤྱོད་མཁན་ལེགས་གྲུབ་བསུབས་ཟིན།';

  @override
  String get userMgmtCantDeleteOwnAccountMessage =>
      'ཁྱེད་རང་གི་ཁ་ཡིག་བསུབ་མི་ཐུབ།';

  @override
  String get userMgmtCantDemoteLastAdminMessage =>
      'You can\'t change the role of the only admin';

  @override
  String get userMgmtCantChangeOwnRoleMessage =>
      'You can\'t change your own role';

  @override
  String get userMgmtUsernameTakenMessage => 'That username is already taken';

  @override
  String get userMgmtDeleteSelectedTitle => 'འདེམས་ཟིན་པའི་སྤྱོད་མཁན་བསུབ་ངམ།';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'འདིས་སྤྱོད་མཁན $count རྟག་ཏུ་བསུབ་ངེས། བྱ་བ་འདི་ཕྱིར་བསྒྱུར་མི་ཐུབ།',
      one: 'འདིས་སྤྱོད་མཁན 1 རྟག་ཏུ་བསུབ་ངེས། བྱ་བ་འདི་ཕྱིར་བསྒྱུར་མི་ཐུབ།',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage =>
      'ཁྱེད་རང་གི་ཁ་ཡིག་འདེམས་ཚན་ནང་ཡོད་ཀྱང་གོམ་པ་གཅིག་གྱོགས་ངེས།';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'སྤྱོད་མཁན $count བསུབས་ཟིན།',
      one: 'སྤྱོད་མཁན 1 བསུབས་ཟིན།',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return 'སྤྱོད་མཁན་བསུབ་སྐབས་ནོར་འཁྲུལ: $error';
  }

  @override
  String get userMgmtTitle => 'སྤྱོད་མཁན་དོ་དམ།';

  @override
  String get userMgmtSubtitle =>
      'མཉེན་ཆས་སྤྱོད་མཁན་དང་འཛུལ་ཞུགས་དབང་ཚད་དོ་དམ་བྱེད།';

  @override
  String get userMgmtAddUserButton => 'སྤྱོད་མཁན་བསྣན།';

  @override
  String get userMgmtSearchHint => 'མིང་ངམ་ལས་འགན་གྱིས་སྤྱོད་མཁན་འཚོལ…';

  @override
  String get userMgmtFilterByRoleTooltip => 'ལས་འགན་གྱིས་འཚག';

  @override
  String get userMgmtAllRolesLabel => 'ལས་འགན་ཡོངས།';

  @override
  String get userMgmtAllLabel => 'ཡོངས།';

  @override
  String userMgmtRoleColonLabel(String role) {
    return 'ལས་འགན: $role';
  }

  @override
  String get userMgmtColUser => 'སྤྱོད་མཁན།';

  @override
  String get userMgmtColRole => 'ལས་འགན།';

  @override
  String get userMgmtYouBadgeLabel => 'ཁྱེད་རང་།';

  @override
  String get userMgmtDeleteSelectedMenuLabel => 'འདེམས་ཟིན་པ་བསུབ།';

  @override
  String get userMgmtBulkActionsTooltip => 'ཚོགས་བཅས་བྱ་བ།';

  @override
  String get userMgmtBulkActionsLabel => 'ཚོགས་བཅས་བྱ་བ།';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return 'སྤྱོད་མཁན $total ནང་ནས $from ནས $to བར་སྟོན།';
  }

  @override
  String get userMgmtNoUsersFoundMessage => 'སྤྱོད་མཁན་མི་རྙེད།';

  @override
  String get userMgmtAddNewUserTitle => 'སྤྱོད་མཁན་གསར་པ་བསྣན།';

  @override
  String get userMgmtEditUserTitle => 'སྤྱོད་མཁན་ཞུ་དག';

  @override
  String get userMgmtUsernameRequiredLabel => 'སྤྱོད་མཁན་མིང་ *';

  @override
  String get userMgmtEnterUsernameHint => 'སྤྱོད་མཁན་མིང་འཇུག';

  @override
  String get userMgmtUsernameRequiredMessage => 'སྤྱོད་མཁན་མིང་དགོས།';

  @override
  String get userMgmtUsernameMinLengthMessage =>
      'སྤྱོད་མཁན་མིང་ཉུང་མཐར་ཡིག་འབྲུ་གསུམ་དགོས།';

  @override
  String get userMgmtPasswordRequiredLabel => 'གསང་ཨང་ *';

  @override
  String get userMgmtEnterPasswordHint => 'གསང་ཨང་འཇུག';

  @override
  String get userMgmtPasswordRequiredMessage => 'གསང་ཨང་དགོས།';

  @override
  String get userMgmtMinimum6CharsMessage => 'ཉུང་མཐར་ཡིག་འབྲུ་དྲུག';

  @override
  String get userMgmtRoleRequiredLabel => 'ལས་འགན *';

  @override
  String get userMgmtRoleRequiredMessage => 'ལས་འགན་དགོས།';

  @override
  String get userMgmtSaveUserButton => 'སྤྱོད་མཁན་ཉར་ཚགས།';

  @override
  String get userMgmtThisIsYourAccountMessage => 'འདི་ཁྱེད་རང་གི་ཁ་ཡིག་ཡིན།';

  @override
  String get invoiceSettingsAppBarTitle => 'ཁྲལ་ཤོག་སྒྲིག་འགོད།';

  @override
  String get invoiceSettingsSavedMessage =>
      'ཁྲལ་ཤོག་སྒྲིག་འགོད་ལེགས་པར་ཉར་ཚགས་བྱས་ཟིན།';

  @override
  String get invoiceSettingsSignatureTooLargeMessage =>
      'མིང་རྟགས་པར་རིས་ནི 2 MB ལས་ཆུང་དགོས།';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage =>
      'ཆུ་རྟགས་པར་རིས་ནི 2 MB ལས་ཆུང་དགོས།';

  @override
  String get invoiceSettingsSectionGeneral => 'སྤྱིར་བཏང་།';

  @override
  String get invoiceSettingsSectionBranding => 'བརྣྡ་མཚོན།';

  @override
  String get invoiceSettingsSectionTax => 'ཁྲལ་དང་ GST';

  @override
  String get invoiceSettingsSectionItems => 'ཁྲལ་ཤོག་རས་ཆས།';

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
  String get invoiceSettingsPrefixLabel => 'ཁྲལ་ཤོག་སྔོན་སྐྱོན།';

  @override
  String get invoiceSettingsStartingNumberHelper =>
      'ཁྲལ་ཤོག་དང་པོ་འདི་ནས་འགོ་ཚུགས།';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      'ཁྲལ་ཤོག་ཡོད་བཞིན་དུ་འགོ་ཙམ་གྲངས་བརྗེ་མི་ཐུབ། ཁྲལ་ཤོག/ཚོང་གྲངས་ཆ་ཚང་ (ཧྲོག་མ་ཚུད) རྟག་ཏུ་བསུབ་ནས་ཡང་བསྐྱར་ཐབས་ཤེས་གནང་རོགས།';

  @override
  String get invoiceSettingsQuantityColumnLabel => 'གྲངས་ཀ་སྟེང་མིང་།';

  @override
  String get invoiceSettingsQuantityColumnHint => 'དཔེར་ན Words, Hours, Units';

  @override
  String get invoiceSettingsQuantityColumnHelper =>
      'སྔར་སྒྲིག \"Qty\" བེད་སྤྱོད་ལ་སྟོང་པར་བཞག';

  @override
  String get invoiceSettingsAdditionalInfoLabel => 'ཆ་འཕྲིན་གཞན།';

  @override
  String get invoiceSettingsThankYouNoteLabel => 'ཐུགས་རྗེ་ཆེའི་ཟུར་བཤད།';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel =>
      'སྔར་སྒྲིག་གིས་ཁྲལ་ཤོག་གྲངས་སྦས་པ།';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      'ཁྲལ་ཤོག་གསར་བཟོའི་སྐབས་ \"PDF ནང་ཁྲལ་ཤོག་གྲངས་སྦས་པ\" སྔར་སྒྲིག་ཏུ་སྒྲིག་རོགས།';

  @override
  String get invoiceSettingsTaxRateHint => 'དཔེར་ན 18';

  @override
  String get invoiceSettingsTaxRateHelper => 'ཁྲལ་ཤོག་གསར་པར་ཁྱབ།';

  @override
  String get invoiceSettingsTaxEnabledLabel => 'སྔར་སྒྲིག་གིས་ཁྲལ་སྒོ་ཕྱེ་བ།';

  @override
  String get invoiceSettingsTaxEnabledSubtitle =>
      'ཁྲལ་ཤོག་གསར་བཟོའི་སྐབས་སྔར་སྒྲིག་གིས་ཁྲལ་མཚོན་བྱེད་སྒོ་ཕྱེ་རོགས།';

  @override
  String get invoiceSettingsTaxModeLabel => 'སྔར་སྒྲིག་ཁྲལ་ཚད་ཐབས་ལམ།';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly =>
      'ཁྲལ་ཤོག་གསར་པར་མ་གཏོགས་མི་ཁྱབ།';

  @override
  String get invoiceSettingsTaxModeGlobal => 'ཡོངས་ཁྱབ།';

  @override
  String get invoiceSettingsTaxModePerItem => 'རས་ཆས་རེ་རེར།';

  @override
  String get invoiceSettingsShowGstFieldsLabel => 'GST ཐིག་ཁྲམ་སྟོན་པ།';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      'ཁྲལ་ཤོག PDF དང CSV ཕྱིར་འདྲེན་ནང GSTIN ཐིག་ཁྲམ (HSN/SAC) སྟོན་རོགས།';

  @override
  String get invoiceSettingsShowCgstSgstLabel => 'CGST/SGST སྟོན་པ།';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      'ཁྲལ་ཤོག་ནང་ཁྲལ་ལ CGST + SGST ལ་དབྱེ་བ (རྒྱ་གར་ཁོ་ནར)།';

  @override
  String get invoiceSettingsDefaultGstTitleLabel =>
      'སྔར་སྒྲིག GST ཁྲལ་ཤོག་མགོ་མིང་།';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel =>
      'སྔར་སྒྲིག་ཁྲལ་ཤོག་མགོ་མིང་།';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      'ཁྲལ་ཤོག་གསར་པར་སྔོན་འདེམས་ — དཔེར་ན GST Composition Scheme ཚོང་པ་ཚོར \"Bill of Supply\"';

  @override
  String get invoiceSettingsGstTitleHelperGeneric =>
      'ཁྲལ་ཤོག་གསར་པར་སྔོན་འདེམས།';

  @override
  String get invoiceSettingsShowRoundOffLabel => 'ཟླུམ་བསྒྱུར་སྟོན་པ།';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      'ཁྲལ་ཤོག PDF ནང་ཟླུམ་བསྒྱུར་ཐིག་དང་དངུལ་གྲངས་ཡོངས་སུ (ཉེ་འདབས་སུ) དང་ཡི་གེར་བཀོད་པའི་དངུལ་གྲངས་སྟོན་རོགས།';

  @override
  String get invoiceSettingsShowAliasNameLabel => 'PDF ནང་མིང་གཞན་སྟོན་པ།';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      'ཐོན་རྫས་ཀྱི་ངོ་མའི་མིང་ཚབ་ PDF ནང་ས་གནས་སྐད་ཡིག་གི་མིང་གཞན (སྒྲིག་ཡོད་ན) པར་སྐྲུན་རོགས།';

  @override
  String get invoiceSettingsShowDescriptionLabel =>
      'ཐོན་རྫས་ཀྱི་འགྲེལ་བཤད་སྟོན་པ།';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      'A4 PDF ནང་ཅ་དངོས་རེ་རེའི་འགྲེལ་བཤད་དེའི་འོག་ཏུ་གྲལ་ཐིག་གཅིག་ཏུ་པར་སྐྲུན་བྱེད་པ (ཚ་དྲོད་ཟིན་ཐོ་ནང་མིན)';

  @override
  String get invoiceSettingsDescriptionNewLineLabel =>
      'Description on a New Line';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      'Print the description as a full-width row below the item instead of a line under its name';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel => 'ཆ་ཤས་གྲངས་ཀ་ཆོག་པ།';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      'ཆ་ཤས་གྲངས་ཀ་སྒོ་ཕྱེ་བ (དཔེར་ན 1.5 ཆུ་ཚོད, 0.5 ཀི་ལོ)';

  @override
  String get invoiceSettingsShowQuantityLabel => 'གྲངས་ཀ་ཐིག་སྟོན་པ།';

  @override
  String get invoiceSettingsShowQuantitySubtitle =>
      'ཞབས་ཞུའི་ཁྲལ་ཤོག་ལ་གྲངས་ཀ་སྦས་པ; རིན་གོང་ཐིག་ \"དར་ཚད\" ལ་བསྒྱུར།';

  @override
  String get invoiceSettingsShowDiscountLabel => 'ཐོ་ཕབས་ཐིག་སྟོན་པ།';

  @override
  String get invoiceSettingsShowDiscountSubtitle =>
      'རས་ཆས་ཐོག་གི་ཐོ་ཕབས་མི་བེད་སྤྱོད་པའི་སྤྱི་སྤྱོད་པར་ཐོ་ཕབས་ཐིག་སྦས་པ།';

  @override
  String get invoiceSettingsShowTypeTagLabel => 'ཐོན་རྫས/ཞབས་ཞུའི་ཏོག་སྟོན་པ།';

  @override
  String get invoiceSettingsShowTypeTagSubtitle =>
      'ཁྲལ་ཤོག་རས་ཆས་རེ་རེར་ཐོན་རྫས/ཞབས་ཞུའི་ཏོག་སྟོན་པའམ་སྦས་པ།';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel =>
      'ཁྲལ་ཤོག་རས་ཆས་ལར་སྣང་ཆོག་པ།';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle =>
      'ཐོན་རྫས་གཅིག་ཁྲལ་ཤོག་ཐོག་ལན་གཅིག་ལས་མང་བར་སྣོན་ཆོག་པ།';

  @override
  String get invoiceSettingsShowPrevBalanceLabel => 'སྔོན་གྱི་ལྷག་དངུལ་སྟོན་པ།';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle =>
      'ཁྲལ་ཤོག PDF ནང་བརྩིས་བྱས་པའི་སྔོན་གྱི་ལྷག་དངུལ་སྟོན་རོགས།';

  @override
  String get invoiceSettingsLogoPositionLabel => 'ཚོང་ལས་མཚོན་རྟགས་གནས་ས།';

  @override
  String get invoiceSettingsLogoSizeLabel => 'ཚོང་ལས་མཚོན་རྟགས་ཚད།';

  @override
  String get commonLeftLabel => 'གཡོན།';

  @override
  String get commonRightLabel => 'གཡས།';

  @override
  String get invoiceSettingsSignatureImageLabel => 'མིང་རྟགས་པར་རིས།';

  @override
  String get invoiceSettingsSignatureImageSubtitle =>
      'ཁྲལ་ཤོག་ཐོག་དབང་ཚད་མིང་རྟགས་སུ་པར་སྐྲུན།';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG, JPG འམ JPEG — མང་མཐར 2 MB';

  @override
  String get invoiceSettingsChangeSignatureButton => 'མིང་རྟགས་བརྗེ་བ།';

  @override
  String get invoiceSettingsUploadSignatureButton => 'མིང་རྟགས་སྤར་གཞུག';

  @override
  String get invoiceSettingsSignatureSizeLabel => 'མིང་རྟགས་ཚད།';

  @override
  String get invoiceSettingsSignaturePositionLabel => 'མིང་རྟགས་གནས་ས།';

  @override
  String get invoiceSettingsWatermarkImageLabel => 'ཆུ་རྟགས་པར་རིས།';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      'ཁྲལ་ཤོག PDF ནང་རས་ཆས་ཐིག་ཁྲམ་རྒྱབ་ཏུ་སྟོན (མེ་འཁོར་ལག་དེབ་ཐོག་མི་འཁོད)';

  @override
  String get invoiceSettingsChangeWatermarkButton => 'ཆུ་རྟགས་བརྗེ་བ།';

  @override
  String get invoiceSettingsUploadWatermarkButton => 'ཆུ་རྟགས་སྤར་གཞུག';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return 'གསལ་མིན: $value%';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value%';
  }

  @override
  String get invoiceSettingsPromoTitle =>
      'ཁྱེད་ཀྱི་ཁྲལ་ཤོག་ཐོག་ཐིག་ཁྲམ་མང་བ་དགོས་སམ།';

  @override
  String get invoiceSettingsPromoBody =>
      'PO གྲངས, ལས་གཞིའི་ཨང་རྟགས, ལས་ཁུངས, འམ་ཐིག་ཁྲམ་གཞན་དང་ག་ར་སྣོན་རོགས།';

  @override
  String get invoiceSettingsPromoButton => 'གདམ་ག་ལྟ་བ།';

  @override
  String get pdfSettingsTitle => 'PDF སྒྲིག་འགོད།';

  @override
  String get pdfSettingsSubtitle =>
      'ཁྲལ་ཤོག་དང་། ཁྲལ་གོང་། ཁྲལ་འབུལ་ཤོག་གི་ PDF དཔེ་གཞི་སྒྲིག་འགོད་བྱེད་རོགས།';

  @override
  String get pdfSettingsResetToDefaultButton => 'སྔར་སྒྲིག་ལ་ལོག';

  @override
  String get pdfSettingsSaveSettingsButton => 'སྒྲིག་འགོད་ཉར་ཚགས།';

  @override
  String get pdfSettingsTemplatesLabel => 'དཔེ་གཞིའི་ཐོ།';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return '$pageSize དོན་དུ་དཔེ་གཞི་མེད།';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'PDF སྒྲིག་འགོད་ཉར་ཚགས་བྱས་ཟིན།';

  @override
  String get commonActiveLabel => 'ད་ལྟ་བཀོལ་བཞིན།';

  @override
  String get commonUnavailableLabel => 'མི་འཐུས།';

  @override
  String get pdfSettingsDisplayOptionsLabel => 'མངོན་པའི་གདམ་ཁ།';

  @override
  String get pdfSettingsShowTotalQtyRowLabel =>
      'ཡོངས་བསྡོམས་གྲངས་ཀའི་གྲལ་བ་སྟོན།';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => 'རྣམ་གྲངས་བཀོད་པ།';

  @override
  String get pdfSettingsItemLayoutTableLabel => 'རེའུ་མིག';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => 'ཞིབ་ཕྲ།';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      'རེའུ་མིག: རྣམ་གྲངས་རེར་གྲལ་བ་གཅིག (Sl/མིང་/གྲངས་ཀ/གོང་ཚད/བསྡོམས). ཞིབ་ཕྲ: མིང་རང་གི་གྲལ་བར་, དེ་ནས་གྲངས་ཀ/གོང་ཚད/བསྡོམས་འོག་ཏུ།';

  @override
  String get pdfSettingsCompanyNameSizeLabel => 'ཚོང་ལས་མིང་གི་ཚད།';

  @override
  String get pdfSettingsThemeColorLabel => 'བཀོད་པའི་ཚོན་མདོག';

  @override
  String get pdfSettingsHexErrorText => '#RRGGBB བེད་སྤྱོད་གནང་རོགས།';

  @override
  String get pdfSettingsPickColorTooltip => 'ཚོན་མདོག་འདེམས་བྱེད་ཁ་ཕྱེ།';

  @override
  String get pdfSettingsPickThemeColorDialogTitle => 'བཀོད་པའི་ཚོན་མདོག་འདེམས།';

  @override
  String get pdfSettingsPreviewDisclaimer =>
      'མཐའ་མའི་ PDF ནང་མངོན་པ་དེ་ཅུང་ཟད་མི་འདྲ་སྲིད།';

  @override
  String get pdfSettingsCustomTemplatePromoTitle => 'རང་སྒྲིག་དཔེ་གཞི་འདོད་དམ?';

  @override
  String get pdfSettingsCustomTemplatePromoBody =>
      'ཁྱེད་ཀྱི་བརྣད་དང་མཐུན་པའི་བཀོད་པ་ཐོབ་པ — ཚོན་མདོག་, ཡིག་གཟུགས་, བཀོད་པ་བཅས།';

  @override
  String get pdfSettingsCustomizationOptionsButton => 'རང་སྒྲིག་གདམ་ཁ།';

  @override
  String get pdfTemplateClassicName => 'ཁྲིམས་སྲོལ།';

  @override
  String get pdfTemplateClassicDescription =>
      'བཀོད་པ་གསལ་པོ་ཡོད་པའི་སྲོལ་རྒྱུན་བཀོད་པ།';

  @override
  String get pdfTemplateModernName => 'དེང་རབས།';

  @override
  String get pdfTemplateModernDescription =>
      'དེང་རབས་བཀོད་སྟངས་ཅན་གྱི་མགོ་ཡིག་ལྕགས་རིང་།';

  @override
  String get pdfTemplateMinimalName => 'ཉུང་ཤོས།';

  @override
  String get pdfTemplateMinimalDescription => 'ཡལ་བར་མི་འགྲོ་བའི་ཟུར་ཙམ།';

  @override
  String get pdfTemplateExecutiveName => 'འགོ་ཁྲིད།';

  @override
  String get pdfTemplateExecutiveDescription =>
      'ཁྲལ་བརྒྱབ་རིམ་པ་ལེགས་པོའི་ཚོང་ལས་ཆེན་པོའི་བཀོད་པ།';

  @override
  String get pdfTemplateCompactName => 'ཉུང་བསྡུས།';

  @override
  String get pdfTemplateCompactDescription =>
      'A6 པར་སྐྲུན་ལ་འོས་པའི་ཐོན་ཁུངས་ཉུང་བའི་ཁྲལ་འབུལ་ཤོག་བཀོད་པ།';

  @override
  String get pdfTemplateThermalName => 'དྲོད་ཤུགས།';

  @override
  String get pdfTemplateThermalDescription =>
      '80mm དང་ 58mm དྲོད་ཤུགས་པར་འཕྲུལ་ལ་འོས་པའི་ཕྲ་མོའི་ཁྲལ་འབུལ་ཤོག་བཀོད་པ།';

  @override
  String get pdfTemplateGridClassicName => 'རེའུ་མིག་སྲོལ་རྒྱུན།';

  @override
  String get pdfTemplateGridClassicDescription =>
      'A4, A5 དང་ A6 ལ་འོས་པའི་རྙིང་གནས་མཚམས་ཐིག་ཅན་གྱི་ཐིག་ཁྲམ་ཁྲལ་ཤོག';

  @override
  String get companyInfoAppBarTitle => 'ཚོང་ལས་ཆ་འཕྲིན།';

  @override
  String get companyInfoUploadLogoLabel => 'མཚོན་རྟགས་སྤོར་བ།';

  @override
  String get companyInfoClickToBrowseLabel => 'བརྟག་ཞིབ་བྱེད་པར་མནན་རོགས།';

  @override
  String get companyInfoRemoveLogoButton => 'མཚོན་རྟགས་བསུབ།';

  @override
  String get companyInfoShowOnPdfLabel => 'PDF ནང་སྟོན།';

  @override
  String get companyInfoLogoRequirementsHint =>
      'མཐོ་ཚད 1080×1080 px · 2 MB\nPNG ཡང་ན JPG རྐྱང་པ།';

  @override
  String get companyInfoLogoSectionLabel => 'ཚོང་ལས་མཚོན་རྟགས།';

  @override
  String get companyInfoDetailsSectionLabel => 'ཚོང་ལས་ཞིབ་ཕྲ།';

  @override
  String get companyInfoBusinessTypeSectionLabel => 'ཚོང་ལས་རིགས།';

  @override
  String get companyInfoPaymentSettingsSectionLabel => 'འཇལ་བའི་སྒྲིག་འགོད།';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'UPI རྩིས་ཁྲ།';

  @override
  String get companyInfoBankAccountsSectionLabel => 'དངུལ་ཁང་རྩིས་ཁྲ།';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => 'ཁྲལ/VAT ཨང་གྲངས།';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'FSSAI ཨང་རྟགས།';

  @override
  String get companyInfoPhoneHelperText =>
      'ཨང་གྲངས་མང་པོ: ཚེག་ཤད་ཀྱིས་དབྱེ་རོགས།';

  @override
  String get fieldWebsiteLabel => 'དྲྭ་ཚིགས།';

  @override
  String get companyInfoBusinessTypeTitle => 'ཚོང་ལས་རིགས།';

  @override
  String get companyInfoBusinessTypeSubtitle =>
      'ཐོན་རྫས་ཐོ་དང་ཁྲལ་ཤོག་ནང་གི་རིགས་གདམ་ཁ་ཚོད་འཛིན་བྱེད།';

  @override
  String get labelBoth => 'གཉིས་ཀ།';

  @override
  String get companyInfoSetAsDefaultTooltip => 'སྔར་སྒྲིག་བཟོ།';

  @override
  String get companyInfoUpiIdLabel => 'UPI ID';

  @override
  String get companyInfoAddUpiAccountButton => 'UPI རྩིས་ཁྲ་སྣོན།';

  @override
  String get companyInfoShowQrToggleTitle => 'ཁྲལ་ཤོག་ནང་ QR ཨང་རྟགས་སྟོན།';

  @override
  String get companyInfoShowQrToggleSubtitle =>
      'བཟོས་པའི་ PDF ནང་ UPI འཇལ་བའི QR ཨང་རྟགས་སྣོན།';

  @override
  String get companyInfoShowBankDetailsToggleTitle =>
      'ཁྲལ་ཤོག་ནང་དངུལ་ཁང་ཞིབ་ཕྲ་སྟོན།';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle =>
      'བཟོས་པའི PDF ནང་དངུལ་ཁང་རྩིས་ཁྲའི་ཞིབ་ཕྲ་དཔར་སྐྲུན།';

  @override
  String get fieldBankNameLabel => 'དངུལ་ཁང་མིང་།';

  @override
  String get fieldAccountNumberLabel => 'རྩིས་ཁྲ་ཨང་གྲངས།';

  @override
  String get fieldIfscCodeLabel => 'IFSC ཨང་རྟགས།';

  @override
  String get companyInfoAddBankAccountButton => 'དངུལ་ཁང་རྩིས་ཁྲ་སྣོན།';

  @override
  String get tooltipShowOnInvoicePdf => 'ཁྲལ་ཤོག PDF ནང་སྟོན།';

  @override
  String get companyInfoSavedSuccessMessage =>
      'ཚོང་ལས་ཆ་འཕྲིན་ལེགས་པར་ཉར་ཚགས་བྱུང་།';

  @override
  String get companyInfoImageTooLargeMessage =>
      'པར་རིས་ཡིག་ཆ་ 2 MB ལས་ཉུང་དགོས།';

  @override
  String get companyInfoInvalidImageMessage => 'ནུས་མེད་པའི་པར་རིས་ཡིག་ཆ།';

  @override
  String get companyInfoImageDimensionsMessage =>
      'པར་རིས་མཐོ་ཚད་ 1080x1080 པིག་སེལ་ལས་མི་བརྒལ་བ་དགོས།';

  @override
  String get companyInfoHintExampleBankName => 'དཔེར་ན HDFC དངུལ་ཁང་།';

  @override
  String get companyInfoHintExampleAccountLabel => 'དཔེར་ན གཙོ་བོའི་རྩིས་ཁྲ།';

  @override
  String get actionConfirm => 'ངེས་གཏན།';

  @override
  String get actionShare => 'མཉམ་སྤྱོད།';

  @override
  String get appInfoTitle => 'མཉེན་ཆས་ཆ་འཕྲིན།';

  @override
  String get appInfoAppDetailsTitle => 'ཆེད་ལས་ཞིབ་ཕྲ།';

  @override
  String get appInfoAppNameLabel => 'ཆེད་ལས་མིང་།';

  @override
  String get appInfoVersionLabel => 'པར་གཞི།';

  @override
  String get appInfoLicenseLabel => 'ཆོག་མཆན།';

  @override
  String get appInfoDeveloperTitle => 'འཕེལ་སྤེལ་བ།';

  @override
  String get appInfoDeveloperLabel => 'འཕེལ་སྤེལ་བ།';

  @override
  String get appInfoSupportEmailLabel => 'རོགས་རམ་གློག་འཕྲིན།';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  $license ཆོག་མཆན་འོག་ཏུ་སྤེལ།';
  }

  @override
  String get appInfoCheckingLabel => 'ཞིབ་བཤེར་བྱེད་བཞིན།';

  @override
  String get appInfoUpdateAvailableLabel => 'གསར་སྒྱུར་ཡོད།';

  @override
  String get appInfoUpToDateLabel => 'དུས་མཐུན།';

  @override
  String get appInfoCheckFailedLabel => 'ཞིབ་བཤེར་མ་གྲུབ།';

  @override
  String get appInfoUpdatesTitle => 'གསར་སྒྱུར།';

  @override
  String get appInfoCurrentVersionLabel => 'ད་ལྟའི་པར་གཞི།';

  @override
  String get appInfoLatestVersionLabel => 'གསར་ཤོས་པར་གཞི།';

  @override
  String get appInfoCheckNowButton => 'ད་ལྟ་ཞིབ་བཤེར།';

  @override
  String get backupManagementTitle => 'ཉར་ཚགས་འཛིན་སྐྱོང་།';

  @override
  String get backupCreateDbButton => 'DB ཉར་ཚགས་བཟོ།';

  @override
  String get backupExportJsonButton => 'JSON ཕྱིར་འདྲེན།';

  @override
  String get backupImportButton => 'ཉར་ཚགས་ནང་འདྲེན།';

  @override
  String get backupNoBackupsFoundMessage => 'ཉར་ཚགས་མ་རྙེད།';

  @override
  String backupSizeLabel(String size) {
    return 'ཆེ་ཆུང་། $size';
  }

  @override
  String backupCreatedLabel(String date) {
    return 'བཟོས་དུས། $date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return 'ཉར་ཚགས་འདེད་འཐེན་མ་གྲུབ། $error';
  }

  @override
  String get backupCreatedSuccessMessage => 'ཉར་ཚགས་ལེགས་པར་བཟོས་སོང་།';

  @override
  String backupCreateErrorMessage(String error) {
    return 'ཉར་ཚགས་བཟོ་བ་མ་གྲུབ། $error';
  }

  @override
  String get backupRestoreConfirmTitle => 'ཉར་ཚགས་སོར་ཆུད།';

  @override
  String get backupRestoreConfirmBody =>
      'འདིས་ད་ལྟའི་གྲངས་འཛིན་ཚང་མ་ཉར་ཚགས་ཀྱིས་ཚབ་བརྗེ་བྱེད། ངེས་པར་དུ་འདོད་དམ།';

  @override
  String backupRestoreErrorMessage(String error) {
    return 'ཉར་ཚགས་སོར་ཆུད་མ་གྲུབ། $error';
  }

  @override
  String get backupDeleteConfirmTitle => 'ཉར་ཚགས་བསུབ།';

  @override
  String get backupDeleteConfirmBody =>
      'ཁྱེད་ཀྱིས་ཉར་ཚགས་འདི་བསུབ་འདོད་ངེས་སམ།';

  @override
  String get backupDeletedSuccessMessage => 'ཉར་ཚགས་ལེགས་པར་བསུབས་སོང་།';

  @override
  String get backupDeleteFailedMessage => 'ཉར་ཚགས་བསུབ་མ་གྲུབ།';

  @override
  String backupDeleteErrorMessage(String error) {
    return 'ཉར་ཚགས་བསུབ་མ་གྲུབ། $error';
  }

  @override
  String get backupSavedToDownloadsMessage =>
      'ཉར་ཚགས་འདེད་འཐེན་ཡིག་སྣོད་དུ་ཉར་ཚགས་བྱས།';

  @override
  String backupDownloadErrorMessage(String error) {
    return 'ཉར་ཚགས་འདེད་འཐེན་མ་གྲུབ། $error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return 'ཉར་ཚགས་མཉམ་སྤྱོད་མ་གྲུབ། $error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return 'ཉར་ཚགས་ནང་འདྲེན་མ་གྲུབ། $error';
  }

  @override
  String get backupRestoreSuccessTitle => 'སོར་ཆུད་ལེགས་གྲུབ།';

  @override
  String get backupRestoreSuccessBody =>
      'གནད་སྡུད་མཛོད་ལེགས་པར་སོར་ཆུད་བྱས་ཟིན། \n\nབཟོ་བཅོས་དག་སྤྱོད་པར་ཆེད་ལས་བསྐྱར་འགོ་བཙུགས་དགོས། ཆེད་ལས་ཁ་བརྒྱབ་སྟེ་བསྐྱར་དུ་ཕྱེ་རོགས།';

  @override
  String get backupCloseLaterButton => 'རྗེས་སུ་ཁ་རྒྱག';

  @override
  String get backupCloseAppNowButton => 'ད་ལྟ་ཆེད་ལས་ཁ་རྒྱག';

  @override
  String get commonSuccessTitle => 'ལེགས་གྲུབ།';

  @override
  String get commonErrorTitle => 'འཛོལ་བ།';

  @override
  String get productColumnsScreenTitle => 'ཐོན་རིགས་ཞིབ་ཕྲ་སྒྲིག་འགོད།';

  @override
  String get productColumnsSavedMessage => 'ཐོན་རིགས་ཐིག་རྟགས་ཉར་ཚགས་བྱས།';

  @override
  String get productColumnsIntroText =>
      'ཐོན་རིགས་སྣོན་/ཞུ་དག་ཐིག་ཁྲམ་དང་། ཐོན་རིགས་ཐོ་གཞུང་། ཁྲལ་ཤོག་གྲངས་རྐྱང་ནང་མཚོན་པའི་ཡིག་ཆ་གང་མངོན་མིན་འདེམས་རོགས། མིང་དང་གོང་ཚད་ནི་རྟག་ཏུ་དགོས་མཁོ་ཡིན།';

  @override
  String get productColumnsNameLabel => 'མིང་།';

  @override
  String get productColumnsPriceLabel => 'གོང་ཚད།';

  @override
  String get productColumnsAlwaysRequiredSubtitle => 'རྟག་ཏུ་མངོན། — དགོས་མཁོ།';

  @override
  String get productColumnsStockLabel => 'ཉར་ཚགས་ཆ་ཚན།';

  @override
  String get productColumnsStockSubtitle =>
      'ཁྱེད་ཀྱིས་ནམ་ཡང་ཆ་ཚན་རྗེས་འདེད་མི་བྱེད་ན་བཀག་རོགས། — ཐོན་རིགས་ཚད་མེད་ཆ་ཚན་སྔར་སྒྲིག་ཡིན།';

  @override
  String get productColumnsProductFieldsSectionTitle => 'ཐོན་རིགས་ཡིག་ཆ།';

  @override
  String get productColumnsAliasNameLabel => 'མིང་གཞན།';

  @override
  String get productColumnsAliasNameSubtitle =>
      'PDF/པར་སྐྲུན་ལ་ས་གནས་སྐད་ཡིག་མངོན་མིང་།';

  @override
  String get productColumnsTaxRateLabel => 'ཁྲལ་ཚད།';

  @override
  String get productColumnsTaxRateSubtitle => 'ཐོན་རིགས་རེ་རེའི་ཁྲལ་བརྒྱ་ཆ།';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'HSN ཡང་ན་ SAC ཨང་རྟགས་ཡིག་ཆ།';

  @override
  String get productColumnsDescriptionLabel => 'འགྲེལ་བཤད།';

  @override
  String get productColumnsDescriptionSubtitle =>
      'ཐོན་རིགས་རང་དབང་ཡི་གེའི་འགྲེལ་བཤད།';

  @override
  String get productColumnsPurchasePriceLabel => 'ཉོ་གོང་།';

  @override
  String get productColumnsPurchasePriceSubtitle =>
      'ཁེ་འབབ་རྗེས་འདེད་ཆེད་གོང་རྐང་།';

  @override
  String get productColumnsDefaultDiscountLabel => 'སྔར་སྒྲིག་ཐོ་ཆད།';

  @override
  String get productColumnsDefaultDiscountSubtitle =>
      'ཐོན་རིགས་འདི་ཁྲལ་ཤོག་ལ་སྣོན་སྐབས་སྔོན་བཀང་ཐོ་ཆད།';

  @override
  String get productColumnsUnitLabel => 'ཆ་ཚད།';

  @override
  String get productColumnsUnitSubtitle => 'ཆེ་ཆུང་ཆ་ཚད (ཆ། ཀི་ལོ། ཆུ་ཚོད...)།';

  @override
  String get productColumnsProductServiceTypeLabel => 'ཐོན་རིགས/ཞབས་ཞུའི་རིགས།';

  @override
  String get productColumnsProductServiceTypeSubtitle =>
      'ཐོན་རིགས་དང་ཞབས་ཞུ་འདེམས་བྱེད།';

  @override
  String get productColumnsMetadataLabel => 'ཐོན་རིགས་གནས་ཚུལ།';

  @override
  String get productColumnsMetadataSubtitle =>
      'ཉར་ཚགས་ས་ཆ། སྣོད་/ཚན་པའི་ཨང་། དུས་ཚད། བཟོ་བསྐྲུན་ཚེས། སྤྲོད་མཁན། SKU། མཆན།';

  @override
  String get productColumnsMetaStorageLocationLabel => 'ཉར་ཚགས་ས་ཆ།';

  @override
  String get productColumnsMetaContainerNumberLabel => 'སྣོད་ཨང་།';

  @override
  String get productColumnsMetaBatchNumberLabel => 'ཚན་པའི་ཨང་།';

  @override
  String get productColumnsMetaExpiryDateLabel => 'དུས་ཚད་ཚེས་གྲངས།';

  @override
  String get productColumnsMetaManufactureDateLabel => 'བཟོ་བསྐྲུན་ཚེས་གྲངས།';

  @override
  String get productColumnsMetaSupplierNameLabel => 'སྤྲོད་མཁན་མིང་།';

  @override
  String get productColumnsMetaSkuCodeLabel => 'SKU ཨང་རྟགས།';

  @override
  String get productColumnsMetaNotesLabel => 'མཆན།';

  @override
  String get productColumnsExtraCostLabel => 'འཕར་མའི་གོང་རྐང་།';

  @override
  String get productColumnsExtraCostSubtitle =>
      'ཁྲལ་ཤོག་གྲངས་རྐྱང་སྟེང་གདམ་གསེས་འཕར་མའི་གོང་རྐང་།';

  @override
  String get settingsOptionsComingSoonMessage =>
      'གདམ་ག་མང་པོ་མགྱོགས་པོར་འོང་གི་རེད།...';

  @override
  String get settingsNavCompanyInfoLabel => 'ཚོང་ལས་ཆ་འཕྲིན།';

  @override
  String get settingsNavTeamLabel => 'སྡེ་ཚན།';

  @override
  String get settingsNavBackupLabel => 'ཉར་ཚགས་གཉིས་པ།';

  @override
  String get settingsNavUsersLabel => 'བེད་སྤྱོད་པ།';

  @override
  String get settingsNavProductDetailsLabel => 'ཐོན་སྐྱེད་ཞིབ་ཕྲ།';

  @override
  String get settingsNavCustomizeLabel => 'སྒེར་སྒྲིག';

  @override
  String get settingsNavAccessibilityLabel => 'ཐོབ་ཐང་།';

  @override
  String get settingsNavSoftwareInfoLabel => 'མཉེན་ཆས་ཆ་འཕྲིན།';

  @override
  String get customizationEyebrowLabel => 'སྒེར་སྒྲིག';

  @override
  String get customizationHeadline => 'ཁྱེད་ཀྱི་ཚོང་ལས་ལ་སྒེར་སྒྲིག་བྱས་པ།';

  @override
  String get customizationSubtitle =>
      'ཁྱེད་ལ་དགོས་པ་འདེམས་ནས་ཞུ་ཡིག་སྐུར་རོགས། ང་ཚོས་ཆུ་ཚོད ༢༤ ནང་ལན་འདེབས་བྱེད་ངེས།';

  @override
  String get customizationRecommendedBadge => 'འོས་སྦྱོར།';

  @override
  String customizationDeliveryLabel(String delivery) {
    return 'སྤྲོད་དུས། $delivery';
  }

  @override
  String get customizationRequestButton => 'ཞུ་བ།';

  @override
  String get customizationFormOpenErrorMessage =>
      'ཐོ་འགོད་ཤོག་ངོས་ཁ་ཕྱེ་མ་ཐུབ། ཁྱེད་ཀྱི་བརའུ་ཟར་ནང་ forms.gle/LyX6Z2kBNR2BpwVu7 ལ་ལྟ་རོགས།';

  @override
  String get customizationDisclaimerMessage =>
      'རིན་གོང་ནི་དཔེ་མཚོན་ཙམ་ཡིན། འདི་ནི་དཀའ་ཚེགས་ཀྱི་ཆེ་ཆུང་ལ་བརྟེན་ནས་འགྱུར་བ་འགྲོ་སྲིད། ཁྱབ་ཁོངས་མོས་མཐུན་བྱས་རྗེས་དངུལ་བསྡུ་བ་ཡིན།';

  @override
  String get customizationPdfTemplateTitle => 'སྒེར་སྒྲིག PDF དཔེ་གཞི།';

  @override
  String get customizationPdfTemplateDescription =>
      'ཁྱེད་ཀྱི་མཚན་བརྗོད་དང་མཐུན་པའི་ཁྲལ་ཤོག་དཔེ་གཞི་ལེན་རོགས། — ཁྱེད་ཀྱི་ཚོན་མདོག ཡིག་གཟུགས མཚོན་རྟགས་གནས་ས་དང་བཀོད་པ།';

  @override
  String get customizationPdfTemplateDelivery => 'ཉིན་ ༢–༥';

  @override
  String get customizationCustomFieldsTitle => 'སྒེར་སྒྲིག་ཡིག་ཆ།';

  @override
  String get customizationCustomFieldsDescription =>
      'ཁྱེད་ཀྱི་ཁྲལ་ཤོག་ལ་ཡིག་ཆ་གཞན་དགོས་སམ? (ཉོ་སྒྲིག་ཨང་གྲངས་ལས་གཞིའི་ཨང་གྲངས་ལས་ཁུངས་སོགས) ང་ཚོས་ཁྱེད་ལ་སྣོན་འཇུག་བྱེད་ངེས།';

  @override
  String get customizationCustomFieldsDelivery => 'ཉིན་ ༡–༣';

  @override
  String get customizationWhiteLabelTitle => 'དཀར་ཅག / མཚན་བརྗོད་བསུབ་པ།';

  @override
  String get customizationWhiteLabelDescription =>
      'མཉེན་ཆས་དང PDF ནང་གི Invoiso མཚན་བརྗོད་ཡོངས་རྫོགས་བསུབ་ནས་ཁྱེད་རང་གི་ཚོང་ལས་ངོ་བོས་ཚབ་བྱེད།';

  @override
  String get customizationWhiteLabelDelivery => 'ཉིན་ ༣–༦';

  @override
  String get customizationIndustryBuildTitle => 'ལས་སྡེའི་སྒེར་སྒྲིག';

  @override
  String get customizationIndustryBuildDescription =>
      'ཁྱེད་ཀྱི་ལས་སྡེ་ལ་སྒེར་སྒྲིག་བྱས་པའི་པར་གཞི་དགོས་སམ? (བརྒྱབ་སྐྲུན་བསམ་འཆར་ཚོང་ལས་སོགས) ང་ཚོས་ཁྱེད་ཀྱི་དགོས་མཁོ་ལྟར་ལས་འགུལ་སྒེར་སྒྲིག་བྱེད་ངེས།';

  @override
  String get customizationIndustryBuildDelivery => 'ཉིན་ ༥–༡༠';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle =>
      'ཁྲལ་ཤོག་གསར་བཟོའི་ཤོག་ངོས་བཀོད་པ་གསར་པ།';

  @override
  String get accessibilityClassicLayoutLabel => 'བཀོད་པ་རྙིང་པ།';

  @override
  String get accessibilityNewLayoutLabel => 'བཀོད་པ་གསར་པ།';

  @override
  String get accessibilityLayoutDescription =>
      '\"ཁྲལ་ཤོག་གསར་པ\" བརྙན་ཤོག་བཟོ་བཀོད་གང་བེད་སྤྱོད་བྱེད་མིན་འདེམས་རོགས།';

  @override
  String get accessibilityShortcutsSubtitle =>
      'མཱའུསི་མ་བརྡབས་པར་ཁྲལ་ཤོག་གསར་བཟོ་མགྱོགས་སུ་གཏོང་རོགས།';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => 'ཁྲལ་ཤོག་བསྡོམས།';

  @override
  String get paymentDialogAmountPaidLabel => 'འཇལ་ཟིན་གྲངས་འབོར།';

  @override
  String get paymentDialogHistoryTitle => 'འཇལ་བའི་ལོ་རྒྱུས།';

  @override
  String get paymentDialogNoPaymentsMessage => 'ད་ལྟའི་བར་འཇལ་བ་ཐོ་འགོད་མ་བྱས།';

  @override
  String get paymentDialogFullyPaidExclaimMessage => 'ཁྲལ་ཤོག་ཚང་མ་འཇལ་ཟིན།';

  @override
  String get paymentDialogFullyPaidBannerLabel => 'ཁྲལ་ཤོག་ཚང་མ་འཇལ་ཟིན།';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return 'འཇལ་བ་ཐོ་འགོད་བྱས། ཐེབས་ཆག: $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return 'འཇལ་བ་ཐོ་འགོད་མ་ཐུབ།: $error';
  }

  @override
  String get paymentDialogDeleteTitle => 'འཇལ་བ་བསུབ།';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return 'ཐོ་ཨང་ $receiptNumber བསུབ་ངེས་སམ།\n\nའདི་ཕྱིར་ལོག་མི་ཐུབ།';
  }

  @override
  String get paymentDialogNewPaymentTitle => 'འཇལ་བ་གསར་པ།';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return 'གྲངས་འབོར། ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return 'མང་ཤོས: $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError =>
      'ནུས་པ་ཡོད་པའི་གྲངས་འབོར་འཇུག་རོགས།';

  @override
  String get paymentDialogExceedsOutstandingError => 'ཐེབས་ཆག་ལས་མང་བ།';

  @override
  String get paymentDialogMethodFieldLabel => 'འཇལ་ཐབས།';

  @override
  String get paymentDialogSelectMethodHint => 'ཐབས་ལམ་འདེམས་རོགས།';

  @override
  String get paymentDialogTaxCoveredLabel => 'ཁྲལ་ཚུད་པ།';

  @override
  String get paymentDialogAutoCalculatedHelper => 'རང་འགུལ་རྩིས་བཏོན།';

  @override
  String get paymentDialogNotesFieldLabel => 'གནས་ཚུལ། / མཆན (དགའ་མོས)';

  @override
  String get paymentDialogNotesHint => 'དཔེར་ན: ཙེག་ཨང་། སྤོ་སྒྱུར་ID...';

  @override
  String get paymentDialogReceiptColLabel => 'ཐོ་ཨང་ #';

  @override
  String get paymentDialogMethodColLabel => 'ཐབས་ལམ།';

  @override
  String get paymentDialogDownloadReceiptTooltip => 'ཐོ་ཡིག་ཕབ་ལེན།';

  @override
  String get paymentDialogDeletePaymentTooltip => 'འཇལ་བ་བསུབ།';

  @override
  String get paymentMethodCash => 'སྔ་དངུལ།';

  @override
  String get paymentMethodBankTransfer => 'དངུལ་ཁང་སྤོ་སྒྱུར།';

  @override
  String get paymentMethodCheck => 'ཙེག།';

  @override
  String get paymentMethodOnline => 'དྲ་ཐོག';

  @override
  String get paymentMethodOther => 'གཞན།';

  @override
  String get customerInfoButtonTooltip => 'འབྲེལ་གནས་ཞིབ་ཕྲ་སྟོན།';

  @override
  String get customerInfoButtonNoContactMessage => 'འབྲེལ་གནས་ཞིབ་ཕྲ་མེད།';

  @override
  String get updateDialogTitle => 'གསར་བཅོས་ཐོན་ཡོད།';

  @override
  String get updateDialogBodyMessage =>
      'invoiso གི་པར་གཞི་གསར་པ་ཐོན་ཡོད། གསར་ཤོས་བླང་ཆེད་ཕབ་ལེན་ཤོག་ངོས་སུ་གཟིགས་རོགས།';

  @override
  String get pageSizeA4Label => 'སྤྱི་ཚད་ A4';

  @override
  String get pageSizeA5Label => 'སྤྱི་ཚད་ A5';

  @override
  String get pageSizeA6Label => 'སྤྱི་ཚད་ A6';

  @override
  String get pageSizeThermal80Label => 'དྲོད་ཤོག་ 80mm';

  @override
  String get pageSizeThermal58Label => 'དྲོད་ཤོག་ 58mm';

  @override
  String get dateFormatDdmmyyyyLabel => 'DD/MM/YYYY  (དཔེར་ན 15/04/2026)';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/DD/YYYY  (དཔེར་ན 04/15/2026)';

  @override
  String get dateFormatDdMmmyyyyLabel => 'DD MMM YYYY  (དཔེར་ན 15 Apr 2026)';

  @override
  String get dateFormatYyyymmddLabel => 'YYYY-MM-DD  (དཔེར་ན 2026-04-15)';

  @override
  String get sizeXSmallLabel => 'ཧ་ཅང་ཆུང་བ།';

  @override
  String get sizeSmallLabel => 'ཆུང་བ།';

  @override
  String get sizeMediumLabel => 'འབྲིང་།';

  @override
  String get sizeLargeLabel => 'ཆེན་པོ།';

  @override
  String get shortcutNewInvoiceDescription =>
      'ཁྲལ་ཤོག་གསར་པ (ཌེཤ་བོརྡ་ནས) / ཡིག་ཆ་སླར་སྒྲིག (ཁྲལ་ཤོག་བཟོ་བའི་ནང་)';

  @override
  String get shortcutSaveInvoiceDescription => 'ཁྲལ་ཤོག་ཉར་ཚགས/བཟོ་བ།';

  @override
  String get shortcutAddProductDescription => 'ཁྲལ་ཤོག་ལ་ཐོན་རྫས་སྣོན་པ།';

  @override
  String get shortcutAddCustomItemDescription => 'རང་སྒྲིག་ཅ་ལག་སྣོན་པ།';

  @override
  String get shortcutPreviewPdfDescription => 'ཁྲལ་ཤོག PDF སྔོན་བལྟ།';

  @override
  String get shortcutPrintPdfDescription => 'ཁྲལ་ཤོག PDF བཟོ/པར་སྐྲུན།';
}
