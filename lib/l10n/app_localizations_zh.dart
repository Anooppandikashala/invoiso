// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Invoiso';

  @override
  String get actionSave => '保存';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSkip => '跳过';

  @override
  String get actionNext => '下一步';

  @override
  String get actionBack => '返回';

  @override
  String get actionGetStarted => '开始使用';

  @override
  String get commonLanguage => '语言';

  @override
  String get commonBeta => '测试版';

  @override
  String get commonSystemDefault => '系统默认';

  @override
  String get commonTheme => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get onboardingStepCompanyTitle => '公司';

  @override
  String get onboardingStepCompanySubtitle => '介绍一下您的公司';

  @override
  String get onboardingStepInvoiceTitle => '发票设置';

  @override
  String get onboardingStepInvoiceSubtitle => '设置发票的工作方式';

  @override
  String get onboardingStepAppearanceTitle => '发票外观';

  @override
  String get onboardingStepAppearanceSubtitle => '选择页面大小和模板';

  @override
  String get onboardingStepDoneTitle => '全部完成';

  @override
  String get onboardingCompanyNameLabel => '公司名称';

  @override
  String get onboardingCountryLabel => '国家';

  @override
  String get onboardingLogoLabel => '公司徽标';

  @override
  String get onboardingCurrencyLabel => '货币';

  @override
  String get onboardingDateFormatLabel => '日期格式';

  @override
  String get onboardingInvoiceStartingNumberLabel => '发票起始编号';

  @override
  String get onboardingLeadingZerosLabel => '前导零';

  @override
  String get onboardingLeadingZerosSubtitle => '将发票编号补齐为8位数字（如 00000007）';

  @override
  String get onboardingDefaultTaxRateLabel => '默认税率 (%)';

  @override
  String get onboardingPageSizeLabel => '页面大小';

  @override
  String get onboardingTemplateLabel => '发票模板';

  @override
  String get onboardingDoneHeadline => '一切就绪！';

  @override
  String get onboardingDoneBody => '您的公司、发票和模板信息已保存。您可以随时在设置中更新这些信息。';

  @override
  String get splashInitErrorTitle => '初始化错误';

  @override
  String splashInitErrorMessage(String error) {
    return '数据库初始化失败。\n\n$error';
  }

  @override
  String get actionRetry => '重试';

  @override
  String get splashInitializingMessage => '正在初始化应用...';

  @override
  String get testGateNoInternetTitle => '测试安装程序需要联网才能验证。';

  @override
  String get testGateExpiredTitle => '此测试版本已过期。';

  @override
  String get testGateNoInternetSubtitle => '请连接网络后重试。';

  @override
  String testGateExpiredSubtitle(String email) {
    return '联系支持：$email';
  }

  @override
  String get dashboardSessionExpiredMessage => '由于长时间未操作，会话已过期。';

  @override
  String get dashboardUnknownTabLabel => '未知标签页';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return '发票布局：$layout — 点击查看详情';
  }

  @override
  String get dashboardLayoutNew => '新版';

  @override
  String get dashboardLayoutClassic => '经典版';

  @override
  String get dashboardInvoiceLayoutDialogTitle => '发票布局';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return '您正在使用$layout版\"新建发票\"布局。您可以在 设置 > 辅助功能 中切换。注意：编辑过程中切换将丢失此表单未保存的更改。';
  }

  @override
  String get actionClose => '关闭';

  @override
  String get dashboardOpenSettingsAction => '打开设置';

  @override
  String get dashboardCollapseSidebarTooltip => '收起侧边栏';

  @override
  String get dashboardExpandSidebarTooltip => '展开侧边栏';

  @override
  String get navDashboard => '仪表盘';

  @override
  String get navNewInvoice => '新建发票';

  @override
  String get navInvoices => '发票';

  @override
  String get navQuotations => '报价单';

  @override
  String get navReceipts => '收据';

  @override
  String get navCustomers => '客户';

  @override
  String get navProducts => '产品';

  @override
  String get navReports => '报表';

  @override
  String get navSettings => '设置';

  @override
  String get dashboardRoleAdmin => '管理员';

  @override
  String get dashboardRoleUser => '用户';

  @override
  String get dashboardSupportTooltip => '支持';

  @override
  String get dashboardLogoutTooltip => '退出登录';

  @override
  String get dashboardTestBuildBadge => '测试版本';

  @override
  String get dashboardTestBadgeShort => '测试';

  @override
  String get dashboardKeyboardShortcutsTitle => '键盘快捷键';

  @override
  String get dashboardShortcutsBannerTitle => '新功能：键盘快捷键';

  @override
  String get dashboardShortcutsBannerSubtitle => 'Ctrl+Q 新建发票，Ctrl+S 保存，还有更多。';

  @override
  String get dashboardViewAllAction => '查看全部';

  @override
  String get dashboardLayoutBannerTitle => '新功能：多种仪表盘布局';

  @override
  String get dashboardLayoutBannerSubtitle =>
      '使用右上角的网格图标在默认、经典、Bento 和简约信息流布局之间切换。';

  @override
  String get actionGotIt => '知道了';

  @override
  String get dashboardThemeBannerTitle => '新功能：深色模式';

  @override
  String get dashboardThemeBannerSubtitle =>
      '我们仍在完善中 — 可在 设置 > 公司信息 中开启，并告诉我们哪里看起来不对。';

  @override
  String dashboardSupportBannerTitle(String count) {
    return '您已创建 $count 张发票！';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      '喜欢 Invoiso 吗？一个简单的好评会有很大帮助。';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      '看起来 Invoiso 已成为您工作流程的一部分。如果它对您有帮助，欢迎在方便的时候支持这个项目。';

  @override
  String get dashboardReviewAction => '评价';

  @override
  String get dashboardSupportAction => '支持';

  @override
  String get dashboardOverviewTitle => '仪表盘概览';

  @override
  String get actionRefresh => '刷新';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count 件缺货';
  }

  @override
  String get dashboardRevenueCollectedLabel => '已收入';

  @override
  String get dashboardOutstandingLabel => '未结清';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count 张逾期';
  }

  @override
  String get dashboardRecentInvoicesTitle => '最近发票';

  @override
  String get dashboardLastFiveInvoicesLabel => '最近 5 张发票';

  @override
  String get dashboardNoInvoicesYetTitle => '暂无发票';

  @override
  String get dashboardNoInvoicesYetSubtitle => '创建您的第一张发票后将显示在此处';

  @override
  String get actionView => '查看';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionDuplicate => '复制';

  @override
  String get actionPdfPreview => 'PDF 预览';

  @override
  String get actionDownloadPdf => '下载 PDF';

  @override
  String get actionPrint => '打印';

  @override
  String get actionPayment => '付款';

  @override
  String get actionDelete => '删除';

  @override
  String get actionRecordPayment => '记录付款';

  @override
  String dashboardDueDateLabel(String date) {
    return '到期：$date';
  }

  @override
  String get labelInvoice => '发票';

  @override
  String get labelQuotation => '报价单';

  @override
  String get labelReceipt => '收据';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return '欢迎回来，$username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle => '这里是您业务的概览';

  @override
  String get dashboardDueSoonTitle => '即将到期';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张发票',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => '今天和明天';

  @override
  String get dashboardDueTodayBadge => '今天到期';

  @override
  String get dashboardDueTomorrowBadge => '明天到期';

  @override
  String get dashboardOverdueSectionTitle => '逾期';

  @override
  String get dashboardOldestFirstLabel => '最早的在前';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '逾期 $days 天',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => '新库存数量';

  @override
  String get actionUpdate => '更新';

  @override
  String get labelService => '服务';

  @override
  String get labelProduct => '产品';

  @override
  String dashboardStockLabel(int count) {
    return '库存：$count';
  }

  @override
  String get actionUpdateStock => '更新库存';

  @override
  String get paymentStatusPaid => '已付款';

  @override
  String get paymentStatusPartial => '部分付款';

  @override
  String get paymentStatusUnpaid => '未付款';

  @override
  String get dashboardDuplicateInvoiceTitle => '复制发票';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return '将发票 #$number\n（$customerName）复制为：';
  }

  @override
  String get dashboardDeleteInvoiceTitle => '删除发票';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return '确定要删除发票 #$number 吗？此操作无法撤销。';
  }

  @override
  String get dashboardLayoutTooltip => '仪表盘布局';

  @override
  String get dashboardLayoutDefaultTitle => '默认';

  @override
  String get dashboardLayoutDefaultSubtitle => '原始布局';

  @override
  String get dashboardLayoutClassicSubtitle => '图表 + KPI 网格';

  @override
  String get dashboardLayoutBentoTitle => 'Bento';

  @override
  String get dashboardLayoutBentoSubtitle => '主图表 + 卡片网格';

  @override
  String get dashboardLayoutSimpleTitle => '简约信息流';

  @override
  String get dashboardLayoutSimpleSubtitle => '简洁列表视图';

  @override
  String get dashboardTotalInvoicesLabel => '发票总数';

  @override
  String get dashboardRevenueLast6MonthsTitle => '收入 — 近 6 个月';

  @override
  String get dashboardNoPaymentDataYetLabel => '暂无付款数据';

  @override
  String get dashboardFinancialOverviewTitle => '财务概览';

  @override
  String get dashboardCollectedLabel => '已收款';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张发票逾期',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return '最近 $n 张';
  }

  @override
  String get labelCustomer => '客户';

  @override
  String get labelAmount => '金额';

  @override
  String get dashboardZeroLeftLabel => '剩余 0';

  @override
  String get labelStock => '库存';

  @override
  String get actionPay => '付款';

  @override
  String get dashboardQuickActionsTitle => '快捷操作';

  @override
  String get dashboardPdfActionsTooltip => 'PDF 操作';

  @override
  String get dashboardActionsTooltip => '操作';

  @override
  String get dashboardTopCustomersTitle => '重要客户';

  @override
  String get dashboardTopProductsTitle => '热销产品';

  @override
  String dashboardUnitsLabel(String qty) {
    return '$qty 件';
  }

  @override
  String get dashboardBetaBadge => '测试版';

  @override
  String get dashboardOutOfStockSectionTitle => '缺货';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件商品',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => '点击补货';

  @override
  String get createInvoiceUnsavedChangesTitle => '未保存的更改';

  @override
  String get createInvoiceUnsavedChangesMessage => '此发票中有未保存的更改。是否在离开前保存？';

  @override
  String get createInvoiceKeepEditingButton => '继续编辑';

  @override
  String get actionDiscard => '放弃';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return '加载数据出错：$e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => '库存不足';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return '仅有 $stock 件库存。仍要添加 $qty 件吗？';
  }

  @override
  String get createInvoiceAddAnywayButton => '仍然添加';

  @override
  String get createInvoiceOutOfStockTitle => '缺货';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name 已缺货。仍要添加吗？';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => '无限库存';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return '可用库存：$stock';
  }

  @override
  String get fieldDiscountLabel => '折扣';

  @override
  String get fieldUnitPriceOverrideLabel => '单价（覆盖）';

  @override
  String get fieldExtraCostLabel => '额外费用（可选）';

  @override
  String get fieldInsertAtPositionLabel => '插入位置';

  @override
  String get actionAdd => '添加';

  @override
  String get createInvoiceProductAlreadyAddedMessage => '此产品已添加';

  @override
  String get createInvoiceCustomerNameRequiredMessage => '请提供客户名称';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage => '请至少添加一个项目';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel创建成功！';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return '创建发票时出错：$e';
  }

  @override
  String get createInvoiceEditItemTitle => '编辑项目';

  @override
  String get createInvoiceCustomItemTitle => '自定义项目';

  @override
  String get fieldItemNameLabel => '项目名称';

  @override
  String get fieldAliasForPdfLabel => '别名（用于 PDF）';

  @override
  String get fieldUnitPriceLabel => '单价';

  @override
  String get fieldRateLabel => '费率';

  @override
  String get fieldTaxRateLabel => '税率 (%)';

  @override
  String get fieldPriceIncludesTaxLabel => '价格含税';

  @override
  String get createInvoicePhoneAlreadyInUseTitle => '电话号码已被使用';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return '此电话号码属于“$ownerName”。\n\n无法使用已属于他人的电话号码保存此客户。';
  }

  @override
  String get actionOk => '确定';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      '保存前请输入客户名称';

  @override
  String get createInvoicePhoneChangedTitle => '电话号码已更改';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return '“$name”的电话号码已更改。\n\n是要更新其现有记录，还是将这些信息另存为新客户？';
  }

  @override
  String get createInvoiceSaveAsNewButton => '另存为新客户';

  @override
  String get createInvoiceUpdateExistingButton => '更新现有客户';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '已在客户列表中更新 $name';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle => '客户已存在';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '“$name”已使用此电话号码保存。\n\n是使用其现有信息，还是用当前信息更新其记录？';
  }

  @override
  String get createInvoiceUseExistingButton => '使用现有客户';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return '正在使用现有客户“$name”';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name 已保存到客户列表';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage => '客户记录已不存在';

  @override
  String get createInvoiceCustomerRefreshedMessage => '客户信息已刷新';

  @override
  String get fieldLabelLabel => '标签';

  @override
  String get hintLabelExample => '例如：运费';

  @override
  String get tooltipRemove => '移除';

  @override
  String get createInvoiceAddRowButton => '添加行';

  @override
  String get fieldDiscountPerUnitLabel => '每单位折扣';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn => '（单价 − 折扣）× 数量';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff => '（单价 × 数量）− 折扣';

  @override
  String get createInvoicePrevBalanceShortLabel => '上期余额';

  @override
  String get createInvoicePreviousBalanceDueLabel => '上期应付余额';

  @override
  String get createInvoiceDueShortLabel => '应付';

  @override
  String get createInvoiceTotalDueLabel => '应付总额';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel更新成功！';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return '更新发票时出错：$e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '$invoiceTypeLabel创建成功！';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return '$invoiceTypeLabel 编号：$invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => '查看详情';

  @override
  String get createInvoicePreviewPdfLabel => '预览 PDF';

  @override
  String get createInvoicePreviewPdfTooltip => '预览 PDF（快捷键：Ctrl+o）';

  @override
  String get createInvoicePrintPdfLabel => '打印 PDF';

  @override
  String get createInvoicePrintPdfTooltip => '打印 PDF（快捷键：Ctrl+p）';

  @override
  String get actionDismiss => '关闭';

  @override
  String get createInvoiceCreateNewInvoiceButton => '创建新发票（快捷键：Ctrl+q）';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return '创建新$invoiceTypeLabel';
  }

  @override
  String get commonLoadingDataMessage => '正在加载数据…';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage => '创建发票前请至少添加一个项目。';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel已创建';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return '编辑$invoiceTypeLabel';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return '复制为$invoiceTypeLabel';
  }

  @override
  String get createInvoiceNewShortLabel => '新建';

  @override
  String get createInvoiceNewInvoiceShortcutLabel => '新发票（快捷键：Ctrl+q）';

  @override
  String get createInvoiceSavingEllipsisLabel => '正在保存…';

  @override
  String get createInvoiceSaveCustomerLabel => '保存客户';

  @override
  String get createInvoiceSelectExistingCustomerButton => '从现有客户中选择';

  @override
  String get createInvoiceRefreshCustomerTooltip => '从已保存客户刷新';

  @override
  String get createInvoiceClearCustomerTooltip => '清除客户选择';

  @override
  String get fieldCustomerNameRequiredLabel => '客户名称 *';

  @override
  String get fieldBusinessNameLabel => '企业名称';

  @override
  String get fieldPhoneLabel => '电话';

  @override
  String get fieldGstinVatLabel => 'GSTIN / 增值税号';

  @override
  String get fieldEmailLabel => '电子邮箱';

  @override
  String get fieldAddressLabel => '地址';

  @override
  String get tooltipEditInLargerView => '在放大视图中编辑';

  @override
  String get createInvoiceChooseCustomerTitle => '选择客户';

  @override
  String get createInvoiceSearchCustomerLabel => '搜索客户';

  @override
  String get createInvoiceNoCustomersFoundMessage => '未找到客户';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return '$invoiceTypeLabel详情';
  }

  @override
  String get createInvoiceTypeFieldLabel => '发票类型';

  @override
  String get createInvoiceTypeLockedHelperText => '创建后无法更改类型';

  @override
  String get createInvoiceOrderDateLabel => '订单日期';

  @override
  String get createInvoiceDueDateLabel => '到期日期';

  @override
  String get createInvoiceGstTitleLabel => 'GST 标题';

  @override
  String get createInvoiceTaxTitleLabel => '税务标题';

  @override
  String get gstTitleTaxInvoiceLabel => '税务发票';

  @override
  String get gstTitleBillOfSupplyLabel => '供货单';

  @override
  String get gstTitleInvoiceCumBillLabel => '发票兼供货单';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => '贷项通知单';

  @override
  String get gstTitleDebitNoteLabel => '借项通知单';

  @override
  String get gstTitleRevisedInvoiceLabel => '修订发票';

  @override
  String get createInvoiceSearchProductLabel => '搜索并添加产品或服务（Ctrl+F）';

  @override
  String get createInvoiceCustomItemButton => '自定义项目（Ctrl+M）';

  @override
  String get createInvoiceNoProductsFoundMessage => '未找到产品';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '“$name”已存在于产品列表中';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name 已保存到产品列表';
  }

  @override
  String get createInvoiceSaveToProductListTooltip => '保存到产品列表';

  @override
  String get tooltipEditItem => '编辑项目';

  @override
  String get tooltipRemoveItem => '移除项目';

  @override
  String get createInvoiceNoItemsAddedMessage => '尚未添加任何项目';

  @override
  String get createInvoiceSearchHintMessage => '在下方搜索或按 Ctrl+F';

  @override
  String get createInvoiceDiscountFieldLabel => '发票折扣';

  @override
  String get discountTypeAmountShortLabel => '金额';

  @override
  String get createInvoiceNotesOptionalLabel => '备注（可选）';

  @override
  String get createInvoiceNotesHint => '付款条款、感谢信息……';

  @override
  String get createInvoiceNotesTitle => '备注';

  @override
  String get createInvoiceHideNumberInPdfLabel => '在 PDF 中隐藏发票编号';

  @override
  String get createInvoiceCustomNumberLabel => '自定义编号（可选）';

  @override
  String get createInvoiceCustomNumberHint => '例如 QUO-2026-014 — 将在 PDF 中显示此编号';

  @override
  String get createInvoiceEnableTaxLabel => '启用税费';

  @override
  String get createInvoiceGlobalRateTooltip => '统一税率';

  @override
  String get createInvoicePerItemRateTooltip => '按项目税率';

  @override
  String get createInvoiceDefaultTaxRateLabel => '默认税率';

  @override
  String get createInvoiceTaxRateFromProductMessage => '使用各产品自身的税率';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => '收款 UPI 账户';

  @override
  String get commonNoneLabel => '无';

  @override
  String get createInvoiceBankAccountLabel => '银行账户';

  @override
  String get fieldSubtotalLabel => '小计';

  @override
  String get createInvoiceDiscountColonLabel => '折扣：';

  @override
  String get fieldTaxLabel => '税费';

  @override
  String get createInvoiceExtraCostFallbackLabel => '额外费用';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return '发票折扣（$toStringAsFixed%）：';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel => '发票折扣：';

  @override
  String get fieldTotalLabel => '合计';

  @override
  String get createInvoicePreviewLabel => '预览';

  @override
  String get createInvoicePreviewTooltip => '预览（快捷键：Ctrl+o）';

  @override
  String get createInvoiceDownloadLabel => '下载';

  @override
  String get createInvoicePrintTooltip => '打印（快捷键：Ctrl+p）';

  @override
  String get fieldUnitOverrideLabel => '单位（覆盖）';

  @override
  String get commonCustomEllipsisLabel => '自定义…';

  @override
  String get fieldCustomUnitLabel => '自定义单位';

  @override
  String get invoiceMgmtMoveToTrashTitle => '移至回收站';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return '将发票 #$number 移至回收站？';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage => '发票已移至回收站。';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return '加载发票失败：$error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return '将$type导出为 CSV';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel => '导出所有记录';

  @override
  String get invoiceMgmtFilterByDateRangeLabel => '或按日期范围筛选：';

  @override
  String get invoiceMgmtFromDateLabel => '起始日期';

  @override
  String get invoiceMgmtToDateLabel => '结束日期';

  @override
  String get invoiceMgmtDateRangeInvalidMessage => '结束日期必须晚于起始日期。';

  @override
  String get actionExport => '导出';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已导出 $count 条记录到：$path',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return '导出失败：$error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将 $count 张发票移至回收站？',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已将 $count 张发票移至回收站。',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return '批量删除失败：$error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已将 $count 张发票导出为 CSV',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'CSV 导出失败：$error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => '下载 PDF';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '您希望如何保存 $count 个 PDF？',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => '保存到文件夹';

  @override
  String get invoiceMgmtSaveAsZipLabel => '保存为 ZIP';

  @override
  String get invoiceMgmtChooseFolderDialogTitle => '选择保存 PDF 的文件夹';

  @override
  String get invoiceMgmtSaveZipDialogTitle => '保存 ZIP 文件';

  @override
  String get invoiceMgmtCreatingZipLabel => '正在创建 ZIP';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => '正在生成 PDF';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在处理 $count 个 PDF...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return '已保存到：$path';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'PDF 导出失败：$error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle => '按筛选条件下载 PDF';

  @override
  String get invoiceMgmtByDateLabel => '按日期';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => '按发票编号';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => '起始发票 #';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => '结束发票 #';

  @override
  String get invoiceMgmtCheckCountLabel => '查看数量';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return '$count 张发票 — 超出 $limit 的限制';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张发票匹配',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return '每次下载最多 $limit 个 PDF。请缩小筛选范围。';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage => '未找到符合所选筛选条件的发票。';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return '筛选结果为 $count 张发票 — 最多为 $limit 张。';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => '筛选发票';

  @override
  String get invoiceMgmtHideFullyPaidLabel => '隐藏已全额付款的发票';

  @override
  String get invoiceMgmtPaymentStatusLabel => '付款状态';

  @override
  String get invoiceMgmtDueDateLabel => '到期日';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => '发票日期范围';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel => '发票编号范围';

  @override
  String get invoiceMgmtFromHashLabel => '起始 #';

  @override
  String get invoiceMgmtToHashLabel => '结束 #';

  @override
  String get actionReset => '重置';

  @override
  String get actionApply => '应用';

  @override
  String get invoiceMgmtSortByTitle => '排序方式';

  @override
  String get invoiceMgmtSearchHintMessage => '按发票编号或客户名称搜索…';

  @override
  String get invoiceMgmtFilterLabel => '筛选';

  @override
  String get invoiceMgmtSortLabel => '排序';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return '总计：$total   ·   第 $page/$totalPages 页';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '已选择 $count 项';
  }

  @override
  String get invoiceMgmtDeselectLabel => '取消选择';

  @override
  String get invoiceMgmtSelectPageLabel => '选择本页';

  @override
  String get invoiceMgmtMarkPaidLabel => '标记为已付款';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDF';

  @override
  String get invoiceMgmtTrashLabel => '回收站';

  @override
  String get actionApplyPayment => '应用付款';

  @override
  String get invoiceMgmtMoreActionsTooltip => '更多操作';

  @override
  String get invoiceMgmtColSlNo => '序号';

  @override
  String get invoiceMgmtColInvoiceCustomer => '发票 / 客户';

  @override
  String get invoiceMgmtColTitle => '标题';

  @override
  String get invoiceMgmtColDate => '日期';

  @override
  String get invoiceMgmtColItems => '项目';

  @override
  String get invoiceMgmtColStatus => '状态';

  @override
  String get invoiceMgmtColOutstanding => '未结余额';

  @override
  String get invoiceMgmtColActions => '操作';

  @override
  String get invoiceMgmtRowsPerPageLabel => '每页行数：';

  @override
  String get actionPrevious => '上一页';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return '第 $page 页，共 $totalPages 页';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return '未找到“$query”的结果';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return '未找到$type';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return '创建您的第一个$type以在此处查看';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage => '请尝试调整搜索或筛选条件';

  @override
  String get invoiceMgmtDownloadByRangeTooltip => '按日期或发票范围下载 PDF';

  @override
  String get invoiceMgmtExportAllCsvTooltip => '全部导出为 CSV';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel => '按范围下载 PDF';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return '$type管理';
  }

  @override
  String get invoiceMgmtOverdueBadge => '已逾期';

  @override
  String get invoiceMgmtTodayBadge => '今天';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => '回收站为空';

  @override
  String get actionRestore => '恢复';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => '永久删除';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return '永久删除发票 #$number？此操作无法撤销。';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage => '发票已恢复。';

  @override
  String get invoiceMgmtAnyDateLabel => '任意';

  @override
  String get invoiceMgmtStatusAllLabel => '全部';

  @override
  String get invoiceMgmtDueAllLabel => '所有到期';

  @override
  String get invoiceMgmtDueTodayLabel => '今日到期';

  @override
  String get invoiceMgmtDueWeekLabel => '本周到期';

  @override
  String get invoiceMgmtDueMonthLabel => '本月到期';

  @override
  String get invoiceMgmtSortRecentlyAdded => '最近添加';

  @override
  String get invoiceMgmtSortOldestAdded => '最早添加';

  @override
  String get invoiceMgmtSortDateNewest => '发票日期（最新优先）';

  @override
  String get invoiceMgmtSortDateOldest => '发票日期（最早优先）';

  @override
  String get invoiceMgmtSortCustomerAZ => '客户名称 (A–Z)';

  @override
  String get invoiceMgmtSortCustomerZA => '客户名称 (Z–A)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => '标记为已付款';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将 $count 张发票标记为已全额付款？',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n（$count 张已付款 — 将被跳过）';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage => '所选发票均已全额付款。';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张发票已标记为已付款。',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return '标记为已付款失败：$error';
  }

  @override
  String get fieldNameLabel => '姓名';

  @override
  String get customerMgmtEditCustomerTitle => '编辑客户';

  @override
  String get customerMgmtViewCustomerTitle => '查看客户';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / 增值税号';
  }

  @override
  String get customerMgmtUpdatedMessage => '客户更新成功！';

  @override
  String fieldRequiredMessage(String field) {
    return '请输入$field';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => '确认删除';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return '确定要删除“$name”吗？';
  }

  @override
  String get customerMgmtDeletedMessage => '客户删除成功！';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle => '保存示例 CSV';

  @override
  String get customerMgmtSampleSavedMessage => '示例 CSV 保存成功！';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return '保存示例时出错：$error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle => '从 CSV 导入客户';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      '您的 CSV 文件必须使用以下列标题（拼写须准确，顺序不限）：';

  @override
  String get customerMgmtCsvColColumnHeader => '列';

  @override
  String get customerMgmtCsvColRequiredHeader => '必填';

  @override
  String get customerMgmtCsvColDescriptionHeader => '说明';

  @override
  String get commonYesLabel => '是';

  @override
  String get commonNoLabel => '否';

  @override
  String get customerMgmtCsvDescName => '客户全名';

  @override
  String get customerMgmtCsvDescEmail => '电子邮件地址';

  @override
  String get customerMgmtCsvDescPhone => '电话号码';

  @override
  String get customerMgmtCsvDescAddress => '详细地址';

  @override
  String get customerMgmtCsvDescBusinessName => '公司 / 企业名称';

  @override
  String get customerMgmtCsvDescTaxNumber => '税号 / 增值税号 / GSTIN';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return '每次导入最多 $max 行。';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      '系统会通过电子邮件或电话检测重复项，并要求您选择覆盖或跳过每一项。';

  @override
  String get customerMgmtCsvMissingNameNote => '缺少姓名的行将被跳过，并在最后报告。';

  @override
  String get customerMgmtCsvEncodingNote => '建议使用 UTF-8 编码。Excel 的 BOM 会自动处理。';

  @override
  String get customerMgmtDownloadSampleCsvButton => '下载示例 CSV';

  @override
  String get customerMgmtChooseFileButton => '选择文件';

  @override
  String get customerMgmtSelectCsvDialogTitle => '选择客户 CSV';

  @override
  String get customerMgmtCsvEmptyMessage => 'CSV 文件为空。';

  @override
  String get customerMgmtCsvMissingNameColumnMessage => 'CSV 缺少必需的列：“name”';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return '未知列“$col”。应为：$expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'CSV 有 $count 行，超出上限 $max 行，请拆分文件。';
  }

  @override
  String get customerMgmtImportingTitle => '正在导入客户';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在检查重复项并验证 $count 行...',
      one: '正在检查重复项并验证 1 行...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return '第 $n 行：缺少姓名 — 已跳过';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return '读取 CSV 时出错：$error';
  }

  @override
  String get customerMgmtImportPreviewTitle => '导入预览';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个新增',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个重复',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个错误',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel => '重复项（按电子邮件或电话匹配）：';

  @override
  String get customerMgmtOverwriteAllButton => '全部覆盖';

  @override
  String get customerMgmtSkipAllButton => '全部跳过';

  @override
  String get customerMgmtOverwriteLabel => '覆盖';

  @override
  String get customerMgmtSkippedRowsLabel => '已跳过的行（错误）：';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '将导入 $total 个客户。',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return '导入 $total 个';
  }

  @override
  String get customerMgmtDeleteAllTitle => '删除所有客户';

  @override
  String get customerMgmtNoCustomersToDeleteMessage => '没有可删除的客户。';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这将永久删除全部 $count 个客户。现有发票不受影响。此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => '全部删除';

  @override
  String get customerMgmtAllDeletedMessage => '所有客户已删除。';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return '删除客户时出错：$error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => '保存客户 CSV';

  @override
  String get customerMgmtCsvExportedMessage => 'CSV 导出成功！';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return '导出 CSV 时出错：$error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => '保存客户 PDF';

  @override
  String get customerMgmtPdfExportedMessage => 'PDF 导出成功！';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return '导出 PDF 时出错：$error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => '客户总数';

  @override
  String get customerMgmtAllCustomersSubtitle => '所有客户';

  @override
  String get customerMgmtBusinessesLabel => '企业';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle => '已注册企业';

  @override
  String get customerMgmtIndividualsLabel => '个人';

  @override
  String get customerMgmtIndividualCustomersSubtitle => '个人客户';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '已$taxWord注册';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return '含$taxWord号';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return '无$taxWord';
  }

  @override
  String get customerMgmtTitle => '客户管理';

  @override
  String get customerMgmtSubtitle => '管理您的客户及联系方式';

  @override
  String get actionImport => '导入';

  @override
  String get customerMgmtExportPdfMenuLabel => '导出 PDF';

  @override
  String get customerMgmtNewCustomerButton => '新建客户';

  @override
  String get customerMgmtSortNameAZ => '姓名 A-Z';

  @override
  String get customerMgmtSortNameZA => '姓名 Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID（最早优先）';

  @override
  String get customerMgmtSortIdNewest => 'ID（最新优先）';

  @override
  String get customerMgmtSortOutstandingHighLow => '未结余额（从高到低）';

  @override
  String get customerMgmtSortOutstandingLowHigh => '未结余额（从低到高）';

  @override
  String get customerMgmtWithOutstandingLabel => '有未结余额';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return '按姓名、企业、电话、$taxWord、邮箱搜索客户…';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return '所有$taxWord状态';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '已$taxWord注册';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return '排序：$label';
  }

  @override
  String get customerMgmtColumnsLabel => '列';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / 增值税号';
  }

  @override
  String get customerMgmtHideStatCardsTooltip => '隐藏统计卡片';

  @override
  String get customerMgmtShowStatCardsTooltip => '显示统计卡片';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label（$count）';
  }

  @override
  String get customerMgmtColSlNo => '序号';

  @override
  String get customerMgmtColNameBusiness => '姓名 / 企业';

  @override
  String get customerMgmtColPhone => '电话';

  @override
  String get customerMgmtColEmail => '邮箱';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / 增值税号';
  }

  @override
  String get customerMgmtColAddress => '地址';

  @override
  String get customerMgmtColActions => '操作';

  @override
  String get customerMgmtViewStatementTooltip => '查看对账单（在报表中）';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return '显示第 $from 至 $to 条，共 $total 位客户';
  }

  @override
  String get customerMgmtRowsPerPageLabel => '每页行数';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return '共 $totalPages 页';
  }

  @override
  String get customerMgmtAddAnotherLabel => '保存后继续添加';

  @override
  String get customerMgmtSaveCustomerButton => '保存客户';

  @override
  String get customerMgmtAddFirstCustomerSubtitle => '添加您的第一位客户以开始使用';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle => '请尝试调整您的搜索条件';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return '加载客户时出错：$error';
  }

  @override
  String get customerMgmtAddedMessage => '客户添加成功！';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return '保存客户时出错：$error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '成功导入 $count 位客户！',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return '导入错误：$error';
  }

  @override
  String get taxWordGst => 'GST';

  @override
  String get taxWordTax => '税';

  @override
  String get commonMoreLabel => '更多';

  @override
  String get productMgmtSellingAtLossTitle => '亏本销售';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return '采购价（$purchase）高于销售价（$sale）。仍要保存吗？';
  }

  @override
  String get actionSaveAnyway => '仍然保存';

  @override
  String get productMgmtAdvancedInformationLabel => '高级信息';

  @override
  String get productMgmtStorageLocationLabel => '存储位置';

  @override
  String get productMgmtContainerNumberLabel => '容器编号';

  @override
  String get productMgmtBatchNumberLabel => '批次号';

  @override
  String get productMgmtExpiryDateLabel => '有效期至';

  @override
  String get productMgmtManufactureDateLabel => '生产日期';

  @override
  String get productMgmtSupplierNameLabel => '供应商名称';

  @override
  String get productMgmtSkuCodeLabel => 'SKU 代码';

  @override
  String get productMgmtNotesLabel => '备注';

  @override
  String get fieldEnterValidPriceMessage => '请输入有效价格';

  @override
  String get fieldEnterValidStockMessage => '请输入有效库存';

  @override
  String get fieldTaxRangeMessage => '税率必须在 0-100 之间';

  @override
  String get productMgmtImportProductsCsvTitle => '从 CSV 导入产品';

  @override
  String get productMgmtCsvDescName => '产品名称';

  @override
  String get productMgmtCsvDescPrice => '单价（数字）';

  @override
  String get productMgmtCsvDescHsnCode => 'HSN / SAC 代码';

  @override
  String get productMgmtCsvDescDescription => '简短描述';

  @override
  String get productMgmtCsvDescTaxRate => '税率 %（0–100），默认 0';

  @override
  String get productMgmtCsvDescStock => '库存数量，默认 0';

  @override
  String get productMgmtCsvDescType => '“product”或“service”，默认 product';

  @override
  String get productMgmtCsvDescDefaultDiscount => '固定折扣金额（货币），默认 0';

  @override
  String get productMgmtCsvDescPurchasePrice => '成本价（数字），默认 0';

  @override
  String get productMgmtCsvDescAliasName => '用于 PDF 的本地语言显示名称';

  @override
  String get productMgmtCsvDescUnit => '计量单位（如 kg、bag、pcs），默认 pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock => '1/true 表示无限库存，默认 0';

  @override
  String get productMgmtCsvDescPriceIncludesTax => '1/true 表示价格已含税，默认 0';

  @override
  String get productMgmtCsvDescStorageLocation => '仓库/货架位置';

  @override
  String get productMgmtCsvDescContainerNumber => '容器/箱号';

  @override
  String get productMgmtCsvDescBatchNumber => '批次号';

  @override
  String get productMgmtCsvDescExpiryDate => '有效期';

  @override
  String get productMgmtCsvDescManufactureDate => '生产日期';

  @override
  String get productMgmtCsvDescSupplierName => '供应商名称';

  @override
  String get productMgmtCsvDescSkuCode => 'SKU 代码';

  @override
  String get productMgmtCsvDescNotes => '自由文本备注';

  @override
  String get productMgmtCsvDuplicateNote =>
      '系统按产品名称（不区分大小写）检测重复项。将逐一询问是否覆盖或跳过。';

  @override
  String get productMgmtCsvMissingRequiredNote => '缺少名称或价格的行将被跳过并报告。';

  @override
  String get productMgmtSelectCsvDialogTitle => '选择产品 CSV';

  @override
  String get productMgmtCsvMissingPriceColumnMessage => 'CSV 缺少必需列：“price”';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return '第 $n 行：价格无效“$price”— 已跳过';
  }

  @override
  String get productMgmtImportingTitle => '正在导入产品';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel => '重复项（按名称匹配）：';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '将导入 $total 个产品。',
      one: '将导入 1 个产品。',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage => '没有可删除的产品。';

  @override
  String get productMgmtDeleteAllTitle => '删除所有产品';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这将永久删除全部 $count 个产品。现有发票不受影响。此操作无法撤销。',
      one: '这将永久删除全部 1 个产品。现有发票不受影响。此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage => '已删除所有产品。';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return '删除产品时出错：$error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle => '保存产品 CSV';

  @override
  String get productMgmtExportToPdfTitle => '导出为 PDF';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return '导出当前页面（$pageSize 个产品）还是全部 $allCount 个产品？';
  }

  @override
  String get productMgmtCurrentPageLabel => '当前页面';

  @override
  String get productMgmtAllProductsLabel => '所有产品';

  @override
  String get productMgmtSaveProductsPdfDialogTitle => '保存产品 PDF';

  @override
  String get productMgmtTitle => '产品管理';

  @override
  String get productMgmtSubtitle => '管理您的产品和服务';

  @override
  String get productMgmtNewProductButton => '新产品';

  @override
  String get productMgmtSearchHint => '按名称、别名、HSN/SAC、SKU 搜索产品…';

  @override
  String get productMgmtFilterByStockStatusTooltip => '按库存状态筛选';

  @override
  String get productMgmtAllStockLevelsLabel => '所有库存水平';

  @override
  String get productMgmtLowStockLabel => '库存不足';

  @override
  String get productMgmtLowStockTabLabel => '库存不足';

  @override
  String get productMgmtOutOfStockLabel => '缺货';

  @override
  String get productMgmtOutOfStockTabLabel => '缺货';

  @override
  String get productMgmtExpiredLabel => '已过期';

  @override
  String get productMgmtSortPriceLowHigh => '价格从低到高';

  @override
  String get productMgmtSortPriceHighLow => '价格从高到低';

  @override
  String get productMgmtSortStockLowHigh => '库存从低到高';

  @override
  String get productMgmtSortStockHighLow => '库存从高到低';

  @override
  String get productMgmtServicesTabLabel => '服务';

  @override
  String get productMgmtColSlNo => '序号';

  @override
  String get productMgmtColNameAlias => '名称/别名';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => '价格';

  @override
  String get productMgmtColPurchase => '采购';

  @override
  String get productMgmtColStock => '库存';

  @override
  String get productMgmtColTaxPercent => '税率 %';

  @override
  String get productMgmtColExpiryDate => '有效期';

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
    return '显示第 $from 至 $to 项，共 $total 个产品';
  }

  @override
  String get productMgmtAddFirstProductSubtitle => '添加您的第一个产品以开始使用';

  @override
  String get productMgmtColumnsBannerTitle => '新功能：自定义产品字段';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      '选择要显示的字段，简化产品目录。设置 > 自定义产品详情。';

  @override
  String get productMgmtConfigureAction => '配置';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return '添加新$type';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle => '输入产品详情';

  @override
  String get productMgmtSaveProductButton => '保存产品';

  @override
  String get productMgmtAliasNameLabel => '别名（用于发票 PDF）';

  @override
  String get productMgmtAliasHelperText => '仅用于 PDF 发票的可选本地语言显示名称。';

  @override
  String get productMgmtDescriptionLabel => '描述';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => '销售价';

  @override
  String get productMgmtPurchasePriceLabel => '采购价';

  @override
  String get productMgmtDefaultDiscountLabel => '默认折扣';

  @override
  String get productMgmtTaxPercentLabel => '税率 (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel => '仅限逐项税模式';

  @override
  String get productMgmtSectionGeneral => '常规';

  @override
  String get productMgmtSectionPricing => '定价';

  @override
  String get productMgmtSectionInventory => '库存';

  @override
  String get productMgmtUnlimitedStockLabel => '无限库存';

  @override
  String get productMgmtTrackInfiniteStockSubtitle => '为此产品跟踪无限库存';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      '提示：在“列”中启用自定义字段以添加更多详情。';

  @override
  String get productMgmtEditProductTitle => '编辑产品';

  @override
  String get productMgmtViewProductTitle => '查看产品';

  @override
  String get productMgmtUpdateProductDetailsSubtitle => '更新产品详情';

  @override
  String get productMgmtProductDetailsSubtitle => '产品详情';

  @override
  String get productMgmtUpdatedMessage => '产品/服务更新成功！';

  @override
  String get productMgmtDeleteProductButton => '删除产品';

  @override
  String get productMgmtSaveChangesButton => '保存更改';

  @override
  String get fieldUnitLabel => '单位';

  @override
  String get productMgmtAddedMessage => '产品添加成功！';

  @override
  String productMgmtAddErrorMessage(String error) {
    return '添加产品时出错：$error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return '加载产品时出错：$error';
  }

  @override
  String get productMgmtDeletedMessage => '产品删除成功！';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已成功导入 $count 个产品！',
      one: '已成功导入 1 个产品！',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => '总项目数';

  @override
  String get productMgmtTangibleProductsSubtitle => '实体产品';

  @override
  String get productMgmtNonTangibleServicesSubtitle => '非实体服务';

  @override
  String get productMgmtNeedAttentionSubtitle => '需要关注';

  @override
  String get productMgmtProductNameLabel => '产品名称';

  @override
  String get productMgmtPriceLabel => '价格';

  @override
  String get actionClear => '清除';

  @override
  String get reportsAboutConversionRateTitle => '关于转化率';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return '账龄应收账款（$count）';
  }

  @override
  String get reportsAllCurrenciesLabel => '所有货币';

  @override
  String get reportsAvgInvoiceValueLabel => '平均发票金额';

  @override
  String get reportsBalanceColumnLabel => '余额';

  @override
  String get reportsBilledLabel => '已开票';

  @override
  String get reportsBucket0to30Label => '0–30 天';

  @override
  String get reportsBucket31to60Label => '31–60 天';

  @override
  String get reportsBucket61to90Label => '61–90 天';

  @override
  String get reportsBucket90PlusLabel => '90天以上';

  @override
  String get reportsBucketLabel => '分组';

  @override
  String get reportsClosingLabel => '期末余额';

  @override
  String get reportsCogsColumnLabel => '销售成本';

  @override
  String get reportsConversionRateExplanationBody =>
      '转化率 = 已创建发票 ÷ 已开具报价单 × 100。\n转化率超过100%表示在所选期间内开出的发票多于报价单（当发票不经过报价单直接创建时很常见）。\n\n注意：这是period级别的比率，不是逐个报价单到发票的追踪。';

  @override
  String get reportsConversionRateLabel => '转化率';

  @override
  String get reportsCreditColumnLabel => '贷方';

  @override
  String get reportsCurrencySectionLabel => '货币';

  @override
  String get reportsCurrentBucketLabel => '当前';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return '当前选择的货币（$currency）';
  }

  @override
  String get reportsCustomRangeLabel => '自定义范围';

  @override
  String get reportsDailySalesProfitTitle => '每日销售与利润';

  @override
  String reportsDaysCountLabel(int d) {
    return '$d 天';
  }

  @override
  String get reportsDaysOverdueLabel => '逾期天数';

  @override
  String get reportsDebitColumnLabel => '借方';

  @override
  String get reportsDiscountGivenColumnLabel => '已给折扣';

  @override
  String get reportsExportCsvLabel => '导出 CSV';

  @override
  String reportsFilteredToDateLabel(String date) {
    return '已筛选至 $date';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此期间 $countString 张发票 · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => '发票编号';

  @override
  String get reportsInvoicedLabel => '已开票';

  @override
  String get reportsInvoicesColumnLabel => '发票';

  @override
  String get reportsInvoicesInPeriodLabel => '期间内发票';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label（$count）';
  }

  @override
  String get reportsMarginColumnLabel => '利润率';

  @override
  String get reportsMaxRangeOneYearMessage => '最大范围为1年。结束日期已被限制。';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage => '最大范围为31天。结束日期已被限制。';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此期间售出的 $count 件商品未设置采购价 — 在为该产品添加采购价之前，这些商品的利润/利润率将被低估。',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => '月份和年份';

  @override
  String get reportsMonthlyRevenueTrendTitle => '月度收入趋势';

  @override
  String get reportsNavDailyReportLabel => '每日报告';

  @override
  String get reportsNavInvoiceStatusLabel => '发票状态';

  @override
  String get reportsNavReceivablesLabel => '应收账款';

  @override
  String get reportsNavRevenueLabel => '收入';

  @override
  String get reportsNavTaxLabel => '税';

  @override
  String get reportsNoCustomerDataMessage => '此期间无客户数据';

  @override
  String get reportsNoCustomersMatchSearchMessage => '没有客户与此搜索匹配';

  @override
  String get reportsNoCustomersWithInvoicesMessage => '没有带发票的客户';

  @override
  String get reportsNoDueDateLabel => '无到期日';

  @override
  String get reportsNoInvoiceDataMessage => '此期间无发票数据';

  @override
  String get reportsNoInvoicesInPeriodMessage => '此期间无发票';

  @override
  String get reportsNoInvoicesMatchFilterMessage => '没有发票与此筛选条件匹配';

  @override
  String get reportsNoOutstandingInvoicesMessage => '没有未结发票';

  @override
  String get reportsNoProductDataMessage => '此期间无产品数据';

  @override
  String get reportsNoSalesInPeriodMessage => '此期间无销售';

  @override
  String get reportsNoStatementActivityMessage => '该客户无对账单活动';

  @override
  String get reportsNoTaxableItemsMessage => '此期间无应税项目';

  @override
  String get reportsNoTransactionsMessage => '此期间无交易';

  @override
  String get reportsOpeningLabel => '期初余额';

  @override
  String get reportsOverviewLabel => '概览';

  @override
  String get reportsPaymentStatusBreakdownTitle => '付款状态细分';

  @override
  String get reportsPeriodSectionLabel => '周期';

  @override
  String get reportsPresetLast30DaysLabel => '最近30天';

  @override
  String get reportsPresetLast3MonthsLabel => '最近3个月';

  @override
  String get reportsPresetLast6MonthsLabel => '最近6个月';

  @override
  String get reportsPresetLastFYLabel => '上一财年';

  @override
  String get reportsPresetThisFYLabel => '本财年';

  @override
  String get reportsPresetThisYearLabel => '今年';

  @override
  String get reportsProductServiceColumnLabel => '产品/服务';

  @override
  String get reportsProfitLabel => '利润';

  @override
  String get reportsQuotationsIssuedLabel => '已开报价单';

  @override
  String get reportsRankByProfitLabel => '排序：利润';

  @override
  String get reportsRankByRevenueLabel => '排序：收入';

  @override
  String get reportsReferenceColumnLabel => '参考';

  @override
  String get reportsSalesColumnLabel => '销售额';

  @override
  String get reportsSaveCsvReportTitle => '保存CSV报告';

  @override
  String get reportsSavePdfReportTitle => '保存PDF报告';

  @override
  String reportsSavedAtMessage(String path) {
    return '已保存：$path';
  }

  @override
  String get reportsSelectCustomerTitle => '选择客户';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText => '选择日期或日期范围（最多31天）';

  @override
  String get reportsSelectDateRangeMaxYearHelpText => '选择日期范围（最多1年）';

  @override
  String get reportsShareLabel => '占比';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return '正在显示 $range 的发票';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end，共 $total';
  }

  @override
  String get reportsSlColumnLabel => '序号';

  @override
  String get reportsStatementsLabel => '对账单';

  @override
  String get reportsTaxCollectedByRateTitle => '按税率收取的税款';

  @override
  String get reportsTaxCollectedLabel => '已收税款';

  @override
  String get reportsTaxRateBucketsLabel => '税率分组';

  @override
  String get reportsTodayLabel => '今天';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return '按收入排名前 $count 名客户';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return '按$metric排名前 $count 名产品/服务';
  }

  @override
  String get reportsTotalBilledLabel => '开票总额';

  @override
  String get reportsTotalCollectedLabel => '已收总额';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $countString 张发票',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => '发票总数';

  @override
  String get reportsTotalProfitLabel => '总利润';

  @override
  String get reportsTotalTaxCollectedLabel => '已收税款总额';

  @override
  String get reportsTypeColumnLabel => '类型';

  @override
  String get reportsUnitsSoldColumnLabel => '已售数量';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return '加载用户时出错：$error';
  }

  @override
  String get userMgmtAddedMessage => '用户添加成功';

  @override
  String get userMgmtUpdatedMessage => '用户更新成功';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return '保存用户时出错：$error';
  }

  @override
  String get userMgmtChangePasswordTitle => '修改密码';

  @override
  String userMgmtUserColonLabel(String username) {
    return '用户：$username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => '当前密码';

  @override
  String get userMgmtCurrentPasswordRequiredMessage => '需要当前密码';

  @override
  String get userMgmtNewPasswordLabel => '新密码';

  @override
  String get userMgmtNewPasswordRequiredMessage => '需要新密码';

  @override
  String get userMgmtPasswordMinLengthMessage => '密码至少需要6个字符';

  @override
  String get userMgmtConfirmNewPasswordLabel => '确认新密码';

  @override
  String get userMgmtConfirmPasswordRequiredMessage => '请确认您的密码';

  @override
  String get userMgmtPasswordsDoNotMatchMessage => '密码不匹配';

  @override
  String get userMgmtPasswordChangedMessage => '密码修改成功';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage => '当前密码不正确';

  @override
  String get userMgmtDeleteUserTitle => '删除用户';

  @override
  String get userMgmtDeleteUserConfirmLabel => '您确定要删除该用户吗：';

  @override
  String get userMgmtActionCannotBeUndoneMessage => '此操作无法撤销。';

  @override
  String get userMgmtDeletedMessage => '用户删除成功';

  @override
  String get userMgmtCantDeleteOwnAccountMessage => '您不能删除自己的账户';

  @override
  String get userMgmtCantDemoteLastAdminMessage => '您不能更改唯一管理员的角色';

  @override
  String get userMgmtCantChangeOwnRoleMessage => '您不能更改自己的角色';

  @override
  String get userMgmtUsernameTakenMessage => '该用户名已被使用';

  @override
  String get userMgmtDeleteSelectedTitle => '删除选中的用户？';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这将永久删除$count个用户。此操作无法撤销。',
      one: '这将永久删除1个用户。此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage => '您自己的账户在所选范围内，但将被跳过。';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已删除$count个用户',
      one: '已删除1个用户',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return '删除用户时出错：$error';
  }

  @override
  String get userMgmtTitle => '用户管理';

  @override
  String get userMgmtSubtitle => '管理应用程序用户和访问权限';

  @override
  String get userMgmtAddUserButton => '添加用户';

  @override
  String get userMgmtSearchHint => '按姓名或角色搜索用户…';

  @override
  String get userMgmtFilterByRoleTooltip => '按角色筛选';

  @override
  String get userMgmtAllRolesLabel => '所有角色';

  @override
  String get userMgmtAllLabel => '全部';

  @override
  String userMgmtRoleColonLabel(String role) {
    return '角色：$role';
  }

  @override
  String get userMgmtColUser => '用户';

  @override
  String get userMgmtColRole => '角色';

  @override
  String get userMgmtYouBadgeLabel => '你';

  @override
  String get userMgmtDeleteSelectedMenuLabel => '删除所选';

  @override
  String get userMgmtBulkActionsTooltip => '批量操作';

  @override
  String get userMgmtBulkActionsLabel => '批量操作';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return '显示第 $from 至 $to 项，共 $total 个用户';
  }

  @override
  String get userMgmtNoUsersFoundMessage => '未找到用户';

  @override
  String get userMgmtAddNewUserTitle => '添加新用户';

  @override
  String get userMgmtEditUserTitle => '编辑用户';

  @override
  String get userMgmtUsernameRequiredLabel => '用户名 *';

  @override
  String get userMgmtEnterUsernameHint => '输入用户名';

  @override
  String get userMgmtUsernameRequiredMessage => '用户名为必填项';

  @override
  String get userMgmtUsernameMinLengthMessage => '用户名至少需要3个字符';

  @override
  String get userMgmtPasswordRequiredLabel => '密码 *';

  @override
  String get userMgmtEnterPasswordHint => '输入密码';

  @override
  String get userMgmtPasswordRequiredMessage => '密码为必填项';

  @override
  String get userMgmtMinimum6CharsMessage => '至少6个字符';

  @override
  String get userMgmtRoleRequiredLabel => '角色 *';

  @override
  String get userMgmtRoleRequiredMessage => '角色为必填项';

  @override
  String get userMgmtSaveUserButton => '保存用户';

  @override
  String get userMgmtThisIsYourAccountMessage => '这是您的账户';

  @override
  String get invoiceSettingsAppBarTitle => '发票设置';

  @override
  String get invoiceSettingsSavedMessage => '发票设置已成功保存！';

  @override
  String get invoiceSettingsSignatureTooLargeMessage => '签名图片必须小于 2 MB。';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage => '水印图片必须小于 2 MB。';

  @override
  String get invoiceSettingsSectionGeneral => '常规';

  @override
  String get invoiceSettingsSectionBranding => '品牌';

  @override
  String get invoiceSettingsSectionTax => '税费与 GST';

  @override
  String get invoiceSettingsSectionItems => '发票项目';

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
  String get invoiceSettingsPrefixLabel => '发票前缀';

  @override
  String get invoiceSettingsStartingNumberHelper => '第一张发票将从此编号开始';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      '存在发票时无法更改起始编号。请永久删除所有发票/报价单（包括回收站）后重试。';

  @override
  String get invoiceSettingsQuantityColumnLabel => '数量列标签';

  @override
  String get invoiceSettingsQuantityColumnHint => '例如 Words、Hours、Units';

  @override
  String get invoiceSettingsQuantityColumnHelper => '留空以使用默认值 \"Qty\"';

  @override
  String get invoiceSettingsAdditionalInfoLabel => '附加信息';

  @override
  String get invoiceSettingsThankYouNoteLabel => '感谢语';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel => '默认隐藏发票编号';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      '创建新发票时默认启用「在 PDF 中隐藏发票编号」。';

  @override
  String get invoiceSettingsTaxRateHint => '例如 18';

  @override
  String get invoiceSettingsTaxRateHelper => '适用于新发票';

  @override
  String get invoiceSettingsTaxEnabledLabel => '默认启用税费';

  @override
  String get invoiceSettingsTaxEnabledSubtitle => '创建新发票时默认启用税费开关。';

  @override
  String get invoiceSettingsTaxModeLabel => '默认税率模式';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly => '仅适用于新发票';

  @override
  String get invoiceSettingsTaxModeGlobal => '整体';

  @override
  String get invoiceSettingsTaxModePerItem => '按项目';

  @override
  String get invoiceSettingsShowGstFieldsLabel => '显示 GST 字段';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      '在发票、PDF 和 CSV 导出中显示 GSTIN 字段（HSN/SAC）';

  @override
  String get invoiceSettingsShowCgstSgstLabel => '显示 CGST/SGST';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      '在发票上将税费拆分为 CGST + SGST（仅限印度）。';

  @override
  String get invoiceSettingsDefaultGstTitleLabel => '默认 GST 发票标题';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel => '默认税费发票标题';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      '在新发票上预选 — 例如 GST 综合计税方案商家使用 \"Bill of Supply\"';

  @override
  String get invoiceSettingsGstTitleHelperGeneric => '在新发票上预选';

  @override
  String get invoiceSettingsShowRoundOffLabel => '显示取整';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      '在发票 PDF 上显示取整行 + 净额（就近取整）及大写金额。';

  @override
  String get invoiceSettingsShowAliasNameLabel => '在 PDF 中显示别名';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      '在 PDF 上打印产品的本地语言别名（如已设置）而非其实际名称';

  @override
  String get invoiceSettingsShowDescriptionLabel => '显示产品描述';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      '在 A4 PDF 中将每个项目的描述作为其下方的一行打印（不适用于热敏收据）';

  @override
  String get invoiceSettingsDescriptionNewLineLabel => '描述另起一行';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      '将描述作为项目下方的整行打印，而不是名称下方的一行';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel => '允许小数数量';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      '启用小数数量（例如 1.5 小时、0.5 千克）';

  @override
  String get invoiceSettingsShowQuantityLabel => '显示数量字段';

  @override
  String get invoiceSettingsShowQuantitySubtitle => '为基于服务的计费隐藏数量；价格列变为「单价」';

  @override
  String get invoiceSettingsShowDiscountLabel => '显示折扣列';

  @override
  String get invoiceSettingsShowDiscountSubtitle => '为不使用逐项折扣的客户隐藏折扣列';

  @override
  String get invoiceSettingsShowTypeTagLabel => '显示产品/服务标签';

  @override
  String get invoiceSettingsShowTypeTagSubtitle => '在每个发票项目上显示或隐藏产品/服务标签';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel => '允许重复的发票项目';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle => '允许将同一产品多次添加到发票中';

  @override
  String get invoiceSettingsShowPrevBalanceLabel => '显示以前的欠款余额';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle => '在发票 PDF 上显示计算出的先前未结余额';

  @override
  String get invoiceSettingsLogoPositionLabel => '公司徽标位置';

  @override
  String get invoiceSettingsLogoSizeLabel => '公司徽标大小';

  @override
  String get commonLeftLabel => '左';

  @override
  String get commonRightLabel => '右';

  @override
  String get invoiceSettingsSignatureImageLabel => '签名图片';

  @override
  String get invoiceSettingsSignatureImageSubtitle => '作为授权签名打印在发票上';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG、JPG 或 JPEG — 最大 2 MB';

  @override
  String get invoiceSettingsChangeSignatureButton => '更换签名';

  @override
  String get invoiceSettingsUploadSignatureButton => '上传签名';

  @override
  String get invoiceSettingsSignatureSizeLabel => '签名大小';

  @override
  String get invoiceSettingsSignaturePositionLabel => '签名位置';

  @override
  String get invoiceSettingsWatermarkImageLabel => '水印图片';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      '显示在发票 PDF 的项目表格后面（不会打印在热敏小票上）';

  @override
  String get invoiceSettingsChangeWatermarkButton => '更换水印';

  @override
  String get invoiceSettingsUploadWatermarkButton => '上传水印';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return '不透明度：$value%';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value%';
  }

  @override
  String get invoiceSettingsPromoTitle => '需要在发票上添加更多字段吗？';

  @override
  String get invoiceSettingsPromoBody => '添加采购单号、项目代码、部门或任何自定义字段。';

  @override
  String get invoiceSettingsPromoButton => '查看选项';

  @override
  String get pdfSettingsTitle => 'PDF 设置';

  @override
  String get pdfSettingsSubtitle => '自定义发票、报价单和收据的 PDF 模板';

  @override
  String get pdfSettingsResetToDefaultButton => '恢复默认';

  @override
  String get pdfSettingsSaveSettingsButton => '保存设置';

  @override
  String get pdfSettingsTemplatesLabel => '模板';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return '$pageSize 没有可用模板';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'PDF 设置已保存';

  @override
  String get commonActiveLabel => '使用中';

  @override
  String get commonUnavailableLabel => '不可用';

  @override
  String get pdfSettingsDisplayOptionsLabel => '显示选项';

  @override
  String get pdfSettingsShowTotalQtyRowLabel => '显示总数量行';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => '项目布局';

  @override
  String get pdfSettingsItemLayoutTableLabel => '表格';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => '详细';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      '表格：每个项目一行（序号/名称/数量/单价/总计）。详细：名称单独一行，下方显示数量/单价/总计。';

  @override
  String get pdfSettingsCompanyNameSizeLabel => '公司名称大小';

  @override
  String get pdfSettingsThemeColorLabel => '主题颜色';

  @override
  String get pdfSettingsHexErrorText => '请使用 #RRGGBB 格式';

  @override
  String get pdfSettingsPickColorTooltip => '打开取色器';

  @override
  String get pdfSettingsPickThemeColorDialogTitle => '选择主题颜色';

  @override
  String get pdfSettingsPreviewDisclaimer => '预览可能与最终 PDF 略有差异。';

  @override
  String get pdfSettingsCustomTemplatePromoTitle => '需要自定义模板吗？';

  @override
  String get pdfSettingsCustomTemplatePromoBody => '获取与您品牌相匹配的设计——颜色、字体和布局。';

  @override
  String get pdfSettingsCustomizationOptionsButton => '自定义选项';

  @override
  String get pdfTemplateClassicName => '经典';

  @override
  String get pdfTemplateClassicDescription => '结构简洁的传统布局';

  @override
  String get pdfTemplateModernName => '现代';

  @override
  String get pdfTemplateModernDescription => '具有现代风格的醒目页眉';

  @override
  String get pdfTemplateMinimalName => '简约';

  @override
  String get pdfTemplateMinimalDescription => '简单、无干扰';

  @override
  String get pdfTemplateExecutiveName => '行政';

  @override
  String get pdfTemplateExecutiveDescription => '带有结构化账单模块的高端商务布局';

  @override
  String get pdfTemplateCompactName => '紧凑';

  @override
  String get pdfTemplateCompactDescription => '节省空间的收据布局，适合 A6 打印';

  @override
  String get pdfTemplateThermalName => '热敏';

  @override
  String get pdfTemplateThermalDescription => '适用于 80mm 和 58mm 热敏打印机的窄幅收据布局';

  @override
  String get pdfTemplateGridClassicName => '经典网格';

  @override
  String get pdfTemplateGridClassicDescription => '旧式带边框表格账单，适用于 A4、A5 和 A6';

  @override
  String get companyInfoAppBarTitle => '公司信息';

  @override
  String get companyInfoUploadLogoLabel => '上传徽标';

  @override
  String get companyInfoClickToBrowseLabel => '点击浏览';

  @override
  String get companyInfoRemoveLogoButton => '移除徽标';

  @override
  String get companyInfoShowOnPdfLabel => '在PDF中显示';

  @override
  String get companyInfoLogoRequirementsHint =>
      '最大 1080×1080 px · 2 MB\n仅限 PNG 或 JPG';

  @override
  String get companyInfoLogoSectionLabel => '公司徽标';

  @override
  String get companyInfoDetailsSectionLabel => '公司详情';

  @override
  String get companyInfoBusinessTypeSectionLabel => '业务类型';

  @override
  String get companyInfoPaymentSettingsSectionLabel => '付款设置';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'UPI账户';

  @override
  String get companyInfoBankAccountsSectionLabel => '银行账户';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => '税号/增值税号';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'FSSAI 代码';

  @override
  String get companyInfoPhoneHelperText => '多个号码请用逗号分隔';

  @override
  String get fieldWebsiteLabel => '网站';

  @override
  String get companyInfoBusinessTypeTitle => '业务类型';

  @override
  String get companyInfoBusinessTypeSubtitle => '控制产品列表和发票中的项目类型选项';

  @override
  String get labelBoth => '两者';

  @override
  String get companyInfoSetAsDefaultTooltip => '设为默认';

  @override
  String get companyInfoUpiIdLabel => 'UPI ID';

  @override
  String get companyInfoAddUpiAccountButton => '添加UPI账户';

  @override
  String get companyInfoShowQrToggleTitle => '在发票上显示二维码';

  @override
  String get companyInfoShowQrToggleSubtitle => '在生成的PDF中添加可扫描的UPI支付二维码';

  @override
  String get companyInfoShowBankDetailsToggleTitle => '在发票上显示银行信息';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle => '在生成的PDF上打印银行账户信息';

  @override
  String get fieldBankNameLabel => '银行名称';

  @override
  String get fieldAccountNumberLabel => '账号';

  @override
  String get fieldIfscCodeLabel => 'IFSC 代码';

  @override
  String get companyInfoAddBankAccountButton => '添加银行账户';

  @override
  String get tooltipShowOnInvoicePdf => '在发票PDF中显示';

  @override
  String get companyInfoSavedSuccessMessage => '公司信息保存成功';

  @override
  String get companyInfoImageTooLargeMessage => '图片文件必须小于2 MB。';

  @override
  String get companyInfoInvalidImageMessage => '图片文件无效。';

  @override
  String get companyInfoImageDimensionsMessage => '图片最大尺寸必须为1080x1080像素。';

  @override
  String get companyInfoHintExampleBankName => '例如 HDFC银行';

  @override
  String get companyInfoHintExampleAccountLabel => '例如 主账户';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionShare => '分享';

  @override
  String get appInfoTitle => '软件信息';

  @override
  String get appInfoAppDetailsTitle => '应用详情';

  @override
  String get appInfoAppNameLabel => '应用名称';

  @override
  String get appInfoVersionLabel => '版本';

  @override
  String get appInfoLicenseLabel => '许可证';

  @override
  String get appInfoDeveloperTitle => '开发者';

  @override
  String get appInfoDeveloperLabel => '开发者';

  @override
  String get appInfoSupportEmailLabel => '支持邮箱';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  基于 $license 许可证发布';
  }

  @override
  String get appInfoCheckingLabel => '检查中...';

  @override
  String get appInfoUpdateAvailableLabel => '有可用更新';

  @override
  String get appInfoUpToDateLabel => '已是最新版本';

  @override
  String get appInfoCheckFailedLabel => '检查失败';

  @override
  String get appInfoUpdatesTitle => '更新';

  @override
  String get appInfoCurrentVersionLabel => '当前版本';

  @override
  String get appInfoLatestVersionLabel => '最新版本';

  @override
  String get appInfoCheckNowButton => '立即检查';

  @override
  String get backupManagementTitle => '备份管理';

  @override
  String get backupCreateDbButton => '创建数据库备份';

  @override
  String get backupExportJsonButton => '导出 JSON';

  @override
  String get backupImportButton => '导入备份';

  @override
  String get backupNoBackupsFoundMessage => '未找到备份';

  @override
  String backupSizeLabel(String size) {
    return '大小：$size';
  }

  @override
  String backupCreatedLabel(String date) {
    return '创建时间：$date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return '加载备份失败：$error';
  }

  @override
  String get backupCreatedSuccessMessage => '备份创建成功！';

  @override
  String backupCreateErrorMessage(String error) {
    return '创建备份失败：$error';
  }

  @override
  String get backupRestoreConfirmTitle => '恢复备份';

  @override
  String get backupRestoreConfirmBody => '这将用备份替换所有当前数据。确定要继续吗？';

  @override
  String backupRestoreErrorMessage(String error) {
    return '恢复备份失败：$error';
  }

  @override
  String get backupDeleteConfirmTitle => '删除备份';

  @override
  String get backupDeleteConfirmBody => '确定要删除此备份吗？';

  @override
  String get backupDeletedSuccessMessage => '备份删除成功！';

  @override
  String get backupDeleteFailedMessage => '删除备份失败';

  @override
  String backupDeleteErrorMessage(String error) {
    return '删除备份失败：$error';
  }

  @override
  String get backupSavedToDownloadsMessage => '备份已保存到下载文件夹。';

  @override
  String backupDownloadErrorMessage(String error) {
    return '下载备份失败：$error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return '分享备份失败：$error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return '导入备份失败：$error';
  }

  @override
  String get backupRestoreSuccessTitle => '恢复成功';

  @override
  String get backupRestoreSuccessBody =>
      '数据库已成功恢复。\n\n应用需要重启以应用更改。请关闭并重新打开应用程序。';

  @override
  String get backupCloseLaterButton => '稍后关闭';

  @override
  String get backupCloseAppNowButton => '立即关闭应用';

  @override
  String get commonSuccessTitle => '成功';

  @override
  String get commonErrorTitle => '错误';

  @override
  String get productColumnsScreenTitle => '自定义产品详情';

  @override
  String get productColumnsSavedMessage => '产品列已保存。';

  @override
  String get productColumnsIntroText =>
      '选择在产品新增/编辑表单、产品列表和发票明细项中显示哪些字段。名称和价格始终为必填项。';

  @override
  String get productColumnsNameLabel => '名称';

  @override
  String get productColumnsPriceLabel => '价格';

  @override
  String get productColumnsAlwaysRequiredSubtitle => '始终显示 — 必填。';

  @override
  String get productColumnsStockLabel => '库存';

  @override
  String get productColumnsStockSubtitle => '如果您从不追踪库存，请关闭此项 — 产品将默认为无限库存。';

  @override
  String get productColumnsProductFieldsSectionTitle => '产品字段';

  @override
  String get productColumnsAliasNameLabel => '别名';

  @override
  String get productColumnsAliasNameSubtitle => '用于 PDF/打印的本地语言显示名称。';

  @override
  String get productColumnsTaxRateLabel => '税率';

  @override
  String get productColumnsTaxRateSubtitle => '按产品设置的税率百分比。';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'HSN 或 SAC 代码字段。';

  @override
  String get productColumnsDescriptionLabel => '描述';

  @override
  String get productColumnsDescriptionSubtitle => '自由文本产品描述。';

  @override
  String get productColumnsPurchasePriceLabel => '采购价';

  @override
  String get productColumnsPurchasePriceSubtitle => '成本价，用于利润追踪。';

  @override
  String get productColumnsDefaultDiscountLabel => '默认折扣';

  @override
  String get productColumnsDefaultDiscountSubtitle => '将此产品添加到发票时预填的折扣。';

  @override
  String get productColumnsUnitLabel => '单位';

  @override
  String get productColumnsUnitSubtitle => '计量单位（个、公斤、小时……）。';

  @override
  String get productColumnsProductServiceTypeLabel => '产品/服务类型';

  @override
  String get productColumnsProductServiceTypeSubtitle => '产品与服务的分段选择器。';

  @override
  String get productColumnsMetadataLabel => '产品元数据';

  @override
  String get productColumnsMetadataSubtitle =>
      '存储位置、集装箱/批次号、有效期、生产日期、供应商、SKU、备注。';

  @override
  String get productColumnsMetaStorageLocationLabel => '存储位置';

  @override
  String get productColumnsMetaContainerNumberLabel => '集装箱号';

  @override
  String get productColumnsMetaBatchNumberLabel => '批次号';

  @override
  String get productColumnsMetaExpiryDateLabel => '有效期';

  @override
  String get productColumnsMetaManufactureDateLabel => '生产日期';

  @override
  String get productColumnsMetaSupplierNameLabel => '供应商名称';

  @override
  String get productColumnsMetaSkuCodeLabel => 'SKU 代码';

  @override
  String get productColumnsMetaNotesLabel => '备注';

  @override
  String get productColumnsExtraCostLabel => '额外费用';

  @override
  String get productColumnsExtraCostSubtitle => '发票明细项上可选的固定额外费用。';

  @override
  String get settingsOptionsComingSoonMessage => '更多选项即将推出...';

  @override
  String get settingsNavCompanyInfoLabel => '公司信息';

  @override
  String get settingsNavTeamLabel => '团队';

  @override
  String get settingsNavBackupLabel => '备份';

  @override
  String get settingsNavUsersLabel => '用户';

  @override
  String get settingsNavProductDetailsLabel => '产品详情';

  @override
  String get settingsNavCustomizeLabel => '自定义';

  @override
  String get settingsNavAccessibilityLabel => '无障碍';

  @override
  String get settingsNavSoftwareInfoLabel => '软件信息';

  @override
  String get customizationEyebrowLabel => '定制服务';

  @override
  String get customizationHeadline => '为您的业务量身定制';

  @override
  String get customizationSubtitle => '选择您需要的内容并发送请求。我们将在24小时内回复您。';

  @override
  String get customizationRecommendedBadge => '推荐';

  @override
  String customizationDeliveryLabel(String delivery) {
    return '交付时间：$delivery';
  }

  @override
  String get customizationRequestButton => '申请';

  @override
  String get customizationFormOpenErrorMessage =>
      '无法打开表单。请在浏览器中访问 forms.gle/LyX6Z2kBNR2BpwVu7。';

  @override
  String get customizationDisclaimerMessage =>
      '价格仅供参考。最终报价可能因复杂程度而异。付款将在确认范围后收取。';

  @override
  String get customizationPdfTemplateTitle => '定制PDF模板';

  @override
  String get customizationPdfTemplateDescription =>
      '获取符合您品牌的发票模板——您的颜色、字体、徽标位置和布局。';

  @override
  String get customizationPdfTemplateDelivery => '2–5 天';

  @override
  String get customizationCustomFieldsTitle => '自定义字段';

  @override
  String get customizationCustomFieldsDescription =>
      '需要在发票上添加额外字段吗？（采购订单号、项目代码、部门等）我们将为您添加。';

  @override
  String get customizationCustomFieldsDelivery => '1–3 天';

  @override
  String get customizationWhiteLabelTitle => '白标 / 移除品牌标识';

  @override
  String get customizationWhiteLabelDescription =>
      '从应用和PDF输出中移除所有Invoiso品牌标识，替换为您自己的企业标识。';

  @override
  String get customizationWhiteLabelDelivery => '3–6 天';

  @override
  String get customizationIndustryBuildTitle => '行业定制版本';

  @override
  String get customizationIndustryBuildDescription =>
      '需要针对您行业定制的版本吗？（建筑、咨询、零售等）我们将根据您的需求定制工作流程。';

  @override
  String get customizationIndustryBuildDelivery => '5–10 天';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle => '新建发票页面布局';

  @override
  String get accessibilityClassicLayoutLabel => '经典布局';

  @override
  String get accessibilityNewLayoutLabel => '新布局';

  @override
  String get accessibilityLayoutDescription => '选择要使用的“新建发票”界面设计。';

  @override
  String get accessibilityShortcutsSubtitle => '无需使用鼠标即可加快发票创建速度。';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => '发票总额';

  @override
  String get paymentDialogAmountPaidLabel => '已付金额';

  @override
  String get paymentDialogHistoryTitle => '付款历史';

  @override
  String get paymentDialogNoPaymentsMessage => '尚未记录任何付款';

  @override
  String get paymentDialogFullyPaidExclaimMessage => '发票已全部付清!';

  @override
  String get paymentDialogFullyPaidBannerLabel => '发票已全部付清';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return '付款已记录。未结清: $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return '记录付款失败: $error';
  }

  @override
  String get paymentDialogDeleteTitle => '删除付款';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return '删除收据 $receiptNumber？\n\n此操作无法撤销。';
  }

  @override
  String get paymentDialogNewPaymentTitle => '新付款';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return '金额 ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return '最多: $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError => '请输入有效金额';

  @override
  String get paymentDialogExceedsOutstandingError => '超过未结清余额';

  @override
  String get paymentDialogMethodFieldLabel => '付款方式';

  @override
  String get paymentDialogSelectMethodHint => '选择方式';

  @override
  String get paymentDialogTaxCoveredLabel => '已含税额';

  @override
  String get paymentDialogAutoCalculatedHelper => '自动计算';

  @override
  String get paymentDialogNotesFieldLabel => '备注 (可选)';

  @override
  String get paymentDialogNotesHint => '例如：支票号、交易 ID...';

  @override
  String get paymentDialogReceiptColLabel => '收据编号';

  @override
  String get paymentDialogMethodColLabel => '方式';

  @override
  String get paymentDialogDownloadReceiptTooltip => '下载收据';

  @override
  String get paymentDialogDeletePaymentTooltip => '删除付款';

  @override
  String get paymentMethodCash => '现金';

  @override
  String get paymentMethodBankTransfer => '银行转账';

  @override
  String get paymentMethodCheck => '支票';

  @override
  String get paymentMethodOnline => '在线支付';

  @override
  String get paymentMethodOther => '其他';

  @override
  String get customerInfoButtonTooltip => '查看联系方式';

  @override
  String get customerInfoButtonNoContactMessage => '暂无联系方式。';

  @override
  String get updateDialogTitle => '有可用更新';

  @override
  String get updateDialogBodyMessage => 'invoiso 有新版本可用。请访问下载页面获取最新版本。';

  @override
  String get pageSizeA4Label => '标准 A4';

  @override
  String get pageSizeA5Label => '标准 A5';

  @override
  String get pageSizeA6Label => '标准 A6';

  @override
  String get pageSizeThermal80Label => '热敏纸 80mm';

  @override
  String get pageSizeThermal58Label => '热敏纸 58mm';

  @override
  String get dateFormatDdmmyyyyLabel => 'DD/MM/YYYY（例如 15/04/2026）';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/DD/YYYY（例如 04/15/2026）';

  @override
  String get dateFormatDdMmmyyyyLabel => 'DD MMM YYYY（例如 15 Apr 2026）';

  @override
  String get dateFormatYyyymmddLabel => 'YYYY-MM-DD（例如 2026-04-15）';

  @override
  String get sizeXSmallLabel => '特小';

  @override
  String get sizeSmallLabel => '小';

  @override
  String get sizeMediumLabel => '中';

  @override
  String get sizeLargeLabel => '大';

  @override
  String get shortcutNewInvoiceDescription => '新建发票（从仪表盘）／重置表单（在创建发票中）';

  @override
  String get shortcutSaveInvoiceDescription => '保存／创建发票';

  @override
  String get shortcutAddProductDescription => '向发票添加产品';

  @override
  String get shortcutAddCustomItemDescription => '添加自定义项目';

  @override
  String get shortcutPreviewPdfDescription => '预览发票 PDF';

  @override
  String get shortcutPrintPdfDescription => '生成／打印发票 PDF';
}
