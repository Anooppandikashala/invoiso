import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bo.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bo'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ne'),
    Locale('zh')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Invoiso'**
  String get appTitle;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get actionGetStarted;

  /// No description provided for @commonLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLanguage;

  /// No description provided for @commonBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get commonBeta;

  /// No description provided for @commonSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get commonSystemDefault;

  /// No description provided for @commonTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get commonTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @onboardingStepCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get onboardingStepCompanyTitle;

  /// No description provided for @onboardingStepCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business'**
  String get onboardingStepCompanySubtitle;

  /// No description provided for @onboardingStepInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Settings'**
  String get onboardingStepInvoiceTitle;

  /// No description provided for @onboardingStepInvoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up how your invoices work'**
  String get onboardingStepInvoiceSubtitle;

  /// No description provided for @onboardingStepAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Appearance'**
  String get onboardingStepAppearanceTitle;

  /// No description provided for @onboardingStepAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a page size and template'**
  String get onboardingStepAppearanceSubtitle;

  /// No description provided for @onboardingStepDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All Set'**
  String get onboardingStepDoneTitle;

  /// No description provided for @onboardingCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get onboardingCompanyNameLabel;

  /// No description provided for @onboardingCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get onboardingCountryLabel;

  /// No description provided for @onboardingLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get onboardingLogoLabel;

  /// No description provided for @onboardingCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get onboardingCurrencyLabel;

  /// No description provided for @onboardingDateFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get onboardingDateFormatLabel;

  /// No description provided for @onboardingInvoiceStartingNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Starting Number'**
  String get onboardingInvoiceStartingNumberLabel;

  /// No description provided for @onboardingLeadingZerosLabel.
  ///
  /// In en, this message translates to:
  /// **'Leading Zeros'**
  String get onboardingLeadingZerosLabel;

  /// No description provided for @onboardingLeadingZerosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pad invoice numbers to 8 digits (e.g. 00000007)'**
  String get onboardingLeadingZerosSubtitle;

  /// No description provided for @onboardingDefaultTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Tax Rate (%)'**
  String get onboardingDefaultTaxRateLabel;

  /// No description provided for @onboardingPageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Page Size'**
  String get onboardingPageSizeLabel;

  /// No description provided for @onboardingTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Template'**
  String get onboardingTemplateLabel;

  /// No description provided for @onboardingDoneHeadline.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingDoneHeadline;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your company, invoice and template details are saved. You can update any of these later from Settings.'**
  String get onboardingDoneBody;

  /// No description provided for @splashInitErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get splashInitErrorTitle;

  /// No description provided for @splashInitErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize the database.\n\n{error}'**
  String splashInitErrorMessage(String error);

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @splashInitializingMessage.
  ///
  /// In en, this message translates to:
  /// **'Initializing App...'**
  String get splashInitializingMessage;

  /// No description provided for @testGateNoInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'Test installer needs internet access to verify.'**
  String get testGateNoInternetTitle;

  /// No description provided for @testGateExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'This test build has expired.'**
  String get testGateExpiredTitle;

  /// No description provided for @testGateNoInternetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet and retry.'**
  String get testGateNoInternetSubtitle;

  /// No description provided for @testGateExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support: {email}'**
  String testGateExpiredSubtitle(String email);

  /// No description provided for @dashboardSessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Session expired due to inactivity.'**
  String get dashboardSessionExpiredMessage;

  /// No description provided for @dashboardUnknownTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown tab'**
  String get dashboardUnknownTabLabel;

  /// No description provided for @dashboardInvoiceLayoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Invoice layout: {layout} — tap for info'**
  String dashboardInvoiceLayoutTooltip(String layout);

  /// No description provided for @dashboardLayoutNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get dashboardLayoutNew;

  /// No description provided for @dashboardLayoutClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get dashboardLayoutClassic;

  /// No description provided for @dashboardInvoiceLayoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice layout'**
  String get dashboardInvoiceLayoutDialogTitle;

  /// No description provided for @dashboardInvoiceLayoutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re using the {layout} \"New Invoice\" layout. You can switch it from Settings > Accessibility. Note: switching mid-edit discards any unsaved changes on this form.'**
  String dashboardInvoiceLayoutDialogBody(String layout);

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @dashboardOpenSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get dashboardOpenSettingsAction;

  /// No description provided for @dashboardCollapseSidebarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get dashboardCollapseSidebarTooltip;

  /// No description provided for @dashboardExpandSidebarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get dashboardExpandSidebarTooltip;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get navNewInvoice;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navQuotations.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get navQuotations;

  /// No description provided for @navReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get navReceipts;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get dashboardRoleAdmin;

  /// No description provided for @dashboardRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get dashboardRoleUser;

  /// No description provided for @dashboardSupportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get dashboardSupportTooltip;

  /// No description provided for @dashboardLogoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get dashboardLogoutTooltip;

  /// No description provided for @dashboardTestBuildBadge.
  ///
  /// In en, this message translates to:
  /// **'TEST BUILD'**
  String get dashboardTestBuildBadge;

  /// No description provided for @dashboardTestBadgeShort.
  ///
  /// In en, this message translates to:
  /// **'TEST'**
  String get dashboardTestBadgeShort;

  /// No description provided for @dashboardKeyboardShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get dashboardKeyboardShortcutsTitle;

  /// No description provided for @dashboardShortcutsBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'New: Keyboard shortcuts'**
  String get dashboardShortcutsBannerTitle;

  /// No description provided for @dashboardShortcutsBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Q for a new invoice, Ctrl+S to save, and more.'**
  String get dashboardShortcutsBannerSubtitle;

  /// No description provided for @dashboardViewAllAction.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAllAction;

  /// No description provided for @dashboardLayoutBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'New: Multiple dashboard layouts'**
  String get dashboardLayoutBannerTitle;

  /// No description provided for @dashboardLayoutBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between Default, Classic, Bento, and Simple Feed using the grid icon in the top-right.'**
  String get dashboardLayoutBannerSubtitle;

  /// No description provided for @actionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get actionGotIt;

  /// No description provided for @dashboardThemeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'New: Dark mode'**
  String get dashboardThemeBannerTitle;

  /// No description provided for @dashboardThemeBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re still polishing it — switch it on from Settings > Company Info and let us know what looks off.'**
  String get dashboardThemeBannerSubtitle;

  /// No description provided for @dashboardSupportBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve created {count} invoices!'**
  String dashboardSupportBannerTitle(String count);

  /// No description provided for @dashboardSupportBannerReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Invoiso? A quick review helps a lot.'**
  String get dashboardSupportBannerReviewSubtitle;

  /// No description provided for @dashboardSupportBannerSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looks like Invoiso is part of your workflow. If it\'s been helpful, consider supporting the project — whenever it feels right.'**
  String get dashboardSupportBannerSupportSubtitle;

  /// No description provided for @dashboardReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get dashboardReviewAction;

  /// No description provided for @dashboardSupportAction.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get dashboardSupportAction;

  /// No description provided for @dashboardOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverviewTitle;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @dashboardOutOfStockCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} out of stock'**
  String dashboardOutOfStockCountLabel(int count);

  /// No description provided for @dashboardRevenueCollectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue Collected'**
  String get dashboardRevenueCollectedLabel;

  /// No description provided for @dashboardOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get dashboardOutstandingLabel;

  /// No description provided for @dashboardOverdueCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String dashboardOverdueCountLabel(int count);

  /// No description provided for @dashboardRecentInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Invoices'**
  String get dashboardRecentInvoicesTitle;

  /// No description provided for @dashboardLastFiveInvoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Last 5 invoices'**
  String get dashboardLastFiveInvoicesLabel;

  /// No description provided for @dashboardNoInvoicesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get dashboardNoInvoicesYetTitle;

  /// No description provided for @dashboardNoInvoicesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first invoice to see it here'**
  String get dashboardNoInvoicesYetSubtitle;

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionPdfPreview.
  ///
  /// In en, this message translates to:
  /// **'PDF Preview'**
  String get actionPdfPreview;

  /// No description provided for @actionDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get actionDownloadPdf;

  /// No description provided for @actionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get actionPrint;

  /// No description provided for @actionPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get actionPayment;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get actionRecordPayment;

  /// No description provided for @dashboardDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dashboardDueDateLabel(String date);

  /// No description provided for @labelInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get labelInvoice;

  /// No description provided for @labelQuotation.
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get labelQuotation;

  /// No description provided for @labelReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get labelReceipt;

  /// No description provided for @dashboardWelcomeBackMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {username}'**
  String dashboardWelcomeBackMessage(String username);

  /// No description provided for @dashboardBusinessGlanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your business at a glance'**
  String get dashboardBusinessGlanceSubtitle;

  /// No description provided for @dashboardDueSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Due Soon'**
  String get dashboardDueSoonTitle;

  /// No description provided for @dashboardInvoiceCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice} other{{count} invoices}}'**
  String dashboardInvoiceCountLabel(int count);

  /// No description provided for @dashboardTodayTomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Today & Tomorrow'**
  String get dashboardTodayTomorrowLabel;

  /// No description provided for @dashboardDueTodayBadge.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get dashboardDueTodayBadge;

  /// No description provided for @dashboardDueTomorrowBadge.
  ///
  /// In en, this message translates to:
  /// **'Due Tomorrow'**
  String get dashboardDueTomorrowBadge;

  /// No description provided for @dashboardOverdueSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardOverdueSectionTitle;

  /// No description provided for @dashboardOldestFirstLabel.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get dashboardOldestFirstLabel;

  /// No description provided for @dashboardDaysOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day overdue} other{{days} days overdue}}'**
  String dashboardDaysOverdueLabel(int days);

  /// No description provided for @dashboardNewStockQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'New Stock Quantity'**
  String get dashboardNewStockQuantityLabel;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// No description provided for @labelService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get labelService;

  /// No description provided for @labelProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get labelProduct;

  /// No description provided for @dashboardStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String dashboardStockLabel(int count);

  /// No description provided for @actionUpdateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get actionUpdateStock;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get paymentStatusPartial;

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get paymentStatusUnpaid;

  /// No description provided for @dashboardDuplicateInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Invoice'**
  String get dashboardDuplicateInvoiceTitle;

  /// No description provided for @dashboardDuplicateInvoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Create a copy of Invoice #{number}\n({customerName}) as:'**
  String dashboardDuplicateInvoiceBody(String number, String customerName);

  /// No description provided for @dashboardDeleteInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get dashboardDeleteInvoiceTitle;

  /// No description provided for @dashboardDeleteInvoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete Invoice #{number}? This action cannot be undone.'**
  String dashboardDeleteInvoiceBody(String number);

  /// No description provided for @dashboardLayoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Layout'**
  String get dashboardLayoutTooltip;

  /// No description provided for @dashboardLayoutDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get dashboardLayoutDefaultTitle;

  /// No description provided for @dashboardLayoutDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Original layout'**
  String get dashboardLayoutDefaultSubtitle;

  /// No description provided for @dashboardLayoutClassicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charts + KPI grid'**
  String get dashboardLayoutClassicSubtitle;

  /// No description provided for @dashboardLayoutBentoTitle.
  ///
  /// In en, this message translates to:
  /// **'Bento'**
  String get dashboardLayoutBentoTitle;

  /// No description provided for @dashboardLayoutBentoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hero chart + card grid'**
  String get dashboardLayoutBentoSubtitle;

  /// No description provided for @dashboardLayoutSimpleTitle.
  ///
  /// In en, this message translates to:
  /// **'Simple Feed'**
  String get dashboardLayoutSimpleTitle;

  /// No description provided for @dashboardLayoutSimpleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clean list view'**
  String get dashboardLayoutSimpleSubtitle;

  /// No description provided for @dashboardTotalInvoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get dashboardTotalInvoicesLabel;

  /// No description provided for @dashboardRevenueLast6MonthsTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue — Last 6 Months'**
  String get dashboardRevenueLast6MonthsTitle;

  /// No description provided for @dashboardNoPaymentDataYetLabel.
  ///
  /// In en, this message translates to:
  /// **'No payment data yet'**
  String get dashboardNoPaymentDataYetLabel;

  /// No description provided for @dashboardFinancialOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get dashboardFinancialOverviewTitle;

  /// No description provided for @dashboardCollectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get dashboardCollectedLabel;

  /// No description provided for @dashboardInvoiceCountOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice overdue} other{{count} invoices overdue}}'**
  String dashboardInvoiceCountOverdueLabel(int count);

  /// No description provided for @dashboardLastNLabel.
  ///
  /// In en, this message translates to:
  /// **'Last {n}'**
  String dashboardLastNLabel(int n);

  /// No description provided for @labelCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get labelCustomer;

  /// No description provided for @labelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get labelAmount;

  /// No description provided for @dashboardZeroLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'0 left'**
  String get dashboardZeroLeftLabel;

  /// No description provided for @labelStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get labelStock;

  /// No description provided for @actionPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get actionPay;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardPdfActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'PDF Actions'**
  String get dashboardPdfActionsTooltip;

  /// No description provided for @dashboardActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get dashboardActionsTooltip;

  /// No description provided for @dashboardTopCustomersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Customers'**
  String get dashboardTopCustomersTitle;

  /// No description provided for @dashboardTopProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Products'**
  String get dashboardTopProductsTitle;

  /// No description provided for @dashboardUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'{qty} units'**
  String dashboardUnitsLabel(String qty);

  /// No description provided for @dashboardBetaBadge.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get dashboardBetaBadge;

  /// No description provided for @dashboardOutOfStockSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get dashboardOutOfStockSectionTitle;

  /// No description provided for @dashboardItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String dashboardItemCountLabel(int count);

  /// No description provided for @dashboardTapToRestockLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to restock'**
  String get dashboardTapToRestockLabel;

  /// No description provided for @createInvoiceUnsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get createInvoiceUnsavedChangesTitle;

  /// No description provided for @createInvoiceUnsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes in this invoice. Save them before leaving?'**
  String get createInvoiceUnsavedChangesMessage;

  /// No description provided for @createInvoiceKeepEditingButton.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get createInvoiceKeepEditingButton;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @createInvoiceErrorLoadingDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {e}'**
  String createInvoiceErrorLoadingDataMessage(String e);

  /// No description provided for @createInvoiceInsufficientStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Stock'**
  String get createInvoiceInsufficientStockTitle;

  /// No description provided for @createInvoiceInsufficientStockMessage.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} unit(s) available. Add {qty} anyway?'**
  String createInvoiceInsufficientStockMessage(int stock, double qty);

  /// No description provided for @createInvoiceAddAnywayButton.
  ///
  /// In en, this message translates to:
  /// **'Add Anyway'**
  String get createInvoiceAddAnywayButton;

  /// No description provided for @createInvoiceOutOfStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get createInvoiceOutOfStockTitle;

  /// No description provided for @createInvoiceOutOfStockMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is out of stock. Add anyway?'**
  String createInvoiceOutOfStockMessage(String name);

  /// No description provided for @createInvoiceUnlimitedStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Stock'**
  String get createInvoiceUnlimitedStockLabel;

  /// No description provided for @createInvoiceAvailableStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Stock: {stock}'**
  String createInvoiceAvailableStockLabel(int stock);

  /// No description provided for @fieldDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get fieldDiscountLabel;

  /// No description provided for @fieldUnitPriceOverrideLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (override)'**
  String get fieldUnitPriceOverrideLabel;

  /// No description provided for @fieldExtraCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra Cost (optional)'**
  String get fieldExtraCostLabel;

  /// No description provided for @fieldInsertAtPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Insert at position'**
  String get fieldInsertAtPositionLabel;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @createInvoiceProductAlreadyAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'This product has already been added'**
  String get createInvoiceProductAlreadyAddedMessage;

  /// No description provided for @createInvoiceCustomerNameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please provide customer name'**
  String get createInvoiceCustomerNameRequiredMessage;

  /// No description provided for @createInvoiceAtLeastOneItemRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one item'**
  String get createInvoiceAtLeastOneItemRequiredMessage;

  /// No description provided for @createInvoiceCreatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{invoiceTypeLabel} created successfully!'**
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel);

  /// No description provided for @createInvoiceErrorCreatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error creating invoice: {e}'**
  String createInvoiceErrorCreatingMessage(String e);

  /// No description provided for @createInvoiceEditItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get createInvoiceEditItemTitle;

  /// No description provided for @createInvoiceCustomItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Item'**
  String get createInvoiceCustomItemTitle;

  /// No description provided for @fieldItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get fieldItemNameLabel;

  /// No description provided for @fieldAliasForPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Alias (for PDF)'**
  String get fieldAliasForPdfLabel;

  /// No description provided for @fieldUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get fieldUnitPriceLabel;

  /// No description provided for @fieldRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get fieldRateLabel;

  /// No description provided for @fieldTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get fieldTaxRateLabel;

  /// No description provided for @fieldPriceIncludesTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Price includes tax'**
  String get fieldPriceIncludesTaxLabel;

  /// No description provided for @createInvoicePhoneAlreadyInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Number Already In Use'**
  String get createInvoicePhoneAlreadyInUseTitle;

  /// No description provided for @createInvoicePhoneAlreadyInUseMessage.
  ///
  /// In en, this message translates to:
  /// **'This phone number belongs to \"{ownerName}\".\n\nCannot save this customer with a phone number that already belongs to someone else.'**
  String createInvoicePhoneAlreadyInUseMessage(String ownerName);

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @createInvoiceCustomerNameRequiredBeforeSavingMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a customer name before saving'**
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage;

  /// No description provided for @createInvoicePhoneChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Number Changed'**
  String get createInvoicePhoneChangedTitle;

  /// No description provided for @createInvoicePhoneChangedMessage.
  ///
  /// In en, this message translates to:
  /// **'The phone number for \"{name}\" was changed.\n\nUpdate their existing record, or save these details as a new customer?'**
  String createInvoicePhoneChangedMessage(String name);

  /// No description provided for @createInvoiceSaveAsNewButton.
  ///
  /// In en, this message translates to:
  /// **'Save as New'**
  String get createInvoiceSaveAsNewButton;

  /// No description provided for @createInvoiceUpdateExistingButton.
  ///
  /// In en, this message translates to:
  /// **'Update Existing'**
  String get createInvoiceUpdateExistingButton;

  /// No description provided for @createInvoiceCustomerUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} updated in customer list'**
  String createInvoiceCustomerUpdatedMessage(String name);

  /// No description provided for @createInvoiceCustomerAlreadyExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Already Exists'**
  String get createInvoiceCustomerAlreadyExistsTitle;

  /// No description provided for @createInvoiceCustomerAlreadyExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is already saved with this phone number.\n\nUse their existing details, or update their record with the current information?'**
  String createInvoiceCustomerAlreadyExistsMessage(String name);

  /// No description provided for @createInvoiceUseExistingButton.
  ///
  /// In en, this message translates to:
  /// **'Use Existing'**
  String get createInvoiceUseExistingButton;

  /// No description provided for @createInvoiceUsingExistingCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Using existing customer \"{name}\"'**
  String createInvoiceUsingExistingCustomerMessage(String name);

  /// No description provided for @createInvoiceCustomerSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} saved to customer list'**
  String createInvoiceCustomerSavedMessage(String name);

  /// No description provided for @createInvoiceCustomerRecordGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Customer record no longer exists'**
  String get createInvoiceCustomerRecordGoneMessage;

  /// No description provided for @createInvoiceCustomerRefreshedMessage.
  ///
  /// In en, this message translates to:
  /// **'Customer details refreshed'**
  String get createInvoiceCustomerRefreshedMessage;

  /// No description provided for @fieldLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get fieldLabelLabel;

  /// No description provided for @hintLabelExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shipping'**
  String get hintLabelExample;

  /// No description provided for @tooltipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tooltipRemove;

  /// No description provided for @createInvoiceAddRowButton.
  ///
  /// In en, this message translates to:
  /// **'Add Row'**
  String get createInvoiceAddRowButton;

  /// No description provided for @fieldDiscountPerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount per unit'**
  String get fieldDiscountPerUnitLabel;

  /// No description provided for @createInvoiceDiscountPerUnitFormulaOn.
  ///
  /// In en, this message translates to:
  /// **'(price − discount) × qty'**
  String get createInvoiceDiscountPerUnitFormulaOn;

  /// No description provided for @createInvoiceDiscountPerUnitFormulaOff.
  ///
  /// In en, this message translates to:
  /// **'(price × qty) − discount'**
  String get createInvoiceDiscountPerUnitFormulaOff;

  /// No description provided for @createInvoicePrevBalanceShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Prev. Balance'**
  String get createInvoicePrevBalanceShortLabel;

  /// No description provided for @createInvoicePreviousBalanceDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous Balance Due'**
  String get createInvoicePreviousBalanceDueLabel;

  /// No description provided for @createInvoiceDueShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get createInvoiceDueShortLabel;

  /// No description provided for @createInvoiceTotalDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Due'**
  String get createInvoiceTotalDueLabel;

  /// No description provided for @createInvoiceUpdatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{invoiceTypeLabel} updated successfully!'**
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel);

  /// No description provided for @createInvoiceErrorUpdatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error updating invoice: {e}'**
  String createInvoiceErrorUpdatingMessage(String e);

  /// No description provided for @createInvoiceCreatedHeadline.
  ///
  /// In en, this message translates to:
  /// **'{invoiceTypeLabel} Created Successfully!'**
  String createInvoiceCreatedHeadline(String invoiceTypeLabel);

  /// No description provided for @createInvoiceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'{invoiceTypeLabel} ID: {invoiceNumber}'**
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber);

  /// No description provided for @createInvoiceViewDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get createInvoiceViewDetailsLabel;

  /// No description provided for @createInvoicePreviewPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get createInvoicePreviewPdfLabel;

  /// No description provided for @createInvoicePreviewPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF (Shortcut: Ctrl+o)'**
  String get createInvoicePreviewPdfTooltip;

  /// No description provided for @createInvoicePrintPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get createInvoicePrintPdfLabel;

  /// No description provided for @createInvoicePrintPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Print PDF (Shortcut: Ctrl+p)'**
  String get createInvoicePrintPdfTooltip;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @createInvoiceCreateNewInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Invoice (Shortcut: Ctrl+q)'**
  String get createInvoiceCreateNewInvoiceButton;

  /// No description provided for @createInvoiceAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New {invoiceTypeLabel}'**
  String createInvoiceAppBarTitle(String invoiceTypeLabel);

  /// No description provided for @commonLoadingDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get commonLoadingDataMessage;

  /// No description provided for @createInvoiceAddItemBeforeCreatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item before creating the invoice.'**
  String get createInvoiceAddItemBeforeCreatingMessage;

  /// No description provided for @createInvoiceCreatedTitleShort.
  ///
  /// In en, this message translates to:
  /// **'{invoiceTypeLabel} Created'**
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel);

  /// No description provided for @createInvoiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {invoiceTypeLabel}'**
  String createInvoiceEditTitle(String invoiceTypeLabel);

  /// No description provided for @createInvoiceDuplicateAsTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate as {invoiceTypeLabel}'**
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel);

  /// No description provided for @createInvoiceNewShortLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get createInvoiceNewShortLabel;

  /// No description provided for @createInvoiceNewInvoiceShortcutLabel.
  ///
  /// In en, this message translates to:
  /// **'New Invoice (Shortcut: Ctrl+q)'**
  String get createInvoiceNewInvoiceShortcutLabel;

  /// No description provided for @createInvoiceSavingEllipsisLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get createInvoiceSavingEllipsisLabel;

  /// No description provided for @createInvoiceSaveCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Save customer'**
  String get createInvoiceSaveCustomerLabel;

  /// No description provided for @createInvoiceSelectExistingCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Select from existing'**
  String get createInvoiceSelectExistingCustomerButton;

  /// No description provided for @createInvoiceRefreshCustomerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh from saved customer'**
  String get createInvoiceRefreshCustomerTooltip;

  /// No description provided for @createInvoiceClearCustomerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear customer selection'**
  String get createInvoiceClearCustomerTooltip;

  /// No description provided for @fieldCustomerNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Name *'**
  String get fieldCustomerNameRequiredLabel;

  /// No description provided for @fieldBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get fieldBusinessNameLabel;

  /// No description provided for @fieldPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get fieldPhoneLabel;

  /// No description provided for @fieldGstinVatLabel.
  ///
  /// In en, this message translates to:
  /// **'GSTIN / VAT'**
  String get fieldGstinVatLabel;

  /// No description provided for @fieldEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmailLabel;

  /// No description provided for @fieldAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddressLabel;

  /// No description provided for @tooltipEditInLargerView.
  ///
  /// In en, this message translates to:
  /// **'Edit in larger view'**
  String get tooltipEditInLargerView;

  /// No description provided for @createInvoiceChooseCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a customer'**
  String get createInvoiceChooseCustomerTitle;

  /// No description provided for @createInvoiceSearchCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Search customer'**
  String get createInvoiceSearchCustomerLabel;

  /// No description provided for @createInvoiceNoCustomersFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get createInvoiceNoCustomersFoundMessage;

  /// No description provided for @createInvoiceDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'{invoiceTypeLabel} DETAILS'**
  String createInvoiceDetailsHeading(String invoiceTypeLabel);

  /// No description provided for @createInvoiceTypeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice type'**
  String get createInvoiceTypeFieldLabel;

  /// No description provided for @createInvoiceTypeLockedHelperText.
  ///
  /// In en, this message translates to:
  /// **'Type can\'t be changed after creation'**
  String get createInvoiceTypeLockedHelperText;

  /// No description provided for @createInvoiceOrderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order date'**
  String get createInvoiceOrderDateLabel;

  /// No description provided for @createInvoiceDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get createInvoiceDueDateLabel;

  /// No description provided for @createInvoiceGstTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'GST title'**
  String get createInvoiceGstTitleLabel;

  /// No description provided for @createInvoiceTaxTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax title'**
  String get createInvoiceTaxTitleLabel;

  /// No description provided for @gstTitleTaxInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoice'**
  String get gstTitleTaxInvoiceLabel;

  /// No description provided for @gstTitleBillOfSupplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill of Supply'**
  String get gstTitleBillOfSupplyLabel;

  /// No description provided for @gstTitleInvoiceCumBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice-cum-Bill of Supply'**
  String get gstTitleInvoiceCumBillLabel;

  /// No description provided for @gstTitleCashBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash Bill'**
  String get gstTitleCashBillLabel;

  /// No description provided for @gstTitleCreditNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Note'**
  String get gstTitleCreditNoteLabel;

  /// No description provided for @gstTitleDebitNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Debit Note'**
  String get gstTitleDebitNoteLabel;

  /// No description provided for @gstTitleRevisedInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Revised Invoice'**
  String get gstTitleRevisedInvoiceLabel;

  /// No description provided for @createInvoiceSearchProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Search & add a product or service (Ctrl+F)'**
  String get createInvoiceSearchProductLabel;

  /// No description provided for @createInvoiceCustomItemButton.
  ///
  /// In en, this message translates to:
  /// **'Custom item (Ctrl+M)'**
  String get createInvoiceCustomItemButton;

  /// No description provided for @createInvoiceNoProductsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get createInvoiceNoProductsFoundMessage;

  /// No description provided for @createInvoiceItemAlreadyInProductListMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists in product list'**
  String createInvoiceItemAlreadyInProductListMessage(String name);

  /// No description provided for @createInvoiceProductSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} saved to product list'**
  String createInvoiceProductSavedMessage(String name);

  /// No description provided for @createInvoiceSaveToProductListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save to product list'**
  String get createInvoiceSaveToProductListTooltip;

  /// No description provided for @tooltipEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get tooltipEditItem;

  /// No description provided for @tooltipRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get tooltipRemoveItem;

  /// No description provided for @createInvoiceNoItemsAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'No items added yet'**
  String get createInvoiceNoItemsAddedMessage;

  /// No description provided for @createInvoiceSearchHintMessage.
  ///
  /// In en, this message translates to:
  /// **'Search below or press Ctrl+F'**
  String get createInvoiceSearchHintMessage;

  /// No description provided for @createInvoiceDiscountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount'**
  String get createInvoiceDiscountFieldLabel;

  /// No description provided for @discountTypeAmountShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Amt'**
  String get discountTypeAmountShortLabel;

  /// No description provided for @createInvoiceNotesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get createInvoiceNotesOptionalLabel;

  /// No description provided for @createInvoiceNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Payment terms, thank-you note…'**
  String get createInvoiceNotesHint;

  /// No description provided for @createInvoiceNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get createInvoiceNotesTitle;

  /// No description provided for @createInvoiceHideNumberInPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide invoice number in PDF'**
  String get createInvoiceHideNumberInPdfLabel;

  /// No description provided for @createInvoiceCustomNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom number (optional)'**
  String get createInvoiceCustomNumberLabel;

  /// No description provided for @createInvoiceCustomNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. QUO-2026-014 — shown in PDF instead'**
  String get createInvoiceCustomNumberHint;

  /// No description provided for @createInvoiceEnableTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable tax'**
  String get createInvoiceEnableTaxLabel;

  /// No description provided for @createInvoiceGlobalRateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Global rate'**
  String get createInvoiceGlobalRateTooltip;

  /// No description provided for @createInvoicePerItemRateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Per item rate'**
  String get createInvoicePerItemRateTooltip;

  /// No description provided for @createInvoiceDefaultTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Default tax rate'**
  String get createInvoiceDefaultTaxRateLabel;

  /// No description provided for @createInvoiceTaxRateFromProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Tax rate from each product'**
  String get createInvoiceTaxRateFromProductMessage;

  /// No description provided for @createInvoiceInterStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interstate supply (IGST)'**
  String get createInvoiceInterStateLabel;

  /// No description provided for @createInvoicePaymentUpiAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment UPI account'**
  String get createInvoicePaymentUpiAccountLabel;

  /// No description provided for @commonNoneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNoneLabel;

  /// No description provided for @createInvoiceBankAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get createInvoiceBankAccountLabel;

  /// No description provided for @fieldSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get fieldSubtotalLabel;

  /// No description provided for @createInvoiceDiscountColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount:'**
  String get createInvoiceDiscountColonLabel;

  /// No description provided for @fieldTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get fieldTaxLabel;

  /// No description provided for @createInvoiceExtraCostFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra Cost'**
  String get createInvoiceExtraCostFallbackLabel;

  /// No description provided for @createInvoiceDiscountPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount ({toStringAsFixed}%):'**
  String createInvoiceDiscountPercentLabel(String toStringAsFixed);

  /// No description provided for @createInvoiceInvoiceDiscountColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discount:'**
  String get createInvoiceInvoiceDiscountColonLabel;

  /// No description provided for @fieldTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get fieldTotalLabel;

  /// No description provided for @createInvoicePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get createInvoicePreviewLabel;

  /// No description provided for @createInvoicePreviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview (Shortcut: Ctrl+o)'**
  String get createInvoicePreviewTooltip;

  /// No description provided for @createInvoiceDownloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get createInvoiceDownloadLabel;

  /// No description provided for @createInvoicePrintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Print (Shortcut: Ctrl+p)'**
  String get createInvoicePrintTooltip;

  /// No description provided for @fieldUnitOverrideLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit (override)'**
  String get fieldUnitOverrideLabel;

  /// No description provided for @commonCustomEllipsisLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get commonCustomEllipsisLabel;

  /// No description provided for @fieldCustomUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom unit'**
  String get fieldCustomUnitLabel;

  /// No description provided for @invoiceMgmtMoveToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get invoiceMgmtMoveToTrashTitle;

  /// No description provided for @invoiceMgmtMoveToTrashBody.
  ///
  /// In en, this message translates to:
  /// **'Move Invoice #{number} to trash?'**
  String invoiceMgmtMoveToTrashBody(String number);

  /// No description provided for @invoiceMgmtMovedToTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'Invoice moved to trash.'**
  String get invoiceMgmtMovedToTrashMessage;

  /// No description provided for @invoiceMgmtFailedToLoadMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoices: {error}'**
  String invoiceMgmtFailedToLoadMessage(String error);

  /// No description provided for @invoiceMgmtExportToCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {type} to CSV'**
  String invoiceMgmtExportToCsvTitle(String type);

  /// No description provided for @invoiceMgmtExportAllRecordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Export All Records'**
  String get invoiceMgmtExportAllRecordsLabel;

  /// No description provided for @invoiceMgmtFilterByDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Or filter by date range:'**
  String get invoiceMgmtFilterByDateRangeLabel;

  /// No description provided for @invoiceMgmtFromDateLabel.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get invoiceMgmtFromDateLabel;

  /// No description provided for @invoiceMgmtToDateLabel.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get invoiceMgmtToDateLabel;

  /// No description provided for @invoiceMgmtDateRangeInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'To date must be after From date.'**
  String get invoiceMgmtDateRangeInvalidMessage;

  /// No description provided for @actionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// No description provided for @invoiceMgmtExportedRecordsMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 record to: {path}} other{Exported {count} records to: {path}}}'**
  String invoiceMgmtExportedRecordsMessage(int count, String path);

  /// No description provided for @invoiceMgmtExportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String invoiceMgmtExportFailedMessage(String error);

  /// No description provided for @invoiceMgmtBulkMoveToTrashBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 invoice to trash?} other{Move {count} invoices to trash?}}'**
  String invoiceMgmtBulkMoveToTrashBody(int count);

  /// No description provided for @invoiceMgmtBulkMovedToTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice moved to trash.} other{{count} invoices moved to trash.}}'**
  String invoiceMgmtBulkMovedToTrashMessage(int count);

  /// No description provided for @invoiceMgmtBulkDeleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Bulk delete failed: {error}'**
  String invoiceMgmtBulkDeleteFailedMessage(String error);

  /// No description provided for @invoiceMgmtBulkExportedCsvMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 invoice to CSV} other{Exported {count} invoices to CSV}}'**
  String invoiceMgmtBulkExportedCsvMessage(int count);

  /// No description provided for @invoiceMgmtCsvExportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'CSV export failed: {error}'**
  String invoiceMgmtCsvExportFailedMessage(String error);

  /// No description provided for @invoiceMgmtDownloadPdfsTitle.
  ///
  /// In en, this message translates to:
  /// **'Download PDFs'**
  String get invoiceMgmtDownloadPdfsTitle;

  /// No description provided for @invoiceMgmtSavePdfsPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{How would you like to save 1 PDF?} other{How would you like to save {count} PDFs?}}'**
  String invoiceMgmtSavePdfsPromptMessage(int count);

  /// No description provided for @invoiceMgmtSaveToFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Save to Folder'**
  String get invoiceMgmtSaveToFolderLabel;

  /// No description provided for @invoiceMgmtSaveAsZipLabel.
  ///
  /// In en, this message translates to:
  /// **'Save as ZIP'**
  String get invoiceMgmtSaveAsZipLabel;

  /// No description provided for @invoiceMgmtChooseFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose folder to save PDFs'**
  String get invoiceMgmtChooseFolderDialogTitle;

  /// No description provided for @invoiceMgmtSaveZipDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save ZIP file'**
  String get invoiceMgmtSaveZipDialogTitle;

  /// No description provided for @invoiceMgmtCreatingZipLabel.
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP'**
  String get invoiceMgmtCreatingZipLabel;

  /// No description provided for @invoiceMgmtGeneratingPdfsLabel.
  ///
  /// In en, this message translates to:
  /// **'Generating PDFs'**
  String get invoiceMgmtGeneratingPdfsLabel;

  /// No description provided for @invoiceMgmtProcessingPdfsMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Processing 1 PDF...} other{Processing {count} PDFs...}}'**
  String invoiceMgmtProcessingPdfsMessage(int count);

  /// No description provided for @invoiceMgmtSavedToMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String invoiceMgmtSavedToMessage(String path);

  /// No description provided for @invoiceMgmtPdfExportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'PDF export failed: {error}'**
  String invoiceMgmtPdfExportFailedMessage(String error);

  /// No description provided for @invoiceMgmtDownloadByFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Download PDFs by Filter'**
  String get invoiceMgmtDownloadByFilterTitle;

  /// No description provided for @invoiceMgmtByDateLabel.
  ///
  /// In en, this message translates to:
  /// **'By Date'**
  String get invoiceMgmtByDateLabel;

  /// No description provided for @invoiceMgmtByInvoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'By Invoice Number'**
  String get invoiceMgmtByInvoiceNumberLabel;

  /// No description provided for @invoiceMgmtFromInvoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'From invoice #'**
  String get invoiceMgmtFromInvoiceNumberLabel;

  /// No description provided for @invoiceMgmtToInvoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'To invoice #'**
  String get invoiceMgmtToInvoiceNumberLabel;

  /// No description provided for @invoiceMgmtCheckCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Check count'**
  String get invoiceMgmtCheckCountLabel;

  /// No description provided for @invoiceMgmtInvoicesExceedLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} invoices — exceeds limit of {limit}'**
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit);

  /// No description provided for @invoiceMgmtInvoicesMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice match} other{{count} invoices match}}'**
  String invoiceMgmtInvoicesMatchMessage(int count);

  /// No description provided for @invoiceMgmtMaxPdfsPerDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'Max {limit} PDFs per download. Narrow your filter.'**
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit);

  /// No description provided for @invoiceMgmtNoInvoicesForFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'No invoices found for the selected filter.'**
  String get invoiceMgmtNoInvoicesForFilterMessage;

  /// No description provided for @invoiceMgmtFilterExceedsLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Filter returned {count} invoices — max is {limit}.'**
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit);

  /// No description provided for @invoiceMgmtFilterInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Invoices'**
  String get invoiceMgmtFilterInvoicesTitle;

  /// No description provided for @invoiceMgmtHideFullyPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide fully paid invoices'**
  String get invoiceMgmtHideFullyPaidLabel;

  /// No description provided for @invoiceMgmtPaymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get invoiceMgmtPaymentStatusLabel;

  /// No description provided for @invoiceMgmtDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get invoiceMgmtDueDateLabel;

  /// No description provided for @invoiceMgmtInvoiceDateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice date range'**
  String get invoiceMgmtInvoiceDateRangeLabel;

  /// No description provided for @invoiceMgmtInvoiceNumberRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice # range'**
  String get invoiceMgmtInvoiceNumberRangeLabel;

  /// No description provided for @invoiceMgmtFromHashLabel.
  ///
  /// In en, this message translates to:
  /// **'From #'**
  String get invoiceMgmtFromHashLabel;

  /// No description provided for @invoiceMgmtToHashLabel.
  ///
  /// In en, this message translates to:
  /// **'To #'**
  String get invoiceMgmtToHashLabel;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @invoiceMgmtSortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get invoiceMgmtSortByTitle;

  /// No description provided for @invoiceMgmtSearchHintMessage.
  ///
  /// In en, this message translates to:
  /// **'Search by Invoice ID or Customer Name…'**
  String get invoiceMgmtSearchHintMessage;

  /// No description provided for @invoiceMgmtFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get invoiceMgmtFilterLabel;

  /// No description provided for @invoiceMgmtSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get invoiceMgmtSortLabel;

  /// No description provided for @invoiceMgmtTotalPageStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}   ·   Page {page}/{totalPages}'**
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages);

  /// No description provided for @invoiceMgmtSelectedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String invoiceMgmtSelectedCountLabel(int count);

  /// No description provided for @invoiceMgmtDeselectLabel.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get invoiceMgmtDeselectLabel;

  /// No description provided for @invoiceMgmtSelectPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Page'**
  String get invoiceMgmtSelectPageLabel;

  /// No description provided for @invoiceMgmtMarkPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get invoiceMgmtMarkPaidLabel;

  /// No description provided for @invoiceMgmtCsvLabel.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get invoiceMgmtCsvLabel;

  /// No description provided for @invoiceMgmtPdfsLabel.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get invoiceMgmtPdfsLabel;

  /// No description provided for @invoiceMgmtTrashLabel.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get invoiceMgmtTrashLabel;

  /// No description provided for @actionApplyPayment.
  ///
  /// In en, this message translates to:
  /// **'Apply Payment'**
  String get actionApplyPayment;

  /// No description provided for @invoiceMgmtMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get invoiceMgmtMoreActionsTooltip;

  /// No description provided for @invoiceMgmtColSlNo.
  ///
  /// In en, this message translates to:
  /// **'Sl No'**
  String get invoiceMgmtColSlNo;

  /// No description provided for @invoiceMgmtColInvoiceCustomer.
  ///
  /// In en, this message translates to:
  /// **'Invoice / Customer'**
  String get invoiceMgmtColInvoiceCustomer;

  /// No description provided for @invoiceMgmtColTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get invoiceMgmtColTitle;

  /// No description provided for @invoiceMgmtColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get invoiceMgmtColDate;

  /// No description provided for @invoiceMgmtColItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get invoiceMgmtColItems;

  /// No description provided for @invoiceMgmtColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get invoiceMgmtColStatus;

  /// No description provided for @invoiceMgmtColOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get invoiceMgmtColOutstanding;

  /// No description provided for @invoiceMgmtColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get invoiceMgmtColActions;

  /// No description provided for @invoiceMgmtRowsPerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Rows per page:'**
  String get invoiceMgmtRowsPerPageLabel;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @invoiceMgmtPageOfLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {totalPages}'**
  String invoiceMgmtPageOfLabel(int page, int totalPages);

  /// No description provided for @invoiceMgmtNoResultsForQueryMessage.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String invoiceMgmtNoResultsForQueryMessage(String query);

  /// No description provided for @invoiceMgmtNoFilteredTypeFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No {type} found'**
  String invoiceMgmtNoFilteredTypeFoundMessage(String type);

  /// No description provided for @invoiceMgmtCreateFirstTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first {type} to see it here'**
  String invoiceMgmtCreateFirstTypeMessage(String type);

  /// No description provided for @invoiceMgmtTryAdjustingFiltersMessage.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get invoiceMgmtTryAdjustingFiltersMessage;

  /// No description provided for @invoiceMgmtDownloadByRangeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download PDFs by date or invoice range'**
  String get invoiceMgmtDownloadByRangeTooltip;

  /// No description provided for @invoiceMgmtExportAllCsvTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export all to CSV'**
  String get invoiceMgmtExportAllCsvTooltip;

  /// No description provided for @invoiceMgmtDownloadByRangeMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Download PDFs by range'**
  String get invoiceMgmtDownloadByRangeMenuLabel;

  /// No description provided for @invoiceMgmtManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Management'**
  String invoiceMgmtManagementTitle(String type);

  /// No description provided for @invoiceMgmtOverdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoiceMgmtOverdueBadge;

  /// No description provided for @invoiceMgmtTodayBadge.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get invoiceMgmtTodayBadge;

  /// No description provided for @invoiceMgmtTrashIsEmptyLabel.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get invoiceMgmtTrashIsEmptyLabel;

  /// No description provided for @actionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// No description provided for @invoiceMgmtPermanentlyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get invoiceMgmtPermanentlyDeleteTitle;

  /// No description provided for @invoiceMgmtPermanentlyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete Invoice #{number}? This cannot be undone.'**
  String invoiceMgmtPermanentlyDeleteBody(String number);

  /// No description provided for @invoiceMgmtInvoiceRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Invoice restored.'**
  String get invoiceMgmtInvoiceRestoredMessage;

  /// No description provided for @invoiceMgmtAnyDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get invoiceMgmtAnyDateLabel;

  /// No description provided for @invoiceMgmtStatusAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get invoiceMgmtStatusAllLabel;

  /// No description provided for @invoiceMgmtDueAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All Dues'**
  String get invoiceMgmtDueAllLabel;

  /// No description provided for @invoiceMgmtDueTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get invoiceMgmtDueTodayLabel;

  /// No description provided for @invoiceMgmtDueWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Due This Week'**
  String get invoiceMgmtDueWeekLabel;

  /// No description provided for @invoiceMgmtDueMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Due This Month'**
  String get invoiceMgmtDueMonthLabel;

  /// No description provided for @invoiceMgmtSortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get invoiceMgmtSortRecentlyAdded;

  /// No description provided for @invoiceMgmtSortOldestAdded.
  ///
  /// In en, this message translates to:
  /// **'Oldest Added'**
  String get invoiceMgmtSortOldestAdded;

  /// No description provided for @invoiceMgmtSortDateNewest.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date (Newest First)'**
  String get invoiceMgmtSortDateNewest;

  /// No description provided for @invoiceMgmtSortDateOldest.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date (Oldest First)'**
  String get invoiceMgmtSortDateOldest;

  /// No description provided for @invoiceMgmtSortCustomerAZ.
  ///
  /// In en, this message translates to:
  /// **'Customer Name (A–Z)'**
  String get invoiceMgmtSortCustomerAZ;

  /// No description provided for @invoiceMgmtSortCustomerZA.
  ///
  /// In en, this message translates to:
  /// **'Customer Name (Z–A)'**
  String get invoiceMgmtSortCustomerZA;

  /// No description provided for @invoiceMgmtMarkAsPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get invoiceMgmtMarkAsPaidTitle;

  /// No description provided for @invoiceMgmtMarkAsPaidBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Mark 1 invoice as fully paid?} other{Mark {count} invoices as fully paid?}}'**
  String invoiceMgmtMarkAsPaidBody(int count);

  /// No description provided for @invoiceMgmtAlreadyPaidNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'\n({count} already paid — will be skipped)'**
  String invoiceMgmtAlreadyPaidNoteMessage(int count);

  /// No description provided for @invoiceMgmtAllAlreadyPaidMessage.
  ///
  /// In en, this message translates to:
  /// **'All selected invoices are already fully paid.'**
  String get invoiceMgmtAllAlreadyPaidMessage;

  /// No description provided for @invoiceMgmtMarkedAsPaidMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice marked as paid.} other{{count} invoices marked as paid.}}'**
  String invoiceMgmtMarkedAsPaidMessage(int count);

  /// No description provided for @invoiceMgmtMarkAsPaidFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as paid: {error}'**
  String invoiceMgmtMarkAsPaidFailedMessage(String error);

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldNameLabel;

  /// No description provided for @customerMgmtEditCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get customerMgmtEditCustomerTitle;

  /// No description provided for @customerMgmtViewCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'View Customer'**
  String get customerMgmtViewCustomerTitle;

  /// No description provided for @fieldTaxVatNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'{taxWord} / VAT Number'**
  String fieldTaxVatNumberLabel(String taxWord);

  /// No description provided for @customerMgmtUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully!'**
  String get customerMgmtUpdatedMessage;

  /// No description provided for @fieldRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String fieldRequiredMessage(String field);

  /// No description provided for @customerMgmtConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get customerMgmtConfirmDeleteTitle;

  /// No description provided for @customerMgmtDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String customerMgmtDeleteConfirmBody(String name);

  /// No description provided for @customerMgmtDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted successfully!'**
  String get customerMgmtDeletedMessage;

  /// No description provided for @customerMgmtSaveSampleCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Sample CSV'**
  String get customerMgmtSaveSampleCsvDialogTitle;

  /// No description provided for @customerMgmtSampleSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sample CSV saved successfully!'**
  String get customerMgmtSampleSavedMessage;

  /// No description provided for @customerMgmtErrorSavingSampleMessage.
  ///
  /// In en, this message translates to:
  /// **'Error saving sample: {error}'**
  String customerMgmtErrorSavingSampleMessage(String error);

  /// No description provided for @customerMgmtImportCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Customers from CSV'**
  String get customerMgmtImportCsvDialogTitle;

  /// No description provided for @customerMgmtCsvFormatInstructionMessage.
  ///
  /// In en, this message translates to:
  /// **'Your CSV file must use the following column headers (exact spelling, any order):'**
  String get customerMgmtCsvFormatInstructionMessage;

  /// No description provided for @customerMgmtCsvColColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get customerMgmtCsvColColumnHeader;

  /// No description provided for @customerMgmtCsvColRequiredHeader.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get customerMgmtCsvColRequiredHeader;

  /// No description provided for @customerMgmtCsvColDescriptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get customerMgmtCsvColDescriptionHeader;

  /// No description provided for @commonYesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYesLabel;

  /// No description provided for @commonNoLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNoLabel;

  /// No description provided for @customerMgmtCsvDescName.
  ///
  /// In en, this message translates to:
  /// **'Customer full name'**
  String get customerMgmtCsvDescName;

  /// No description provided for @customerMgmtCsvDescEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get customerMgmtCsvDescEmail;

  /// No description provided for @customerMgmtCsvDescPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get customerMgmtCsvDescPhone;

  /// No description provided for @customerMgmtCsvDescAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get customerMgmtCsvDescAddress;

  /// No description provided for @customerMgmtCsvDescBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Company / business name'**
  String get customerMgmtCsvDescBusinessName;

  /// No description provided for @customerMgmtCsvDescTaxNumber.
  ///
  /// In en, this message translates to:
  /// **'Tax / VAT / GSTIN number'**
  String get customerMgmtCsvDescTaxNumber;

  /// No description provided for @customerMgmtCsvMaxRowsNote.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} rows per import.'**
  String customerMgmtCsvMaxRowsNote(int max);

  /// No description provided for @customerMgmtCsvDuplicatesNote.
  ///
  /// In en, this message translates to:
  /// **'Duplicates are detected by email or phone. You will be asked to overwrite or skip each one.'**
  String get customerMgmtCsvDuplicatesNote;

  /// No description provided for @customerMgmtCsvMissingNameNote.
  ///
  /// In en, this message translates to:
  /// **'Rows missing a name are skipped and reported at the end.'**
  String get customerMgmtCsvMissingNameNote;

  /// No description provided for @customerMgmtCsvEncodingNote.
  ///
  /// In en, this message translates to:
  /// **'UTF-8 encoding recommended. Excel BOM is handled automatically.'**
  String get customerMgmtCsvEncodingNote;

  /// No description provided for @customerMgmtDownloadSampleCsvButton.
  ///
  /// In en, this message translates to:
  /// **'Download Sample CSV'**
  String get customerMgmtDownloadSampleCsvButton;

  /// No description provided for @customerMgmtChooseFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get customerMgmtChooseFileButton;

  /// No description provided for @customerMgmtSelectCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Customer CSV'**
  String get customerMgmtSelectCsvDialogTitle;

  /// No description provided for @customerMgmtCsvEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'CSV file is empty.'**
  String get customerMgmtCsvEmptyMessage;

  /// No description provided for @customerMgmtCsvMissingNameColumnMessage.
  ///
  /// In en, this message translates to:
  /// **'CSV missing required column: \"name\"'**
  String get customerMgmtCsvMissingNameColumnMessage;

  /// No description provided for @customerMgmtUnknownColumnMessage.
  ///
  /// In en, this message translates to:
  /// **'Unknown column \"{col}\". Expected: {expected}'**
  String customerMgmtUnknownColumnMessage(String col, String expected);

  /// No description provided for @customerMgmtCsvTooManyRowsMessage.
  ///
  /// In en, this message translates to:
  /// **'CSV has {count} rows. Maximum is {max}. Please split the file.'**
  String customerMgmtCsvTooManyRowsMessage(int count, int max);

  /// No description provided for @customerMgmtImportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing Customers'**
  String get customerMgmtImportingTitle;

  /// No description provided for @customerMgmtValidatingRowsMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Checking for duplicates and validating 1 row...} other{Checking for duplicates and validating {count} rows...}}'**
  String customerMgmtValidatingRowsMessage(int count);

  /// No description provided for @customerMgmtRowMissingNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Row {n}: missing name — skipped'**
  String customerMgmtRowMissingNameMessage(int n);

  /// No description provided for @customerMgmtCsvReadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error reading CSV: {error}'**
  String customerMgmtCsvReadErrorMessage(String error);

  /// No description provided for @customerMgmtImportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get customerMgmtImportPreviewTitle;

  /// No description provided for @customerMgmtNewCountChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new} other{{count} new}}'**
  String customerMgmtNewCountChip(int count);

  /// No description provided for @customerMgmtDuplicatesCountChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 duplicate} other{{count} duplicates}}'**
  String customerMgmtDuplicatesCountChip(int count);

  /// No description provided for @customerMgmtErrorsCountChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 error} other{{count} errors}}'**
  String customerMgmtErrorsCountChip(int count);

  /// No description provided for @customerMgmtDuplicatesMatchedLabel.
  ///
  /// In en, this message translates to:
  /// **'Duplicates (matched by email or phone):'**
  String get customerMgmtDuplicatesMatchedLabel;

  /// No description provided for @customerMgmtOverwriteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Overwrite All'**
  String get customerMgmtOverwriteAllButton;

  /// No description provided for @customerMgmtSkipAllButton.
  ///
  /// In en, this message translates to:
  /// **'Skip All'**
  String get customerMgmtSkipAllButton;

  /// No description provided for @customerMgmtOverwriteLabel.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get customerMgmtOverwriteLabel;

  /// No description provided for @customerMgmtSkippedRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped rows (errors):'**
  String get customerMgmtSkippedRowsLabel;

  /// No description provided for @customerMgmtErrorBulletLabel.
  ///
  /// In en, this message translates to:
  /// **'• {error}'**
  String customerMgmtErrorBulletLabel(String error);

  /// No description provided for @customerMgmtWillImportMessage.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Will import 1 customer.} other{Will import {total} customers.}}'**
  String customerMgmtWillImportMessage(int total);

  /// No description provided for @customerMgmtImportCountButton.
  ///
  /// In en, this message translates to:
  /// **'Import {total}'**
  String customerMgmtImportCountButton(int total);

  /// No description provided for @customerMgmtDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Customers'**
  String get customerMgmtDeleteAllTitle;

  /// No description provided for @customerMgmtNoCustomersToDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'No customers to delete.'**
  String get customerMgmtNoCustomersToDeleteMessage;

  /// No description provided for @customerMgmtDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete all 1 customer. Existing invoices are not affected. This cannot be undone.} other{This will permanently delete all {count} customers. Existing invoices are not affected. This cannot be undone.}}'**
  String customerMgmtDeleteAllBody(int count);

  /// No description provided for @customerMgmtDeleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get customerMgmtDeleteAllButton;

  /// No description provided for @customerMgmtAllDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'All customers deleted.'**
  String get customerMgmtAllDeletedMessage;

  /// No description provided for @customerMgmtDeleteAllErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error deleting customers: {error}'**
  String customerMgmtDeleteAllErrorMessage(String error);

  /// No description provided for @customerMgmtSaveCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Customer CSV'**
  String get customerMgmtSaveCsvDialogTitle;

  /// No description provided for @customerMgmtCsvExportedMessage.
  ///
  /// In en, this message translates to:
  /// **'CSV exported successfully!'**
  String get customerMgmtCsvExportedMessage;

  /// No description provided for @customerMgmtCsvExportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error exporting CSV: {error}'**
  String customerMgmtCsvExportErrorMessage(String error);

  /// No description provided for @customerMgmtSavePdfDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Customer PDF'**
  String get customerMgmtSavePdfDialogTitle;

  /// No description provided for @customerMgmtPdfExportedMessage.
  ///
  /// In en, this message translates to:
  /// **'PDF exported successfully!'**
  String get customerMgmtPdfExportedMessage;

  /// No description provided for @customerMgmtPdfExportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error exporting PDF: {error}'**
  String customerMgmtPdfExportErrorMessage(String error);

  /// No description provided for @customerMgmtTotalCustomersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get customerMgmtTotalCustomersLabel;

  /// No description provided for @customerMgmtAllCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All customers'**
  String get customerMgmtAllCustomersSubtitle;

  /// No description provided for @customerMgmtBusinessesLabel.
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get customerMgmtBusinessesLabel;

  /// No description provided for @customerMgmtRegisteredBusinessesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Registered businesses'**
  String get customerMgmtRegisteredBusinessesSubtitle;

  /// No description provided for @customerMgmtIndividualsLabel.
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get customerMgmtIndividualsLabel;

  /// No description provided for @customerMgmtIndividualCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Individual customers'**
  String get customerMgmtIndividualCustomersSubtitle;

  /// No description provided for @customerMgmtTaxRegisteredLabel.
  ///
  /// In en, this message translates to:
  /// **'{taxWord} Registered'**
  String customerMgmtTaxRegisteredLabel(String taxWord);

  /// No description provided for @customerMgmtWithTaxNumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With {taxWord} number'**
  String customerMgmtWithTaxNumberSubtitle(String taxWord);

  /// No description provided for @customerMgmtWithoutTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Without {taxWord}'**
  String customerMgmtWithoutTaxLabel(String taxWord);

  /// No description provided for @customerMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Management'**
  String get customerMgmtTitle;

  /// No description provided for @customerMgmtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your customers and contact details'**
  String get customerMgmtSubtitle;

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// No description provided for @customerMgmtExportPdfMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get customerMgmtExportPdfMenuLabel;

  /// No description provided for @customerMgmtNewCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get customerMgmtNewCustomerButton;

  /// No description provided for @customerMgmtSortNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get customerMgmtSortNameAZ;

  /// No description provided for @customerMgmtSortNameZA.
  ///
  /// In en, this message translates to:
  /// **'Name Z-A'**
  String get customerMgmtSortNameZA;

  /// No description provided for @customerMgmtSortIdOldest.
  ///
  /// In en, this message translates to:
  /// **'ID (oldest first)'**
  String get customerMgmtSortIdOldest;

  /// No description provided for @customerMgmtSortIdNewest.
  ///
  /// In en, this message translates to:
  /// **'ID (newest first)'**
  String get customerMgmtSortIdNewest;

  /// No description provided for @customerMgmtSortOutstandingHighLow.
  ///
  /// In en, this message translates to:
  /// **'Outstanding (high-low)'**
  String get customerMgmtSortOutstandingHighLow;

  /// No description provided for @customerMgmtSortOutstandingLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Outstanding (low-high)'**
  String get customerMgmtSortOutstandingLowHigh;

  /// No description provided for @customerMgmtWithOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'With Outstanding'**
  String get customerMgmtWithOutstandingLabel;

  /// No description provided for @customerMgmtSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers by name, business, phone, {taxWord}, email…'**
  String customerMgmtSearchHint(String taxWord);

  /// No description provided for @customerMgmtAllTaxStatusesLabel.
  ///
  /// In en, this message translates to:
  /// **'All {taxWord} statuses'**
  String customerMgmtAllTaxStatusesLabel(String taxWord);

  /// No description provided for @customerMgmtTaxRegisteredLowerLabel.
  ///
  /// In en, this message translates to:
  /// **'{taxWord} registered'**
  String customerMgmtTaxRegisteredLowerLabel(String taxWord);

  /// No description provided for @customerMgmtSortWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {label}'**
  String customerMgmtSortWithLabel(String label);

  /// No description provided for @customerMgmtColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get customerMgmtColumnsLabel;

  /// No description provided for @customerMgmtTaxVatNoColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'{taxWord} / VAT No'**
  String customerMgmtTaxVatNoColumnLabel(String taxWord);

  /// No description provided for @customerMgmtHideStatCardsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide stat cards'**
  String get customerMgmtHideStatCardsTooltip;

  /// No description provided for @customerMgmtShowStatCardsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show stat cards'**
  String get customerMgmtShowStatCardsTooltip;

  /// No description provided for @customerMgmtTabChipLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String customerMgmtTabChipLabel(String label, int count);

  /// No description provided for @customerMgmtColSlNo.
  ///
  /// In en, this message translates to:
  /// **'SL. NO.'**
  String get customerMgmtColSlNo;

  /// No description provided for @customerMgmtColNameBusiness.
  ///
  /// In en, this message translates to:
  /// **'NAME / BUSINESS'**
  String get customerMgmtColNameBusiness;

  /// No description provided for @customerMgmtColPhone.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get customerMgmtColPhone;

  /// No description provided for @customerMgmtColEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get customerMgmtColEmail;

  /// No description provided for @customerMgmtColTaxVatNo.
  ///
  /// In en, this message translates to:
  /// **'{taxWord} / VAT NO'**
  String customerMgmtColTaxVatNo(String taxWord);

  /// No description provided for @customerMgmtColAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get customerMgmtColAddress;

  /// No description provided for @customerMgmtColActions.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get customerMgmtColActions;

  /// No description provided for @customerMgmtViewStatementTooltip.
  ///
  /// In en, this message translates to:
  /// **'View Statement (in Reports)'**
  String get customerMgmtViewStatementTooltip;

  /// No description provided for @customerMgmtShowingRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Showing {from} to {to} of {total} customers'**
  String customerMgmtShowingRangeLabel(int from, int to, int total);

  /// No description provided for @customerMgmtRowsPerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Rows per page'**
  String get customerMgmtRowsPerPageLabel;

  /// No description provided for @customerMgmtOfTotalPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'of {totalPages}'**
  String customerMgmtOfTotalPagesLabel(int totalPages);

  /// No description provided for @customerMgmtAddAnotherLabel.
  ///
  /// In en, this message translates to:
  /// **'Add another after saving'**
  String get customerMgmtAddAnotherLabel;

  /// No description provided for @customerMgmtSaveCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Save Customer'**
  String get customerMgmtSaveCustomerButton;

  /// No description provided for @customerMgmtAddFirstCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to get started'**
  String get customerMgmtAddFirstCustomerSubtitle;

  /// No description provided for @customerMgmtTryAdjustingSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search'**
  String get customerMgmtTryAdjustingSearchSubtitle;

  /// No description provided for @customerMgmtLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading customers: {error}'**
  String customerMgmtLoadErrorMessage(String error);

  /// No description provided for @customerMgmtAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully!'**
  String get customerMgmtAddedMessage;

  /// No description provided for @customerMgmtSaveErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error saving customer: {error}'**
  String customerMgmtSaveErrorMessage(String error);

  /// No description provided for @customerMgmtImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 customer successfully!} other{Imported {count} customers successfully!}}'**
  String customerMgmtImportedMessage(int count);

  /// No description provided for @customerMgmtImportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Import error: {error}'**
  String customerMgmtImportErrorMessage(String error);

  /// No description provided for @taxWordGst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get taxWordGst;

  /// No description provided for @taxWordTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxWordTax;

  /// No description provided for @commonMoreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMoreLabel;

  /// No description provided for @productMgmtSellingAtLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Selling at a loss'**
  String get productMgmtSellingAtLossTitle;

  /// No description provided for @productMgmtSellingAtLossMessage.
  ///
  /// In en, this message translates to:
  /// **'Purchase price ({purchase}) is higher than sale price ({sale}). Save anyway?'**
  String productMgmtSellingAtLossMessage(String purchase, String sale);

  /// No description provided for @actionSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save Anyway'**
  String get actionSaveAnyway;

  /// No description provided for @productMgmtAdvancedInformationLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced Information'**
  String get productMgmtAdvancedInformationLabel;

  /// No description provided for @productMgmtStorageLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get productMgmtStorageLocationLabel;

  /// No description provided for @productMgmtContainerNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Container Number'**
  String get productMgmtContainerNumberLabel;

  /// No description provided for @productMgmtBatchNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch Number'**
  String get productMgmtBatchNumberLabel;

  /// No description provided for @productMgmtExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get productMgmtExpiryDateLabel;

  /// No description provided for @productMgmtManufactureDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Manufacture Date'**
  String get productMgmtManufactureDateLabel;

  /// No description provided for @productMgmtSupplierNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get productMgmtSupplierNameLabel;

  /// No description provided for @productMgmtSkuCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU Code'**
  String get productMgmtSkuCodeLabel;

  /// No description provided for @productMgmtNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get productMgmtNotesLabel;

  /// No description provided for @fieldEnterValidPriceMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter valid price'**
  String get fieldEnterValidPriceMessage;

  /// No description provided for @fieldEnterValidStockMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter valid stock'**
  String get fieldEnterValidStockMessage;

  /// No description provided for @fieldTaxRangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Tax must be between 0-100'**
  String get fieldTaxRangeMessage;

  /// No description provided for @productMgmtImportProductsCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Products from CSV'**
  String get productMgmtImportProductsCsvTitle;

  /// No description provided for @productMgmtCsvDescName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productMgmtCsvDescName;

  /// No description provided for @productMgmtCsvDescPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price (numeric)'**
  String get productMgmtCsvDescPrice;

  /// No description provided for @productMgmtCsvDescHsnCode.
  ///
  /// In en, this message translates to:
  /// **'HSN / SAC code'**
  String get productMgmtCsvDescHsnCode;

  /// No description provided for @productMgmtCsvDescDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get productMgmtCsvDescDescription;

  /// No description provided for @productMgmtCsvDescTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax % (0–100), default 0'**
  String get productMgmtCsvDescTaxRate;

  /// No description provided for @productMgmtCsvDescStock.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity, default 0'**
  String get productMgmtCsvDescStock;

  /// No description provided for @productMgmtCsvDescType.
  ///
  /// In en, this message translates to:
  /// **'\"product\" or \"service\", default product'**
  String get productMgmtCsvDescType;

  /// No description provided for @productMgmtCsvDescDefaultDiscount.
  ///
  /// In en, this message translates to:
  /// **'Flat discount amount (currency), default 0'**
  String get productMgmtCsvDescDefaultDiscount;

  /// No description provided for @productMgmtCsvDescPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price (numeric), default 0'**
  String get productMgmtCsvDescPurchasePrice;

  /// No description provided for @productMgmtCsvDescAliasName.
  ///
  /// In en, this message translates to:
  /// **'Local-language display name for PDFs'**
  String get productMgmtCsvDescAliasName;

  /// No description provided for @productMgmtCsvDescUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit of measure (e.g. kg, bag, pcs), default pcs'**
  String get productMgmtCsvDescUnit;

  /// No description provided for @productMgmtCsvDescUnlimitedStock.
  ///
  /// In en, this message translates to:
  /// **'1/true for unlimited stock, default 0'**
  String get productMgmtCsvDescUnlimitedStock;

  /// No description provided for @productMgmtCsvDescPriceIncludesTax.
  ///
  /// In en, this message translates to:
  /// **'1/true if price already includes tax, default 0'**
  String get productMgmtCsvDescPriceIncludesTax;

  /// No description provided for @productMgmtCsvDescStorageLocation.
  ///
  /// In en, this message translates to:
  /// **'Warehouse/shelf location'**
  String get productMgmtCsvDescStorageLocation;

  /// No description provided for @productMgmtCsvDescContainerNumber.
  ///
  /// In en, this message translates to:
  /// **'Container/box number'**
  String get productMgmtCsvDescContainerNumber;

  /// No description provided for @productMgmtCsvDescBatchNumber.
  ///
  /// In en, this message translates to:
  /// **'Batch/lot number'**
  String get productMgmtCsvDescBatchNumber;

  /// No description provided for @productMgmtCsvDescExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get productMgmtCsvDescExpiryDate;

  /// No description provided for @productMgmtCsvDescManufactureDate.
  ///
  /// In en, this message translates to:
  /// **'Manufacture date'**
  String get productMgmtCsvDescManufactureDate;

  /// No description provided for @productMgmtCsvDescSupplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier name'**
  String get productMgmtCsvDescSupplierName;

  /// No description provided for @productMgmtCsvDescSkuCode.
  ///
  /// In en, this message translates to:
  /// **'SKU code'**
  String get productMgmtCsvDescSkuCode;

  /// No description provided for @productMgmtCsvDescNotes.
  ///
  /// In en, this message translates to:
  /// **'Free-text notes'**
  String get productMgmtCsvDescNotes;

  /// No description provided for @productMgmtCsvDuplicateNote.
  ///
  /// In en, this message translates to:
  /// **'Duplicates are detected by product name (case-insensitive). You will be asked to overwrite or skip each one.'**
  String get productMgmtCsvDuplicateNote;

  /// No description provided for @productMgmtCsvMissingRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'Rows missing name or price are skipped and reported.'**
  String get productMgmtCsvMissingRequiredNote;

  /// No description provided for @productMgmtSelectCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Product CSV'**
  String get productMgmtSelectCsvDialogTitle;

  /// No description provided for @productMgmtCsvMissingPriceColumnMessage.
  ///
  /// In en, this message translates to:
  /// **'CSV missing required column: \"price\"'**
  String get productMgmtCsvMissingPriceColumnMessage;

  /// No description provided for @productMgmtRowInvalidPriceMessage.
  ///
  /// In en, this message translates to:
  /// **'Row {n}: invalid price \"{price}\" — skipped'**
  String productMgmtRowInvalidPriceMessage(int n, String price);

  /// No description provided for @productMgmtImportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing Products'**
  String get productMgmtImportingTitle;

  /// No description provided for @productMgmtDuplicatesMatchedByNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Duplicates (matched by name):'**
  String get productMgmtDuplicatesMatchedByNameLabel;

  /// No description provided for @productMgmtWillImportMessage.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Will import 1 product.} other{Will import {total} products.}}'**
  String productMgmtWillImportMessage(int total);

  /// No description provided for @productMgmtNoProductsToDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'No products to delete.'**
  String get productMgmtNoProductsToDeleteMessage;

  /// No description provided for @productMgmtDeleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Products'**
  String get productMgmtDeleteAllTitle;

  /// No description provided for @productMgmtDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete all 1 product. Existing invoices are not affected. This cannot be undone.} other{This will permanently delete all {count} products. Existing invoices are not affected. This cannot be undone.}}'**
  String productMgmtDeleteAllBody(int count);

  /// No description provided for @productMgmtAllDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'All products deleted.'**
  String get productMgmtAllDeletedMessage;

  /// No description provided for @productMgmtDeleteAllErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error deleting products: {error}'**
  String productMgmtDeleteAllErrorMessage(String error);

  /// No description provided for @productMgmtSaveProductsCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Products CSV'**
  String get productMgmtSaveProductsCsvDialogTitle;

  /// No description provided for @productMgmtExportToPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get productMgmtExportToPdfTitle;

  /// No description provided for @productMgmtExportPdfChoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Export the current page ({pageSize} products) or all {allCount} products?'**
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount);

  /// No description provided for @productMgmtCurrentPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Page'**
  String get productMgmtCurrentPageLabel;

  /// No description provided for @productMgmtAllProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get productMgmtAllProductsLabel;

  /// No description provided for @productMgmtSaveProductsPdfDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Products PDF'**
  String get productMgmtSaveProductsPdfDialogTitle;

  /// No description provided for @productMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productMgmtTitle;

  /// No description provided for @productMgmtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your products and services'**
  String get productMgmtSubtitle;

  /// No description provided for @productMgmtNewProductButton.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get productMgmtNewProductButton;

  /// No description provided for @productMgmtSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by name, alias, HSN/SAC, SKU…'**
  String get productMgmtSearchHint;

  /// No description provided for @productMgmtFilterByStockStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by stock status'**
  String get productMgmtFilterByStockStatusTooltip;

  /// No description provided for @productMgmtAllStockLevelsLabel.
  ///
  /// In en, this message translates to:
  /// **'All stock levels'**
  String get productMgmtAllStockLevelsLabel;

  /// No description provided for @productMgmtLowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productMgmtLowStockLabel;

  /// No description provided for @productMgmtLowStockTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get productMgmtLowStockTabLabel;

  /// No description provided for @productMgmtOutOfStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productMgmtOutOfStockLabel;

  /// No description provided for @productMgmtOutOfStockTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get productMgmtOutOfStockTabLabel;

  /// No description provided for @productMgmtExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get productMgmtExpiredLabel;

  /// No description provided for @productMgmtSortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price Low-High'**
  String get productMgmtSortPriceLowHigh;

  /// No description provided for @productMgmtSortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price High-Low'**
  String get productMgmtSortPriceHighLow;

  /// No description provided for @productMgmtSortStockLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Stock Low-High'**
  String get productMgmtSortStockLowHigh;

  /// No description provided for @productMgmtSortStockHighLow.
  ///
  /// In en, this message translates to:
  /// **'Stock High-Low'**
  String get productMgmtSortStockHighLow;

  /// No description provided for @productMgmtServicesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get productMgmtServicesTabLabel;

  /// No description provided for @productMgmtColSlNo.
  ///
  /// In en, this message translates to:
  /// **'SL. NO.'**
  String get productMgmtColSlNo;

  /// No description provided for @productMgmtColNameAlias.
  ///
  /// In en, this message translates to:
  /// **'NAME / ALIAS'**
  String get productMgmtColNameAlias;

  /// No description provided for @productMgmtColHsnSac.
  ///
  /// In en, this message translates to:
  /// **'HSN / SAC'**
  String get productMgmtColHsnSac;

  /// No description provided for @productMgmtColPrice.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get productMgmtColPrice;

  /// No description provided for @productMgmtColPurchase.
  ///
  /// In en, this message translates to:
  /// **'PURCHASE'**
  String get productMgmtColPurchase;

  /// No description provided for @productMgmtColStock.
  ///
  /// In en, this message translates to:
  /// **'STOCK'**
  String get productMgmtColStock;

  /// No description provided for @productMgmtColTaxPercent.
  ///
  /// In en, this message translates to:
  /// **'TAX %'**
  String get productMgmtColTaxPercent;

  /// No description provided for @productMgmtColExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'EXPIRY DATE'**
  String get productMgmtColExpiryDate;

  /// No description provided for @productMgmtCustomizeColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Customize Product Columns'**
  String get productMgmtCustomizeColumnsLabel;

  /// No description provided for @productMgmtShowColumnsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Columns'**
  String get productMgmtShowColumnsLabel;

  /// No description provided for @productMgmtShowColumnsMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Show up to {max} columns'**
  String productMgmtShowColumnsMaxHint(int max);

  /// No description provided for @productMgmtShowingRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Showing {from} to {to} of {total} products'**
  String productMgmtShowingRangeLabel(int from, int to, int total);

  /// No description provided for @productMgmtAddFirstProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to get started'**
  String get productMgmtAddFirstProductSubtitle;

  /// No description provided for @productMgmtColumnsBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'New: Customize product fields'**
  String get productMgmtColumnsBannerTitle;

  /// No description provided for @productMgmtColumnsBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which fields show for a simpler catalog. Settings > Customize Product Details.'**
  String get productMgmtColumnsBannerSubtitle;

  /// No description provided for @productMgmtConfigureAction.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get productMgmtConfigureAction;

  /// No description provided for @productMgmtAddNewItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New {type}'**
  String productMgmtAddNewItemTitle(String type);

  /// No description provided for @productMgmtEnterProductDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter product details'**
  String get productMgmtEnterProductDetailsSubtitle;

  /// No description provided for @productMgmtSaveProductButton.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get productMgmtSaveProductButton;

  /// No description provided for @productMgmtAliasNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Alias Name (for invoice PDF)'**
  String get productMgmtAliasNameLabel;

  /// No description provided for @productMgmtAliasHelperText.
  ///
  /// In en, this message translates to:
  /// **'Optional local-language display name used only on PDF invoices.'**
  String get productMgmtAliasHelperText;

  /// No description provided for @productMgmtDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productMgmtDescriptionLabel;

  /// No description provided for @productMgmtHsnSacLabel.
  ///
  /// In en, this message translates to:
  /// **'HSN/SAC'**
  String get productMgmtHsnSacLabel;

  /// No description provided for @productMgmtSalePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get productMgmtSalePriceLabel;

  /// No description provided for @productMgmtPurchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get productMgmtPurchasePriceLabel;

  /// No description provided for @productMgmtDefaultDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Discount'**
  String get productMgmtDefaultDiscountLabel;

  /// No description provided for @productMgmtTaxPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax (%)'**
  String get productMgmtTaxPercentLabel;

  /// No description provided for @productMgmtPerItemTaxModeOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Per-item tax mode only'**
  String get productMgmtPerItemTaxModeOnlyLabel;

  /// No description provided for @productMgmtSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get productMgmtSectionGeneral;

  /// No description provided for @productMgmtSectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get productMgmtSectionPricing;

  /// No description provided for @productMgmtSectionInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get productMgmtSectionInventory;

  /// No description provided for @productMgmtUnlimitedStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlimited stock'**
  String get productMgmtUnlimitedStockLabel;

  /// No description provided for @productMgmtTrackInfiniteStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track infinite stock for this product'**
  String get productMgmtTrackInfiniteStockSubtitle;

  /// No description provided for @productMgmtTipEnableCustomFieldsMessage.
  ///
  /// In en, this message translates to:
  /// **'Tip: Enable custom fields from Columns to add more details.'**
  String get productMgmtTipEnableCustomFieldsMessage;

  /// No description provided for @productMgmtEditProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get productMgmtEditProductTitle;

  /// No description provided for @productMgmtViewProductTitle.
  ///
  /// In en, this message translates to:
  /// **'View Product'**
  String get productMgmtViewProductTitle;

  /// No description provided for @productMgmtUpdateProductDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update product details'**
  String get productMgmtUpdateProductDetailsSubtitle;

  /// No description provided for @productMgmtProductDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productMgmtProductDetailsSubtitle;

  /// No description provided for @productMgmtUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Product/Service updated successfully!'**
  String get productMgmtUpdatedMessage;

  /// No description provided for @productMgmtDeleteProductButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get productMgmtDeleteProductButton;

  /// No description provided for @productMgmtSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get productMgmtSaveChangesButton;

  /// No description provided for @fieldUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnitLabel;

  /// No description provided for @productMgmtAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productMgmtAddedMessage;

  /// No description provided for @productMgmtAddErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error adding product: {error}'**
  String productMgmtAddErrorMessage(String error);

  /// No description provided for @productMgmtLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading products: {error}'**
  String productMgmtLoadErrorMessage(String error);

  /// No description provided for @productMgmtDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully!'**
  String get productMgmtDeletedMessage;

  /// No description provided for @productMgmtImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 product successfully!} other{Imported {count} products successfully!}}'**
  String productMgmtImportedMessage(int count);

  /// No description provided for @productMgmtTotalItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get productMgmtTotalItemsSubtitle;

  /// No description provided for @productMgmtTangibleProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tangible products'**
  String get productMgmtTangibleProductsSubtitle;

  /// No description provided for @productMgmtNonTangibleServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Non-tangible services'**
  String get productMgmtNonTangibleServicesSubtitle;

  /// No description provided for @productMgmtNeedAttentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Need attention'**
  String get productMgmtNeedAttentionSubtitle;

  /// No description provided for @productMgmtProductNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productMgmtProductNameLabel;

  /// No description provided for @productMgmtPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productMgmtPriceLabel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @reportsAboutConversionRateTitle.
  ///
  /// In en, this message translates to:
  /// **'About Conversion Rate'**
  String get reportsAboutConversionRateTitle;

  /// No description provided for @reportsAgedReceivablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Aged Receivables ({count})'**
  String reportsAgedReceivablesTitle(int count);

  /// No description provided for @reportsAllCurrenciesLabel.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get reportsAllCurrenciesLabel;

  /// No description provided for @reportsAvgInvoiceValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Invoice Value'**
  String get reportsAvgInvoiceValueLabel;

  /// No description provided for @reportsBalanceColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get reportsBalanceColumnLabel;

  /// No description provided for @reportsBilledLabel.
  ///
  /// In en, this message translates to:
  /// **'Billed'**
  String get reportsBilledLabel;

  /// No description provided for @reportsBucket0to30Label.
  ///
  /// In en, this message translates to:
  /// **'0–30 days'**
  String get reportsBucket0to30Label;

  /// No description provided for @reportsBucket31to60Label.
  ///
  /// In en, this message translates to:
  /// **'31–60 days'**
  String get reportsBucket31to60Label;

  /// No description provided for @reportsBucket61to90Label.
  ///
  /// In en, this message translates to:
  /// **'61–90 days'**
  String get reportsBucket61to90Label;

  /// No description provided for @reportsBucket90PlusLabel.
  ///
  /// In en, this message translates to:
  /// **'90+ days'**
  String get reportsBucket90PlusLabel;

  /// No description provided for @reportsBucketLabel.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get reportsBucketLabel;

  /// No description provided for @reportsClosingLabel.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get reportsClosingLabel;

  /// No description provided for @reportsCogsColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'COGS'**
  String get reportsCogsColumnLabel;

  /// No description provided for @reportsConversionRateExplanationBody.
  ///
  /// In en, this message translates to:
  /// **'Conversion rate = Invoices created ÷ Quotations issued × 100.\nA rate above 100% means more invoices were raised than quotations in the selected period (common when invoices are created directly without a prior quotation).\n\nNote: this is a period-level ratio, not individual quote-to-invoice tracking.'**
  String get reportsConversionRateExplanationBody;

  /// No description provided for @reportsConversionRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get reportsConversionRateLabel;

  /// No description provided for @reportsCreditColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get reportsCreditColumnLabel;

  /// No description provided for @reportsCurrencySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENCY'**
  String get reportsCurrencySectionLabel;

  /// No description provided for @reportsCurrentBucketLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get reportsCurrentBucketLabel;

  /// No description provided for @reportsCurrentSelectedCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Current selected currency ({currency})'**
  String reportsCurrentSelectedCurrencyLabel(String currency);

  /// No description provided for @reportsCustomRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get reportsCustomRangeLabel;

  /// No description provided for @reportsDailySalesProfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales & Profit'**
  String get reportsDailySalesProfitTitle;

  /// No description provided for @reportsDaysCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{d} days'**
  String reportsDaysCountLabel(int d);

  /// No description provided for @reportsDaysOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Days Overdue'**
  String get reportsDaysOverdueLabel;

  /// No description provided for @reportsDebitColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get reportsDebitColumnLabel;

  /// No description provided for @reportsDiscountGivenColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount Given'**
  String get reportsDiscountGivenColumnLabel;

  /// No description provided for @reportsExportCsvLabel.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reportsExportCsvLabel;

  /// No description provided for @reportsFilteredToDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Filtered to {date}'**
  String reportsFilteredToDateLabel(String date);

  /// No description provided for @reportsInvoiceCountInPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invoice in period · {scope}} other{{count} invoices in period · {scope}}}'**
  String reportsInvoiceCountInPeriodLabel(int count, String scope);

  /// No description provided for @reportsInvoiceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice ID'**
  String get reportsInvoiceIdLabel;

  /// No description provided for @reportsInvoicedLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoiced'**
  String get reportsInvoicedLabel;

  /// No description provided for @reportsInvoicesColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get reportsInvoicesColumnLabel;

  /// No description provided for @reportsInvoicesInPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoices in Period'**
  String get reportsInvoicesInPeriodLabel;

  /// No description provided for @reportsLabelWithCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String reportsLabelWithCountLabel(String label, int count);

  /// No description provided for @reportsMarginColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get reportsMarginColumnLabel;

  /// No description provided for @reportsMaxRangeOneYearMessage.
  ///
  /// In en, this message translates to:
  /// **'Maximum range is 1 year. End date clamped.'**
  String get reportsMaxRangeOneYearMessage;

  /// No description provided for @reportsMaxRangeThirtyOneDaysMessage.
  ///
  /// In en, this message translates to:
  /// **'Maximum range is 31 days. End date clamped.'**
  String get reportsMaxRangeThirtyOneDaysMessage;

  /// No description provided for @reportsMissingCostBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item sold in this period has no purchase price set — profit/margin is understated for that item until a purchase price is added to the product.} other{{count} items sold in this period have no purchase price set — profit/margin is understated for those items until a purchase price is added to the product.}}'**
  String reportsMissingCostBannerMessage(int count);

  /// No description provided for @reportsMonthYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Month & Year'**
  String get reportsMonthYearLabel;

  /// No description provided for @reportsMonthlyRevenueTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue Trend'**
  String get reportsMonthlyRevenueTrendTitle;

  /// No description provided for @reportsNavDailyReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get reportsNavDailyReportLabel;

  /// No description provided for @reportsNavInvoiceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Status'**
  String get reportsNavInvoiceStatusLabel;

  /// No description provided for @reportsNavReceivablesLabel.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get reportsNavReceivablesLabel;

  /// No description provided for @reportsNavRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsNavRevenueLabel;

  /// No description provided for @reportsNavTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get reportsNavTaxLabel;

  /// No description provided for @reportsNoCustomerDataMessage.
  ///
  /// In en, this message translates to:
  /// **'No customer data in this period'**
  String get reportsNoCustomerDataMessage;

  /// No description provided for @reportsNoCustomersMatchSearchMessage.
  ///
  /// In en, this message translates to:
  /// **'No customers match this search'**
  String get reportsNoCustomersMatchSearchMessage;

  /// No description provided for @reportsNoCustomersWithInvoicesMessage.
  ///
  /// In en, this message translates to:
  /// **'No customers with invoices'**
  String get reportsNoCustomersWithInvoicesMessage;

  /// No description provided for @reportsNoDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'No Due Date'**
  String get reportsNoDueDateLabel;

  /// No description provided for @reportsNoInvoiceDataMessage.
  ///
  /// In en, this message translates to:
  /// **'No invoice data in this period'**
  String get reportsNoInvoiceDataMessage;

  /// No description provided for @reportsNoInvoicesInPeriodMessage.
  ///
  /// In en, this message translates to:
  /// **'No invoices in this period'**
  String get reportsNoInvoicesInPeriodMessage;

  /// No description provided for @reportsNoInvoicesMatchFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'No invoices match this filter'**
  String get reportsNoInvoicesMatchFilterMessage;

  /// No description provided for @reportsNoOutstandingInvoicesMessage.
  ///
  /// In en, this message translates to:
  /// **'No outstanding invoices'**
  String get reportsNoOutstandingInvoicesMessage;

  /// No description provided for @reportsNoProductDataMessage.
  ///
  /// In en, this message translates to:
  /// **'No product data in this period'**
  String get reportsNoProductDataMessage;

  /// No description provided for @reportsNoSalesInPeriodMessage.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get reportsNoSalesInPeriodMessage;

  /// No description provided for @reportsNoStatementActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'No statement activity for this customer'**
  String get reportsNoStatementActivityMessage;

  /// No description provided for @reportsNoTaxableItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No taxable items in this period'**
  String get reportsNoTaxableItemsMessage;

  /// No description provided for @reportsNoTransactionsMessage.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get reportsNoTransactionsMessage;

  /// No description provided for @reportsOpeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get reportsOpeningLabel;

  /// No description provided for @reportsOverviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportsOverviewLabel;

  /// No description provided for @reportsPaymentStatusBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Status Breakdown'**
  String get reportsPaymentStatusBreakdownTitle;

  /// No description provided for @reportsPeriodSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'PERIOD'**
  String get reportsPeriodSectionLabel;

  /// No description provided for @reportsPresetLast30DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get reportsPresetLast30DaysLabel;

  /// No description provided for @reportsPresetLast3MonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get reportsPresetLast3MonthsLabel;

  /// No description provided for @reportsPresetLast6MonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get reportsPresetLast6MonthsLabel;

  /// No description provided for @reportsPresetLastFYLabel.
  ///
  /// In en, this message translates to:
  /// **'Last FY'**
  String get reportsPresetLastFYLabel;

  /// No description provided for @reportsPresetThisFYLabel.
  ///
  /// In en, this message translates to:
  /// **'This FY'**
  String get reportsPresetThisFYLabel;

  /// No description provided for @reportsPresetThisYearLabel.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get reportsPresetThisYearLabel;

  /// No description provided for @reportsProductServiceColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Product / Service'**
  String get reportsProductServiceColumnLabel;

  /// No description provided for @reportsProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get reportsProfitLabel;

  /// No description provided for @reportsQuotationsIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Quotations Issued'**
  String get reportsQuotationsIssuedLabel;

  /// No description provided for @reportsRankByProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank: Profit'**
  String get reportsRankByProfitLabel;

  /// No description provided for @reportsRankByRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank: Revenue'**
  String get reportsRankByRevenueLabel;

  /// No description provided for @reportsReferenceColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reportsReferenceColumnLabel;

  /// No description provided for @reportsSalesColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportsSalesColumnLabel;

  /// No description provided for @reportsSaveCsvReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Save CSV Report'**
  String get reportsSaveCsvReportTitle;

  /// No description provided for @reportsSavePdfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Save PDF Report'**
  String get reportsSavePdfReportTitle;

  /// No description provided for @reportsSavedAtMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String reportsSavedAtMessage(String path);

  /// No description provided for @reportsSelectCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get reportsSelectCustomerTitle;

  /// No description provided for @reportsSelectDailyRangeMaxDaysHelpText.
  ///
  /// In en, this message translates to:
  /// **'Select date or date range (max 31 days)'**
  String get reportsSelectDailyRangeMaxDaysHelpText;

  /// No description provided for @reportsSelectDateRangeMaxYearHelpText.
  ///
  /// In en, this message translates to:
  /// **'Select date range (max 1 year)'**
  String get reportsSelectDateRangeMaxYearHelpText;

  /// No description provided for @reportsShareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get reportsShareLabel;

  /// No description provided for @reportsShowingInvoicesDatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Showing invoices dated {range}'**
  String reportsShowingInvoicesDatedLabel(String range);

  /// No description provided for @reportsShowingRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} of {total}'**
  String reportsShowingRangeLabel(int start, int end, int total);

  /// No description provided for @reportsSlColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'SL'**
  String get reportsSlColumnLabel;

  /// No description provided for @reportsStatementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get reportsStatementsLabel;

  /// No description provided for @reportsTaxCollectedByRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Collected by Rate'**
  String get reportsTaxCollectedByRateTitle;

  /// No description provided for @reportsTaxCollectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Collected'**
  String get reportsTaxCollectedLabel;

  /// No description provided for @reportsTaxRateBucketsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate Buckets'**
  String get reportsTaxRateBucketsLabel;

  /// No description provided for @reportsTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportsTodayLabel;

  /// No description provided for @reportsTopCustomersByRevenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Top {count} Customers by Revenue'**
  String reportsTopCustomersByRevenueTitle(int count);

  /// No description provided for @reportsTopProductsByMetricTitle.
  ///
  /// In en, this message translates to:
  /// **'Top {count} Products / Services by {metric}'**
  String reportsTopProductsByMetricTitle(int count, String metric);

  /// No description provided for @reportsTotalBilledLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Billed'**
  String get reportsTotalBilledLabel;

  /// No description provided for @reportsTotalCollectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Collected'**
  String get reportsTotalCollectedLabel;

  /// No description provided for @reportsTotalInvoicesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 total invoice} other{{count} total invoices}}'**
  String reportsTotalInvoicesCountLabel(int count);

  /// No description provided for @reportsTotalInvoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get reportsTotalInvoicesLabel;

  /// No description provided for @reportsTotalProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Profit'**
  String get reportsTotalProfitLabel;

  /// No description provided for @reportsTotalTaxCollectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Tax Collected'**
  String get reportsTotalTaxCollectedLabel;

  /// No description provided for @reportsTypeColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reportsTypeColumnLabel;

  /// No description provided for @reportsUnitsSoldColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Units Sold'**
  String get reportsUnitsSoldColumnLabel;

  /// No description provided for @userMgmtLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading users: {error}'**
  String userMgmtLoadErrorMessage(String error);

  /// No description provided for @userMgmtAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'User added successfully'**
  String get userMgmtAddedMessage;

  /// No description provided for @userMgmtUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userMgmtUpdatedMessage;

  /// No description provided for @userMgmtSaveErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error saving user: {error}'**
  String userMgmtSaveErrorMessage(String error);

  /// No description provided for @userMgmtChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get userMgmtChangePasswordTitle;

  /// No description provided for @userMgmtUserColonLabel.
  ///
  /// In en, this message translates to:
  /// **'User: {username}'**
  String userMgmtUserColonLabel(String username);

  /// No description provided for @userMgmtCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get userMgmtCurrentPasswordLabel;

  /// No description provided for @userMgmtCurrentPasswordRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get userMgmtCurrentPasswordRequiredMessage;

  /// No description provided for @userMgmtNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get userMgmtNewPasswordLabel;

  /// No description provided for @userMgmtNewPasswordRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get userMgmtNewPasswordRequiredMessage;

  /// No description provided for @userMgmtPasswordMinLengthMessage.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get userMgmtPasswordMinLengthMessage;

  /// No description provided for @userMgmtConfirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get userMgmtConfirmNewPasswordLabel;

  /// No description provided for @userMgmtConfirmPasswordRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get userMgmtConfirmPasswordRequiredMessage;

  /// No description provided for @userMgmtPasswordsDoNotMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get userMgmtPasswordsDoNotMatchMessage;

  /// No description provided for @userMgmtPasswordChangedMessage.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get userMgmtPasswordChangedMessage;

  /// No description provided for @userMgmtCurrentPasswordIncorrectMessage.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get userMgmtCurrentPasswordIncorrectMessage;

  /// No description provided for @userMgmtDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get userMgmtDeleteUserTitle;

  /// No description provided for @userMgmtDeleteUserConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete user:'**
  String get userMgmtDeleteUserConfirmLabel;

  /// No description provided for @userMgmtActionCannotBeUndoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get userMgmtActionCannotBeUndoneMessage;

  /// No description provided for @userMgmtDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userMgmtDeletedMessage;

  /// No description provided for @userMgmtCantDeleteOwnAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'You can\'t delete your own account'**
  String get userMgmtCantDeleteOwnAccountMessage;

  /// No description provided for @userMgmtCantDemoteLastAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'You can\'t change the role of the only admin'**
  String get userMgmtCantDemoteLastAdminMessage;

  /// No description provided for @userMgmtCantChangeOwnRoleMessage.
  ///
  /// In en, this message translates to:
  /// **'You can\'t change your own role'**
  String get userMgmtCantChangeOwnRoleMessage;

  /// No description provided for @userMgmtUsernameTakenMessage.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken'**
  String get userMgmtUsernameTakenMessage;

  /// No description provided for @userMgmtDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected users?'**
  String get userMgmtDeleteSelectedTitle;

  /// No description provided for @userMgmtBulkDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete 1 user. This action cannot be undone.} other{This will permanently delete {count} users. This action cannot be undone.}}'**
  String userMgmtBulkDeleteBody(int count);

  /// No description provided for @userMgmtOwnAccountSkippedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your own account was in the selection but will be skipped.'**
  String get userMgmtOwnAccountSkippedMessage;

  /// No description provided for @userMgmtBulkDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 user deleted} other{{count} users deleted}}'**
  String userMgmtBulkDeletedMessage(int count);

  /// No description provided for @userMgmtBulkDeleteErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error deleting users: {error}'**
  String userMgmtBulkDeleteErrorMessage(String error);

  /// No description provided for @userMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userMgmtTitle;

  /// No description provided for @userMgmtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage application users and access permissions'**
  String get userMgmtSubtitle;

  /// No description provided for @userMgmtAddUserButton.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get userMgmtAddUserButton;

  /// No description provided for @userMgmtSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users by name or role…'**
  String get userMgmtSearchHint;

  /// No description provided for @userMgmtFilterByRoleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by role'**
  String get userMgmtFilterByRoleTooltip;

  /// No description provided for @userMgmtAllRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get userMgmtAllRolesLabel;

  /// No description provided for @userMgmtAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get userMgmtAllLabel;

  /// No description provided for @userMgmtRoleColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String userMgmtRoleColonLabel(String role);

  /// No description provided for @userMgmtColUser.
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get userMgmtColUser;

  /// No description provided for @userMgmtColRole.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get userMgmtColRole;

  /// No description provided for @userMgmtYouBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get userMgmtYouBadgeLabel;

  /// No description provided for @userMgmtDeleteSelectedMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get userMgmtDeleteSelectedMenuLabel;

  /// No description provided for @userMgmtBulkActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Bulk actions'**
  String get userMgmtBulkActionsTooltip;

  /// No description provided for @userMgmtBulkActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bulk Actions'**
  String get userMgmtBulkActionsLabel;

  /// No description provided for @userMgmtShowingRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Showing {from} to {to} of {total} users'**
  String userMgmtShowingRangeLabel(int from, int to, int total);

  /// No description provided for @userMgmtNoUsersFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get userMgmtNoUsersFoundMessage;

  /// No description provided for @userMgmtAddNewUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get userMgmtAddNewUserTitle;

  /// No description provided for @userMgmtEditUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get userMgmtEditUserTitle;

  /// No description provided for @userMgmtUsernameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get userMgmtUsernameRequiredLabel;

  /// No description provided for @userMgmtEnterUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get userMgmtEnterUsernameHint;

  /// No description provided for @userMgmtUsernameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get userMgmtUsernameRequiredMessage;

  /// No description provided for @userMgmtUsernameMinLengthMessage.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get userMgmtUsernameMinLengthMessage;

  /// No description provided for @userMgmtPasswordRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get userMgmtPasswordRequiredLabel;

  /// No description provided for @userMgmtEnterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get userMgmtEnterPasswordHint;

  /// No description provided for @userMgmtPasswordRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get userMgmtPasswordRequiredMessage;

  /// No description provided for @userMgmtMinimum6CharsMessage.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get userMgmtMinimum6CharsMessage;

  /// No description provided for @userMgmtRoleRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Role *'**
  String get userMgmtRoleRequiredLabel;

  /// No description provided for @userMgmtRoleRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Role is required'**
  String get userMgmtRoleRequiredMessage;

  /// No description provided for @userMgmtSaveUserButton.
  ///
  /// In en, this message translates to:
  /// **'Save User'**
  String get userMgmtSaveUserButton;

  /// No description provided for @userMgmtThisIsYourAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your account'**
  String get userMgmtThisIsYourAccountMessage;

  /// No description provided for @invoiceSettingsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Settings'**
  String get invoiceSettingsAppBarTitle;

  /// No description provided for @invoiceSettingsSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Invoice settings saved successfully!'**
  String get invoiceSettingsSavedMessage;

  /// No description provided for @invoiceSettingsSignatureTooLargeMessage.
  ///
  /// In en, this message translates to:
  /// **'Signature image must be less than 2 MB.'**
  String get invoiceSettingsSignatureTooLargeMessage;

  /// No description provided for @invoiceSettingsWatermarkTooLargeMessage.
  ///
  /// In en, this message translates to:
  /// **'Watermark image must be less than 2 MB.'**
  String get invoiceSettingsWatermarkTooLargeMessage;

  /// No description provided for @invoiceSettingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get invoiceSettingsSectionGeneral;

  /// No description provided for @invoiceSettingsSectionBranding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get invoiceSettingsSectionBranding;

  /// No description provided for @invoiceSettingsSectionTax.
  ///
  /// In en, this message translates to:
  /// **'Tax & GST'**
  String get invoiceSettingsSectionTax;

  /// No description provided for @invoiceSettingsSectionItems.
  ///
  /// In en, this message translates to:
  /// **'Invoice Items'**
  String get invoiceSettingsSectionItems;

  /// No description provided for @invoiceSettingsSectionCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get invoiceSettingsSectionCustomer;

  /// No description provided for @invoiceSettingsSectionColumns.
  ///
  /// In en, this message translates to:
  /// **'Invoice Columns'**
  String get invoiceSettingsSectionColumns;

  /// No description provided for @invoiceSettingsColumnsSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which columns appear in the invoice PDF items table. Item Name, Price and Total are always shown.'**
  String get invoiceSettingsColumnsSectionHint;

  /// No description provided for @invoiceSettingsShowSlNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Sl No column'**
  String get invoiceSettingsShowSlNoLabel;

  /// No description provided for @invoiceSettingsShowSlNoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the serial-number column on A4/Letter invoices'**
  String get invoiceSettingsShowSlNoSubtitle;

  /// No description provided for @invoiceSettingsColumnHsnLabel.
  ///
  /// In en, this message translates to:
  /// **'HSN/SAC column'**
  String get invoiceSettingsColumnHsnLabel;

  /// No description provided for @invoiceSettingsColumnHsnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the HSN/SAC code column (tied to Show GST Fields)'**
  String get invoiceSettingsColumnHsnSubtitle;

  /// No description provided for @invoiceSettingsColumnTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax column'**
  String get invoiceSettingsColumnTaxLabel;

  /// No description provided for @invoiceSettingsColumnTaxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the per-item CGST/SGST, IGST % column'**
  String get invoiceSettingsColumnTaxSubtitle;

  /// No description provided for @invoiceSettingsColumnRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always shown'**
  String get invoiceSettingsColumnRequiredSubtitle;

  /// No description provided for @invoiceSettingsColumnItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name column'**
  String get invoiceSettingsColumnItemNameLabel;

  /// No description provided for @invoiceSettingsColumnPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price / Rate column'**
  String get invoiceSettingsColumnPriceLabel;

  /// No description provided for @invoiceSettingsColumnTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total column'**
  String get invoiceSettingsColumnTotalLabel;

  /// No description provided for @invoiceSettingsCustomerSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which customer details print on invoice PDFs and thermal receipts. A field only shows when it\'s enabled and the customer has a value for it. Customer name is always shown.'**
  String get invoiceSettingsCustomerSectionHint;

  /// No description provided for @invoiceSettingsShowCustomerBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Business Name'**
  String get invoiceSettingsShowCustomerBusinessNameLabel;

  /// No description provided for @invoiceSettingsShowCustomerBusinessNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the customer\'s business name under their name'**
  String get invoiceSettingsShowCustomerBusinessNameSubtitle;

  /// No description provided for @invoiceSettingsShowCustomerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Address'**
  String get invoiceSettingsShowCustomerAddressLabel;

  /// No description provided for @invoiceSettingsShowCustomerAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the customer\'s address in the Bill To block'**
  String get invoiceSettingsShowCustomerAddressSubtitle;

  /// No description provided for @invoiceSettingsShowCustomerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Phone'**
  String get invoiceSettingsShowCustomerPhoneLabel;

  /// No description provided for @invoiceSettingsShowCustomerPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the customer\'s phone number'**
  String get invoiceSettingsShowCustomerPhoneSubtitle;

  /// No description provided for @invoiceSettingsShowCustomerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Email'**
  String get invoiceSettingsShowCustomerEmailLabel;

  /// No description provided for @invoiceSettingsShowCustomerEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the customer\'s email address (not shown on thermal receipts)'**
  String get invoiceSettingsShowCustomerEmailSubtitle;

  /// No description provided for @invoiceSettingsShowCustomerGstinLabel.
  ///
  /// In en, this message translates to:
  /// **'Show GSTIN / Tax ID'**
  String get invoiceSettingsShowCustomerGstinLabel;

  /// No description provided for @invoiceSettingsShowCustomerGstinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the customer\'s GSTIN / tax id (requires GST fields on)'**
  String get invoiceSettingsShowCustomerGstinSubtitle;

  /// No description provided for @invoiceSettingsShowTimeInPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Time on PDF'**
  String get invoiceSettingsShowTimeInPdfLabel;

  /// No description provided for @invoiceSettingsShowTimeInPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Append the invoice creation time next to the date on PDFs and thermal receipts'**
  String get invoiceSettingsShowTimeInPdfSubtitle;

  /// No description provided for @invoiceSettingsTimeFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get invoiceSettingsTimeFormatLabel;

  /// No description provided for @invoiceSettingsTimeFormat24.
  ///
  /// In en, this message translates to:
  /// **'24-hour (14:30)'**
  String get invoiceSettingsTimeFormat24;

  /// No description provided for @invoiceSettingsTimeFormat12.
  ///
  /// In en, this message translates to:
  /// **'12-hour (2:30 PM)'**
  String get invoiceSettingsTimeFormat12;

  /// No description provided for @invoiceSettingsPrefixLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Prefix'**
  String get invoiceSettingsPrefixLabel;

  /// No description provided for @invoiceSettingsStartingNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'First invoice will start from this number'**
  String get invoiceSettingsStartingNumberHelper;

  /// No description provided for @invoiceSettingsStartingNumberLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Invoice starting number cannot be changed while invoices exist. Please permanently delete all invoices/quotations (including trash) and try again.'**
  String get invoiceSettingsStartingNumberLockedMessage;

  /// No description provided for @invoiceSettingsQuantityColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity Column Label'**
  String get invoiceSettingsQuantityColumnLabel;

  /// No description provided for @invoiceSettingsQuantityColumnHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Words, Hours, Units'**
  String get invoiceSettingsQuantityColumnHint;

  /// No description provided for @invoiceSettingsQuantityColumnHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use default \"Qty\"'**
  String get invoiceSettingsQuantityColumnHelper;

  /// No description provided for @invoiceSettingsAdditionalInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get invoiceSettingsAdditionalInfoLabel;

  /// No description provided for @invoiceSettingsThankYouNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Thank You Note'**
  String get invoiceSettingsThankYouNoteLabel;

  /// No description provided for @invoiceSettingsHideInvoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide Invoice Number by Default'**
  String get invoiceSettingsHideInvoiceNumberLabel;

  /// No description provided for @invoiceSettingsHideInvoiceNumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Hide invoice number in PDF\" by default when creating new invoices.'**
  String get invoiceSettingsHideInvoiceNumberSubtitle;

  /// No description provided for @invoiceSettingsTaxRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 18'**
  String get invoiceSettingsTaxRateHint;

  /// No description provided for @invoiceSettingsTaxRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Applied to new invoices'**
  String get invoiceSettingsTaxRateHelper;

  /// No description provided for @invoiceSettingsTaxEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Enabled by Default'**
  String get invoiceSettingsTaxEnabledLabel;

  /// No description provided for @invoiceSettingsTaxEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable the Tax toggle by default when creating new invoices.'**
  String get invoiceSettingsTaxEnabledSubtitle;

  /// No description provided for @invoiceSettingsTaxModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Tax Rate Mode'**
  String get invoiceSettingsTaxModeLabel;

  /// No description provided for @invoiceSettingsAppliesNewInvoicesOnly.
  ///
  /// In en, this message translates to:
  /// **'Applies to new invoices only'**
  String get invoiceSettingsAppliesNewInvoicesOnly;

  /// No description provided for @invoiceSettingsTaxModeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get invoiceSettingsTaxModeGlobal;

  /// No description provided for @invoiceSettingsTaxModePerItem.
  ///
  /// In en, this message translates to:
  /// **'Per Item'**
  String get invoiceSettingsTaxModePerItem;

  /// No description provided for @invoiceSettingsShowGstFieldsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show GST Fields'**
  String get invoiceSettingsShowGstFieldsLabel;

  /// No description provided for @invoiceSettingsShowGstFieldsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display GSTIN fields (HSN/SAC) on invoices, PDFs, and CSV exports'**
  String get invoiceSettingsShowGstFieldsSubtitle;

  /// No description provided for @invoiceSettingsShowCgstSgstLabel.
  ///
  /// In en, this message translates to:
  /// **'Show CGST/SGST/IGST'**
  String get invoiceSettingsShowCgstSgstLabel;

  /// No description provided for @invoiceSettingsShowCgstSgstSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Split tax into CGST + SGST, or IGST for interstate invoices (India only).'**
  String get invoiceSettingsShowCgstSgstSubtitle;

  /// No description provided for @invoiceSettingsDefaultGstTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Default GST Invoice Title'**
  String get invoiceSettingsDefaultGstTitleLabel;

  /// No description provided for @invoiceSettingsDefaultTaxTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Default TAX Invoice Title'**
  String get invoiceSettingsDefaultTaxTitleLabel;

  /// No description provided for @invoiceSettingsGstTitleHelperGst.
  ///
  /// In en, this message translates to:
  /// **'Preselected on new invoices — e.g. \"Bill of Supply\" for GST Composition Scheme dealers'**
  String get invoiceSettingsGstTitleHelperGst;

  /// No description provided for @invoiceSettingsGstTitleHelperGeneric.
  ///
  /// In en, this message translates to:
  /// **'Preselected on new invoices'**
  String get invoiceSettingsGstTitleHelperGeneric;

  /// No description provided for @invoiceSettingsShowRoundOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Round Off'**
  String get invoiceSettingsShowRoundOffLabel;

  /// No description provided for @invoiceSettingsShowRoundOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show a Round Off row + Net Amount (rounded to nearest) and amount in words on invoice PDFs.'**
  String get invoiceSettingsShowRoundOffSubtitle;

  /// No description provided for @invoiceSettingsShowAliasNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Alias Name in PDF'**
  String get invoiceSettingsShowAliasNameLabel;

  /// No description provided for @invoiceSettingsShowAliasNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print a product\'s local-language alias (if set) instead of its actual name on PDFs'**
  String get invoiceSettingsShowAliasNameSubtitle;

  /// No description provided for @invoiceSettingsShowDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Product Description'**
  String get invoiceSettingsShowDescriptionLabel;

  /// No description provided for @invoiceSettingsShowDescriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print each item\'s description as a row under it on A4 PDFs (not on thermal receipts)'**
  String get invoiceSettingsShowDescriptionSubtitle;

  /// No description provided for @invoiceSettingsDescriptionNewLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Description on a New Line'**
  String get invoiceSettingsDescriptionNewLineLabel;

  /// No description provided for @invoiceSettingsDescriptionNewLineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print the description as a full-width row below the item instead of a line under its name'**
  String get invoiceSettingsDescriptionNewLineSubtitle;

  /// No description provided for @invoiceSettingsAllowFractionalQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow Fractional Quantities'**
  String get invoiceSettingsAllowFractionalQtyLabel;

  /// No description provided for @invoiceSettingsAllowFractionalQtySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable decimal quantities (e.g. 1.5 hrs, 0.5 kg)'**
  String get invoiceSettingsAllowFractionalQtySubtitle;

  /// No description provided for @invoiceSettingsShowQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Quantity Field'**
  String get invoiceSettingsShowQuantityLabel;

  /// No description provided for @invoiceSettingsShowQuantitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide quantity for service-based billing; price column becomes \"Rate\"'**
  String get invoiceSettingsShowQuantitySubtitle;

  /// No description provided for @invoiceSettingsShowDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Discount Column'**
  String get invoiceSettingsShowDiscountLabel;

  /// No description provided for @invoiceSettingsShowDiscountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide discount column for clients who don\'t use item-level discounts'**
  String get invoiceSettingsShowDiscountSubtitle;

  /// No description provided for @invoiceSettingsShowTypeTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Product/Service Tag'**
  String get invoiceSettingsShowTypeTagLabel;

  /// No description provided for @invoiceSettingsShowTypeTagSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the Product/Service label on each invoice item'**
  String get invoiceSettingsShowTypeTagSubtitle;

  /// No description provided for @invoiceSettingsAllowDuplicateItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow Duplicate Invoice Items'**
  String get invoiceSettingsAllowDuplicateItemsLabel;

  /// No description provided for @invoiceSettingsAllowDuplicateItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow adding the same product more than once to an invoice'**
  String get invoiceSettingsAllowDuplicateItemsSubtitle;

  /// No description provided for @invoiceSettingsShowPrevBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Show Previous Balance Due'**
  String get invoiceSettingsShowPrevBalanceLabel;

  /// No description provided for @invoiceSettingsShowPrevBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show calculated prior outstanding balance on invoice PDFs'**
  String get invoiceSettingsShowPrevBalanceSubtitle;

  /// No description provided for @invoiceSettingsLogoPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Logo Position'**
  String get invoiceSettingsLogoPositionLabel;

  /// No description provided for @invoiceSettingsLogoSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Logo Size'**
  String get invoiceSettingsLogoSizeLabel;

  /// No description provided for @commonLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get commonLeftLabel;

  /// No description provided for @commonRightLabel.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get commonRightLabel;

  /// No description provided for @invoiceSettingsSignatureImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature Image'**
  String get invoiceSettingsSignatureImageLabel;

  /// No description provided for @invoiceSettingsSignatureImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Printed on invoices as Authorised Signature'**
  String get invoiceSettingsSignatureImageSubtitle;

  /// No description provided for @invoiceSettingsImageFormatHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG or JPEG — max 2 MB'**
  String get invoiceSettingsImageFormatHint;

  /// No description provided for @invoiceSettingsChangeSignatureButton.
  ///
  /// In en, this message translates to:
  /// **'Change Signature'**
  String get invoiceSettingsChangeSignatureButton;

  /// No description provided for @invoiceSettingsUploadSignatureButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Signature'**
  String get invoiceSettingsUploadSignatureButton;

  /// No description provided for @invoiceSettingsSignatureSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature Size'**
  String get invoiceSettingsSignatureSizeLabel;

  /// No description provided for @invoiceSettingsSignaturePositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature Position'**
  String get invoiceSettingsSignaturePositionLabel;

  /// No description provided for @invoiceSettingsWatermarkImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Watermark Image'**
  String get invoiceSettingsWatermarkImageLabel;

  /// No description provided for @invoiceSettingsWatermarkImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shown behind the items table on invoice PDFs (not printed on thermal receipts)'**
  String get invoiceSettingsWatermarkImageSubtitle;

  /// No description provided for @invoiceSettingsChangeWatermarkButton.
  ///
  /// In en, this message translates to:
  /// **'Change Watermark'**
  String get invoiceSettingsChangeWatermarkButton;

  /// No description provided for @invoiceSettingsUploadWatermarkButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Watermark'**
  String get invoiceSettingsUploadWatermarkButton;

  /// No description provided for @invoiceSettingsOpacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Opacity: {value}%'**
  String invoiceSettingsOpacityLabel(int value);

  /// No description provided for @invoiceSettingsPercentValueLabel.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String invoiceSettingsPercentValueLabel(int value);

  /// No description provided for @invoiceSettingsPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Need more fields on your invoices?'**
  String get invoiceSettingsPromoTitle;

  /// No description provided for @invoiceSettingsPromoBody.
  ///
  /// In en, this message translates to:
  /// **'Add PO number, project code, department, or any custom field.'**
  String get invoiceSettingsPromoBody;

  /// No description provided for @invoiceSettingsPromoButton.
  ///
  /// In en, this message translates to:
  /// **'See Options'**
  String get invoiceSettingsPromoButton;

  /// No description provided for @pdfSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF Settings'**
  String get pdfSettingsTitle;

  /// No description provided for @pdfSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize invoice, quotation and receipt PDF templates'**
  String get pdfSettingsSubtitle;

  /// No description provided for @pdfSettingsResetToDefaultButton.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get pdfSettingsResetToDefaultButton;

  /// No description provided for @pdfSettingsSaveSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get pdfSettingsSaveSettingsButton;

  /// No description provided for @pdfSettingsTemplatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get pdfSettingsTemplatesLabel;

  /// No description provided for @pdfSettingsNoTemplatesForPageSizeMessage.
  ///
  /// In en, this message translates to:
  /// **'No templates for {pageSize}'**
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize);

  /// No description provided for @pdfSettingsSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'PDF settings saved'**
  String get pdfSettingsSavedSnackbar;

  /// No description provided for @commonActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActiveLabel;

  /// No description provided for @commonUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonUnavailableLabel;

  /// No description provided for @pdfSettingsDisplayOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get pdfSettingsDisplayOptionsLabel;

  /// No description provided for @pdfSettingsShowTotalQtyRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Show total quantity row'**
  String get pdfSettingsShowTotalQtyRowLabel;

  /// No description provided for @pdfSettingsOrientationLabel.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get pdfSettingsOrientationLabel;

  /// No description provided for @pdfSettingsOrientationPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get pdfSettingsOrientationPortrait;

  /// No description provided for @pdfSettingsOrientationLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get pdfSettingsOrientationLandscape;

  /// No description provided for @pdfSettingsItemLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Item layout'**
  String get pdfSettingsItemLayoutLabel;

  /// No description provided for @pdfSettingsItemLayoutTableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get pdfSettingsItemLayoutTableLabel;

  /// No description provided for @pdfSettingsItemLayoutDetailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get pdfSettingsItemLayoutDetailedLabel;

  /// No description provided for @pdfSettingsItemLayoutHelpText.
  ///
  /// In en, this message translates to:
  /// **'Table: one line per item (Sl/Name/Qty/Rate/Total). Detailed: name on its own line, then Qty/Rate/Total below it.'**
  String get pdfSettingsItemLayoutHelpText;

  /// No description provided for @pdfSettingsCompanyNameSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name size'**
  String get pdfSettingsCompanyNameSizeLabel;

  /// No description provided for @pdfSettingsThemeColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get pdfSettingsThemeColorLabel;

  /// No description provided for @pdfSettingsHexErrorText.
  ///
  /// In en, this message translates to:
  /// **'Use #RRGGBB'**
  String get pdfSettingsHexErrorText;

  /// No description provided for @pdfSettingsPickColorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open color picker'**
  String get pdfSettingsPickColorTooltip;

  /// No description provided for @pdfSettingsPickThemeColorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick theme color'**
  String get pdfSettingsPickThemeColorDialogTitle;

  /// No description provided for @pdfSettingsPreviewDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Preview may slightly differ in the final PDF.'**
  String get pdfSettingsPreviewDisclaimer;

  /// No description provided for @pdfSettingsCustomTemplatePromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Want a custom template?'**
  String get pdfSettingsCustomTemplatePromoTitle;

  /// No description provided for @pdfSettingsCustomTemplatePromoBody.
  ///
  /// In en, this message translates to:
  /// **'Get a design that matches your brand — colors, fonts, and layout.'**
  String get pdfSettingsCustomTemplatePromoBody;

  /// No description provided for @pdfSettingsCustomizationOptionsButton.
  ///
  /// In en, this message translates to:
  /// **'Customization Options'**
  String get pdfSettingsCustomizationOptionsButton;

  /// No description provided for @pdfTemplateClassicName.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get pdfTemplateClassicName;

  /// No description provided for @pdfTemplateClassicDescription.
  ///
  /// In en, this message translates to:
  /// **'Traditional layout with clean structure'**
  String get pdfTemplateClassicDescription;

  /// No description provided for @pdfTemplateModernName.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get pdfTemplateModernName;

  /// No description provided for @pdfTemplateModernDescription.
  ///
  /// In en, this message translates to:
  /// **'Bold header with contemporary styling'**
  String get pdfTemplateModernDescription;

  /// No description provided for @pdfTemplateMinimalName.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get pdfTemplateMinimalName;

  /// No description provided for @pdfTemplateMinimalDescription.
  ///
  /// In en, this message translates to:
  /// **'Simple and distraction-free'**
  String get pdfTemplateMinimalDescription;

  /// No description provided for @pdfTemplateExecutiveName.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get pdfTemplateExecutiveName;

  /// No description provided for @pdfTemplateExecutiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Premium business layout with structured billing blocks'**
  String get pdfTemplateExecutiveDescription;

  /// No description provided for @pdfTemplateCompactName.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get pdfTemplateCompactName;

  /// No description provided for @pdfTemplateCompactDescription.
  ///
  /// In en, this message translates to:
  /// **'Space-efficient receipt layout, ideal for A6 printing'**
  String get pdfTemplateCompactDescription;

  /// No description provided for @pdfTemplateThermalName.
  ///
  /// In en, this message translates to:
  /// **'Thermal'**
  String get pdfTemplateThermalName;

  /// No description provided for @pdfTemplateThermalDescription.
  ///
  /// In en, this message translates to:
  /// **'Narrow receipt layout for 80mm and 58mm thermal printers'**
  String get pdfTemplateThermalDescription;

  /// No description provided for @pdfTemplateGridClassicName.
  ///
  /// In en, this message translates to:
  /// **'Grid Classic'**
  String get pdfTemplateGridClassicName;

  /// No description provided for @pdfTemplateGridClassicDescription.
  ///
  /// In en, this message translates to:
  /// **'Old-style bordered tabular bill, for A4, A5 and A6'**
  String get pdfTemplateGridClassicDescription;

  /// No description provided for @companyInfoAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInfoAppBarTitle;

  /// No description provided for @companyInfoUploadLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get companyInfoUploadLogoLabel;

  /// No description provided for @companyInfoClickToBrowseLabel.
  ///
  /// In en, this message translates to:
  /// **'Click to browse'**
  String get companyInfoClickToBrowseLabel;

  /// No description provided for @companyInfoRemoveLogoButton.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get companyInfoRemoveLogoButton;

  /// No description provided for @companyInfoShowOnPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Show on PDF'**
  String get companyInfoShowOnPdfLabel;

  /// No description provided for @companyInfoLogoRequirementsHint.
  ///
  /// In en, this message translates to:
  /// **'Max 1080×1080 px · 2 MB\nPNG or JPG only'**
  String get companyInfoLogoRequirementsHint;

  /// No description provided for @companyInfoLogoSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'COMPANY LOGO'**
  String get companyInfoLogoSectionLabel;

  /// No description provided for @companyInfoDetailsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'COMPANY DETAILS'**
  String get companyInfoDetailsSectionLabel;

  /// No description provided for @companyInfoBusinessTypeSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS TYPE'**
  String get companyInfoBusinessTypeSectionLabel;

  /// No description provided for @companyInfoPaymentSettingsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT SETTINGS'**
  String get companyInfoPaymentSettingsSectionLabel;

  /// No description provided for @companyInfoUpiAccountsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI ACCOUNTS'**
  String get companyInfoUpiAccountsSectionLabel;

  /// No description provided for @companyInfoBankAccountsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'BANK ACCOUNTS'**
  String get companyInfoBankAccountsSectionLabel;

  /// No description provided for @fieldGstinLabel.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get fieldGstinLabel;

  /// No description provided for @fieldTaxVatNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax/VAT No'**
  String get fieldTaxVatNoLabel;

  /// No description provided for @fieldPanLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get fieldPanLabel;

  /// No description provided for @fieldTinLabel.
  ///
  /// In en, this message translates to:
  /// **'TIN'**
  String get fieldTinLabel;

  /// No description provided for @companyInfoFssaiCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'FSSAI Code'**
  String get companyInfoFssaiCodeLabel;

  /// No description provided for @companyInfoPhoneHelperText.
  ///
  /// In en, this message translates to:
  /// **'Multiple numbers: separate with comma'**
  String get companyInfoPhoneHelperText;

  /// No description provided for @fieldWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get fieldWebsiteLabel;

  /// No description provided for @companyInfoBusinessTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get companyInfoBusinessTypeTitle;

  /// No description provided for @companyInfoBusinessTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Controls item type options in the product list and invoices'**
  String get companyInfoBusinessTypeSubtitle;

  /// No description provided for @labelBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get labelBoth;

  /// No description provided for @companyInfoSetAsDefaultTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get companyInfoSetAsDefaultTooltip;

  /// No description provided for @companyInfoUpiIdLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get companyInfoUpiIdLabel;

  /// No description provided for @companyInfoAddUpiAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Add UPI Account'**
  String get companyInfoAddUpiAccountButton;

  /// No description provided for @companyInfoShowQrToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code on Invoices'**
  String get companyInfoShowQrToggleTitle;

  /// No description provided for @companyInfoShowQrToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds scannable UPI payment QR codes to generated PDFs'**
  String get companyInfoShowQrToggleSubtitle;

  /// No description provided for @companyInfoShowBankDetailsToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Show Bank Details on Invoices'**
  String get companyInfoShowBankDetailsToggleTitle;

  /// No description provided for @companyInfoShowBankDetailsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prints bank account details on generated PDFs'**
  String get companyInfoShowBankDetailsToggleSubtitle;

  /// No description provided for @fieldBankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get fieldBankNameLabel;

  /// No description provided for @fieldAccountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get fieldAccountNumberLabel;

  /// No description provided for @fieldIfscCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get fieldIfscCodeLabel;

  /// No description provided for @companyInfoAddBankAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Account'**
  String get companyInfoAddBankAccountButton;

  /// No description provided for @tooltipShowOnInvoicePdf.
  ///
  /// In en, this message translates to:
  /// **'Show on invoice PDF'**
  String get tooltipShowOnInvoicePdf;

  /// No description provided for @companyInfoSavedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Company info saved successfully'**
  String get companyInfoSavedSuccessMessage;

  /// No description provided for @companyInfoImageTooLargeMessage.
  ///
  /// In en, this message translates to:
  /// **'Image file must be less than 2 MB.'**
  String get companyInfoImageTooLargeMessage;

  /// No description provided for @companyInfoInvalidImageMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid image file.'**
  String get companyInfoInvalidImageMessage;

  /// No description provided for @companyInfoImageDimensionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Image must be max 1080x1080 pixels.'**
  String get companyInfoImageDimensionsMessage;

  /// No description provided for @companyInfoHintExampleBankName.
  ///
  /// In en, this message translates to:
  /// **'e.g. HDFC Bank'**
  String get companyInfoHintExampleBankName;

  /// No description provided for @companyInfoHintExampleAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main Account'**
  String get companyInfoHintExampleAccountLabel;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @appInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Software Information'**
  String get appInfoTitle;

  /// No description provided for @appInfoAppDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'APP DETAILS'**
  String get appInfoAppDetailsTitle;

  /// No description provided for @appInfoAppNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appInfoAppNameLabel;

  /// No description provided for @appInfoVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appInfoVersionLabel;

  /// No description provided for @appInfoLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get appInfoLicenseLabel;

  /// No description provided for @appInfoDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get appInfoDeveloperTitle;

  /// No description provided for @appInfoDeveloperLabel.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get appInfoDeveloperLabel;

  /// No description provided for @appInfoSupportEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get appInfoSupportEmailLabel;

  /// No description provided for @appInfoFooterCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} {developer}  |  Released under the {license} License'**
  String appInfoFooterCopyright(int year, String developer, String license);

  /// No description provided for @appInfoCheckingLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get appInfoCheckingLabel;

  /// No description provided for @appInfoUpdateAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get appInfoUpdateAvailableLabel;

  /// No description provided for @appInfoUpToDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get appInfoUpToDateLabel;

  /// No description provided for @appInfoCheckFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get appInfoCheckFailedLabel;

  /// No description provided for @appInfoUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'UPDATES'**
  String get appInfoUpdatesTitle;

  /// No description provided for @appInfoCurrentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get appInfoCurrentVersionLabel;

  /// No description provided for @appInfoLatestVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest Version'**
  String get appInfoLatestVersionLabel;

  /// No description provided for @appInfoCheckNowButton.
  ///
  /// In en, this message translates to:
  /// **'Check Now'**
  String get appInfoCheckNowButton;

  /// No description provided for @backupManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Management'**
  String get backupManagementTitle;

  /// No description provided for @backupCreateDbButton.
  ///
  /// In en, this message translates to:
  /// **'Create DB Backup'**
  String get backupCreateDbButton;

  /// No description provided for @backupExportJsonButton.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get backupExportJsonButton;

  /// No description provided for @backupImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get backupImportButton;

  /// No description provided for @backupNoBackupsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No backups found'**
  String get backupNoBackupsFoundMessage;

  /// No description provided for @backupSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String backupSizeLabel(String size);

  /// No description provided for @backupCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String backupCreatedLabel(String date);

  /// No description provided for @backupLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backups: {error}'**
  String backupLoadErrorMessage(String error);

  /// No description provided for @backupCreatedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!'**
  String get backupCreatedSuccessMessage;

  /// No description provided for @backupCreateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup: {error}'**
  String backupCreateErrorMessage(String error);

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data with the backup. Are you sure?'**
  String get backupRestoreConfirmBody;

  /// No description provided for @backupRestoreErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup: {error}'**
  String backupRestoreErrorMessage(String error);

  /// No description provided for @backupDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get backupDeleteConfirmTitle;

  /// No description provided for @backupDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this backup?'**
  String get backupDeleteConfirmBody;

  /// No description provided for @backupDeletedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted successfully!'**
  String get backupDeletedSuccessMessage;

  /// No description provided for @backupDeleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete backup'**
  String get backupDeleteFailedMessage;

  /// No description provided for @backupDeleteErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete backup: {error}'**
  String backupDeleteErrorMessage(String error);

  /// No description provided for @backupSavedToDownloadsMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to Downloads folder.'**
  String get backupSavedToDownloadsMessage;

  /// No description provided for @backupDownloadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to download backup: {error}'**
  String backupDownloadErrorMessage(String error);

  /// No description provided for @backupShareErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to share backup: {error}'**
  String backupShareErrorMessage(String error);

  /// No description provided for @backupImportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup: {error}'**
  String backupImportErrorMessage(String error);

  /// No description provided for @backupRestoreSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Successful'**
  String get backupRestoreSuccessTitle;

  /// No description provided for @backupRestoreSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The database has been restored successfully.\n\nThe app needs to restart to apply the changes. Please close and reopen the application.'**
  String get backupRestoreSuccessBody;

  /// No description provided for @backupCloseLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Close Later'**
  String get backupCloseLaterButton;

  /// No description provided for @backupCloseAppNowButton.
  ///
  /// In en, this message translates to:
  /// **'Close App Now'**
  String get backupCloseAppNowButton;

  /// No description provided for @commonSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccessTitle;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonErrorTitle;

  /// No description provided for @productColumnsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Product Details'**
  String get productColumnsScreenTitle;

  /// No description provided for @productColumnsSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Product columns saved.'**
  String get productColumnsSavedMessage;

  /// No description provided for @productColumnsIntroText.
  ///
  /// In en, this message translates to:
  /// **'Choose which fields appear on the product add/edit forms, the product list, and invoice line items. Name and Price are always required.'**
  String get productColumnsIntroText;

  /// No description provided for @productColumnsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productColumnsNameLabel;

  /// No description provided for @productColumnsPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productColumnsPriceLabel;

  /// No description provided for @productColumnsAlwaysRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always shown — required.'**
  String get productColumnsAlwaysRequiredSubtitle;

  /// No description provided for @productColumnsStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productColumnsStockLabel;

  /// No description provided for @productColumnsStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off if you never track stock — products default to unlimited stock instead.'**
  String get productColumnsStockSubtitle;

  /// No description provided for @productColumnsProductFieldsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Product fields'**
  String get productColumnsProductFieldsSectionTitle;

  /// No description provided for @productColumnsAliasNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Alias Name'**
  String get productColumnsAliasNameLabel;

  /// No description provided for @productColumnsAliasNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local-language display name for PDFs/printing.'**
  String get productColumnsAliasNameSubtitle;

  /// No description provided for @productColumnsTaxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate'**
  String get productColumnsTaxRateLabel;

  /// No description provided for @productColumnsTaxRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Per-product tax percentage.'**
  String get productColumnsTaxRateSubtitle;

  /// No description provided for @productColumnsHsnSacLabel.
  ///
  /// In en, this message translates to:
  /// **'HSN/SAC'**
  String get productColumnsHsnSacLabel;

  /// No description provided for @productColumnsHsnSacSubtitle.
  ///
  /// In en, this message translates to:
  /// **'HSN or SAC code field.'**
  String get productColumnsHsnSacSubtitle;

  /// No description provided for @productColumnsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productColumnsDescriptionLabel;

  /// No description provided for @productColumnsDescriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free-text product description.'**
  String get productColumnsDescriptionSubtitle;

  /// No description provided for @productColumnsPurchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get productColumnsPurchasePriceLabel;

  /// No description provided for @productColumnsPurchasePriceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cost price, for margin tracking.'**
  String get productColumnsPurchasePriceSubtitle;

  /// No description provided for @productColumnsDefaultDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Discount'**
  String get productColumnsDefaultDiscountLabel;

  /// No description provided for @productColumnsDefaultDiscountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-filled discount when adding this product to an invoice.'**
  String get productColumnsDefaultDiscountSubtitle;

  /// No description provided for @productColumnsUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get productColumnsUnitLabel;

  /// No description provided for @productColumnsUnitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unit of measure (pcs, kg, hrs...).'**
  String get productColumnsUnitSubtitle;

  /// No description provided for @productColumnsProductServiceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Product/Service Type'**
  String get productColumnsProductServiceTypeLabel;

  /// No description provided for @productColumnsProductServiceTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Segmented Product vs Service selector.'**
  String get productColumnsProductServiceTypeSubtitle;

  /// No description provided for @productColumnsMetadataLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Metadata'**
  String get productColumnsMetadataLabel;

  /// No description provided for @productColumnsMetadataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Storage location, container/batch number, expiry, manufacture date, supplier, SKU, notes.'**
  String get productColumnsMetadataSubtitle;

  /// No description provided for @productColumnsMetaStorageLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get productColumnsMetaStorageLocationLabel;

  /// No description provided for @productColumnsMetaContainerNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Container Number'**
  String get productColumnsMetaContainerNumberLabel;

  /// No description provided for @productColumnsMetaBatchNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch Number'**
  String get productColumnsMetaBatchNumberLabel;

  /// No description provided for @productColumnsMetaExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get productColumnsMetaExpiryDateLabel;

  /// No description provided for @productColumnsMetaManufactureDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Manufacture Date'**
  String get productColumnsMetaManufactureDateLabel;

  /// No description provided for @productColumnsMetaSupplierNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get productColumnsMetaSupplierNameLabel;

  /// No description provided for @productColumnsMetaSkuCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU Code'**
  String get productColumnsMetaSkuCodeLabel;

  /// No description provided for @productColumnsMetaNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get productColumnsMetaNotesLabel;

  /// No description provided for @productColumnsExtraCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra Cost'**
  String get productColumnsExtraCostLabel;

  /// No description provided for @productColumnsExtraCostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional flat extra charge on an invoice line item.'**
  String get productColumnsExtraCostSubtitle;

  /// No description provided for @settingsOptionsComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Options coming soon...'**
  String get settingsOptionsComingSoonMessage;

  /// No description provided for @settingsNavCompanyInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Info'**
  String get settingsNavCompanyInfoLabel;

  /// No description provided for @settingsNavTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get settingsNavTeamLabel;

  /// No description provided for @settingsNavBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsNavBackupLabel;

  /// No description provided for @settingsNavUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get settingsNavUsersLabel;

  /// No description provided for @settingsNavProductDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get settingsNavProductDetailsLabel;

  /// No description provided for @settingsNavCustomizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get settingsNavCustomizeLabel;

  /// No description provided for @settingsNavAccessibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsNavAccessibilityLabel;

  /// No description provided for @settingsNavSoftwareInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Software Info'**
  String get settingsNavSoftwareInfoLabel;

  /// No description provided for @customizationEyebrowLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMIZATION'**
  String get customizationEyebrowLabel;

  /// No description provided for @customizationHeadline.
  ///
  /// In en, this message translates to:
  /// **'Tailored just for your business'**
  String get customizationHeadline;

  /// No description provided for @customizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick what you need and send a request. We\'ll get back to you within 24 hours.'**
  String get customizationSubtitle;

  /// No description provided for @customizationRecommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get customizationRecommendedBadge;

  /// No description provided for @customizationDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery: {delivery}'**
  String customizationDeliveryLabel(String delivery);

  /// No description provided for @customizationRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get customizationRequestButton;

  /// No description provided for @customizationFormOpenErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not open the form. Please visit forms.gle/LyX6Z2kBNR2BpwVu7 in your browser.'**
  String get customizationFormOpenErrorMessage;

  /// No description provided for @customizationDisclaimerMessage.
  ///
  /// In en, this message translates to:
  /// **'Prices are indicative. Final quote may vary based on complexity. Payment is collected after scope agreement.'**
  String get customizationDisclaimerMessage;

  /// No description provided for @customizationPdfTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom PDF Template'**
  String get customizationPdfTemplateTitle;

  /// No description provided for @customizationPdfTemplateDescription.
  ///
  /// In en, this message translates to:
  /// **'Get an invoice template designed to match your brand — your colors, fonts, logo placement, and layout.'**
  String get customizationPdfTemplateDescription;

  /// No description provided for @customizationPdfTemplateDelivery.
  ///
  /// In en, this message translates to:
  /// **'2–5 days'**
  String get customizationPdfTemplateDelivery;

  /// No description provided for @customizationCustomFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get customizationCustomFieldsTitle;

  /// No description provided for @customizationCustomFieldsDescription.
  ///
  /// In en, this message translates to:
  /// **'Need extra fields on your invoices? (PO number, project code, department, etc.) We\'ll add them for you.'**
  String get customizationCustomFieldsDescription;

  /// No description provided for @customizationCustomFieldsDelivery.
  ///
  /// In en, this message translates to:
  /// **'1–3 days'**
  String get customizationCustomFieldsDelivery;

  /// No description provided for @customizationWhiteLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'White-label / Remove Branding'**
  String get customizationWhiteLabelTitle;

  /// No description provided for @customizationWhiteLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all Invoiso branding from the app and PDF outputs, and replace it with your own company identity.'**
  String get customizationWhiteLabelDescription;

  /// No description provided for @customizationWhiteLabelDelivery.
  ///
  /// In en, this message translates to:
  /// **'3–6 days'**
  String get customizationWhiteLabelDelivery;

  /// No description provided for @customizationIndustryBuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Industry-specific Build'**
  String get customizationIndustryBuildTitle;

  /// No description provided for @customizationIndustryBuildDescription.
  ///
  /// In en, this message translates to:
  /// **'Need a version tailored to your industry? (construction, consulting, retail, etc.) We\'ll customise the workflow to fit your needs.'**
  String get customizationIndustryBuildDescription;

  /// No description provided for @customizationIndustryBuildDelivery.
  ///
  /// In en, this message translates to:
  /// **'5–10 days'**
  String get customizationIndustryBuildDelivery;

  /// No description provided for @accessibilityCreateInvoiceLayoutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Create Invoice Page Layout'**
  String get accessibilityCreateInvoiceLayoutSectionTitle;

  /// No description provided for @accessibilityClassicLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Classic layout'**
  String get accessibilityClassicLayoutLabel;

  /// No description provided for @accessibilityNewLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'New layout'**
  String get accessibilityNewLayoutLabel;

  /// No description provided for @accessibilityLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which \"New Invoice\" screen design to use.'**
  String get accessibilityLayoutDescription;

  /// No description provided for @accessibilityShortcutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Speed up invoice creation without touching the mouse.'**
  String get accessibilityShortcutsSubtitle;

  /// No description provided for @paymentDialogInvoiceRefLabel.
  ///
  /// In en, this message translates to:
  /// **'#{number} — {customer}'**
  String paymentDialogInvoiceRefLabel(String number, String customer);

  /// No description provided for @paymentDialogInvoiceTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Total'**
  String get paymentDialogInvoiceTotalLabel;

  /// No description provided for @paymentDialogAmountPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get paymentDialogAmountPaidLabel;

  /// No description provided for @paymentDialogHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentDialogHistoryTitle;

  /// No description provided for @paymentDialogNoPaymentsMessage.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet'**
  String get paymentDialogNoPaymentsMessage;

  /// No description provided for @paymentDialogFullyPaidExclaimMessage.
  ///
  /// In en, this message translates to:
  /// **'Invoice fully paid!'**
  String get paymentDialogFullyPaidExclaimMessage;

  /// No description provided for @paymentDialogFullyPaidBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice fully paid'**
  String get paymentDialogFullyPaidBannerLabel;

  /// No description provided for @paymentDialogRecordedMessage.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded. Outstanding: {symbol} {amount}'**
  String paymentDialogRecordedMessage(String symbol, String amount);

  /// No description provided for @paymentDialogRecordFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment: {error}'**
  String paymentDialogRecordFailedMessage(String error);

  /// No description provided for @paymentDialogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get paymentDialogDeleteTitle;

  /// No description provided for @paymentDialogDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete receipt {receiptNumber}?\n\nThis cannot be undone.'**
  String paymentDialogDeleteConfirmBody(String receiptNumber);

  /// No description provided for @paymentDialogNewPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'New Payment'**
  String get paymentDialogNewPaymentTitle;

  /// No description provided for @paymentDialogAmountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol})'**
  String paymentDialogAmountFieldLabel(String symbol);

  /// No description provided for @paymentDialogMaxHelperText.
  ///
  /// In en, this message translates to:
  /// **'Max: {symbol} {amount}'**
  String paymentDialogMaxHelperText(String symbol, String amount);

  /// No description provided for @paymentDialogInvalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get paymentDialogInvalidAmountError;

  /// No description provided for @paymentDialogExceedsOutstandingError.
  ///
  /// In en, this message translates to:
  /// **'Exceeds outstanding balance'**
  String get paymentDialogExceedsOutstandingError;

  /// No description provided for @paymentDialogMethodFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentDialogMethodFieldLabel;

  /// No description provided for @paymentDialogSelectMethodHint.
  ///
  /// In en, this message translates to:
  /// **'Select method'**
  String get paymentDialogSelectMethodHint;

  /// No description provided for @paymentDialogTaxCoveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Covered'**
  String get paymentDialogTaxCoveredLabel;

  /// No description provided for @paymentDialogAutoCalculatedHelper.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculated'**
  String get paymentDialogAutoCalculatedHelper;

  /// No description provided for @paymentDialogNotesFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference / Notes (optional)'**
  String get paymentDialogNotesFieldLabel;

  /// No description provided for @paymentDialogNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cheque no., transaction ID...'**
  String get paymentDialogNotesHint;

  /// No description provided for @paymentDialogReceiptColLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt #'**
  String get paymentDialogReceiptColLabel;

  /// No description provided for @paymentDialogMethodColLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentDialogMethodColLabel;

  /// No description provided for @paymentDialogDownloadReceiptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get paymentDialogDownloadReceiptTooltip;

  /// No description provided for @paymentDialogDeletePaymentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete payment'**
  String get paymentDialogDeletePaymentTooltip;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get paymentMethodCheck;

  /// No description provided for @paymentMethodOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get paymentMethodOnline;

  /// No description provided for @paymentMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paymentMethodOther;

  /// No description provided for @customerInfoButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'View contact details'**
  String get customerInfoButtonTooltip;

  /// No description provided for @customerInfoButtonNoContactMessage.
  ///
  /// In en, this message translates to:
  /// **'No contact details available.'**
  String get customerInfoButtonNoContactMessage;

  /// No description provided for @updateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateDialogTitle;

  /// No description provided for @updateDialogBodyMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of invoiso is available. Visit the download page to get the latest release.'**
  String get updateDialogBodyMessage;

  /// No description provided for @pageSizeA4Label.
  ///
  /// In en, this message translates to:
  /// **'Standard A4'**
  String get pageSizeA4Label;

  /// No description provided for @pageSizeA5Label.
  ///
  /// In en, this message translates to:
  /// **'Standard A5'**
  String get pageSizeA5Label;

  /// No description provided for @pageSizeA6Label.
  ///
  /// In en, this message translates to:
  /// **'Standard A6'**
  String get pageSizeA6Label;

  /// No description provided for @pageSizeThermal80Label.
  ///
  /// In en, this message translates to:
  /// **'Thermal Paper 80mm'**
  String get pageSizeThermal80Label;

  /// No description provided for @pageSizeThermal58Label.
  ///
  /// In en, this message translates to:
  /// **'Thermal Paper 58mm'**
  String get pageSizeThermal58Label;

  /// No description provided for @dateFormatDdmmyyyyLabel.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY  (e.g. 15/04/2026)'**
  String get dateFormatDdmmyyyyLabel;

  /// No description provided for @dateFormatMmddyyyyLabel.
  ///
  /// In en, this message translates to:
  /// **'MM/DD/YYYY  (e.g. 04/15/2026)'**
  String get dateFormatMmddyyyyLabel;

  /// No description provided for @dateFormatDdMmmyyyyLabel.
  ///
  /// In en, this message translates to:
  /// **'DD MMM YYYY  (e.g. 15 Apr 2026)'**
  String get dateFormatDdMmmyyyyLabel;

  /// No description provided for @dateFormatYyyymmddLabel.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD  (e.g. 2026-04-15)'**
  String get dateFormatYyyymmddLabel;

  /// No description provided for @sizeXSmallLabel.
  ///
  /// In en, this message translates to:
  /// **'X-Small'**
  String get sizeXSmallLabel;

  /// No description provided for @sizeSmallLabel.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmallLabel;

  /// No description provided for @sizeMediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMediumLabel;

  /// No description provided for @sizeLargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLargeLabel;

  /// No description provided for @shortcutNewInvoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'New Invoice (from Dashboard) / Reset form (in Create Invoice)'**
  String get shortcutNewInvoiceDescription;

  /// No description provided for @shortcutSaveInvoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Save / create the invoice'**
  String get shortcutSaveInvoiceDescription;

  /// No description provided for @shortcutAddProductDescription.
  ///
  /// In en, this message translates to:
  /// **'Add product to invoice'**
  String get shortcutAddProductDescription;

  /// No description provided for @shortcutAddCustomItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Add custom (ad-hoc) item'**
  String get shortcutAddCustomItemDescription;

  /// No description provided for @shortcutPreviewPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Preview invoice PDF'**
  String get shortcutPreviewPdfDescription;

  /// No description provided for @shortcutPrintPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate / print invoice PDF'**
  String get shortcutPrintPdfDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bo',
        'en',
        'es',
        'fr',
        'hi',
        'ne',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bo':
      return AppLocalizationsBo();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ne':
      return AppLocalizationsNe();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
