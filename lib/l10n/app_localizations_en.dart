// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Invoiso';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionGetStarted => 'Get Started';

  @override
  String get commonLanguage => 'Language';

  @override
  String get commonBeta => 'Beta';

  @override
  String get commonSystemDefault => 'System Default';

  @override
  String get commonTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get onboardingStepCompanyTitle => 'Company';

  @override
  String get onboardingStepCompanySubtitle => 'Tell us about your business';

  @override
  String get onboardingStepInvoiceTitle => 'Invoice Settings';

  @override
  String get onboardingStepInvoiceSubtitle => 'Set up how your invoices work';

  @override
  String get onboardingStepAppearanceTitle => 'Invoice Appearance';

  @override
  String get onboardingStepAppearanceSubtitle =>
      'Pick a page size and template';

  @override
  String get onboardingStepDoneTitle => 'All Set';

  @override
  String get onboardingCompanyNameLabel => 'Company Name';

  @override
  String get onboardingCountryLabel => 'Country';

  @override
  String get onboardingLogoLabel => 'Company Logo';

  @override
  String get onboardingCurrencyLabel => 'Currency';

  @override
  String get onboardingDateFormatLabel => 'Date Format';

  @override
  String get onboardingInvoiceStartingNumberLabel => 'Invoice Starting Number';

  @override
  String get onboardingLeadingZerosLabel => 'Leading Zeros';

  @override
  String get onboardingLeadingZerosSubtitle =>
      'Pad invoice numbers to 8 digits (e.g. 00000007)';

  @override
  String get onboardingDefaultTaxRateLabel => 'Default Tax Rate (%)';

  @override
  String get onboardingPageSizeLabel => 'Page Size';

  @override
  String get onboardingTemplateLabel => 'Invoice Template';

  @override
  String get onboardingDoneHeadline => 'You\'re all set!';

  @override
  String get onboardingDoneBody =>
      'Your company, invoice and template details are saved. You can update any of these later from Settings.';

  @override
  String get splashInitErrorTitle => 'Initialization Error';

  @override
  String splashInitErrorMessage(String error) {
    return 'Failed to initialize the database.\n\n$error';
  }

  @override
  String get actionRetry => 'Retry';

  @override
  String get splashInitializingMessage => 'Initializing App...';

  @override
  String get testGateNoInternetTitle =>
      'Test installer needs internet access to verify.';

  @override
  String get testGateExpiredTitle => 'This test build has expired.';

  @override
  String get testGateNoInternetSubtitle => 'Connect to the internet and retry.';

  @override
  String testGateExpiredSubtitle(String email) {
    return 'Contact support: $email';
  }

  @override
  String get dashboardSessionExpiredMessage =>
      'Session expired due to inactivity.';

  @override
  String get dashboardUnknownTabLabel => 'Unknown tab';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return 'Invoice layout: $layout — tap for info';
  }

  @override
  String get dashboardLayoutNew => 'New';

  @override
  String get dashboardLayoutClassic => 'Classic';

  @override
  String get dashboardInvoiceLayoutDialogTitle => 'Invoice layout';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return 'You\'re using the $layout \"New Invoice\" layout. You can switch it from Settings > Accessibility. Note: switching mid-edit discards any unsaved changes on this form.';
  }

  @override
  String get actionClose => 'Close';

  @override
  String get dashboardOpenSettingsAction => 'Open Settings';

  @override
  String get dashboardCollapseSidebarTooltip => 'Collapse sidebar';

  @override
  String get dashboardExpandSidebarTooltip => 'Expand sidebar';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navNewInvoice => 'New Invoice';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navQuotations => 'Quotations';

  @override
  String get navReceipts => 'Receipts';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navProducts => 'Products';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardRoleAdmin => 'Admin';

  @override
  String get dashboardRoleUser => 'User';

  @override
  String get dashboardSupportTooltip => 'Support';

  @override
  String get dashboardLogoutTooltip => 'Logout';

  @override
  String get dashboardTestBuildBadge => 'TEST BUILD';

  @override
  String get dashboardTestBadgeShort => 'TEST';

  @override
  String get dashboardKeyboardShortcutsTitle => 'Keyboard Shortcuts';

  @override
  String get dashboardShortcutsBannerTitle => 'New: Keyboard shortcuts';

  @override
  String get dashboardShortcutsBannerSubtitle =>
      'Ctrl+Q for a new invoice, Ctrl+S to save, and more.';

  @override
  String get dashboardViewAllAction => 'View all';

  @override
  String get dashboardLayoutBannerTitle => 'New: Multiple dashboard layouts';

  @override
  String get dashboardLayoutBannerSubtitle =>
      'Switch between Default, Classic, Bento, and Simple Feed using the grid icon in the top-right.';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get dashboardThemeBannerTitle => 'New: Dark mode';

  @override
  String get dashboardThemeBannerSubtitle =>
      'We\'re still polishing it — switch it on from Settings > Company Info and let us know what looks off.';

  @override
  String dashboardSupportBannerTitle(String count) {
    return 'You\'ve created $count invoices!';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      'Enjoying Invoiso? A quick review helps a lot.';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      'Looks like Invoiso is part of your workflow. If it\'s been helpful, consider supporting the project — whenever it feels right.';

  @override
  String get dashboardReviewAction => 'Review';

  @override
  String get dashboardSupportAction => 'Support';

  @override
  String get dashboardOverviewTitle => 'Dashboard Overview';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count out of stock';
  }

  @override
  String get dashboardRevenueCollectedLabel => 'Revenue Collected';

  @override
  String get dashboardOutstandingLabel => 'Outstanding';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count overdue';
  }

  @override
  String get dashboardRecentInvoicesTitle => 'Recent Invoices';

  @override
  String get dashboardLastFiveInvoicesLabel => 'Last 5 invoices';

  @override
  String get dashboardNoInvoicesYetTitle => 'No invoices yet';

  @override
  String get dashboardNoInvoicesYetSubtitle =>
      'Create your first invoice to see it here';

  @override
  String get actionView => 'View';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionPdfPreview => 'PDF Preview';

  @override
  String get actionDownloadPdf => 'Download PDF';

  @override
  String get actionPrint => 'Print';

  @override
  String get actionPayment => 'Payment';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRecordPayment => 'Record Payment';

  @override
  String dashboardDueDateLabel(String date) {
    return 'Due: $date';
  }

  @override
  String get labelInvoice => 'Invoice';

  @override
  String get labelQuotation => 'Quotation';

  @override
  String get labelReceipt => 'Receipt';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return 'Welcome back, $username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle =>
      'Here\'s your business at a glance';

  @override
  String get dashboardDueSoonTitle => 'Due Soon';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => 'Today & Tomorrow';

  @override
  String get dashboardDueTodayBadge => 'Due Today';

  @override
  String get dashboardDueTomorrowBadge => 'Due Tomorrow';

  @override
  String get dashboardOverdueSectionTitle => 'Overdue';

  @override
  String get dashboardOldestFirstLabel => 'Oldest first';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => 'New Stock Quantity';

  @override
  String get actionUpdate => 'Update';

  @override
  String get labelService => 'Service';

  @override
  String get labelProduct => 'Product';

  @override
  String dashboardStockLabel(int count) {
    return 'Stock: $count';
  }

  @override
  String get actionUpdateStock => 'Update Stock';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusPartial => 'Partial';

  @override
  String get paymentStatusUnpaid => 'Unpaid';

  @override
  String get dashboardDuplicateInvoiceTitle => 'Duplicate Invoice';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return 'Create a copy of Invoice #$number\n($customerName) as:';
  }

  @override
  String get dashboardDeleteInvoiceTitle => 'Delete Invoice';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return 'Are you sure you want to delete Invoice #$number? This action cannot be undone.';
  }

  @override
  String get dashboardLayoutTooltip => 'Dashboard Layout';

  @override
  String get dashboardLayoutDefaultTitle => 'Default';

  @override
  String get dashboardLayoutDefaultSubtitle => 'Original layout';

  @override
  String get dashboardLayoutClassicSubtitle => 'Charts + KPI grid';

  @override
  String get dashboardLayoutBentoTitle => 'Bento';

  @override
  String get dashboardLayoutBentoSubtitle => 'Hero chart + card grid';

  @override
  String get dashboardLayoutSimpleTitle => 'Simple Feed';

  @override
  String get dashboardLayoutSimpleSubtitle => 'Clean list view';

  @override
  String get dashboardTotalInvoicesLabel => 'Total Invoices';

  @override
  String get dashboardRevenueLast6MonthsTitle => 'Revenue — Last 6 Months';

  @override
  String get dashboardNoPaymentDataYetLabel => 'No payment data yet';

  @override
  String get dashboardFinancialOverviewTitle => 'Financial Overview';

  @override
  String get dashboardCollectedLabel => 'Collected';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices overdue',
      one: '1 invoice overdue',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return 'Last $n';
  }

  @override
  String get labelCustomer => 'Customer';

  @override
  String get labelAmount => 'Amount';

  @override
  String get dashboardZeroLeftLabel => '0 left';

  @override
  String get labelStock => 'Stock';

  @override
  String get actionPay => 'Pay';

  @override
  String get dashboardQuickActionsTitle => 'Quick Actions';

  @override
  String get dashboardPdfActionsTooltip => 'PDF Actions';

  @override
  String get dashboardActionsTooltip => 'Actions';

  @override
  String get dashboardTopCustomersTitle => 'Top Customers';

  @override
  String get dashboardTopProductsTitle => 'Top Products';

  @override
  String dashboardUnitsLabel(String qty) {
    return '$qty units';
  }

  @override
  String get dashboardBetaBadge => 'BETA';

  @override
  String get dashboardOutOfStockSectionTitle => 'Out of Stock';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => 'Tap to restock';

  @override
  String get createInvoiceUnsavedChangesTitle => 'Unsaved changes';

  @override
  String get createInvoiceUnsavedChangesMessage =>
      'You have unsaved changes in this invoice. Save them before leaving?';

  @override
  String get createInvoiceKeepEditingButton => 'Keep Editing';

  @override
  String get actionDiscard => 'Discard';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return 'Error loading data: $e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => 'Insufficient Stock';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return 'Only $stock unit(s) available. Add $qty anyway?';
  }

  @override
  String get createInvoiceAddAnywayButton => 'Add Anyway';

  @override
  String get createInvoiceOutOfStockTitle => 'Out of Stock';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name is out of stock. Add anyway?';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => 'Unlimited Stock';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return 'Available Stock: $stock';
  }

  @override
  String get fieldDiscountLabel => 'Discount';

  @override
  String get fieldUnitPriceOverrideLabel => 'Unit Price (override)';

  @override
  String get fieldExtraCostLabel => 'Extra Cost (optional)';

  @override
  String get fieldInsertAtPositionLabel => 'Insert at position';

  @override
  String get actionAdd => 'Add';

  @override
  String get createInvoiceProductAlreadyAddedMessage =>
      'This product has already been added';

  @override
  String get createInvoiceCustomerNameRequiredMessage =>
      'Please provide customer name';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage =>
      'Please add at least one item';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel created successfully!';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return 'Error creating invoice: $e';
  }

  @override
  String get createInvoiceEditItemTitle => 'Edit Item';

  @override
  String get createInvoiceCustomItemTitle => 'Custom Item';

  @override
  String get fieldItemNameLabel => 'Item Name';

  @override
  String get fieldAliasForPdfLabel => 'Alias (for PDF)';

  @override
  String get fieldUnitPriceLabel => 'Unit Price';

  @override
  String get fieldRateLabel => 'Rate';

  @override
  String get fieldTaxRateLabel => 'Tax Rate (%)';

  @override
  String get fieldPriceIncludesTaxLabel => 'Price includes tax';

  @override
  String get createInvoicePhoneAlreadyInUseTitle =>
      'Phone Number Already In Use';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return 'This phone number belongs to \"$ownerName\".\n\nCannot save this customer with a phone number that already belongs to someone else.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      'Please enter a customer name before saving';

  @override
  String get createInvoicePhoneChangedTitle => 'Phone Number Changed';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return 'The phone number for \"$name\" was changed.\n\nUpdate their existing record, or save these details as a new customer?';
  }

  @override
  String get createInvoiceSaveAsNewButton => 'Save as New';

  @override
  String get createInvoiceUpdateExistingButton => 'Update Existing';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '$name updated in customer list';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle =>
      'Customer Already Exists';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '\"$name\" is already saved with this phone number.\n\nUse their existing details, or update their record with the current information?';
  }

  @override
  String get createInvoiceUseExistingButton => 'Use Existing';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return 'Using existing customer \"$name\"';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name saved to customer list';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage =>
      'Customer record no longer exists';

  @override
  String get createInvoiceCustomerRefreshedMessage =>
      'Customer details refreshed';

  @override
  String get fieldLabelLabel => 'Label';

  @override
  String get hintLabelExample => 'e.g. Shipping';

  @override
  String get tooltipRemove => 'Remove';

  @override
  String get createInvoiceAddRowButton => 'Add Row';

  @override
  String get fieldDiscountPerUnitLabel => 'Discount per unit';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn =>
      '(price − discount) × qty';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff =>
      '(price × qty) − discount';

  @override
  String get createInvoicePrevBalanceShortLabel => 'Prev. Balance';

  @override
  String get createInvoicePreviousBalanceDueLabel => 'Previous Balance Due';

  @override
  String get createInvoiceDueShortLabel => 'Due';

  @override
  String get createInvoiceTotalDueLabel => 'Total Due';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel updated successfully!';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return 'Error updating invoice: $e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '$invoiceTypeLabel Created Successfully!';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return '$invoiceTypeLabel ID: $invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => 'View Details';

  @override
  String get createInvoicePreviewPdfLabel => 'Preview PDF';

  @override
  String get createInvoicePreviewPdfTooltip => 'Preview PDF (Shortcut: Ctrl+o)';

  @override
  String get createInvoicePrintPdfLabel => 'Print PDF';

  @override
  String get createInvoicePrintPdfTooltip => 'Print PDF (Shortcut: Ctrl+p)';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get createInvoiceCreateNewInvoiceButton =>
      'Create New Invoice (Shortcut: Ctrl+q)';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return 'Create New $invoiceTypeLabel';
  }

  @override
  String get commonLoadingDataMessage => 'Loading data...';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage =>
      'Add at least one item before creating the invoice.';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel Created';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return 'Edit $invoiceTypeLabel';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return 'Duplicate as $invoiceTypeLabel';
  }

  @override
  String get createInvoiceNewShortLabel => 'New';

  @override
  String get createInvoiceNewInvoiceShortcutLabel =>
      'New Invoice (Shortcut: Ctrl+q)';

  @override
  String get createInvoiceSavingEllipsisLabel => 'Saving...';

  @override
  String get createInvoiceSaveCustomerLabel => 'Save customer';

  @override
  String get createInvoiceSelectExistingCustomerButton =>
      'Select from existing';

  @override
  String get createInvoiceRefreshCustomerTooltip =>
      'Refresh from saved customer';

  @override
  String get createInvoiceClearCustomerTooltip => 'Clear customer selection';

  @override
  String get fieldCustomerNameRequiredLabel => 'Customer Name *';

  @override
  String get fieldBusinessNameLabel => 'Business Name';

  @override
  String get fieldPhoneLabel => 'Phone';

  @override
  String get fieldGstinVatLabel => 'GSTIN / VAT';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldAddressLabel => 'Address';

  @override
  String get tooltipEditInLargerView => 'Edit in larger view';

  @override
  String get createInvoiceChooseCustomerTitle => 'Choose a customer';

  @override
  String get createInvoiceSearchCustomerLabel => 'Search customer';

  @override
  String get createInvoiceNoCustomersFoundMessage => 'No customers found';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return '$invoiceTypeLabel DETAILS';
  }

  @override
  String get createInvoiceTypeFieldLabel => 'Invoice type';

  @override
  String get createInvoiceTypeLockedHelperText =>
      'Type can\'t be changed after creation';

  @override
  String get createInvoiceOrderDateLabel => 'Order date';

  @override
  String get createInvoiceDueDateLabel => 'Due date';

  @override
  String get createInvoiceGstTitleLabel => 'GST title';

  @override
  String get createInvoiceTaxTitleLabel => 'Tax title';

  @override
  String get gstTitleTaxInvoiceLabel => 'Tax Invoice';

  @override
  String get gstTitleBillOfSupplyLabel => 'Bill of Supply';

  @override
  String get gstTitleInvoiceCumBillLabel => 'Invoice-cum-Bill of Supply';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => 'Credit Note';

  @override
  String get gstTitleDebitNoteLabel => 'Debit Note';

  @override
  String get gstTitleRevisedInvoiceLabel => 'Revised Invoice';

  @override
  String get createInvoiceSearchProductLabel =>
      'Search & add a product or service (Ctrl+F)';

  @override
  String get createInvoiceCustomItemButton => 'Custom item (Ctrl+M)';

  @override
  String get createInvoiceNoProductsFoundMessage => 'No products found';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '\"$name\" already exists in product list';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name saved to product list';
  }

  @override
  String get createInvoiceSaveToProductListTooltip => 'Save to product list';

  @override
  String get tooltipEditItem => 'Edit item';

  @override
  String get tooltipRemoveItem => 'Remove item';

  @override
  String get createInvoiceNoItemsAddedMessage => 'No items added yet';

  @override
  String get createInvoiceSearchHintMessage => 'Search below or press Ctrl+F';

  @override
  String get createInvoiceDiscountFieldLabel => 'Invoice Discount';

  @override
  String get discountTypeAmountShortLabel => 'Amt';

  @override
  String get createInvoiceNotesOptionalLabel => 'Notes (optional)';

  @override
  String get createInvoiceNotesHint => 'Payment terms, thank-you note…';

  @override
  String get createInvoiceNotesTitle => 'Notes';

  @override
  String get createInvoiceHideNumberInPdfLabel => 'Hide invoice number in PDF';

  @override
  String get createInvoiceCustomNumberLabel => 'Custom number (optional)';

  @override
  String get createInvoiceCustomNumberHint =>
      'e.g. QUO-2026-014 — shown in PDF instead';

  @override
  String get createInvoiceEnableTaxLabel => 'Enable tax';

  @override
  String get createInvoiceGlobalRateTooltip => 'Global rate';

  @override
  String get createInvoicePerItemRateTooltip => 'Per item rate';

  @override
  String get createInvoiceDefaultTaxRateLabel => 'Default tax rate';

  @override
  String get createInvoiceTaxRateFromProductMessage =>
      'Tax rate from each product';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => 'Payment UPI account';

  @override
  String get commonNoneLabel => 'None';

  @override
  String get createInvoiceBankAccountLabel => 'Bank account';

  @override
  String get fieldSubtotalLabel => 'Subtotal';

  @override
  String get createInvoiceDiscountColonLabel => 'Discount:';

  @override
  String get fieldTaxLabel => 'Tax';

  @override
  String get createInvoiceExtraCostFallbackLabel => 'Extra Cost';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return 'Invoice Discount ($toStringAsFixed%):';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel => 'Invoice Discount:';

  @override
  String get fieldTotalLabel => 'Total';

  @override
  String get createInvoicePreviewLabel => 'Preview';

  @override
  String get createInvoicePreviewTooltip => 'Preview (Shortcut: Ctrl+o)';

  @override
  String get createInvoiceDownloadLabel => 'Download';

  @override
  String get createInvoicePrintTooltip => 'Print (Shortcut: Ctrl+p)';

  @override
  String get fieldUnitOverrideLabel => 'Unit (override)';

  @override
  String get commonCustomEllipsisLabel => 'Custom…';

  @override
  String get fieldCustomUnitLabel => 'Custom unit';

  @override
  String get invoiceMgmtMoveToTrashTitle => 'Move to Trash';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return 'Move Invoice #$number to trash?';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage => 'Invoice moved to trash.';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return 'Failed to load invoices: $error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return 'Export $type to CSV';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel => 'Export All Records';

  @override
  String get invoiceMgmtFilterByDateRangeLabel => 'Or filter by date range:';

  @override
  String get invoiceMgmtFromDateLabel => 'From Date';

  @override
  String get invoiceMgmtToDateLabel => 'To Date';

  @override
  String get invoiceMgmtDateRangeInvalidMessage =>
      'To date must be after From date.';

  @override
  String get actionExport => 'Export';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count records to: $path',
      one: 'Exported 1 record to: $path',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return 'Export failed: $error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count invoices to trash?',
      one: 'Move 1 invoice to trash?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices moved to trash.',
      one: '1 invoice moved to trash.',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return 'Bulk delete failed: $error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count invoices to CSV',
      one: 'Exported 1 invoice to CSV',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'CSV export failed: $error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => 'Download PDFs';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'How would you like to save $count PDFs?',
      one: 'How would you like to save 1 PDF?',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => 'Save to Folder';

  @override
  String get invoiceMgmtSaveAsZipLabel => 'Save as ZIP';

  @override
  String get invoiceMgmtChooseFolderDialogTitle => 'Choose folder to save PDFs';

  @override
  String get invoiceMgmtSaveZipDialogTitle => 'Save ZIP file';

  @override
  String get invoiceMgmtCreatingZipLabel => 'Creating ZIP';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => 'Generating PDFs';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Processing $count PDFs...',
      one: 'Processing 1 PDF...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return 'Saved to: $path';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'PDF export failed: $error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle => 'Download PDFs by Filter';

  @override
  String get invoiceMgmtByDateLabel => 'By Date';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => 'By Invoice Number';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => 'From invoice #';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => 'To invoice #';

  @override
  String get invoiceMgmtCheckCountLabel => 'Check count';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return '$count invoices — exceeds limit of $limit';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices match',
      one: '1 invoice match',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return 'Max $limit PDFs per download. Narrow your filter.';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage =>
      'No invoices found for the selected filter.';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return 'Filter returned $count invoices — max is $limit.';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => 'Filter Invoices';

  @override
  String get invoiceMgmtHideFullyPaidLabel => 'Hide fully paid invoices';

  @override
  String get invoiceMgmtPaymentStatusLabel => 'Payment status';

  @override
  String get invoiceMgmtDueDateLabel => 'Due date';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => 'Invoice date range';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel => 'Invoice # range';

  @override
  String get invoiceMgmtFromHashLabel => 'From #';

  @override
  String get invoiceMgmtToHashLabel => 'To #';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionApply => 'Apply';

  @override
  String get invoiceMgmtSortByTitle => 'Sort By';

  @override
  String get invoiceMgmtSearchHintMessage =>
      'Search by Invoice ID or Customer Name…';

  @override
  String get invoiceMgmtFilterLabel => 'Filter';

  @override
  String get invoiceMgmtSortLabel => 'Sort';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return 'Total: $total   ·   Page $page/$totalPages';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get invoiceMgmtDeselectLabel => 'Deselect';

  @override
  String get invoiceMgmtSelectPageLabel => 'Select Page';

  @override
  String get invoiceMgmtMarkPaidLabel => 'Mark Paid';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDFs';

  @override
  String get invoiceMgmtTrashLabel => 'Trash';

  @override
  String get actionApplyPayment => 'Apply Payment';

  @override
  String get invoiceMgmtMoreActionsTooltip => 'More actions';

  @override
  String get invoiceMgmtColSlNo => 'Sl No';

  @override
  String get invoiceMgmtColInvoiceCustomer => 'Invoice / Customer';

  @override
  String get invoiceMgmtColTitle => 'Title';

  @override
  String get invoiceMgmtColDate => 'Date';

  @override
  String get invoiceMgmtColItems => 'Items';

  @override
  String get invoiceMgmtColStatus => 'Status';

  @override
  String get invoiceMgmtColOutstanding => 'Outstanding';

  @override
  String get invoiceMgmtColActions => 'Actions';

  @override
  String get invoiceMgmtRowsPerPageLabel => 'Rows per page:';

  @override
  String get actionPrevious => 'Previous';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return 'Page $page of $totalPages';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return 'No $type found';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return 'Create your first $type to see it here';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage =>
      'Try adjusting your search or filters';

  @override
  String get invoiceMgmtDownloadByRangeTooltip =>
      'Download PDFs by date or invoice range';

  @override
  String get invoiceMgmtExportAllCsvTooltip => 'Export all to CSV';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel => 'Download PDFs by range';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return '$type Management';
  }

  @override
  String get invoiceMgmtOverdueBadge => 'Overdue';

  @override
  String get invoiceMgmtTodayBadge => 'Today';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => 'Trash is empty';

  @override
  String get actionRestore => 'Restore';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => 'Permanently Delete';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return 'Permanently delete Invoice #$number? This cannot be undone.';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage => 'Invoice restored.';

  @override
  String get invoiceMgmtAnyDateLabel => 'Any';

  @override
  String get invoiceMgmtStatusAllLabel => 'All';

  @override
  String get invoiceMgmtDueAllLabel => 'All Dues';

  @override
  String get invoiceMgmtDueTodayLabel => 'Due Today';

  @override
  String get invoiceMgmtDueWeekLabel => 'Due This Week';

  @override
  String get invoiceMgmtDueMonthLabel => 'Due This Month';

  @override
  String get invoiceMgmtSortRecentlyAdded => 'Recently Added';

  @override
  String get invoiceMgmtSortOldestAdded => 'Oldest Added';

  @override
  String get invoiceMgmtSortDateNewest => 'Invoice Date (Newest First)';

  @override
  String get invoiceMgmtSortDateOldest => 'Invoice Date (Oldest First)';

  @override
  String get invoiceMgmtSortCustomerAZ => 'Customer Name (A–Z)';

  @override
  String get invoiceMgmtSortCustomerZA => 'Customer Name (Z–A)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => 'Mark as Paid';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $count invoices as fully paid?',
      one: 'Mark 1 invoice as fully paid?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n($count already paid — will be skipped)';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage =>
      'All selected invoices are already fully paid.';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices marked as paid.',
      one: '1 invoice marked as paid.',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return 'Failed to mark as paid: $error';
  }

  @override
  String get fieldNameLabel => 'Name';

  @override
  String get customerMgmtEditCustomerTitle => 'Edit Customer';

  @override
  String get customerMgmtViewCustomerTitle => 'View Customer';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / VAT Number';
  }

  @override
  String get customerMgmtUpdatedMessage => 'Customer updated successfully!';

  @override
  String fieldRequiredMessage(String field) {
    return 'Please enter $field';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => 'Confirm Delete';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get customerMgmtDeletedMessage => 'Customer deleted successfully!';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle => 'Save Sample CSV';

  @override
  String get customerMgmtSampleSavedMessage => 'Sample CSV saved successfully!';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return 'Error saving sample: $error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle => 'Import Customers from CSV';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      'Your CSV file must use the following column headers (exact spelling, any order):';

  @override
  String get customerMgmtCsvColColumnHeader => 'Column';

  @override
  String get customerMgmtCsvColRequiredHeader => 'Required';

  @override
  String get customerMgmtCsvColDescriptionHeader => 'Description';

  @override
  String get commonYesLabel => 'Yes';

  @override
  String get commonNoLabel => 'No';

  @override
  String get customerMgmtCsvDescName => 'Customer full name';

  @override
  String get customerMgmtCsvDescEmail => 'Email address';

  @override
  String get customerMgmtCsvDescPhone => 'Phone number';

  @override
  String get customerMgmtCsvDescAddress => 'Full address';

  @override
  String get customerMgmtCsvDescBusinessName => 'Company / business name';

  @override
  String get customerMgmtCsvDescTaxNumber => 'Tax / VAT / GSTIN number';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return 'Maximum $max rows per import.';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      'Duplicates are detected by email or phone. You will be asked to overwrite or skip each one.';

  @override
  String get customerMgmtCsvMissingNameNote =>
      'Rows missing a name are skipped and reported at the end.';

  @override
  String get customerMgmtCsvEncodingNote =>
      'UTF-8 encoding recommended. Excel BOM is handled automatically.';

  @override
  String get customerMgmtDownloadSampleCsvButton => 'Download Sample CSV';

  @override
  String get customerMgmtChooseFileButton => 'Choose File';

  @override
  String get customerMgmtSelectCsvDialogTitle => 'Select Customer CSV';

  @override
  String get customerMgmtCsvEmptyMessage => 'CSV file is empty.';

  @override
  String get customerMgmtCsvMissingNameColumnMessage =>
      'CSV missing required column: \"name\"';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return 'Unknown column \"$col\". Expected: $expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'CSV has $count rows. Maximum is $max. Please split the file.';
  }

  @override
  String get customerMgmtImportingTitle => 'Importing Customers';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Checking for duplicates and validating $count rows...',
      one: 'Checking for duplicates and validating 1 row...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return 'Row $n: missing name — skipped';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return 'Error reading CSV: $error';
  }

  @override
  String get customerMgmtImportPreviewTitle => 'Import Preview';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates',
      one: '1 duplicate',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors',
      one: '1 error',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel =>
      'Duplicates (matched by email or phone):';

  @override
  String get customerMgmtOverwriteAllButton => 'Overwrite All';

  @override
  String get customerMgmtSkipAllButton => 'Skip All';

  @override
  String get customerMgmtOverwriteLabel => 'Overwrite';

  @override
  String get customerMgmtSkippedRowsLabel => 'Skipped rows (errors):';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Will import $total customers.',
      one: 'Will import 1 customer.',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return 'Import $total';
  }

  @override
  String get customerMgmtDeleteAllTitle => 'Delete All Customers';

  @override
  String get customerMgmtNoCustomersToDeleteMessage =>
      'No customers to delete.';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will permanently delete all $count customers. Existing invoices are not affected. This cannot be undone.',
      one:
          'This will permanently delete all 1 customer. Existing invoices are not affected. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => 'Delete All';

  @override
  String get customerMgmtAllDeletedMessage => 'All customers deleted.';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return 'Error deleting customers: $error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => 'Save Customer CSV';

  @override
  String get customerMgmtCsvExportedMessage => 'CSV exported successfully!';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return 'Error exporting CSV: $error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => 'Save Customer PDF';

  @override
  String get customerMgmtPdfExportedMessage => 'PDF exported successfully!';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return 'Error exporting PDF: $error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => 'Total Customers';

  @override
  String get customerMgmtAllCustomersSubtitle => 'All customers';

  @override
  String get customerMgmtBusinessesLabel => 'Businesses';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle =>
      'Registered businesses';

  @override
  String get customerMgmtIndividualsLabel => 'Individuals';

  @override
  String get customerMgmtIndividualCustomersSubtitle => 'Individual customers';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '$taxWord Registered';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return 'With $taxWord number';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return 'Without $taxWord';
  }

  @override
  String get customerMgmtTitle => 'Customer Management';

  @override
  String get customerMgmtSubtitle =>
      'Manage your customers and contact details';

  @override
  String get actionImport => 'Import';

  @override
  String get customerMgmtExportPdfMenuLabel => 'Export PDF';

  @override
  String get customerMgmtNewCustomerButton => 'New Customer';

  @override
  String get customerMgmtSortNameAZ => 'Name A-Z';

  @override
  String get customerMgmtSortNameZA => 'Name Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID (oldest first)';

  @override
  String get customerMgmtSortIdNewest => 'ID (newest first)';

  @override
  String get customerMgmtSortOutstandingHighLow => 'Outstanding (high-low)';

  @override
  String get customerMgmtSortOutstandingLowHigh => 'Outstanding (low-high)';

  @override
  String get customerMgmtWithOutstandingLabel => 'With Outstanding';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return 'Search customers by name, business, phone, $taxWord, email…';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return 'All $taxWord statuses';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '$taxWord registered';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return 'Sort: $label';
  }

  @override
  String get customerMgmtColumnsLabel => 'Columns';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / VAT No';
  }

  @override
  String get customerMgmtHideStatCardsTooltip => 'Hide stat cards';

  @override
  String get customerMgmtShowStatCardsTooltip => 'Show stat cards';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get customerMgmtColSlNo => 'SL. NO.';

  @override
  String get customerMgmtColNameBusiness => 'NAME / BUSINESS';

  @override
  String get customerMgmtColPhone => 'PHONE';

  @override
  String get customerMgmtColEmail => 'EMAIL';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / VAT NO';
  }

  @override
  String get customerMgmtColAddress => 'ADDRESS';

  @override
  String get customerMgmtColActions => 'ACTIONS';

  @override
  String get customerMgmtViewStatementTooltip => 'View Statement (in Reports)';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return 'Showing $from to $to of $total customers';
  }

  @override
  String get customerMgmtRowsPerPageLabel => 'Rows per page';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return 'of $totalPages';
  }

  @override
  String get customerMgmtAddAnotherLabel => 'Add another after saving';

  @override
  String get customerMgmtSaveCustomerButton => 'Save Customer';

  @override
  String get customerMgmtAddFirstCustomerSubtitle =>
      'Add your first customer to get started';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle =>
      'Try adjusting your search';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return 'Error loading customers: $error';
  }

  @override
  String get customerMgmtAddedMessage => 'Customer added successfully!';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return 'Error saving customer: $error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count customers successfully!',
      one: 'Imported 1 customer successfully!',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return 'Import error: $error';
  }

  @override
  String get taxWordGst => 'GST';

  @override
  String get taxWordTax => 'Tax';

  @override
  String get commonMoreLabel => 'More';

  @override
  String get productMgmtSellingAtLossTitle => 'Selling at a loss';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return 'Purchase price ($purchase) is higher than sale price ($sale). Save anyway?';
  }

  @override
  String get actionSaveAnyway => 'Save Anyway';

  @override
  String get productMgmtAdvancedInformationLabel => 'Advanced Information';

  @override
  String get productMgmtStorageLocationLabel => 'Storage Location';

  @override
  String get productMgmtContainerNumberLabel => 'Container Number';

  @override
  String get productMgmtBatchNumberLabel => 'Batch Number';

  @override
  String get productMgmtExpiryDateLabel => 'Expiry Date';

  @override
  String get productMgmtManufactureDateLabel => 'Manufacture Date';

  @override
  String get productMgmtSupplierNameLabel => 'Supplier Name';

  @override
  String get productMgmtSkuCodeLabel => 'SKU Code';

  @override
  String get productMgmtNotesLabel => 'Notes';

  @override
  String get fieldEnterValidPriceMessage => 'Enter valid price';

  @override
  String get fieldEnterValidStockMessage => 'Enter valid stock';

  @override
  String get fieldTaxRangeMessage => 'Tax must be between 0-100';

  @override
  String get productMgmtImportProductsCsvTitle => 'Import Products from CSV';

  @override
  String get productMgmtCsvDescName => 'Product name';

  @override
  String get productMgmtCsvDescPrice => 'Unit price (numeric)';

  @override
  String get productMgmtCsvDescHsnCode => 'HSN / SAC code';

  @override
  String get productMgmtCsvDescDescription => 'Short description';

  @override
  String get productMgmtCsvDescTaxRate => 'Tax % (0–100), default 0';

  @override
  String get productMgmtCsvDescStock => 'Stock quantity, default 0';

  @override
  String get productMgmtCsvDescType =>
      '\"product\" or \"service\", default product';

  @override
  String get productMgmtCsvDescDefaultDiscount =>
      'Flat discount amount (currency), default 0';

  @override
  String get productMgmtCsvDescPurchasePrice =>
      'Cost price (numeric), default 0';

  @override
  String get productMgmtCsvDescAliasName =>
      'Local-language display name for PDFs';

  @override
  String get productMgmtCsvDescUnit =>
      'Unit of measure (e.g. kg, bag, pcs), default pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock =>
      '1/true for unlimited stock, default 0';

  @override
  String get productMgmtCsvDescPriceIncludesTax =>
      '1/true if price already includes tax, default 0';

  @override
  String get productMgmtCsvDescStorageLocation => 'Warehouse/shelf location';

  @override
  String get productMgmtCsvDescContainerNumber => 'Container/box number';

  @override
  String get productMgmtCsvDescBatchNumber => 'Batch/lot number';

  @override
  String get productMgmtCsvDescExpiryDate => 'Expiry date';

  @override
  String get productMgmtCsvDescManufactureDate => 'Manufacture date';

  @override
  String get productMgmtCsvDescSupplierName => 'Supplier name';

  @override
  String get productMgmtCsvDescSkuCode => 'SKU code';

  @override
  String get productMgmtCsvDescNotes => 'Free-text notes';

  @override
  String get productMgmtCsvDuplicateNote =>
      'Duplicates are detected by product name (case-insensitive). You will be asked to overwrite or skip each one.';

  @override
  String get productMgmtCsvMissingRequiredNote =>
      'Rows missing name or price are skipped and reported.';

  @override
  String get productMgmtSelectCsvDialogTitle => 'Select Product CSV';

  @override
  String get productMgmtCsvMissingPriceColumnMessage =>
      'CSV missing required column: \"price\"';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return 'Row $n: invalid price \"$price\" — skipped';
  }

  @override
  String get productMgmtImportingTitle => 'Importing Products';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel =>
      'Duplicates (matched by name):';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Will import $total products.',
      one: 'Will import 1 product.',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage => 'No products to delete.';

  @override
  String get productMgmtDeleteAllTitle => 'Delete All Products';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will permanently delete all $count products. Existing invoices are not affected. This cannot be undone.',
      one:
          'This will permanently delete all 1 product. Existing invoices are not affected. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage => 'All products deleted.';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return 'Error deleting products: $error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle => 'Save Products CSV';

  @override
  String get productMgmtExportToPdfTitle => 'Export to PDF';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return 'Export the current page ($pageSize products) or all $allCount products?';
  }

  @override
  String get productMgmtCurrentPageLabel => 'Current Page';

  @override
  String get productMgmtAllProductsLabel => 'All Products';

  @override
  String get productMgmtSaveProductsPdfDialogTitle => 'Save Products PDF';

  @override
  String get productMgmtTitle => 'Product Management';

  @override
  String get productMgmtSubtitle => 'Manage your products and services';

  @override
  String get productMgmtNewProductButton => 'New Product';

  @override
  String get productMgmtSearchHint =>
      'Search products by name, alias, HSN/SAC, SKU…';

  @override
  String get productMgmtFilterByStockStatusTooltip => 'Filter by stock status';

  @override
  String get productMgmtAllStockLevelsLabel => 'All stock levels';

  @override
  String get productMgmtLowStockLabel => 'Low stock';

  @override
  String get productMgmtLowStockTabLabel => 'Low Stock';

  @override
  String get productMgmtOutOfStockLabel => 'Out of stock';

  @override
  String get productMgmtOutOfStockTabLabel => 'Out of Stock';

  @override
  String get productMgmtExpiredLabel => 'Expired';

  @override
  String get productMgmtSortPriceLowHigh => 'Price Low-High';

  @override
  String get productMgmtSortPriceHighLow => 'Price High-Low';

  @override
  String get productMgmtSortStockLowHigh => 'Stock Low-High';

  @override
  String get productMgmtSortStockHighLow => 'Stock High-Low';

  @override
  String get productMgmtServicesTabLabel => 'Services';

  @override
  String get productMgmtColSlNo => 'SL. NO.';

  @override
  String get productMgmtColNameAlias => 'NAME / ALIAS';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => 'PRICE';

  @override
  String get productMgmtColPurchase => 'PURCHASE';

  @override
  String get productMgmtColStock => 'STOCK';

  @override
  String get productMgmtColTaxPercent => 'TAX %';

  @override
  String get productMgmtColExpiryDate => 'EXPIRY DATE';

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
    return 'Showing $from to $to of $total products';
  }

  @override
  String get productMgmtAddFirstProductSubtitle =>
      'Add your first product to get started';

  @override
  String get productMgmtColumnsBannerTitle => 'New: Customize product fields';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      'Choose which fields show for a simpler catalog. Settings > Customize Product Details.';

  @override
  String get productMgmtConfigureAction => 'Configure';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return 'Add New $type';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle => 'Enter product details';

  @override
  String get productMgmtSaveProductButton => 'Save Product';

  @override
  String get productMgmtAliasNameLabel => 'Alias Name (for invoice PDF)';

  @override
  String get productMgmtAliasHelperText =>
      'Optional local-language display name used only on PDF invoices.';

  @override
  String get productMgmtDescriptionLabel => 'Description';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => 'Sale Price';

  @override
  String get productMgmtPurchasePriceLabel => 'Purchase Price';

  @override
  String get productMgmtDefaultDiscountLabel => 'Default Discount';

  @override
  String get productMgmtTaxPercentLabel => 'Tax (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel => 'Per-item tax mode only';

  @override
  String get productMgmtSectionGeneral => 'General';

  @override
  String get productMgmtSectionPricing => 'Pricing';

  @override
  String get productMgmtSectionInventory => 'Inventory';

  @override
  String get productMgmtUnlimitedStockLabel => 'Unlimited stock';

  @override
  String get productMgmtTrackInfiniteStockSubtitle =>
      'Track infinite stock for this product';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      'Tip: Enable custom fields from Columns to add more details.';

  @override
  String get productMgmtEditProductTitle => 'Edit Product';

  @override
  String get productMgmtViewProductTitle => 'View Product';

  @override
  String get productMgmtUpdateProductDetailsSubtitle =>
      'Update product details';

  @override
  String get productMgmtProductDetailsSubtitle => 'Product details';

  @override
  String get productMgmtUpdatedMessage =>
      'Product/Service updated successfully!';

  @override
  String get productMgmtDeleteProductButton => 'Delete Product';

  @override
  String get productMgmtSaveChangesButton => 'Save Changes';

  @override
  String get fieldUnitLabel => 'Unit';

  @override
  String get productMgmtAddedMessage => 'Product added successfully!';

  @override
  String productMgmtAddErrorMessage(String error) {
    return 'Error adding product: $error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return 'Error loading products: $error';
  }

  @override
  String get productMgmtDeletedMessage => 'Product deleted successfully!';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count products successfully!',
      one: 'Imported 1 product successfully!',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => 'Total items';

  @override
  String get productMgmtTangibleProductsSubtitle => 'Tangible products';

  @override
  String get productMgmtNonTangibleServicesSubtitle => 'Non-tangible services';

  @override
  String get productMgmtNeedAttentionSubtitle => 'Need attention';

  @override
  String get productMgmtProductNameLabel => 'Product Name';

  @override
  String get productMgmtPriceLabel => 'Price';

  @override
  String get actionClear => 'Clear';

  @override
  String get reportsAboutConversionRateTitle => 'About Conversion Rate';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return 'Aged Receivables ($count)';
  }

  @override
  String get reportsAllCurrenciesLabel => 'All currencies';

  @override
  String get reportsAvgInvoiceValueLabel => 'Avg Invoice Value';

  @override
  String get reportsBalanceColumnLabel => 'Balance';

  @override
  String get reportsBilledLabel => 'Billed';

  @override
  String get reportsBucket0to30Label => '0–30 days';

  @override
  String get reportsBucket31to60Label => '31–60 days';

  @override
  String get reportsBucket61to90Label => '61–90 days';

  @override
  String get reportsBucket90PlusLabel => '90+ days';

  @override
  String get reportsBucketLabel => 'Bucket';

  @override
  String get reportsClosingLabel => 'Closing';

  @override
  String get reportsCogsColumnLabel => 'COGS';

  @override
  String get reportsConversionRateExplanationBody =>
      'Conversion rate = Invoices created ÷ Quotations issued × 100.\nA rate above 100% means more invoices were raised than quotations in the selected period (common when invoices are created directly without a prior quotation).\n\nNote: this is a period-level ratio, not individual quote-to-invoice tracking.';

  @override
  String get reportsConversionRateLabel => 'Conversion Rate';

  @override
  String get reportsCreditColumnLabel => 'Credit';

  @override
  String get reportsCurrencySectionLabel => 'CURRENCY';

  @override
  String get reportsCurrentBucketLabel => 'Current';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return 'Current selected currency ($currency)';
  }

  @override
  String get reportsCustomRangeLabel => 'Custom Range';

  @override
  String get reportsDailySalesProfitTitle => 'Daily Sales & Profit';

  @override
  String reportsDaysCountLabel(int d) {
    return '$d days';
  }

  @override
  String get reportsDaysOverdueLabel => 'Days Overdue';

  @override
  String get reportsDebitColumnLabel => 'Debit';

  @override
  String get reportsDiscountGivenColumnLabel => 'Discount Given';

  @override
  String get reportsExportCsvLabel => 'Export CSV';

  @override
  String reportsFilteredToDateLabel(String date) {
    return 'Filtered to $date';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString invoices in period · $scope',
      one: '1 invoice in period · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => 'Invoice ID';

  @override
  String get reportsInvoicedLabel => 'Invoiced';

  @override
  String get reportsInvoicesColumnLabel => 'Invoices';

  @override
  String get reportsInvoicesInPeriodLabel => 'Invoices in Period';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get reportsMarginColumnLabel => 'Margin';

  @override
  String get reportsMaxRangeOneYearMessage =>
      'Maximum range is 1 year. End date clamped.';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage =>
      'Maximum range is 31 days. End date clamped.';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items sold in this period have no purchase price set — profit/margin is understated for those items until a purchase price is added to the product.',
      one:
          '1 item sold in this period has no purchase price set — profit/margin is understated for that item until a purchase price is added to the product.',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => 'Month & Year';

  @override
  String get reportsMonthlyRevenueTrendTitle => 'Monthly Revenue Trend';

  @override
  String get reportsNavDailyReportLabel => 'Daily Report';

  @override
  String get reportsNavInvoiceStatusLabel => 'Invoice Status';

  @override
  String get reportsNavReceivablesLabel => 'Receivables';

  @override
  String get reportsNavRevenueLabel => 'Revenue';

  @override
  String get reportsNavTaxLabel => 'Tax';

  @override
  String get reportsNoCustomerDataMessage => 'No customer data in this period';

  @override
  String get reportsNoCustomersMatchSearchMessage =>
      'No customers match this search';

  @override
  String get reportsNoCustomersWithInvoicesMessage =>
      'No customers with invoices';

  @override
  String get reportsNoDueDateLabel => 'No Due Date';

  @override
  String get reportsNoInvoiceDataMessage => 'No invoice data in this period';

  @override
  String get reportsNoInvoicesInPeriodMessage => 'No invoices in this period';

  @override
  String get reportsNoInvoicesMatchFilterMessage =>
      'No invoices match this filter';

  @override
  String get reportsNoOutstandingInvoicesMessage => 'No outstanding invoices';

  @override
  String get reportsNoProductDataMessage => 'No product data in this period';

  @override
  String get reportsNoSalesInPeriodMessage => 'No sales in this period';

  @override
  String get reportsNoStatementActivityMessage =>
      'No statement activity for this customer';

  @override
  String get reportsNoTaxableItemsMessage => 'No taxable items in this period';

  @override
  String get reportsNoTransactionsMessage => 'No transactions in this period';

  @override
  String get reportsOpeningLabel => 'Opening';

  @override
  String get reportsOverviewLabel => 'Overview';

  @override
  String get reportsPaymentStatusBreakdownTitle => 'Payment Status Breakdown';

  @override
  String get reportsPeriodSectionLabel => 'PERIOD';

  @override
  String get reportsPresetLast30DaysLabel => 'Last 30 days';

  @override
  String get reportsPresetLast3MonthsLabel => 'Last 3 months';

  @override
  String get reportsPresetLast6MonthsLabel => 'Last 6 months';

  @override
  String get reportsPresetLastFYLabel => 'Last FY';

  @override
  String get reportsPresetThisFYLabel => 'This FY';

  @override
  String get reportsPresetThisYearLabel => 'This year';

  @override
  String get reportsProductServiceColumnLabel => 'Product / Service';

  @override
  String get reportsProfitLabel => 'Profit';

  @override
  String get reportsQuotationsIssuedLabel => 'Quotations Issued';

  @override
  String get reportsRankByProfitLabel => 'Rank: Profit';

  @override
  String get reportsRankByRevenueLabel => 'Rank: Revenue';

  @override
  String get reportsReferenceColumnLabel => 'Reference';

  @override
  String get reportsSalesColumnLabel => 'Sales';

  @override
  String get reportsSaveCsvReportTitle => 'Save CSV Report';

  @override
  String get reportsSavePdfReportTitle => 'Save PDF Report';

  @override
  String reportsSavedAtMessage(String path) {
    return 'Saved: $path';
  }

  @override
  String get reportsSelectCustomerTitle => 'Select customer';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText =>
      'Select date or date range (max 31 days)';

  @override
  String get reportsSelectDateRangeMaxYearHelpText =>
      'Select date range (max 1 year)';

  @override
  String get reportsShareLabel => 'Share';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return 'Showing invoices dated $range';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end of $total';
  }

  @override
  String get reportsSlColumnLabel => 'SL';

  @override
  String get reportsStatementsLabel => 'Statements';

  @override
  String get reportsTaxCollectedByRateTitle => 'Tax Collected by Rate';

  @override
  String get reportsTaxCollectedLabel => 'Tax Collected';

  @override
  String get reportsTaxRateBucketsLabel => 'Tax Rate Buckets';

  @override
  String get reportsTodayLabel => 'Today';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return 'Top $count Customers by Revenue';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return 'Top $count Products / Services by $metric';
  }

  @override
  String get reportsTotalBilledLabel => 'Total Billed';

  @override
  String get reportsTotalCollectedLabel => 'Total Collected';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString total invoices',
      one: '1 total invoice',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => 'Total Invoices';

  @override
  String get reportsTotalProfitLabel => 'Total Profit';

  @override
  String get reportsTotalTaxCollectedLabel => 'Total Tax Collected';

  @override
  String get reportsTypeColumnLabel => 'Type';

  @override
  String get reportsUnitsSoldColumnLabel => 'Units Sold';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return 'Error loading users: $error';
  }

  @override
  String get userMgmtAddedMessage => 'User added successfully';

  @override
  String get userMgmtUpdatedMessage => 'User updated successfully';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return 'Error saving user: $error';
  }

  @override
  String get userMgmtChangePasswordTitle => 'Change Password';

  @override
  String userMgmtUserColonLabel(String username) {
    return 'User: $username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => 'Current Password';

  @override
  String get userMgmtCurrentPasswordRequiredMessage =>
      'Current password is required';

  @override
  String get userMgmtNewPasswordLabel => 'New Password';

  @override
  String get userMgmtNewPasswordRequiredMessage => 'New password is required';

  @override
  String get userMgmtPasswordMinLengthMessage =>
      'Password must be at least 6 characters';

  @override
  String get userMgmtConfirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get userMgmtConfirmPasswordRequiredMessage =>
      'Please confirm your password';

  @override
  String get userMgmtPasswordsDoNotMatchMessage => 'Passwords do not match';

  @override
  String get userMgmtPasswordChangedMessage => 'Password changed successfully';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage =>
      'Current password is incorrect';

  @override
  String get userMgmtDeleteUserTitle => 'Delete User';

  @override
  String get userMgmtDeleteUserConfirmLabel =>
      'Are you sure you want to delete user:';

  @override
  String get userMgmtActionCannotBeUndoneMessage =>
      'This action cannot be undone.';

  @override
  String get userMgmtDeletedMessage => 'User deleted successfully';

  @override
  String get userMgmtCantDeleteOwnAccountMessage =>
      'You can\'t delete your own account';

  @override
  String get userMgmtCantDemoteLastAdminMessage =>
      'You can\'t change the role of the only admin';

  @override
  String get userMgmtCantChangeOwnRoleMessage =>
      'You can\'t change your own role';

  @override
  String get userMgmtUsernameTakenMessage => 'That username is already taken';

  @override
  String get userMgmtDeleteSelectedTitle => 'Delete selected users?';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will permanently delete $count users. This action cannot be undone.',
      one: 'This will permanently delete 1 user. This action cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage =>
      'Your own account was in the selection but will be skipped.';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users deleted',
      one: '1 user deleted',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return 'Error deleting users: $error';
  }

  @override
  String get userMgmtTitle => 'User Management';

  @override
  String get userMgmtSubtitle =>
      'Manage application users and access permissions';

  @override
  String get userMgmtAddUserButton => 'Add User';

  @override
  String get userMgmtSearchHint => 'Search users by name or role…';

  @override
  String get userMgmtFilterByRoleTooltip => 'Filter by role';

  @override
  String get userMgmtAllRolesLabel => 'All roles';

  @override
  String get userMgmtAllLabel => 'All';

  @override
  String userMgmtRoleColonLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get userMgmtColUser => 'USER';

  @override
  String get userMgmtColRole => 'ROLE';

  @override
  String get userMgmtYouBadgeLabel => 'You';

  @override
  String get userMgmtDeleteSelectedMenuLabel => 'Delete selected';

  @override
  String get userMgmtBulkActionsTooltip => 'Bulk actions';

  @override
  String get userMgmtBulkActionsLabel => 'Bulk Actions';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return 'Showing $from to $to of $total users';
  }

  @override
  String get userMgmtNoUsersFoundMessage => 'No users found';

  @override
  String get userMgmtAddNewUserTitle => 'Add New User';

  @override
  String get userMgmtEditUserTitle => 'Edit User';

  @override
  String get userMgmtUsernameRequiredLabel => 'Username *';

  @override
  String get userMgmtEnterUsernameHint => 'Enter username';

  @override
  String get userMgmtUsernameRequiredMessage => 'Username is required';

  @override
  String get userMgmtUsernameMinLengthMessage =>
      'Username must be at least 3 characters';

  @override
  String get userMgmtPasswordRequiredLabel => 'Password *';

  @override
  String get userMgmtEnterPasswordHint => 'Enter password';

  @override
  String get userMgmtPasswordRequiredMessage => 'Password is required';

  @override
  String get userMgmtMinimum6CharsMessage => 'Minimum 6 characters';

  @override
  String get userMgmtRoleRequiredLabel => 'Role *';

  @override
  String get userMgmtRoleRequiredMessage => 'Role is required';

  @override
  String get userMgmtSaveUserButton => 'Save User';

  @override
  String get userMgmtThisIsYourAccountMessage => 'This is your account';

  @override
  String get invoiceSettingsAppBarTitle => 'Invoice Settings';

  @override
  String get invoiceSettingsSavedMessage =>
      'Invoice settings saved successfully!';

  @override
  String get invoiceSettingsSignatureTooLargeMessage =>
      'Signature image must be less than 2 MB.';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage =>
      'Watermark image must be less than 2 MB.';

  @override
  String get invoiceSettingsSectionGeneral => 'General';

  @override
  String get invoiceSettingsSectionBranding => 'Branding';

  @override
  String get invoiceSettingsSectionTax => 'Tax & GST';

  @override
  String get invoiceSettingsSectionItems => 'Invoice Items';

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
  String get invoiceSettingsPrefixLabel => 'Invoice Prefix';

  @override
  String get invoiceSettingsStartingNumberHelper =>
      'First invoice will start from this number';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      'Invoice starting number cannot be changed while invoices exist. Please permanently delete all invoices/quotations (including trash) and try again.';

  @override
  String get invoiceSettingsQuantityColumnLabel => 'Quantity Column Label';

  @override
  String get invoiceSettingsQuantityColumnHint => 'e.g. Words, Hours, Units';

  @override
  String get invoiceSettingsQuantityColumnHelper =>
      'Leave blank to use default \"Qty\"';

  @override
  String get invoiceSettingsAdditionalInfoLabel => 'Additional Information';

  @override
  String get invoiceSettingsThankYouNoteLabel => 'Thank You Note';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel =>
      'Hide Invoice Number by Default';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      'Enable \"Hide invoice number in PDF\" by default when creating new invoices.';

  @override
  String get invoiceSettingsTaxRateHint => 'e.g. 18';

  @override
  String get invoiceSettingsTaxRateHelper => 'Applied to new invoices';

  @override
  String get invoiceSettingsTaxEnabledLabel => 'Tax Enabled by Default';

  @override
  String get invoiceSettingsTaxEnabledSubtitle =>
      'Enable the Tax toggle by default when creating new invoices.';

  @override
  String get invoiceSettingsTaxModeLabel => 'Default Tax Rate Mode';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly =>
      'Applies to new invoices only';

  @override
  String get invoiceSettingsTaxModeGlobal => 'Global';

  @override
  String get invoiceSettingsTaxModePerItem => 'Per Item';

  @override
  String get invoiceSettingsShowGstFieldsLabel => 'Show GST Fields';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      'Display GSTIN fields (HSN/SAC) on invoices, PDFs, and CSV exports';

  @override
  String get invoiceSettingsShowCgstSgstLabel => 'Show CGST/SGST/IGST';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      'Split tax into CGST + SGST, or IGST for interstate invoices (India only).';

  @override
  String get invoiceSettingsDefaultGstTitleLabel => 'Default GST Invoice Title';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel => 'Default TAX Invoice Title';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      'Preselected on new invoices — e.g. \"Bill of Supply\" for GST Composition Scheme dealers';

  @override
  String get invoiceSettingsGstTitleHelperGeneric =>
      'Preselected on new invoices';

  @override
  String get invoiceSettingsShowRoundOffLabel => 'Show Round Off';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      'Show a Round Off row + Net Amount (rounded to nearest) and amount in words on invoice PDFs.';

  @override
  String get invoiceSettingsShowAliasNameLabel => 'Show Alias Name in PDF';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      'Print a product\'s local-language alias (if set) instead of its actual name on PDFs';

  @override
  String get invoiceSettingsShowDescriptionLabel => 'Show Product Description';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      'Print each item\'s description as a row under it on A4 PDFs (not on thermal receipts)';

  @override
  String get invoiceSettingsDescriptionNewLineLabel =>
      'Description on a New Line';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      'Print the description as a full-width row below the item instead of a line under its name';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel =>
      'Allow Fractional Quantities';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      'Enable decimal quantities (e.g. 1.5 hrs, 0.5 kg)';

  @override
  String get invoiceSettingsShowQuantityLabel => 'Show Quantity Field';

  @override
  String get invoiceSettingsShowQuantitySubtitle =>
      'Hide quantity for service-based billing; price column becomes \"Rate\"';

  @override
  String get invoiceSettingsShowDiscountLabel => 'Show Discount Column';

  @override
  String get invoiceSettingsShowDiscountSubtitle =>
      'Hide discount column for clients who don\'t use item-level discounts';

  @override
  String get invoiceSettingsShowTypeTagLabel => 'Show Product/Service Tag';

  @override
  String get invoiceSettingsShowTypeTagSubtitle =>
      'Show or hide the Product/Service label on each invoice item';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel =>
      'Allow Duplicate Invoice Items';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle =>
      'Allow adding the same product more than once to an invoice';

  @override
  String get invoiceSettingsShowPrevBalanceLabel => 'Show Previous Balance Due';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle =>
      'Show calculated prior outstanding balance on invoice PDFs';

  @override
  String get invoiceSettingsLogoPositionLabel => 'Company Logo Position';

  @override
  String get invoiceSettingsLogoSizeLabel => 'Company Logo Size';

  @override
  String get commonLeftLabel => 'Left';

  @override
  String get commonRightLabel => 'Right';

  @override
  String get invoiceSettingsSignatureImageLabel => 'Signature Image';

  @override
  String get invoiceSettingsSignatureImageSubtitle =>
      'Printed on invoices as Authorised Signature';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG, JPG or JPEG — max 2 MB';

  @override
  String get invoiceSettingsChangeSignatureButton => 'Change Signature';

  @override
  String get invoiceSettingsUploadSignatureButton => 'Upload Signature';

  @override
  String get invoiceSettingsSignatureSizeLabel => 'Signature Size';

  @override
  String get invoiceSettingsSignaturePositionLabel => 'Signature Position';

  @override
  String get invoiceSettingsWatermarkImageLabel => 'Watermark Image';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      'Shown behind the items table on invoice PDFs (not printed on thermal receipts)';

  @override
  String get invoiceSettingsChangeWatermarkButton => 'Change Watermark';

  @override
  String get invoiceSettingsUploadWatermarkButton => 'Upload Watermark';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return 'Opacity: $value%';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value%';
  }

  @override
  String get invoiceSettingsPromoTitle => 'Need more fields on your invoices?';

  @override
  String get invoiceSettingsPromoBody =>
      'Add PO number, project code, department, or any custom field.';

  @override
  String get invoiceSettingsPromoButton => 'See Options';

  @override
  String get pdfSettingsTitle => 'PDF Settings';

  @override
  String get pdfSettingsSubtitle =>
      'Customize invoice, quotation and receipt PDF templates';

  @override
  String get pdfSettingsResetToDefaultButton => 'Reset to Default';

  @override
  String get pdfSettingsSaveSettingsButton => 'Save Settings';

  @override
  String get pdfSettingsTemplatesLabel => 'Templates';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return 'No templates for $pageSize';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'PDF settings saved';

  @override
  String get commonActiveLabel => 'Active';

  @override
  String get commonUnavailableLabel => 'Unavailable';

  @override
  String get pdfSettingsDisplayOptionsLabel => 'Display Options';

  @override
  String get pdfSettingsShowTotalQtyRowLabel => 'Show total quantity row';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => 'Item layout';

  @override
  String get pdfSettingsItemLayoutTableLabel => 'Table';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => 'Detailed';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      'Table: one line per item (Sl/Name/Qty/Rate/Total). Detailed: name on its own line, then Qty/Rate/Total below it.';

  @override
  String get pdfSettingsCompanyNameSizeLabel => 'Company name size';

  @override
  String get pdfSettingsThemeColorLabel => 'Theme Color';

  @override
  String get pdfSettingsHexErrorText => 'Use #RRGGBB';

  @override
  String get pdfSettingsPickColorTooltip => 'Open color picker';

  @override
  String get pdfSettingsPickThemeColorDialogTitle => 'Pick theme color';

  @override
  String get pdfSettingsPreviewDisclaimer =>
      'Preview may slightly differ in the final PDF.';

  @override
  String get pdfSettingsCustomTemplatePromoTitle => 'Want a custom template?';

  @override
  String get pdfSettingsCustomTemplatePromoBody =>
      'Get a design that matches your brand — colors, fonts, and layout.';

  @override
  String get pdfSettingsCustomizationOptionsButton => 'Customization Options';

  @override
  String get pdfTemplateClassicName => 'Classic';

  @override
  String get pdfTemplateClassicDescription =>
      'Traditional layout with clean structure';

  @override
  String get pdfTemplateModernName => 'Modern';

  @override
  String get pdfTemplateModernDescription =>
      'Bold header with contemporary styling';

  @override
  String get pdfTemplateMinimalName => 'Minimal';

  @override
  String get pdfTemplateMinimalDescription => 'Simple and distraction-free';

  @override
  String get pdfTemplateExecutiveName => 'Executive';

  @override
  String get pdfTemplateExecutiveDescription =>
      'Premium business layout with structured billing blocks';

  @override
  String get pdfTemplateCompactName => 'Compact';

  @override
  String get pdfTemplateCompactDescription =>
      'Space-efficient receipt layout, ideal for A6 printing';

  @override
  String get pdfTemplateThermalName => 'Thermal';

  @override
  String get pdfTemplateThermalDescription =>
      'Narrow receipt layout for 80mm and 58mm thermal printers';

  @override
  String get pdfTemplateGridClassicName => 'Grid Classic';

  @override
  String get pdfTemplateGridClassicDescription =>
      'Old-style bordered tabular bill, for A4, A5 and A6';

  @override
  String get companyInfoAppBarTitle => 'Company Information';

  @override
  String get companyInfoUploadLogoLabel => 'Upload Logo';

  @override
  String get companyInfoClickToBrowseLabel => 'Click to browse';

  @override
  String get companyInfoRemoveLogoButton => 'Remove Logo';

  @override
  String get companyInfoShowOnPdfLabel => 'Show on PDF';

  @override
  String get companyInfoLogoRequirementsHint =>
      'Max 1080×1080 px · 2 MB\nPNG or JPG only';

  @override
  String get companyInfoLogoSectionLabel => 'COMPANY LOGO';

  @override
  String get companyInfoDetailsSectionLabel => 'COMPANY DETAILS';

  @override
  String get companyInfoBusinessTypeSectionLabel => 'BUSINESS TYPE';

  @override
  String get companyInfoPaymentSettingsSectionLabel => 'PAYMENT SETTINGS';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'UPI ACCOUNTS';

  @override
  String get companyInfoBankAccountsSectionLabel => 'BANK ACCOUNTS';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => 'Tax/VAT No';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'FSSAI Code';

  @override
  String get companyInfoPhoneHelperText =>
      'Multiple numbers: separate with comma';

  @override
  String get fieldWebsiteLabel => 'Website';

  @override
  String get companyInfoBusinessTypeTitle => 'Business Type';

  @override
  String get companyInfoBusinessTypeSubtitle =>
      'Controls item type options in the product list and invoices';

  @override
  String get labelBoth => 'Both';

  @override
  String get companyInfoSetAsDefaultTooltip => 'Set as Default';

  @override
  String get companyInfoUpiIdLabel => 'UPI ID';

  @override
  String get companyInfoAddUpiAccountButton => 'Add UPI Account';

  @override
  String get companyInfoShowQrToggleTitle => 'Show QR Code on Invoices';

  @override
  String get companyInfoShowQrToggleSubtitle =>
      'Adds scannable UPI payment QR codes to generated PDFs';

  @override
  String get companyInfoShowBankDetailsToggleTitle =>
      'Show Bank Details on Invoices';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle =>
      'Prints bank account details on generated PDFs';

  @override
  String get fieldBankNameLabel => 'Bank Name';

  @override
  String get fieldAccountNumberLabel => 'Account Number';

  @override
  String get fieldIfscCodeLabel => 'IFSC Code';

  @override
  String get companyInfoAddBankAccountButton => 'Add Bank Account';

  @override
  String get tooltipShowOnInvoicePdf => 'Show on invoice PDF';

  @override
  String get companyInfoSavedSuccessMessage =>
      'Company info saved successfully';

  @override
  String get companyInfoImageTooLargeMessage =>
      'Image file must be less than 2 MB.';

  @override
  String get companyInfoInvalidImageMessage => 'Invalid image file.';

  @override
  String get companyInfoImageDimensionsMessage =>
      'Image must be max 1080x1080 pixels.';

  @override
  String get companyInfoHintExampleBankName => 'e.g. HDFC Bank';

  @override
  String get companyInfoHintExampleAccountLabel => 'e.g. Main Account';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionShare => 'Share';

  @override
  String get appInfoTitle => 'Software Information';

  @override
  String get appInfoAppDetailsTitle => 'APP DETAILS';

  @override
  String get appInfoAppNameLabel => 'App Name';

  @override
  String get appInfoVersionLabel => 'Version';

  @override
  String get appInfoLicenseLabel => 'License';

  @override
  String get appInfoDeveloperTitle => 'DEVELOPER';

  @override
  String get appInfoDeveloperLabel => 'Developer';

  @override
  String get appInfoSupportEmailLabel => 'Support Email';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  Released under the $license License';
  }

  @override
  String get appInfoCheckingLabel => 'Checking...';

  @override
  String get appInfoUpdateAvailableLabel => 'Update Available';

  @override
  String get appInfoUpToDateLabel => 'Up to date';

  @override
  String get appInfoCheckFailedLabel => 'Check failed';

  @override
  String get appInfoUpdatesTitle => 'UPDATES';

  @override
  String get appInfoCurrentVersionLabel => 'Current Version';

  @override
  String get appInfoLatestVersionLabel => 'Latest Version';

  @override
  String get appInfoCheckNowButton => 'Check Now';

  @override
  String get backupManagementTitle => 'Backup Management';

  @override
  String get backupCreateDbButton => 'Create DB Backup';

  @override
  String get backupExportJsonButton => 'Export JSON';

  @override
  String get backupImportButton => 'Import Backup';

  @override
  String get backupNoBackupsFoundMessage => 'No backups found';

  @override
  String backupSizeLabel(String size) {
    return 'Size: $size';
  }

  @override
  String backupCreatedLabel(String date) {
    return 'Created: $date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return 'Failed to load backups: $error';
  }

  @override
  String get backupCreatedSuccessMessage => 'Backup created successfully!';

  @override
  String backupCreateErrorMessage(String error) {
    return 'Failed to create backup: $error';
  }

  @override
  String get backupRestoreConfirmTitle => 'Restore Backup';

  @override
  String get backupRestoreConfirmBody =>
      'This will replace all current data with the backup. Are you sure?';

  @override
  String backupRestoreErrorMessage(String error) {
    return 'Failed to restore backup: $error';
  }

  @override
  String get backupDeleteConfirmTitle => 'Delete Backup';

  @override
  String get backupDeleteConfirmBody =>
      'Are you sure you want to delete this backup?';

  @override
  String get backupDeletedSuccessMessage => 'Backup deleted successfully!';

  @override
  String get backupDeleteFailedMessage => 'Failed to delete backup';

  @override
  String backupDeleteErrorMessage(String error) {
    return 'Failed to delete backup: $error';
  }

  @override
  String get backupSavedToDownloadsMessage =>
      'Backup saved to Downloads folder.';

  @override
  String backupDownloadErrorMessage(String error) {
    return 'Failed to download backup: $error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return 'Failed to share backup: $error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return 'Failed to import backup: $error';
  }

  @override
  String get backupRestoreSuccessTitle => 'Restore Successful';

  @override
  String get backupRestoreSuccessBody =>
      'The database has been restored successfully.\n\nThe app needs to restart to apply the changes. Please close and reopen the application.';

  @override
  String get backupCloseLaterButton => 'Close Later';

  @override
  String get backupCloseAppNowButton => 'Close App Now';

  @override
  String get commonSuccessTitle => 'Success';

  @override
  String get commonErrorTitle => 'Error';

  @override
  String get productColumnsScreenTitle => 'Customize Product Details';

  @override
  String get productColumnsSavedMessage => 'Product columns saved.';

  @override
  String get productColumnsIntroText =>
      'Choose which fields appear on the product add/edit forms, the product list, and invoice line items. Name and Price are always required.';

  @override
  String get productColumnsNameLabel => 'Name';

  @override
  String get productColumnsPriceLabel => 'Price';

  @override
  String get productColumnsAlwaysRequiredSubtitle => 'Always shown — required.';

  @override
  String get productColumnsStockLabel => 'Stock';

  @override
  String get productColumnsStockSubtitle =>
      'Turn off if you never track stock — products default to unlimited stock instead.';

  @override
  String get productColumnsProductFieldsSectionTitle => 'Product fields';

  @override
  String get productColumnsAliasNameLabel => 'Alias Name';

  @override
  String get productColumnsAliasNameSubtitle =>
      'Local-language display name for PDFs/printing.';

  @override
  String get productColumnsTaxRateLabel => 'Tax Rate';

  @override
  String get productColumnsTaxRateSubtitle => 'Per-product tax percentage.';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'HSN or SAC code field.';

  @override
  String get productColumnsDescriptionLabel => 'Description';

  @override
  String get productColumnsDescriptionSubtitle =>
      'Free-text product description.';

  @override
  String get productColumnsPurchasePriceLabel => 'Purchase Price';

  @override
  String get productColumnsPurchasePriceSubtitle =>
      'Cost price, for margin tracking.';

  @override
  String get productColumnsDefaultDiscountLabel => 'Default Discount';

  @override
  String get productColumnsDefaultDiscountSubtitle =>
      'Pre-filled discount when adding this product to an invoice.';

  @override
  String get productColumnsUnitLabel => 'Unit';

  @override
  String get productColumnsUnitSubtitle => 'Unit of measure (pcs, kg, hrs...).';

  @override
  String get productColumnsProductServiceTypeLabel => 'Product/Service Type';

  @override
  String get productColumnsProductServiceTypeSubtitle =>
      'Segmented Product vs Service selector.';

  @override
  String get productColumnsMetadataLabel => 'Product Metadata';

  @override
  String get productColumnsMetadataSubtitle =>
      'Storage location, container/batch number, expiry, manufacture date, supplier, SKU, notes.';

  @override
  String get productColumnsMetaStorageLocationLabel => 'Storage Location';

  @override
  String get productColumnsMetaContainerNumberLabel => 'Container Number';

  @override
  String get productColumnsMetaBatchNumberLabel => 'Batch Number';

  @override
  String get productColumnsMetaExpiryDateLabel => 'Expiry Date';

  @override
  String get productColumnsMetaManufactureDateLabel => 'Manufacture Date';

  @override
  String get productColumnsMetaSupplierNameLabel => 'Supplier Name';

  @override
  String get productColumnsMetaSkuCodeLabel => 'SKU Code';

  @override
  String get productColumnsMetaNotesLabel => 'Notes';

  @override
  String get productColumnsExtraCostLabel => 'Extra Cost';

  @override
  String get productColumnsExtraCostSubtitle =>
      'Optional flat extra charge on an invoice line item.';

  @override
  String get settingsOptionsComingSoonMessage => 'Options coming soon...';

  @override
  String get settingsNavCompanyInfoLabel => 'Company Info';

  @override
  String get settingsNavTeamLabel => 'Team';

  @override
  String get settingsNavBackupLabel => 'Backup';

  @override
  String get settingsNavUsersLabel => 'Users';

  @override
  String get settingsNavProductDetailsLabel => 'Product Details';

  @override
  String get settingsNavCustomizeLabel => 'Customize';

  @override
  String get settingsNavAccessibilityLabel => 'Accessibility';

  @override
  String get settingsNavSoftwareInfoLabel => 'Software Info';

  @override
  String get customizationEyebrowLabel => 'CUSTOMIZATION';

  @override
  String get customizationHeadline => 'Tailored just for your business';

  @override
  String get customizationSubtitle =>
      'Pick what you need and send a request. We\'ll get back to you within 24 hours.';

  @override
  String get customizationRecommendedBadge => 'Recommended';

  @override
  String customizationDeliveryLabel(String delivery) {
    return 'Delivery: $delivery';
  }

  @override
  String get customizationRequestButton => 'Request';

  @override
  String get customizationFormOpenErrorMessage =>
      'Could not open the form. Please visit forms.gle/LyX6Z2kBNR2BpwVu7 in your browser.';

  @override
  String get customizationDisclaimerMessage =>
      'Prices are indicative. Final quote may vary based on complexity. Payment is collected after scope agreement.';

  @override
  String get customizationPdfTemplateTitle => 'Custom PDF Template';

  @override
  String get customizationPdfTemplateDescription =>
      'Get an invoice template designed to match your brand — your colors, fonts, logo placement, and layout.';

  @override
  String get customizationPdfTemplateDelivery => '2–5 days';

  @override
  String get customizationCustomFieldsTitle => 'Custom Fields';

  @override
  String get customizationCustomFieldsDescription =>
      'Need extra fields on your invoices? (PO number, project code, department, etc.) We\'ll add them for you.';

  @override
  String get customizationCustomFieldsDelivery => '1–3 days';

  @override
  String get customizationWhiteLabelTitle => 'White-label / Remove Branding';

  @override
  String get customizationWhiteLabelDescription =>
      'Remove all Invoiso branding from the app and PDF outputs, and replace it with your own company identity.';

  @override
  String get customizationWhiteLabelDelivery => '3–6 days';

  @override
  String get customizationIndustryBuildTitle => 'Industry-specific Build';

  @override
  String get customizationIndustryBuildDescription =>
      'Need a version tailored to your industry? (construction, consulting, retail, etc.) We\'ll customise the workflow to fit your needs.';

  @override
  String get customizationIndustryBuildDelivery => '5–10 days';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle =>
      'New Create Invoice Page Layout';

  @override
  String get accessibilityClassicLayoutLabel => 'Classic layout';

  @override
  String get accessibilityNewLayoutLabel => 'New layout';

  @override
  String get accessibilityLayoutDescription =>
      'Choose which \"New Invoice\" screen design to use.';

  @override
  String get accessibilityShortcutsSubtitle =>
      'Speed up invoice creation without touching the mouse.';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => 'Invoice Total';

  @override
  String get paymentDialogAmountPaidLabel => 'Amount Paid';

  @override
  String get paymentDialogHistoryTitle => 'Payment History';

  @override
  String get paymentDialogNoPaymentsMessage => 'No payments recorded yet';

  @override
  String get paymentDialogFullyPaidExclaimMessage => 'Invoice fully paid!';

  @override
  String get paymentDialogFullyPaidBannerLabel => 'Invoice fully paid';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return 'Payment recorded. Outstanding: $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return 'Failed to record payment: $error';
  }

  @override
  String get paymentDialogDeleteTitle => 'Delete Payment';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return 'Delete receipt $receiptNumber?\n\nThis cannot be undone.';
  }

  @override
  String get paymentDialogNewPaymentTitle => 'New Payment';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return 'Amount ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return 'Max: $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError => 'Enter a valid amount';

  @override
  String get paymentDialogExceedsOutstandingError =>
      'Exceeds outstanding balance';

  @override
  String get paymentDialogMethodFieldLabel => 'Payment Method';

  @override
  String get paymentDialogSelectMethodHint => 'Select method';

  @override
  String get paymentDialogTaxCoveredLabel => 'Tax Covered';

  @override
  String get paymentDialogAutoCalculatedHelper => 'Auto-calculated';

  @override
  String get paymentDialogNotesFieldLabel => 'Reference / Notes (optional)';

  @override
  String get paymentDialogNotesHint => 'e.g. cheque no., transaction ID...';

  @override
  String get paymentDialogReceiptColLabel => 'Receipt #';

  @override
  String get paymentDialogMethodColLabel => 'Method';

  @override
  String get paymentDialogDownloadReceiptTooltip => 'Download receipt';

  @override
  String get paymentDialogDeletePaymentTooltip => 'Delete payment';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodBankTransfer => 'Bank Transfer';

  @override
  String get paymentMethodCheck => 'Check';

  @override
  String get paymentMethodOnline => 'Online';

  @override
  String get paymentMethodOther => 'Other';

  @override
  String get customerInfoButtonTooltip => 'View contact details';

  @override
  String get customerInfoButtonNoContactMessage =>
      'No contact details available.';

  @override
  String get updateDialogTitle => 'Update Available';

  @override
  String get updateDialogBodyMessage =>
      'A new version of invoiso is available. Visit the download page to get the latest release.';

  @override
  String get pageSizeA4Label => 'Standard A4';

  @override
  String get pageSizeA5Label => 'Standard A5';

  @override
  String get pageSizeA6Label => 'Standard A6';

  @override
  String get pageSizeThermal80Label => 'Thermal Paper 80mm';

  @override
  String get pageSizeThermal58Label => 'Thermal Paper 58mm';

  @override
  String get dateFormatDdmmyyyyLabel => 'DD/MM/YYYY  (e.g. 15/04/2026)';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/DD/YYYY  (e.g. 04/15/2026)';

  @override
  String get dateFormatDdMmmyyyyLabel => 'DD MMM YYYY  (e.g. 15 Apr 2026)';

  @override
  String get dateFormatYyyymmddLabel => 'YYYY-MM-DD  (e.g. 2026-04-15)';

  @override
  String get sizeXSmallLabel => 'X-Small';

  @override
  String get sizeSmallLabel => 'Small';

  @override
  String get sizeMediumLabel => 'Medium';

  @override
  String get sizeLargeLabel => 'Large';

  @override
  String get shortcutNewInvoiceDescription =>
      'New Invoice (from Dashboard) / Reset form (in Create Invoice)';

  @override
  String get shortcutSaveInvoiceDescription => 'Save / create the invoice';

  @override
  String get shortcutAddProductDescription => 'Add product to invoice';

  @override
  String get shortcutAddCustomItemDescription => 'Add custom (ad-hoc) item';

  @override
  String get shortcutPreviewPdfDescription => 'Preview invoice PDF';

  @override
  String get shortcutPrintPdfDescription => 'Generate / print invoice PDF';
}
