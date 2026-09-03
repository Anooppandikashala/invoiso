// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Invoiso';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSkip => 'Omitir';

  @override
  String get actionNext => 'Siguiente';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionGetStarted => 'Comenzar';

  @override
  String get commonLanguage => 'Idioma';

  @override
  String get commonBeta => 'Beta';

  @override
  String get commonSystemDefault => 'Predeterminado del sistema';

  @override
  String get commonTheme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get onboardingStepCompanyTitle => 'Empresa';

  @override
  String get onboardingStepCompanySubtitle => 'Cuéntanos sobre tu empresa';

  @override
  String get onboardingStepInvoiceTitle => 'Configuración de facturas';

  @override
  String get onboardingStepInvoiceSubtitle =>
      'Configura cómo funcionan tus facturas';

  @override
  String get onboardingStepAppearanceTitle => 'Apariencia de la factura';

  @override
  String get onboardingStepAppearanceSubtitle =>
      'Elige un tamaño de página y una plantilla';

  @override
  String get onboardingStepDoneTitle => 'Todo listo';

  @override
  String get onboardingCompanyNameLabel => 'Nombre de la empresa';

  @override
  String get onboardingCountryLabel => 'País';

  @override
  String get onboardingLogoLabel => 'Logo de la empresa';

  @override
  String get onboardingCurrencyLabel => 'Moneda';

  @override
  String get onboardingDateFormatLabel => 'Formato de fecha';

  @override
  String get onboardingInvoiceStartingNumberLabel =>
      'Número inicial de factura';

  @override
  String get onboardingLeadingZerosLabel => 'Ceros a la izquierda';

  @override
  String get onboardingLeadingZerosSubtitle =>
      'Rellenar los números de factura a 8 dígitos (ej. 00000007)';

  @override
  String get onboardingDefaultTaxRateLabel =>
      'Tasa de impuesto predeterminada (%)';

  @override
  String get onboardingPageSizeLabel => 'Tamaño de página';

  @override
  String get onboardingTemplateLabel => 'Plantilla de factura';

  @override
  String get onboardingDoneHeadline => '¡Todo listo!';

  @override
  String get onboardingDoneBody =>
      'Los datos de tu empresa, facturas y plantilla están guardados. Puedes actualizarlos en cualquier momento desde Configuración.';

  @override
  String get splashInitErrorTitle => 'Error de inicialización';

  @override
  String splashInitErrorMessage(String error) {
    return 'Error al inicializar la base de datos.\n\n$error';
  }

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get splashInitializingMessage => 'Inicializando la aplicación...';

  @override
  String get testGateNoInternetTitle =>
      'El instalador de prueba necesita acceso a internet para verificar.';

  @override
  String get testGateExpiredTitle => 'Esta compilación de prueba ha caducado.';

  @override
  String get testGateNoInternetSubtitle =>
      'Conéctate a internet e inténtalo de nuevo.';

  @override
  String testGateExpiredSubtitle(String email) {
    return 'Contacta con soporte: $email';
  }

  @override
  String get dashboardSessionExpiredMessage =>
      'Sesión expirada por inactividad.';

  @override
  String get dashboardUnknownTabLabel => 'Pestaña desconocida';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return 'Diseño de factura: $layout — toca para más información';
  }

  @override
  String get dashboardLayoutNew => 'Nuevo';

  @override
  String get dashboardLayoutClassic => 'Clásico';

  @override
  String get dashboardInvoiceLayoutDialogTitle => 'Diseño de factura';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return 'Estás usando el diseño $layout de \"Nueva factura\". Puedes cambiarlo desde Configuración > Accesibilidad. Nota: cambiarlo a mitad de edición descarta los cambios no guardados de este formulario.';
  }

  @override
  String get actionClose => 'Cerrar';

  @override
  String get dashboardOpenSettingsAction => 'Abrir configuración';

  @override
  String get dashboardCollapseSidebarTooltip => 'Contraer barra lateral';

  @override
  String get dashboardExpandSidebarTooltip => 'Expandir barra lateral';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navNewInvoice => 'Nueva factura';

  @override
  String get navInvoices => 'Facturas';

  @override
  String get navQuotations => 'Presupuestos';

  @override
  String get navReceipts => 'Recibos';

  @override
  String get navCustomers => 'Clientes';

  @override
  String get navProducts => 'Productos';

  @override
  String get navReports => 'Informes';

  @override
  String get navSettings => 'Configuración';

  @override
  String get dashboardRoleAdmin => 'Administrador';

  @override
  String get dashboardRoleUser => 'Usuario';

  @override
  String get dashboardSupportTooltip => 'Soporte';

  @override
  String get dashboardLogoutTooltip => 'Cerrar sesión';

  @override
  String get dashboardTestBuildBadge => 'VERSIÓN DE PRUEBA';

  @override
  String get dashboardTestBadgeShort => 'PRUEBA';

  @override
  String get dashboardKeyboardShortcutsTitle => 'Atajos de teclado';

  @override
  String get dashboardShortcutsBannerTitle => 'Nuevo: atajos de teclado';

  @override
  String get dashboardShortcutsBannerSubtitle =>
      'Ctrl+Q para una nueva factura, Ctrl+S para guardar, y más.';

  @override
  String get dashboardViewAllAction => 'Ver todo';

  @override
  String get dashboardLayoutBannerTitle => 'Nuevo: múltiples diseños de panel';

  @override
  String get dashboardLayoutBannerSubtitle =>
      'Cambia entre Predeterminado, Clásico, Bento y Feed simple usando el icono de cuadrícula arriba a la derecha.';

  @override
  String get actionGotIt => 'Entendido';

  @override
  String get dashboardThemeBannerTitle => 'Nuevo: modo oscuro';

  @override
  String get dashboardThemeBannerSubtitle =>
      'Seguimos puliéndolo — actívalo desde Configuración > Datos de la empresa y cuéntanos qué no se ve bien.';

  @override
  String dashboardSupportBannerTitle(String count) {
    return '¡Has creado $count facturas!';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      '¿Te gusta Invoiso? Una reseña rápida ayuda mucho.';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      'Parece que Invoiso forma parte de tu flujo de trabajo. Si te ha resultado útil, considera apoyar el proyecto — cuando te parezca bien.';

  @override
  String get dashboardReviewAction => 'Reseñar';

  @override
  String get dashboardSupportAction => 'Apoyar';

  @override
  String get dashboardOverviewTitle => 'Resumen del panel';

  @override
  String get actionRefresh => 'Actualizar';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count sin stock';
  }

  @override
  String get dashboardRevenueCollectedLabel => 'Ingresos cobrados';

  @override
  String get dashboardOutstandingLabel => 'Pendiente';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count vencidas';
  }

  @override
  String get dashboardRecentInvoicesTitle => 'Facturas recientes';

  @override
  String get dashboardLastFiveInvoicesLabel => 'Últimas 5 facturas';

  @override
  String get dashboardNoInvoicesYetTitle => 'Aún no hay facturas';

  @override
  String get dashboardNoInvoicesYetSubtitle =>
      'Crea tu primera factura para verla aquí';

  @override
  String get actionView => 'Ver';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get actionPdfPreview => 'Vista previa del PDF';

  @override
  String get actionDownloadPdf => 'Descargar PDF';

  @override
  String get actionPrint => 'Imprimir';

  @override
  String get actionPayment => 'Pago';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionRecordPayment => 'Registrar pago';

  @override
  String dashboardDueDateLabel(String date) {
    return 'Vence: $date';
  }

  @override
  String get labelInvoice => 'Factura';

  @override
  String get labelQuotation => 'Presupuesto';

  @override
  String get labelReceipt => 'Recibo';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return 'Bienvenido de nuevo, $username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle =>
      'Aquí tienes un vistazo de tu negocio';

  @override
  String get dashboardDueSoonTitle => 'Próximas a vencer';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas',
      one: '1 factura',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => 'Hoy y mañana';

  @override
  String get dashboardDueTodayBadge => 'Vence hoy';

  @override
  String get dashboardDueTomorrowBadge => 'Vence mañana';

  @override
  String get dashboardOverdueSectionTitle => 'Vencidas';

  @override
  String get dashboardOldestFirstLabel => 'Más antiguas primero';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días de retraso',
      one: '1 día de retraso',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => 'Nueva cantidad en stock';

  @override
  String get actionUpdate => 'Actualizar';

  @override
  String get labelService => 'Servicio';

  @override
  String get labelProduct => 'Producto';

  @override
  String dashboardStockLabel(int count) {
    return 'Stock: $count';
  }

  @override
  String get actionUpdateStock => 'Actualizar stock';

  @override
  String get paymentStatusPaid => 'Pagada';

  @override
  String get paymentStatusPartial => 'Parcial';

  @override
  String get paymentStatusUnpaid => 'Impagada';

  @override
  String get dashboardDuplicateInvoiceTitle => 'Duplicar factura';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return 'Crear una copia de la factura n.º $number\n($customerName) como:';
  }

  @override
  String get dashboardDeleteInvoiceTitle => 'Eliminar factura';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return '¿Seguro que deseas eliminar la factura n.º $number? Esta acción no se puede deshacer.';
  }

  @override
  String get dashboardLayoutTooltip => 'Diseño del panel';

  @override
  String get dashboardLayoutDefaultTitle => 'Predeterminado';

  @override
  String get dashboardLayoutDefaultSubtitle => 'Diseño original';

  @override
  String get dashboardLayoutClassicSubtitle => 'Gráficos + cuadrícula de KPI';

  @override
  String get dashboardLayoutBentoTitle => 'Bento';

  @override
  String get dashboardLayoutBentoSubtitle =>
      'Gráfico principal + cuadrícula de tarjetas';

  @override
  String get dashboardLayoutSimpleTitle => 'Feed simple';

  @override
  String get dashboardLayoutSimpleSubtitle => 'Vista de lista simple';

  @override
  String get dashboardTotalInvoicesLabel => 'Total de facturas';

  @override
  String get dashboardRevenueLast6MonthsTitle => 'Ingresos — últimos 6 meses';

  @override
  String get dashboardNoPaymentDataYetLabel => 'Aún no hay datos de pagos';

  @override
  String get dashboardFinancialOverviewTitle => 'Resumen financiero';

  @override
  String get dashboardCollectedLabel => 'Cobrado';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas vencidas',
      one: '1 factura vencida',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return 'Últimas $n';
  }

  @override
  String get labelCustomer => 'Cliente';

  @override
  String get labelAmount => 'Importe';

  @override
  String get dashboardZeroLeftLabel => '0 restantes';

  @override
  String get labelStock => 'Stock';

  @override
  String get actionPay => 'Pagar';

  @override
  String get dashboardQuickActionsTitle => 'Acciones rápidas';

  @override
  String get dashboardPdfActionsTooltip => 'Acciones de PDF';

  @override
  String get dashboardActionsTooltip => 'Acciones';

  @override
  String get dashboardTopCustomersTitle => 'Mejores clientes';

  @override
  String get dashboardTopProductsTitle => 'Mejores productos';

  @override
  String dashboardUnitsLabel(String qty) {
    return '$qty unidades';
  }

  @override
  String get dashboardBetaBadge => 'BETA';

  @override
  String get dashboardOutOfStockSectionTitle => 'Sin stock';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => 'Toca para reponer';

  @override
  String get createInvoiceUnsavedChangesTitle => 'Cambios sin guardar';

  @override
  String get createInvoiceUnsavedChangesMessage =>
      'Tiene cambios sin guardar en esta factura. ¿Guardarlos antes de salir?';

  @override
  String get createInvoiceKeepEditingButton => 'Seguir editando';

  @override
  String get actionDiscard => 'Descartar';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return 'Error al cargar los datos: $e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => 'Stock insuficiente';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return 'Solo hay $stock unidad(es) disponible(s). ¿Agregar $qty de todos modos?';
  }

  @override
  String get createInvoiceAddAnywayButton => 'Agregar de todos modos';

  @override
  String get createInvoiceOutOfStockTitle => 'Sin stock';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name está sin stock. ¿Agregar de todos modos?';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => 'Stock ilimitado';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return 'Stock disponible: $stock';
  }

  @override
  String get fieldDiscountLabel => 'Descuento';

  @override
  String get fieldUnitPriceOverrideLabel => 'Precio unitario (anular)';

  @override
  String get fieldExtraCostLabel => 'Costo adicional (opcional)';

  @override
  String get fieldInsertAtPositionLabel => 'Insertar en la posición';

  @override
  String get actionAdd => 'Agregar';

  @override
  String get createInvoiceProductAlreadyAddedMessage =>
      'Este producto ya fue agregado';

  @override
  String get createInvoiceCustomerNameRequiredMessage =>
      'Indique el nombre del cliente';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage =>
      'Agregue al menos un artículo';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '¡$invoiceTypeLabel creado(a) con éxito!';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return 'Error al crear la factura: $e';
  }

  @override
  String get createInvoiceEditItemTitle => 'Editar artículo';

  @override
  String get createInvoiceCustomItemTitle => 'Artículo personalizado';

  @override
  String get fieldItemNameLabel => 'Nombre del artículo';

  @override
  String get fieldAliasForPdfLabel => 'Alias (para el PDF)';

  @override
  String get fieldUnitPriceLabel => 'Precio unitario';

  @override
  String get fieldRateLabel => 'Tarifa';

  @override
  String get fieldTaxRateLabel => 'Tasa de impuesto (%)';

  @override
  String get fieldPriceIncludesTaxLabel => 'El precio incluye impuesto';

  @override
  String get createInvoicePhoneAlreadyInUseTitle =>
      'Número de teléfono ya en uso';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return 'Este número de teléfono pertenece a \"$ownerName\".\n\nNo se puede guardar este cliente con un número de teléfono que ya pertenece a otra persona.';
  }

  @override
  String get actionOk => 'Aceptar';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      'Ingrese un nombre de cliente antes de guardar';

  @override
  String get createInvoicePhoneChangedTitle => 'Número de teléfono cambiado';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return 'El número de teléfono de \"$name\" cambió.\n\n¿Actualizar su registro existente o guardar estos datos como un nuevo cliente?';
  }

  @override
  String get createInvoiceSaveAsNewButton => 'Guardar como nuevo';

  @override
  String get createInvoiceUpdateExistingButton => 'Actualizar existente';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '$name actualizado en la lista de clientes';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle => 'El cliente ya existe';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '\"$name\" ya está guardado con este número de teléfono.\n\n¿Usar sus datos existentes o actualizar su registro con la información actual?';
  }

  @override
  String get createInvoiceUseExistingButton => 'Usar existente';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return 'Usando cliente existente \"$name\"';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name guardado en la lista de clientes';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage =>
      'El registro del cliente ya no existe';

  @override
  String get createInvoiceCustomerRefreshedMessage =>
      'Datos del cliente actualizados';

  @override
  String get fieldLabelLabel => 'Etiqueta';

  @override
  String get hintLabelExample => 'ej. Envío';

  @override
  String get tooltipRemove => 'Quitar';

  @override
  String get createInvoiceAddRowButton => 'Agregar fila';

  @override
  String get fieldDiscountPerUnitLabel => 'Descuento por unidad';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn =>
      '(precio − descuento) × cant.';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff =>
      '(precio × cant.) − descuento';

  @override
  String get createInvoicePrevBalanceShortLabel => 'Saldo ant.';

  @override
  String get createInvoicePreviousBalanceDueLabel => 'Saldo anterior pendiente';

  @override
  String get createInvoiceDueShortLabel => 'Vence';

  @override
  String get createInvoiceTotalDueLabel => 'Total adeudado';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '¡$invoiceTypeLabel actualizado(a) con éxito!';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return 'Error al actualizar la factura: $e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '¡$invoiceTypeLabel creado(a) con éxito!';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return 'N.º de $invoiceTypeLabel: $invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => 'Ver detalles';

  @override
  String get createInvoicePreviewPdfLabel => 'Vista previa del PDF';

  @override
  String get createInvoicePreviewPdfTooltip =>
      'Vista previa del PDF (Atajo: Ctrl+o)';

  @override
  String get createInvoicePrintPdfLabel => 'Imprimir PDF';

  @override
  String get createInvoicePrintPdfTooltip => 'Imprimir PDF (Atajo: Ctrl+p)';

  @override
  String get actionDismiss => 'Descartar';

  @override
  String get createInvoiceCreateNewInvoiceButton =>
      'Crear nueva factura (Atajo: Ctrl+q)';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return 'Crear nuevo(a) $invoiceTypeLabel';
  }

  @override
  String get commonLoadingDataMessage => 'Cargando datos…';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage =>
      'Agregue al menos un artículo antes de crear la factura.';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel creado(a)';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return 'Editar $invoiceTypeLabel';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return 'Duplicar como $invoiceTypeLabel';
  }

  @override
  String get createInvoiceNewShortLabel => 'Nuevo';

  @override
  String get createInvoiceNewInvoiceShortcutLabel =>
      'Nueva factura (Atajo: Ctrl+q)';

  @override
  String get createInvoiceSavingEllipsisLabel => 'Guardando…';

  @override
  String get createInvoiceSaveCustomerLabel => 'Guardar cliente';

  @override
  String get createInvoiceSelectExistingCustomerButton =>
      'Seleccionar de los existentes';

  @override
  String get createInvoiceRefreshCustomerTooltip =>
      'Actualizar desde cliente guardado';

  @override
  String get createInvoiceClearCustomerTooltip => 'Borrar selección de cliente';

  @override
  String get fieldCustomerNameRequiredLabel => 'Nombre del cliente *';

  @override
  String get fieldBusinessNameLabel => 'Nombre de la empresa';

  @override
  String get fieldPhoneLabel => 'Teléfono';

  @override
  String get fieldGstinVatLabel => 'GSTIN / NIF-IVA';

  @override
  String get fieldEmailLabel => 'Correo electrónico';

  @override
  String get fieldAddressLabel => 'Dirección';

  @override
  String get tooltipEditInLargerView => 'Editar en vista ampliada';

  @override
  String get createInvoiceChooseCustomerTitle => 'Elegir un cliente';

  @override
  String get createInvoiceSearchCustomerLabel => 'Buscar cliente';

  @override
  String get createInvoiceNoCustomersFoundMessage =>
      'No se encontraron clientes';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return 'DETALLES DE $invoiceTypeLabel';
  }

  @override
  String get createInvoiceTypeFieldLabel => 'Tipo de factura';

  @override
  String get createInvoiceTypeLockedHelperText =>
      'El tipo no se puede cambiar después de crearla';

  @override
  String get createInvoiceOrderDateLabel => 'Fecha del pedido';

  @override
  String get createInvoiceDueDateLabel => 'Fecha de vencimiento';

  @override
  String get createInvoiceGstTitleLabel => 'Título GST';

  @override
  String get createInvoiceTaxTitleLabel => 'Título del impuesto';

  @override
  String get gstTitleTaxInvoiceLabel => 'Factura fiscal';

  @override
  String get gstTitleBillOfSupplyLabel => 'Nota de entrega';

  @override
  String get gstTitleInvoiceCumBillLabel => 'Factura y nota de entrega';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => 'Nota de crédito';

  @override
  String get gstTitleDebitNoteLabel => 'Nota de débito';

  @override
  String get gstTitleRevisedInvoiceLabel => 'Factura revisada';

  @override
  String get createInvoiceSearchProductLabel =>
      'Buscar y agregar un producto o servicio (Ctrl+F)';

  @override
  String get createInvoiceCustomItemButton => 'Artículo personalizado (Ctrl+M)';

  @override
  String get createInvoiceNoProductsFoundMessage =>
      'No se encontraron productos';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '\"$name\" ya existe en la lista de productos';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name guardado en la lista de productos';
  }

  @override
  String get createInvoiceSaveToProductListTooltip =>
      'Guardar en la lista de productos';

  @override
  String get tooltipEditItem => 'Editar artículo';

  @override
  String get tooltipRemoveItem => 'Quitar artículo';

  @override
  String get createInvoiceNoItemsAddedMessage =>
      'Aún no se agregaron artículos';

  @override
  String get createInvoiceSearchHintMessage => 'Busque abajo o presione Ctrl+F';

  @override
  String get createInvoiceDiscountFieldLabel => 'Descuento de la factura';

  @override
  String get discountTypeAmountShortLabel => 'Mto';

  @override
  String get createInvoiceNotesOptionalLabel => 'Notas (opcional)';

  @override
  String get createInvoiceNotesHint =>
      'Condiciones de pago, nota de agradecimiento…';

  @override
  String get createInvoiceNotesTitle => 'Notas';

  @override
  String get createInvoiceHideNumberInPdfLabel =>
      'Ocultar número de factura en el PDF';

  @override
  String get createInvoiceCustomNumberLabel =>
      'Número personalizado (opcional)';

  @override
  String get createInvoiceCustomNumberHint =>
      'ej. QUO-2026-014 — se muestra en el PDF en su lugar';

  @override
  String get createInvoiceEnableTaxLabel => 'Activar impuesto';

  @override
  String get createInvoiceGlobalRateTooltip => 'Tasa global';

  @override
  String get createInvoicePerItemRateTooltip => 'Tasa por artículo';

  @override
  String get createInvoiceDefaultTaxRateLabel =>
      'Tasa de impuesto predeterminada';

  @override
  String get createInvoiceTaxRateFromProductMessage =>
      'Tasa de impuesto de cada producto';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => 'Cuenta UPI de pago';

  @override
  String get commonNoneLabel => 'Ninguno';

  @override
  String get createInvoiceBankAccountLabel => 'Cuenta bancaria';

  @override
  String get fieldSubtotalLabel => 'Subtotal';

  @override
  String get createInvoiceDiscountColonLabel => 'Descuento:';

  @override
  String get fieldTaxLabel => 'Impuesto';

  @override
  String get createInvoiceExtraCostFallbackLabel => 'Costo adicional';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return 'Descuento de la factura ($toStringAsFixed%):';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel =>
      'Descuento de la factura:';

  @override
  String get fieldTotalLabel => 'Total';

  @override
  String get createInvoicePreviewLabel => 'Vista previa';

  @override
  String get createInvoicePreviewTooltip => 'Vista previa (Atajo: Ctrl+o)';

  @override
  String get createInvoiceDownloadLabel => 'Descargar';

  @override
  String get createInvoicePrintTooltip => 'Imprimir (Atajo: Ctrl+p)';

  @override
  String get fieldUnitOverrideLabel => 'Unidad (anular)';

  @override
  String get commonCustomEllipsisLabel => 'Personalizado…';

  @override
  String get fieldCustomUnitLabel => 'Unidad personalizada';

  @override
  String get invoiceMgmtMoveToTrashTitle => 'Mover a la papelera';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return '¿Mover la factura #$number a la papelera?';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage => 'Factura movida a la papelera.';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return 'Error al cargar las facturas: $error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return 'Exportar $type a CSV';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel => 'Exportar todos los registros';

  @override
  String get invoiceMgmtFilterByDateRangeLabel =>
      'O filtrar por rango de fechas:';

  @override
  String get invoiceMgmtFromDateLabel => 'Fecha desde';

  @override
  String get invoiceMgmtToDateLabel => 'Fecha hasta';

  @override
  String get invoiceMgmtDateRangeInvalidMessage =>
      'La fecha hasta debe ser posterior a la fecha desde.';

  @override
  String get actionExport => 'Exportar';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros exportados a: $path',
      one: '1 registro exportado a: $path',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Mover $count facturas a la papelera?',
      one: '¿Mover 1 factura a la papelera?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas movidas a la papelera.',
      one: '1 factura movida a la papelera.',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return 'Error al eliminar en lote: $error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas exportadas a CSV',
      one: '1 factura exportada a CSV',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'Error al exportar CSV: $error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => 'Descargar PDF';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Cómo desea guardar $count PDF?',
      one: '¿Cómo desea guardar 1 PDF?',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => 'Guardar en carpeta';

  @override
  String get invoiceMgmtSaveAsZipLabel => 'Guardar como ZIP';

  @override
  String get invoiceMgmtChooseFolderDialogTitle =>
      'Elegir carpeta para guardar los PDF';

  @override
  String get invoiceMgmtSaveZipDialogTitle => 'Guardar archivo ZIP';

  @override
  String get invoiceMgmtCreatingZipLabel => 'Creando ZIP';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => 'Generando PDF';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Procesando $count PDF...',
      one: 'Procesando 1 PDF...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return 'Guardado en: $path';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'Error al exportar PDF: $error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle => 'Descargar PDF por filtro';

  @override
  String get invoiceMgmtByDateLabel => 'Por fecha';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => 'Por número de factura';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => 'Desde factura n.°';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => 'Hasta factura n.°';

  @override
  String get invoiceMgmtCheckCountLabel => 'Verificar cantidad';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return '$count facturas — supera el límite de $limit';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas coinciden',
      one: '1 factura coincide',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return 'Máximo $limit PDF por descarga. Reduzca su filtro.';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage =>
      'No se encontraron facturas para el filtro seleccionado.';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return 'El filtro devolvió $count facturas — el máximo es $limit.';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => 'Filtrar facturas';

  @override
  String get invoiceMgmtHideFullyPaidLabel =>
      'Ocultar facturas totalmente pagadas';

  @override
  String get invoiceMgmtPaymentStatusLabel => 'Estado de pago';

  @override
  String get invoiceMgmtDueDateLabel => 'Fecha de vencimiento';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => 'Rango de fechas de factura';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel =>
      'Rango de números de factura';

  @override
  String get invoiceMgmtFromHashLabel => 'Desde n.°';

  @override
  String get invoiceMgmtToHashLabel => 'Hasta n.°';

  @override
  String get actionReset => 'Restablecer';

  @override
  String get actionApply => 'Aplicar';

  @override
  String get invoiceMgmtSortByTitle => 'Ordenar por';

  @override
  String get invoiceMgmtSearchHintMessage =>
      'Buscar por N.° de factura o nombre del cliente…';

  @override
  String get invoiceMgmtFilterLabel => 'Filtrar';

  @override
  String get invoiceMgmtSortLabel => 'Ordenar';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return 'Total: $total   ·   Página $page/$totalPages';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '$count seleccionado(s)';
  }

  @override
  String get invoiceMgmtDeselectLabel => 'Deseleccionar';

  @override
  String get invoiceMgmtSelectPageLabel => 'Seleccionar página';

  @override
  String get invoiceMgmtMarkPaidLabel => 'Marcar como pagado';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDF';

  @override
  String get invoiceMgmtTrashLabel => 'Papelera';

  @override
  String get actionApplyPayment => 'Aplicar pago';

  @override
  String get invoiceMgmtMoreActionsTooltip => 'Más acciones';

  @override
  String get invoiceMgmtColSlNo => 'N.°';

  @override
  String get invoiceMgmtColInvoiceCustomer => 'Factura / Cliente';

  @override
  String get invoiceMgmtColTitle => 'Título';

  @override
  String get invoiceMgmtColDate => 'Fecha';

  @override
  String get invoiceMgmtColItems => 'Artículos';

  @override
  String get invoiceMgmtColStatus => 'Estado';

  @override
  String get invoiceMgmtColOutstanding => 'Saldo pendiente';

  @override
  String get invoiceMgmtColActions => 'Acciones';

  @override
  String get invoiceMgmtRowsPerPageLabel => 'Filas por página:';

  @override
  String get actionPrevious => 'Anterior';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return 'Página $page de $totalPages';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return 'No se encontró(aron) $type';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return 'Crea tu primer(a) $type para verlo(a) aquí';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage =>
      'Intenta ajustar tu búsqueda o filtros';

  @override
  String get invoiceMgmtDownloadByRangeTooltip =>
      'Descargar PDF por fecha o rango de facturas';

  @override
  String get invoiceMgmtExportAllCsvTooltip => 'Exportar todo a CSV';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel => 'Descargar PDF por rango';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return 'Gestión de $type';
  }

  @override
  String get invoiceMgmtOverdueBadge => 'Vencida';

  @override
  String get invoiceMgmtTodayBadge => 'Hoy';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => 'La papelera está vacía';

  @override
  String get actionRestore => 'Restaurar';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => 'Eliminar permanentemente';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return '¿Eliminar permanentemente la factura #$number? Esto no se puede deshacer.';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage => 'Factura restaurada.';

  @override
  String get invoiceMgmtAnyDateLabel => 'Cualquiera';

  @override
  String get invoiceMgmtStatusAllLabel => 'Todos';

  @override
  String get invoiceMgmtDueAllLabel => 'Todos los vencimientos';

  @override
  String get invoiceMgmtDueTodayLabel => 'Vence hoy';

  @override
  String get invoiceMgmtDueWeekLabel => 'Vence esta semana';

  @override
  String get invoiceMgmtDueMonthLabel => 'Vence este mes';

  @override
  String get invoiceMgmtSortRecentlyAdded => 'Agregado recientemente';

  @override
  String get invoiceMgmtSortOldestAdded => 'Agregado hace más tiempo';

  @override
  String get invoiceMgmtSortDateNewest =>
      'Fecha de factura (más reciente primero)';

  @override
  String get invoiceMgmtSortDateOldest =>
      'Fecha de factura (más antigua primero)';

  @override
  String get invoiceMgmtSortCustomerAZ => 'Nombre del cliente (A–Z)';

  @override
  String get invoiceMgmtSortCustomerZA => 'Nombre del cliente (Z–A)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => 'Marcar como pagado';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Marcar $count facturas como totalmente pagadas?',
      one: '¿Marcar 1 factura como totalmente pagada?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n($count ya pagada(s) — se omitirá(n))';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage =>
      'Todas las facturas seleccionadas ya están totalmente pagadas.';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count facturas marcadas como pagadas.',
      one: '1 factura marcada como pagada.',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return 'Error al marcar como pagado: $error';
  }

  @override
  String get fieldNameLabel => 'Nombre';

  @override
  String get customerMgmtEditCustomerTitle => 'Editar cliente';

  @override
  String get customerMgmtViewCustomerTitle => 'Ver cliente';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / Número de IVA';
  }

  @override
  String get customerMgmtUpdatedMessage =>
      '¡Cliente actualizado correctamente!';

  @override
  String fieldRequiredMessage(String field) {
    return 'Por favor ingrese $field';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => 'Confirmar eliminación';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return '¿Está seguro de que desea eliminar \"$name\"?';
  }

  @override
  String get customerMgmtDeletedMessage => '¡Cliente eliminado correctamente!';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle => 'Guardar CSV de ejemplo';

  @override
  String get customerMgmtSampleSavedMessage =>
      '¡CSV de ejemplo guardado correctamente!';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return 'Error al guardar el ejemplo: $error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle => 'Importar clientes desde CSV';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      'Su archivo CSV debe usar los siguientes encabezados de columna (ortografía exacta, cualquier orden):';

  @override
  String get customerMgmtCsvColColumnHeader => 'Columna';

  @override
  String get customerMgmtCsvColRequiredHeader => 'Requerido';

  @override
  String get customerMgmtCsvColDescriptionHeader => 'Descripción';

  @override
  String get commonYesLabel => 'Sí';

  @override
  String get commonNoLabel => 'No';

  @override
  String get customerMgmtCsvDescName => 'Nombre completo del cliente';

  @override
  String get customerMgmtCsvDescEmail => 'Dirección de correo electrónico';

  @override
  String get customerMgmtCsvDescPhone => 'Número de teléfono';

  @override
  String get customerMgmtCsvDescAddress => 'Dirección completa';

  @override
  String get customerMgmtCsvDescBusinessName => 'Nombre de la empresa';

  @override
  String get customerMgmtCsvDescTaxNumber => 'Número de impuesto / IVA / GSTIN';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return 'Máximo $max filas por importación.';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      'Los duplicados se detectan por correo electrónico o teléfono. Se le pedirá que sobrescriba u omita cada uno.';

  @override
  String get customerMgmtCsvMissingNameNote =>
      'Las filas sin nombre se omiten y se informan al final.';

  @override
  String get customerMgmtCsvEncodingNote =>
      'Se recomienda codificación UTF-8. El BOM de Excel se maneja automáticamente.';

  @override
  String get customerMgmtDownloadSampleCsvButton => 'Descargar CSV de ejemplo';

  @override
  String get customerMgmtChooseFileButton => 'Elegir archivo';

  @override
  String get customerMgmtSelectCsvDialogTitle => 'Seleccionar CSV de clientes';

  @override
  String get customerMgmtCsvEmptyMessage => 'El archivo CSV está vacío.';

  @override
  String get customerMgmtCsvMissingNameColumnMessage =>
      'Falta la columna requerida en el CSV: \"name\"';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return 'Columna desconocida \"$col\". Se esperaba: $expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'El CSV tiene $count filas. El máximo es $max. Por favor divida el archivo.';
  }

  @override
  String get customerMgmtImportingTitle => 'Importando clientes';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Comprobando duplicados y validando $count filas...',
      one: 'Comprobando duplicados y validando 1 fila...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return 'Fila $n: falta el nombre — omitida';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return 'Error al leer el CSV: $error';
  }

  @override
  String get customerMgmtImportPreviewTitle => 'Vista previa de importación';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevos',
      one: '1 nuevo',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicados',
      one: '1 duplicado',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errores',
      one: '1 error',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel =>
      'Duplicados (coincidencia por correo o teléfono):';

  @override
  String get customerMgmtOverwriteAllButton => 'Sobrescribir todo';

  @override
  String get customerMgmtSkipAllButton => 'Omitir todo';

  @override
  String get customerMgmtOverwriteLabel => 'Sobrescribir';

  @override
  String get customerMgmtSkippedRowsLabel => 'Filas omitidas (errores):';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Se importarán $total clientes.',
      one: 'Se importará 1 cliente.',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return 'Importar $total';
  }

  @override
  String get customerMgmtDeleteAllTitle => 'Eliminar todos los clientes';

  @override
  String get customerMgmtNoCustomersToDeleteMessage =>
      'No hay clientes para eliminar.';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esto eliminará permanentemente los $count clientes. Las facturas existentes no se ven afectadas. Esto no se puede deshacer.',
      one:
          'Esto eliminará permanentemente 1 cliente. Las facturas existentes no se ven afectadas. Esto no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => 'Eliminar todo';

  @override
  String get customerMgmtAllDeletedMessage =>
      'Todos los clientes han sido eliminados.';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return 'Error al eliminar clientes: $error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => 'Guardar CSV de clientes';

  @override
  String get customerMgmtCsvExportedMessage => '¡CSV exportado correctamente!';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return 'Error al exportar el CSV: $error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => 'Guardar PDF de clientes';

  @override
  String get customerMgmtPdfExportedMessage => '¡PDF exportado correctamente!';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return 'Error al exportar el PDF: $error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => 'Total de clientes';

  @override
  String get customerMgmtAllCustomersSubtitle => 'Todos los clientes';

  @override
  String get customerMgmtBusinessesLabel => 'Empresas';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle => 'Empresas registradas';

  @override
  String get customerMgmtIndividualsLabel => 'Particulares';

  @override
  String get customerMgmtIndividualCustomersSubtitle => 'Clientes particulares';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '$taxWord registrados';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return 'Con número de $taxWord';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return 'Sin $taxWord';
  }

  @override
  String get customerMgmtTitle => 'Gestión de clientes';

  @override
  String get customerMgmtSubtitle =>
      'Gestione sus clientes y datos de contacto';

  @override
  String get actionImport => 'Importar';

  @override
  String get customerMgmtExportPdfMenuLabel => 'Exportar PDF';

  @override
  String get customerMgmtNewCustomerButton => 'Nuevo cliente';

  @override
  String get customerMgmtSortNameAZ => 'Nombre A-Z';

  @override
  String get customerMgmtSortNameZA => 'Nombre Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID (más antiguo primero)';

  @override
  String get customerMgmtSortIdNewest => 'ID (más reciente primero)';

  @override
  String get customerMgmtSortOutstandingHighLow =>
      'Saldo pendiente (mayor a menor)';

  @override
  String get customerMgmtSortOutstandingLowHigh =>
      'Saldo pendiente (menor a mayor)';

  @override
  String get customerMgmtWithOutstandingLabel => 'Con saldo pendiente';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return 'Buscar clientes por nombre, empresa, teléfono, $taxWord, correo…';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return 'Todos los estados de $taxWord';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '$taxWord registrados';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return 'Ordenar: $label';
  }

  @override
  String get customerMgmtColumnsLabel => 'Columnas';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / N.º IVA';
  }

  @override
  String get customerMgmtHideStatCardsTooltip =>
      'Ocultar tarjetas de estadísticas';

  @override
  String get customerMgmtShowStatCardsTooltip =>
      'Mostrar tarjetas de estadísticas';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get customerMgmtColSlNo => 'N.º';

  @override
  String get customerMgmtColNameBusiness => 'NOMBRE / EMPRESA';

  @override
  String get customerMgmtColPhone => 'TELÉFONO';

  @override
  String get customerMgmtColEmail => 'CORREO';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / N.º IVA';
  }

  @override
  String get customerMgmtColAddress => 'DIRECCIÓN';

  @override
  String get customerMgmtColActions => 'ACCIONES';

  @override
  String get customerMgmtViewStatementTooltip =>
      'Ver estado de cuenta (en Informes)';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return 'Mostrando $from a $to de $total clientes';
  }

  @override
  String get customerMgmtRowsPerPageLabel => 'Filas por página';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return 'de $totalPages';
  }

  @override
  String get customerMgmtAddAnotherLabel => 'Agregar otro después de guardar';

  @override
  String get customerMgmtSaveCustomerButton => 'Guardar cliente';

  @override
  String get customerMgmtAddFirstCustomerSubtitle =>
      'Agregue su primer cliente para comenzar';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle =>
      'Intente ajustar su búsqueda';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return 'Error al cargar clientes: $error';
  }

  @override
  String get customerMgmtAddedMessage => '¡Cliente agregado correctamente!';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return 'Error al guardar el cliente: $error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count clientes importados correctamente!',
      one: '¡1 cliente importado correctamente!',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return 'Error de importación: $error';
  }

  @override
  String get taxWordGst => 'GST';

  @override
  String get taxWordTax => 'Impuesto';

  @override
  String get commonMoreLabel => 'Más';

  @override
  String get productMgmtSellingAtLossTitle => 'Venta con pérdida';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return 'El precio de compra ($purchase) es mayor que el precio de venta ($sale). ¿Guardar de todos modos?';
  }

  @override
  String get actionSaveAnyway => 'Guardar de todos modos';

  @override
  String get productMgmtAdvancedInformationLabel => 'Información avanzada';

  @override
  String get productMgmtStorageLocationLabel => 'Ubicación de almacenamiento';

  @override
  String get productMgmtContainerNumberLabel => 'Número de contenedor';

  @override
  String get productMgmtBatchNumberLabel => 'Número de lote';

  @override
  String get productMgmtExpiryDateLabel => 'Fecha de caducidad';

  @override
  String get productMgmtManufactureDateLabel => 'Fecha de fabricación';

  @override
  String get productMgmtSupplierNameLabel => 'Nombre del proveedor';

  @override
  String get productMgmtSkuCodeLabel => 'Código SKU';

  @override
  String get productMgmtNotesLabel => 'Notas';

  @override
  String get fieldEnterValidPriceMessage => 'Introduce un precio válido';

  @override
  String get fieldEnterValidStockMessage => 'Introduce un stock válido';

  @override
  String get fieldTaxRangeMessage => 'El impuesto debe estar entre 0 y 100';

  @override
  String get productMgmtImportProductsCsvTitle =>
      'Importar productos desde CSV';

  @override
  String get productMgmtCsvDescName => 'Nombre del producto';

  @override
  String get productMgmtCsvDescPrice => 'Precio unitario (numérico)';

  @override
  String get productMgmtCsvDescHsnCode => 'Código HSN / SAC';

  @override
  String get productMgmtCsvDescDescription => 'Descripción breve';

  @override
  String get productMgmtCsvDescTaxRate =>
      'Impuesto % (0–100), predeterminado 0';

  @override
  String get productMgmtCsvDescStock => 'Cantidad en stock, predeterminado 0';

  @override
  String get productMgmtCsvDescType =>
      '«product» o «service», predeterminado product';

  @override
  String get productMgmtCsvDescDefaultDiscount =>
      'Importe de descuento fijo (moneda), predeterminado 0';

  @override
  String get productMgmtCsvDescPurchasePrice =>
      'Precio de costo (numérico), predeterminado 0';

  @override
  String get productMgmtCsvDescAliasName =>
      'Nombre de visualización en idioma local para los PDF';

  @override
  String get productMgmtCsvDescUnit =>
      'Unidad de medida (ej. kg, bolsa, uds), predeterminado pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock =>
      '1/true para stock ilimitado, predeterminado 0';

  @override
  String get productMgmtCsvDescPriceIncludesTax =>
      '1/true si el precio ya incluye impuestos, predeterminado 0';

  @override
  String get productMgmtCsvDescStorageLocation =>
      'Ubicación de almacén/estante';

  @override
  String get productMgmtCsvDescContainerNumber => 'Número de contenedor/caja';

  @override
  String get productMgmtCsvDescBatchNumber => 'Número de lote';

  @override
  String get productMgmtCsvDescExpiryDate => 'Fecha de caducidad';

  @override
  String get productMgmtCsvDescManufactureDate => 'Fecha de fabricación';

  @override
  String get productMgmtCsvDescSupplierName => 'Nombre del proveedor';

  @override
  String get productMgmtCsvDescSkuCode => 'Código SKU';

  @override
  String get productMgmtCsvDescNotes => 'Notas de texto libre';

  @override
  String get productMgmtCsvDuplicateNote =>
      'Los duplicados se detectan por el nombre del producto (sin distinguir mayúsculas). Se te preguntará si deseas sobrescribir u omitir cada uno.';

  @override
  String get productMgmtCsvMissingRequiredNote =>
      'Las filas sin nombre o precio se omiten y se informan.';

  @override
  String get productMgmtSelectCsvDialogTitle => 'Seleccionar CSV de productos';

  @override
  String get productMgmtCsvMissingPriceColumnMessage =>
      'Falta la columna requerida en el CSV: «price»';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return 'Fila $n: precio inválido «$price» — omitida';
  }

  @override
  String get productMgmtImportingTitle => 'Importando productos';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel =>
      'Duplicados (coincidentes por nombre):';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Se importarán $total productos.',
      one: 'Se importará 1 producto.',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage =>
      'No hay productos para eliminar.';

  @override
  String get productMgmtDeleteAllTitle => 'Eliminar todos los productos';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esto eliminará permanentemente los $count productos. Las facturas existentes no se ven afectadas. Esto no se puede deshacer.',
      one:
          'Esto eliminará permanentemente el único producto. Las facturas existentes no se ven afectadas. Esto no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage =>
      'Todos los productos han sido eliminados.';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return 'Error al eliminar productos: $error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle =>
      'Guardar CSV de productos';

  @override
  String get productMgmtExportToPdfTitle => 'Exportar a PDF';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return '¿Exportar la página actual ($pageSize productos) o los $allCount productos?';
  }

  @override
  String get productMgmtCurrentPageLabel => 'Página actual';

  @override
  String get productMgmtAllProductsLabel => 'Todos los productos';

  @override
  String get productMgmtSaveProductsPdfDialogTitle =>
      'Guardar PDF de productos';

  @override
  String get productMgmtTitle => 'Gestión de productos';

  @override
  String get productMgmtSubtitle => 'Gestiona tus productos y servicios';

  @override
  String get productMgmtNewProductButton => 'Nuevo producto';

  @override
  String get productMgmtSearchHint =>
      'Buscar productos por nombre, alias, HSN/SAC, SKU…';

  @override
  String get productMgmtFilterByStockStatusTooltip =>
      'Filtrar por estado de stock';

  @override
  String get productMgmtAllStockLevelsLabel => 'Todos los niveles de stock';

  @override
  String get productMgmtLowStockLabel => 'Stock bajo';

  @override
  String get productMgmtLowStockTabLabel => 'Stock bajo';

  @override
  String get productMgmtOutOfStockLabel => 'Sin stock';

  @override
  String get productMgmtOutOfStockTabLabel => 'Sin stock';

  @override
  String get productMgmtExpiredLabel => 'Caducado';

  @override
  String get productMgmtSortPriceLowHigh => 'Precio ascendente';

  @override
  String get productMgmtSortPriceHighLow => 'Precio descendente';

  @override
  String get productMgmtSortStockLowHigh => 'Stock ascendente';

  @override
  String get productMgmtSortStockHighLow => 'Stock descendente';

  @override
  String get productMgmtServicesTabLabel => 'Servicios';

  @override
  String get productMgmtColSlNo => 'N.° SEC.';

  @override
  String get productMgmtColNameAlias => 'NOMBRE / ALIAS';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => 'PRECIO';

  @override
  String get productMgmtColPurchase => 'COMPRA';

  @override
  String get productMgmtColStock => 'STOCK';

  @override
  String get productMgmtColTaxPercent => 'IMPUESTO %';

  @override
  String get productMgmtColExpiryDate => 'FECHA DE CADUCIDAD';

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
    return 'Mostrando $from a $to de $total productos';
  }

  @override
  String get productMgmtAddFirstProductSubtitle =>
      'Agrega tu primer producto para comenzar';

  @override
  String get productMgmtColumnsBannerTitle =>
      'Nuevo: personaliza los campos del producto';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      'Elige qué campos mostrar para un catálogo más simple. Configuración > Personalizar detalles del producto.';

  @override
  String get productMgmtConfigureAction => 'Configurar';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return 'Agregar nuevo $type';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle =>
      'Introduce los detalles del producto';

  @override
  String get productMgmtSaveProductButton => 'Guardar producto';

  @override
  String get productMgmtAliasNameLabel =>
      'Nombre de alias (para el PDF de la factura)';

  @override
  String get productMgmtAliasHelperText =>
      'Nombre de visualización opcional en idioma local usado solo en facturas PDF.';

  @override
  String get productMgmtDescriptionLabel => 'Descripción';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => 'Precio de venta';

  @override
  String get productMgmtPurchasePriceLabel => 'Precio de compra';

  @override
  String get productMgmtDefaultDiscountLabel => 'Descuento predeterminado';

  @override
  String get productMgmtTaxPercentLabel => 'Impuesto (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel =>
      'Solo modo de impuesto por artículo';

  @override
  String get productMgmtSectionGeneral => 'General';

  @override
  String get productMgmtSectionPricing => 'Precios';

  @override
  String get productMgmtSectionInventory => 'Inventario';

  @override
  String get productMgmtUnlimitedStockLabel => 'Stock ilimitado';

  @override
  String get productMgmtTrackInfiniteStockSubtitle =>
      'Rastrear stock infinito para este producto';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      'Consejo: habilita campos personalizados desde Columnas para agregar más detalles.';

  @override
  String get productMgmtEditProductTitle => 'Editar producto';

  @override
  String get productMgmtViewProductTitle => 'Ver producto';

  @override
  String get productMgmtUpdateProductDetailsSubtitle =>
      'Actualizar detalles del producto';

  @override
  String get productMgmtProductDetailsSubtitle => 'Detalles del producto';

  @override
  String get productMgmtUpdatedMessage =>
      '¡Producto/Servicio actualizado con éxito!';

  @override
  String get productMgmtDeleteProductButton => 'Eliminar producto';

  @override
  String get productMgmtSaveChangesButton => 'Guardar cambios';

  @override
  String get fieldUnitLabel => 'Unidad';

  @override
  String get productMgmtAddedMessage => '¡Producto agregado con éxito!';

  @override
  String productMgmtAddErrorMessage(String error) {
    return 'Error al agregar el producto: $error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return 'Error al cargar los productos: $error';
  }

  @override
  String get productMgmtDeletedMessage => '¡Producto eliminado con éxito!';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count productos importados con éxito!',
      one: '¡1 producto importado con éxito!',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => 'Total de artículos';

  @override
  String get productMgmtTangibleProductsSubtitle => 'Productos tangibles';

  @override
  String get productMgmtNonTangibleServicesSubtitle => 'Servicios intangibles';

  @override
  String get productMgmtNeedAttentionSubtitle => 'Requiere atención';

  @override
  String get productMgmtProductNameLabel => 'Nombre del producto';

  @override
  String get productMgmtPriceLabel => 'Precio';

  @override
  String get actionClear => 'Borrar';

  @override
  String get reportsAboutConversionRateTitle =>
      'Acerca de la tasa de conversión';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return 'Cuentas por cobrar vencidas ($count)';
  }

  @override
  String get reportsAllCurrenciesLabel => 'Todas las monedas';

  @override
  String get reportsAvgInvoiceValueLabel => 'Valor promedio de factura';

  @override
  String get reportsBalanceColumnLabel => 'Saldo';

  @override
  String get reportsBilledLabel => 'Facturado';

  @override
  String get reportsBucket0to30Label => '0 a 30 días';

  @override
  String get reportsBucket31to60Label => '31 a 60 días';

  @override
  String get reportsBucket61to90Label => '61 a 90 días';

  @override
  String get reportsBucket90PlusLabel => '90+ días';

  @override
  String get reportsBucketLabel => 'Categoría';

  @override
  String get reportsClosingLabel => 'Saldo final';

  @override
  String get reportsCogsColumnLabel => 'Costo de ventas';

  @override
  String get reportsConversionRateExplanationBody =>
      'Tasa de conversión = Facturas creadas ÷ Presupuestos emitidos × 100.\nUna tasa superior al 100% significa que se generaron más facturas que presupuestos en el período seleccionado (habitual cuando las facturas se crean directamente sin un presupuesto previo).\n\nNota: esta es una relación a nivel de período, no un seguimiento individual de presupuesto a factura.';

  @override
  String get reportsConversionRateLabel => 'Tasa de conversión';

  @override
  String get reportsCreditColumnLabel => 'Crédito';

  @override
  String get reportsCurrencySectionLabel => 'MONEDA';

  @override
  String get reportsCurrentBucketLabel => 'Corriente';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return 'Moneda actualmente seleccionada ($currency)';
  }

  @override
  String get reportsCustomRangeLabel => 'Rango personalizado';

  @override
  String get reportsDailySalesProfitTitle => 'Ventas y ganancias diarias';

  @override
  String reportsDaysCountLabel(int d) {
    return '$d días';
  }

  @override
  String get reportsDaysOverdueLabel => 'Días de atraso';

  @override
  String get reportsDebitColumnLabel => 'Débito';

  @override
  String get reportsDiscountGivenColumnLabel => 'Descuento otorgado';

  @override
  String get reportsExportCsvLabel => 'Exportar CSV';

  @override
  String reportsFilteredToDateLabel(String date) {
    return 'Filtrado al $date';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString facturas en el período · $scope',
      one: '1 factura en el período · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => 'ID de factura';

  @override
  String get reportsInvoicedLabel => 'Facturado';

  @override
  String get reportsInvoicesColumnLabel => 'Facturas';

  @override
  String get reportsInvoicesInPeriodLabel => 'Facturas en el período';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get reportsMarginColumnLabel => 'Margen';

  @override
  String get reportsMaxRangeOneYearMessage =>
      'El rango máximo es de 1 año. La fecha final se limitó.';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage =>
      'El rango máximo es de 31 días. La fecha final se limitó.';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count artículos vendidos en este período no tienen precio de compra definido — la ganancia/margen está subestimado para esos artículos hasta que se agregue un precio de compra al producto.',
      one:
          '1 artículo vendido en este período no tiene precio de compra definido — la ganancia/margen está subestimado para ese artículo hasta que se agregue un precio de compra al producto.',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => 'Mes y año';

  @override
  String get reportsMonthlyRevenueTrendTitle =>
      'Tendencia de ingresos mensuales';

  @override
  String get reportsNavDailyReportLabel => 'Informe diario';

  @override
  String get reportsNavInvoiceStatusLabel => 'Estado de facturas';

  @override
  String get reportsNavReceivablesLabel => 'Cuentas por cobrar';

  @override
  String get reportsNavRevenueLabel => 'Ingresos';

  @override
  String get reportsNavTaxLabel => 'Impuesto';

  @override
  String get reportsNoCustomerDataMessage =>
      'Sin datos de clientes en este período';

  @override
  String get reportsNoCustomersMatchSearchMessage =>
      'Ningún cliente coincide con esta búsqueda';

  @override
  String get reportsNoCustomersWithInvoicesMessage =>
      'No hay clientes con facturas';

  @override
  String get reportsNoDueDateLabel => 'Sin fecha de vencimiento';

  @override
  String get reportsNoInvoiceDataMessage =>
      'Sin datos de facturas en este período';

  @override
  String get reportsNoInvoicesInPeriodMessage => 'Sin facturas en este período';

  @override
  String get reportsNoInvoicesMatchFilterMessage =>
      'Ninguna factura coincide con este filtro';

  @override
  String get reportsNoOutstandingInvoicesMessage =>
      'No hay facturas pendientes';

  @override
  String get reportsNoProductDataMessage =>
      'Sin datos de productos en este período';

  @override
  String get reportsNoSalesInPeriodMessage => 'Sin ventas en este período';

  @override
  String get reportsNoStatementActivityMessage =>
      'Sin actividad de estado de cuenta para este cliente';

  @override
  String get reportsNoTaxableItemsMessage =>
      'Sin artículos gravables en este período';

  @override
  String get reportsNoTransactionsMessage =>
      'Sin transacciones en este período';

  @override
  String get reportsOpeningLabel => 'Saldo inicial';

  @override
  String get reportsOverviewLabel => 'Resumen';

  @override
  String get reportsPaymentStatusBreakdownTitle =>
      'Desglose del estado de pago';

  @override
  String get reportsPeriodSectionLabel => 'PERÍODO';

  @override
  String get reportsPresetLast30DaysLabel => 'Últimos 30 días';

  @override
  String get reportsPresetLast3MonthsLabel => 'Últimos 3 meses';

  @override
  String get reportsPresetLast6MonthsLabel => 'Últimos 6 meses';

  @override
  String get reportsPresetLastFYLabel => 'Año fiscal anterior';

  @override
  String get reportsPresetThisFYLabel => 'Año fiscal actual';

  @override
  String get reportsPresetThisYearLabel => 'Este año';

  @override
  String get reportsProductServiceColumnLabel => 'Producto / Servicio';

  @override
  String get reportsProfitLabel => 'Ganancia';

  @override
  String get reportsQuotationsIssuedLabel => 'Presupuestos emitidos';

  @override
  String get reportsRankByProfitLabel => 'Clasificación: Ganancia';

  @override
  String get reportsRankByRevenueLabel => 'Clasificación: Ingresos';

  @override
  String get reportsReferenceColumnLabel => 'Referencia';

  @override
  String get reportsSalesColumnLabel => 'Ventas';

  @override
  String get reportsSaveCsvReportTitle => 'Guardar informe CSV';

  @override
  String get reportsSavePdfReportTitle => 'Guardar informe PDF';

  @override
  String reportsSavedAtMessage(String path) {
    return 'Guardado: $path';
  }

  @override
  String get reportsSelectCustomerTitle => 'Seleccionar cliente';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText =>
      'Seleccione una fecha o rango de fechas (máx. 31 días)';

  @override
  String get reportsSelectDateRangeMaxYearHelpText =>
      'Seleccione un rango de fechas (máx. 1 año)';

  @override
  String get reportsShareLabel => 'Parte';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return 'Mostrando facturas con fecha $range';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end de $total';
  }

  @override
  String get reportsSlColumnLabel => 'N.°';

  @override
  String get reportsStatementsLabel => 'Estados de cuenta';

  @override
  String get reportsTaxCollectedByRateTitle => 'Impuesto recaudado por tasa';

  @override
  String get reportsTaxCollectedLabel => 'Impuesto recaudado';

  @override
  String get reportsTaxRateBucketsLabel => 'Rangos de tasa de impuesto';

  @override
  String get reportsTodayLabel => 'Hoy';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return 'Los $count principales clientes por ingresos';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return 'Los $count principales productos / servicios por $metric';
  }

  @override
  String get reportsTotalBilledLabel => 'Total facturado';

  @override
  String get reportsTotalCollectedLabel => 'Total cobrado';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString facturas en total',
      one: '1 factura en total',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => 'Total de facturas';

  @override
  String get reportsTotalProfitLabel => 'Ganancia total';

  @override
  String get reportsTotalTaxCollectedLabel => 'Total de impuestos recaudados';

  @override
  String get reportsTypeColumnLabel => 'Tipo';

  @override
  String get reportsUnitsSoldColumnLabel => 'Unidades vendidas';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return 'Error al cargar usuarios: $error';
  }

  @override
  String get userMgmtAddedMessage => 'Usuario añadido correctamente';

  @override
  String get userMgmtUpdatedMessage => 'Usuario actualizado correctamente';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return 'Error al guardar el usuario: $error';
  }

  @override
  String get userMgmtChangePasswordTitle => 'Cambiar contraseña';

  @override
  String userMgmtUserColonLabel(String username) {
    return 'Usuario: $username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => 'Contraseña actual';

  @override
  String get userMgmtCurrentPasswordRequiredMessage =>
      'Se requiere la contraseña actual';

  @override
  String get userMgmtNewPasswordLabel => 'Nueva contraseña';

  @override
  String get userMgmtNewPasswordRequiredMessage =>
      'Se requiere la nueva contraseña';

  @override
  String get userMgmtPasswordMinLengthMessage =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get userMgmtConfirmNewPasswordLabel => 'Confirmar nueva contraseña';

  @override
  String get userMgmtConfirmPasswordRequiredMessage =>
      'Por favor confirme su contraseña';

  @override
  String get userMgmtPasswordsDoNotMatchMessage =>
      'Las contraseñas no coinciden';

  @override
  String get userMgmtPasswordChangedMessage =>
      'Contraseña cambiada correctamente';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage =>
      'La contraseña actual es incorrecta';

  @override
  String get userMgmtDeleteUserTitle => 'Eliminar usuario';

  @override
  String get userMgmtDeleteUserConfirmLabel =>
      '¿Está seguro de que desea eliminar al usuario:';

  @override
  String get userMgmtActionCannotBeUndoneMessage =>
      'Esta acción no se puede deshacer.';

  @override
  String get userMgmtDeletedMessage => 'Usuario eliminado correctamente';

  @override
  String get userMgmtCantDeleteOwnAccountMessage =>
      'No puede eliminar su propia cuenta';

  @override
  String get userMgmtCantDemoteLastAdminMessage =>
      'No puede cambiar el rol del único administrador';

  @override
  String get userMgmtCantChangeOwnRoleMessage =>
      'No puede cambiar su propio rol';

  @override
  String get userMgmtUsernameTakenMessage =>
      'Ese nombre de usuario ya está en uso';

  @override
  String get userMgmtDeleteSelectedTitle =>
      '¿Eliminar los usuarios seleccionados?';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esto eliminará permanentemente $count usuarios. Esta acción no se puede deshacer.',
      one:
          'Esto eliminará permanentemente 1 usuario. Esta acción no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage =>
      'Su propia cuenta estaba en la selección, pero se omitirá.';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usuarios eliminados',
      one: '1 usuario eliminado',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return 'Error al eliminar usuarios: $error';
  }

  @override
  String get userMgmtTitle => 'Gestión de usuarios';

  @override
  String get userMgmtSubtitle =>
      'Gestione los usuarios de la aplicación y los permisos de acceso';

  @override
  String get userMgmtAddUserButton => 'Añadir usuario';

  @override
  String get userMgmtSearchHint => 'Buscar usuarios por nombre o rol…';

  @override
  String get userMgmtFilterByRoleTooltip => 'Filtrar por rol';

  @override
  String get userMgmtAllRolesLabel => 'Todos los roles';

  @override
  String get userMgmtAllLabel => 'Todos';

  @override
  String userMgmtRoleColonLabel(String role) {
    return 'Rol: $role';
  }

  @override
  String get userMgmtColUser => 'USUARIO';

  @override
  String get userMgmtColRole => 'ROL';

  @override
  String get userMgmtYouBadgeLabel => 'Tú';

  @override
  String get userMgmtDeleteSelectedMenuLabel => 'Eliminar seleccionados';

  @override
  String get userMgmtBulkActionsTooltip => 'Acciones masivas';

  @override
  String get userMgmtBulkActionsLabel => 'Acciones masivas';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return 'Mostrando $from a $to de $total usuarios';
  }

  @override
  String get userMgmtNoUsersFoundMessage => 'No se encontraron usuarios';

  @override
  String get userMgmtAddNewUserTitle => 'Añadir nuevo usuario';

  @override
  String get userMgmtEditUserTitle => 'Editar usuario';

  @override
  String get userMgmtUsernameRequiredLabel => 'Nombre de usuario *';

  @override
  String get userMgmtEnterUsernameHint => 'Ingrese el nombre de usuario';

  @override
  String get userMgmtUsernameRequiredMessage =>
      'El nombre de usuario es obligatorio';

  @override
  String get userMgmtUsernameMinLengthMessage =>
      'El nombre de usuario debe tener al menos 3 caracteres';

  @override
  String get userMgmtPasswordRequiredLabel => 'Contraseña *';

  @override
  String get userMgmtEnterPasswordHint => 'Ingrese la contraseña';

  @override
  String get userMgmtPasswordRequiredMessage => 'La contraseña es obligatoria';

  @override
  String get userMgmtMinimum6CharsMessage => 'Mínimo 6 caracteres';

  @override
  String get userMgmtRoleRequiredLabel => 'Rol *';

  @override
  String get userMgmtRoleRequiredMessage => 'El rol es obligatorio';

  @override
  String get userMgmtSaveUserButton => 'Guardar usuario';

  @override
  String get userMgmtThisIsYourAccountMessage => 'Esta es tu cuenta';

  @override
  String get invoiceSettingsAppBarTitle => 'Configuración de facturas';

  @override
  String get invoiceSettingsSavedMessage =>
      '¡Configuración de facturas guardada correctamente!';

  @override
  String get invoiceSettingsSignatureTooLargeMessage =>
      'La imagen de la firma debe ser menor de 2 MB.';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage =>
      'La imagen de la marca de agua debe ser menor de 2 MB.';

  @override
  String get invoiceSettingsSectionGeneral => 'General';

  @override
  String get invoiceSettingsSectionBranding => 'Marca';

  @override
  String get invoiceSettingsSectionTax => 'Impuesto y GST';

  @override
  String get invoiceSettingsSectionItems => 'Artículos de la factura';

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
  String get invoiceSettingsPrefixLabel => 'Prefijo de factura';

  @override
  String get invoiceSettingsStartingNumberHelper =>
      'La primera factura comenzará con este número';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      'El número inicial de factura no se puede cambiar mientras existan facturas. Elimine permanentemente todas las facturas/cotizaciones (incluida la papelera) y vuelva a intentarlo.';

  @override
  String get invoiceSettingsQuantityColumnLabel =>
      'Etiqueta de la columna Cantidad';

  @override
  String get invoiceSettingsQuantityColumnHint =>
      'ej. Palabras, Horas, Unidades';

  @override
  String get invoiceSettingsQuantityColumnHelper =>
      'Dejar en blanco para usar \"Cant.\" por defecto';

  @override
  String get invoiceSettingsAdditionalInfoLabel => 'Información adicional';

  @override
  String get invoiceSettingsThankYouNoteLabel => 'Nota de agradecimiento';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel =>
      'Ocultar número de factura por defecto';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      'Activar \"Ocultar número de factura en el PDF\" por defecto al crear nuevas facturas.';

  @override
  String get invoiceSettingsTaxRateHint => 'ej. 18';

  @override
  String get invoiceSettingsTaxRateHelper => 'Se aplica a las nuevas facturas';

  @override
  String get invoiceSettingsTaxEnabledLabel => 'Impuesto activado por defecto';

  @override
  String get invoiceSettingsTaxEnabledSubtitle =>
      'Activar el interruptor de impuesto por defecto al crear nuevas facturas.';

  @override
  String get invoiceSettingsTaxModeLabel =>
      'Modo de tasa de impuesto por defecto';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly =>
      'Solo se aplica a las nuevas facturas';

  @override
  String get invoiceSettingsTaxModeGlobal => 'Global';

  @override
  String get invoiceSettingsTaxModePerItem => 'Por artículo';

  @override
  String get invoiceSettingsShowGstFieldsLabel => 'Mostrar campos GST';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      'Mostrar campos GSTIN (HSN/SAC) en facturas, PDF y exportaciones CSV';

  @override
  String get invoiceSettingsShowCgstSgstLabel => 'Mostrar CGST/SGST';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      'Dividir el impuesto en CGST + SGST en las facturas (solo India).';

  @override
  String get invoiceSettingsDefaultGstTitleLabel =>
      'Título de factura GST por defecto';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel =>
      'Título de factura de impuesto por defecto';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      'Preseleccionado en las nuevas facturas — ej. \"Bill of Supply\" para comerciantes del Régimen de Composición GST';

  @override
  String get invoiceSettingsGstTitleHelperGeneric =>
      'Preseleccionado en las nuevas facturas';

  @override
  String get invoiceSettingsShowRoundOffLabel => 'Mostrar redondeo';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      'Mostrar una fila de redondeo + el importe neto (redondeado al más cercano) y el importe en palabras en los PDF de factura.';

  @override
  String get invoiceSettingsShowAliasNameLabel =>
      'Mostrar nombre de alias en el PDF';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      'Imprimir el alias en el idioma local de un producto (si está definido) en lugar de su nombre real en los PDF';

  @override
  String get invoiceSettingsShowDescriptionLabel =>
      'Mostrar descripción del producto';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      'Imprimir la descripción de cada artículo como una fila debajo de él en los PDF A4 (no en recibos térmicos)';

  @override
  String get invoiceSettingsDescriptionNewLineLabel =>
      'Descripción en una línea nueva';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      'Imprimir la descripción como una fila de ancho completo debajo del artículo en lugar de una línea bajo su nombre';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel =>
      'Permitir cantidades fraccionarias';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      'Activar cantidades decimales (ej. 1.5 h, 0.5 kg)';

  @override
  String get invoiceSettingsShowQuantityLabel => 'Mostrar campo de cantidad';

  @override
  String get invoiceSettingsShowQuantitySubtitle =>
      'Ocultar cantidad para facturación basada en servicios; la columna de precio se convierte en \"Tarifa\"';

  @override
  String get invoiceSettingsShowDiscountLabel => 'Mostrar columna de descuento';

  @override
  String get invoiceSettingsShowDiscountSubtitle =>
      'Ocultar la columna de descuento para clientes que no usan descuentos por artículo';

  @override
  String get invoiceSettingsShowTypeTagLabel =>
      'Mostrar etiqueta de Producto/Servicio';

  @override
  String get invoiceSettingsShowTypeTagSubtitle =>
      'Mostrar u ocultar la etiqueta Producto/Servicio en cada artículo de la factura';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel =>
      'Permitir artículos de factura duplicados';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle =>
      'Permitir agregar el mismo producto más de una vez a una factura';

  @override
  String get invoiceSettingsShowPrevBalanceLabel =>
      'Mostrar saldo pendiente anterior';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle =>
      'Mostrar el saldo pendiente anterior calculado en los PDF de factura';

  @override
  String get invoiceSettingsLogoPositionLabel =>
      'Posición del logo de la empresa';

  @override
  String get invoiceSettingsLogoSizeLabel => 'Tamaño del logo de la empresa';

  @override
  String get commonLeftLabel => 'Izquierda';

  @override
  String get commonRightLabel => 'Derecha';

  @override
  String get invoiceSettingsSignatureImageLabel => 'Imagen de firma';

  @override
  String get invoiceSettingsSignatureImageSubtitle =>
      'Impresa en las facturas como Firma Autorizada';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG, JPG o JPEG — máx. 2 MB';

  @override
  String get invoiceSettingsChangeSignatureButton => 'Cambiar firma';

  @override
  String get invoiceSettingsUploadSignatureButton => 'Subir firma';

  @override
  String get invoiceSettingsSignatureSizeLabel => 'Tamaño de la firma';

  @override
  String get invoiceSettingsSignaturePositionLabel => 'Posición de la firma';

  @override
  String get invoiceSettingsWatermarkImageLabel => 'Imagen de marca de agua';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      'Se muestra detrás de la tabla de artículos en los PDF de factura (no se imprime en recibos térmicos)';

  @override
  String get invoiceSettingsChangeWatermarkButton => 'Cambiar marca de agua';

  @override
  String get invoiceSettingsUploadWatermarkButton => 'Subir marca de agua';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return 'Opacidad: $value%';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value%';
  }

  @override
  String get invoiceSettingsPromoTitle =>
      '¿Necesitas más campos en tus facturas?';

  @override
  String get invoiceSettingsPromoBody =>
      'Agrega número de orden de compra, código de proyecto, departamento o cualquier campo personalizado.';

  @override
  String get invoiceSettingsPromoButton => 'Ver opciones';

  @override
  String get pdfSettingsTitle => 'Configuración de PDF';

  @override
  String get pdfSettingsSubtitle =>
      'Personaliza las plantillas PDF de facturas, presupuestos y recibos';

  @override
  String get pdfSettingsResetToDefaultButton =>
      'Restablecer valores predeterminados';

  @override
  String get pdfSettingsSaveSettingsButton => 'Guardar configuración';

  @override
  String get pdfSettingsTemplatesLabel => 'Plantillas';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return 'No hay plantillas para $pageSize';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'Configuración de PDF guardada';

  @override
  String get commonActiveLabel => 'Activo';

  @override
  String get commonUnavailableLabel => 'No disponible';

  @override
  String get pdfSettingsDisplayOptionsLabel => 'Opciones de visualización';

  @override
  String get pdfSettingsShowTotalQtyRowLabel =>
      'Mostrar fila de cantidad total';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => 'Diseño de artículos';

  @override
  String get pdfSettingsItemLayoutTableLabel => 'Tabla';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => 'Detallado';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      'Tabla: una línea por artículo (Sl/Nombre/Cant/Precio/Total). Detallado: nombre en su propia línea, luego Cant/Precio/Total debajo.';

  @override
  String get pdfSettingsCompanyNameSizeLabel =>
      'Tamaño del nombre de la empresa';

  @override
  String get pdfSettingsThemeColorLabel => 'Color del tema';

  @override
  String get pdfSettingsHexErrorText => 'Usa #RRGGBB';

  @override
  String get pdfSettingsPickColorTooltip => 'Abrir selector de color';

  @override
  String get pdfSettingsPickThemeColorDialogTitle => 'Elegir color del tema';

  @override
  String get pdfSettingsPreviewDisclaimer =>
      'La vista previa puede diferir ligeramente del PDF final.';

  @override
  String get pdfSettingsCustomTemplatePromoTitle =>
      '¿Quieres una plantilla personalizada?';

  @override
  String get pdfSettingsCustomTemplatePromoBody =>
      'Obtén un diseño que combine con tu marca: colores, fuentes y diseño.';

  @override
  String get pdfSettingsCustomizationOptionsButton =>
      'Opciones de personalización';

  @override
  String get pdfTemplateClassicName => 'Clásico';

  @override
  String get pdfTemplateClassicDescription =>
      'Diseño tradicional con estructura limpia';

  @override
  String get pdfTemplateModernName => 'Moderno';

  @override
  String get pdfTemplateModernDescription =>
      'Encabezado destacado con estilo contemporáneo';

  @override
  String get pdfTemplateMinimalName => 'Minimalista';

  @override
  String get pdfTemplateMinimalDescription => 'Simple y sin distracciones';

  @override
  String get pdfTemplateExecutiveName => 'Ejecutivo';

  @override
  String get pdfTemplateExecutiveDescription =>
      'Diseño empresarial premium con bloques de facturación estructurados';

  @override
  String get pdfTemplateCompactName => 'Compacto';

  @override
  String get pdfTemplateCompactDescription =>
      'Diseño de recibo eficiente en espacio, ideal para impresión A6';

  @override
  String get pdfTemplateThermalName => 'Térmico';

  @override
  String get pdfTemplateThermalDescription =>
      'Diseño de recibo estrecho para impresoras térmicas de 80mm y 58mm';

  @override
  String get pdfTemplateGridClassicName => 'Cuadrícula clásica';

  @override
  String get pdfTemplateGridClassicDescription =>
      'Factura tabular con bordes al estilo antiguo, para A4, A5 y A6';

  @override
  String get companyInfoAppBarTitle => 'Información de la empresa';

  @override
  String get companyInfoUploadLogoLabel => 'Subir logo';

  @override
  String get companyInfoClickToBrowseLabel => 'Haga clic para buscar';

  @override
  String get companyInfoRemoveLogoButton => 'Eliminar logo';

  @override
  String get companyInfoShowOnPdfLabel => 'Mostrar en el PDF';

  @override
  String get companyInfoLogoRequirementsHint =>
      'Máx. 1080×1080 px · 2 MB\nSolo PNG o JPG';

  @override
  String get companyInfoLogoSectionLabel => 'LOGO DE LA EMPRESA';

  @override
  String get companyInfoDetailsSectionLabel => 'DATOS DE LA EMPRESA';

  @override
  String get companyInfoBusinessTypeSectionLabel => 'TIPO DE NEGOCIO';

  @override
  String get companyInfoPaymentSettingsSectionLabel => 'CONFIGURACIÓN DE PAGO';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'CUENTAS UPI';

  @override
  String get companyInfoBankAccountsSectionLabel => 'CUENTAS BANCARIAS';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => 'N.º de Impuesto/IVA';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'Código FSSAI';

  @override
  String get companyInfoPhoneHelperText =>
      'Varios números: sepárelos con una coma';

  @override
  String get fieldWebsiteLabel => 'Sitio web';

  @override
  String get companyInfoBusinessTypeTitle => 'Tipo de negocio';

  @override
  String get companyInfoBusinessTypeSubtitle =>
      'Controla las opciones de tipo de artículo en la lista de productos y facturas';

  @override
  String get labelBoth => 'Ambos';

  @override
  String get companyInfoSetAsDefaultTooltip => 'Establecer como predeterminado';

  @override
  String get companyInfoUpiIdLabel => 'ID de UPI';

  @override
  String get companyInfoAddUpiAccountButton => 'Añadir cuenta UPI';

  @override
  String get companyInfoShowQrToggleTitle =>
      'Mostrar código QR en las facturas';

  @override
  String get companyInfoShowQrToggleSubtitle =>
      'Añade códigos QR de pago UPI escaneables a los PDF generados';

  @override
  String get companyInfoShowBankDetailsToggleTitle =>
      'Mostrar datos bancarios en las facturas';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle =>
      'Imprime los datos de la cuenta bancaria en los PDF generados';

  @override
  String get fieldBankNameLabel => 'Nombre del banco';

  @override
  String get fieldAccountNumberLabel => 'Número de cuenta';

  @override
  String get fieldIfscCodeLabel => 'Código IFSC';

  @override
  String get companyInfoAddBankAccountButton => 'Añadir cuenta bancaria';

  @override
  String get tooltipShowOnInvoicePdf => 'Mostrar en el PDF de la factura';

  @override
  String get companyInfoSavedSuccessMessage =>
      'Información de la empresa guardada correctamente';

  @override
  String get companyInfoImageTooLargeMessage =>
      'El archivo de imagen debe ser menor de 2 MB.';

  @override
  String get companyInfoInvalidImageMessage => 'Archivo de imagen no válido.';

  @override
  String get companyInfoImageDimensionsMessage =>
      'La imagen debe ser de máximo 1080x1080 píxeles.';

  @override
  String get companyInfoHintExampleBankName => 'ej. Banco HDFC';

  @override
  String get companyInfoHintExampleAccountLabel => 'ej. Cuenta principal';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get appInfoTitle => 'Información del software';

  @override
  String get appInfoAppDetailsTitle => 'DETALLES DE LA APLICACIÓN';

  @override
  String get appInfoAppNameLabel => 'Nombre de la aplicación';

  @override
  String get appInfoVersionLabel => 'Versión';

  @override
  String get appInfoLicenseLabel => 'Licencia';

  @override
  String get appInfoDeveloperTitle => 'DESARROLLADOR';

  @override
  String get appInfoDeveloperLabel => 'Desarrollador';

  @override
  String get appInfoSupportEmailLabel => 'Correo de soporte';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  Publicado bajo la licencia $license';
  }

  @override
  String get appInfoCheckingLabel => 'Comprobando...';

  @override
  String get appInfoUpdateAvailableLabel => 'Actualización disponible';

  @override
  String get appInfoUpToDateLabel => 'Actualizado';

  @override
  String get appInfoCheckFailedLabel => 'Error al comprobar';

  @override
  String get appInfoUpdatesTitle => 'ACTUALIZACIONES';

  @override
  String get appInfoCurrentVersionLabel => 'Versión actual';

  @override
  String get appInfoLatestVersionLabel => 'Última versión';

  @override
  String get appInfoCheckNowButton => 'Comprobar ahora';

  @override
  String get backupManagementTitle => 'Gestión de copias de seguridad';

  @override
  String get backupCreateDbButton => 'Crear copia de la BD';

  @override
  String get backupExportJsonButton => 'Exportar JSON';

  @override
  String get backupImportButton => 'Importar copia de seguridad';

  @override
  String get backupNoBackupsFoundMessage =>
      'No se encontraron copias de seguridad';

  @override
  String backupSizeLabel(String size) {
    return 'Tamaño: $size';
  }

  @override
  String backupCreatedLabel(String date) {
    return 'Creada: $date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return 'Error al cargar las copias de seguridad: $error';
  }

  @override
  String get backupCreatedSuccessMessage =>
      '¡Copia de seguridad creada correctamente!';

  @override
  String backupCreateErrorMessage(String error) {
    return 'Error al crear la copia de seguridad: $error';
  }

  @override
  String get backupRestoreConfirmTitle => 'Restaurar copia de seguridad';

  @override
  String get backupRestoreConfirmBody =>
      'Esto reemplazará todos los datos actuales con la copia de seguridad. ¿Está seguro?';

  @override
  String backupRestoreErrorMessage(String error) {
    return 'Error al restaurar la copia de seguridad: $error';
  }

  @override
  String get backupDeleteConfirmTitle => 'Eliminar copia de seguridad';

  @override
  String get backupDeleteConfirmBody =>
      '¿Está seguro de que desea eliminar esta copia de seguridad?';

  @override
  String get backupDeletedSuccessMessage =>
      '¡Copia de seguridad eliminada correctamente!';

  @override
  String get backupDeleteFailedMessage =>
      'Error al eliminar la copia de seguridad';

  @override
  String backupDeleteErrorMessage(String error) {
    return 'Error al eliminar la copia de seguridad: $error';
  }

  @override
  String get backupSavedToDownloadsMessage =>
      'Copia de seguridad guardada en la carpeta Descargas.';

  @override
  String backupDownloadErrorMessage(String error) {
    return 'Error al descargar la copia de seguridad: $error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return 'Error al compartir la copia de seguridad: $error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return 'Error al importar la copia de seguridad: $error';
  }

  @override
  String get backupRestoreSuccessTitle => 'Restauración exitosa';

  @override
  String get backupRestoreSuccessBody =>
      'La base de datos se ha restaurado correctamente.\n\nLa aplicación debe reiniciarse para aplicar los cambios. Cierre y vuelva a abrir la aplicación.';

  @override
  String get backupCloseLaterButton => 'Cerrar más tarde';

  @override
  String get backupCloseAppNowButton => 'Cerrar aplicación ahora';

  @override
  String get commonSuccessTitle => 'Éxito';

  @override
  String get commonErrorTitle => 'Error';

  @override
  String get productColumnsScreenTitle => 'Personalizar detalles del producto';

  @override
  String get productColumnsSavedMessage => 'Columnas de producto guardadas.';

  @override
  String get productColumnsIntroText =>
      'Elija qué campos aparecen en los formularios de agregar/editar producto, la lista de productos y las líneas de factura. El nombre y el precio siempre son obligatorios.';

  @override
  String get productColumnsNameLabel => 'Nombre';

  @override
  String get productColumnsPriceLabel => 'Precio';

  @override
  String get productColumnsAlwaysRequiredSubtitle =>
      'Siempre visible — obligatorio.';

  @override
  String get productColumnsStockLabel => 'Existencias';

  @override
  String get productColumnsStockSubtitle =>
      'Desactive si nunca controla existencias — los productos tendrán existencias ilimitadas de forma predeterminada.';

  @override
  String get productColumnsProductFieldsSectionTitle => 'Campos del producto';

  @override
  String get productColumnsAliasNameLabel => 'Nombre alternativo';

  @override
  String get productColumnsAliasNameSubtitle =>
      'Nombre de visualización en idioma local para PDF/impresión.';

  @override
  String get productColumnsTaxRateLabel => 'Tasa de impuesto';

  @override
  String get productColumnsTaxRateSubtitle =>
      'Porcentaje de impuesto por producto.';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'Campo de código HSN o SAC.';

  @override
  String get productColumnsDescriptionLabel => 'Descripción';

  @override
  String get productColumnsDescriptionSubtitle =>
      'Descripción de texto libre del producto.';

  @override
  String get productColumnsPurchasePriceLabel => 'Precio de compra';

  @override
  String get productColumnsPurchasePriceSubtitle =>
      'Precio de costo, para el seguimiento de márgenes.';

  @override
  String get productColumnsDefaultDiscountLabel => 'Descuento predeterminado';

  @override
  String get productColumnsDefaultDiscountSubtitle =>
      'Descuento prellenado al agregar este producto a una factura.';

  @override
  String get productColumnsUnitLabel => 'Unidad';

  @override
  String get productColumnsUnitSubtitle =>
      'Unidad de medida (uds, kg, horas...).';

  @override
  String get productColumnsProductServiceTypeLabel => 'Tipo Producto/Servicio';

  @override
  String get productColumnsProductServiceTypeSubtitle =>
      'Selector segmentado Producto vs Servicio.';

  @override
  String get productColumnsMetadataLabel => 'Metadatos del producto';

  @override
  String get productColumnsMetadataSubtitle =>
      'Ubicación de almacenamiento, número de contenedor/lote, caducidad, fecha de fabricación, proveedor, SKU, notas.';

  @override
  String get productColumnsMetaStorageLocationLabel =>
      'Ubicación de almacenamiento';

  @override
  String get productColumnsMetaContainerNumberLabel => 'Número de contenedor';

  @override
  String get productColumnsMetaBatchNumberLabel => 'Número de lote';

  @override
  String get productColumnsMetaExpiryDateLabel => 'Fecha de caducidad';

  @override
  String get productColumnsMetaManufactureDateLabel => 'Fecha de fabricación';

  @override
  String get productColumnsMetaSupplierNameLabel => 'Nombre del proveedor';

  @override
  String get productColumnsMetaSkuCodeLabel => 'Código SKU';

  @override
  String get productColumnsMetaNotesLabel => 'Notas';

  @override
  String get productColumnsExtraCostLabel => 'Costo adicional';

  @override
  String get productColumnsExtraCostSubtitle =>
      'Cargo adicional fijo opcional en una línea de factura.';

  @override
  String get settingsOptionsComingSoonMessage => 'Opciones próximamente...';

  @override
  String get settingsNavCompanyInfoLabel => 'Info. de la empresa';

  @override
  String get settingsNavTeamLabel => 'Equipo';

  @override
  String get settingsNavBackupLabel => 'Copia de seguridad';

  @override
  String get settingsNavUsersLabel => 'Usuarios';

  @override
  String get settingsNavProductDetailsLabel => 'Detalles del producto';

  @override
  String get settingsNavCustomizeLabel => 'Personalizar';

  @override
  String get settingsNavAccessibilityLabel => 'Accesibilidad';

  @override
  String get settingsNavSoftwareInfoLabel => 'Info. del software';

  @override
  String get customizationEyebrowLabel => 'PERSONALIZACIÓN';

  @override
  String get customizationHeadline => 'Adaptado a tu negocio';

  @override
  String get customizationSubtitle =>
      'Elige lo que necesitas y envía una solicitud. Te responderemos dentro de 24 horas.';

  @override
  String get customizationRecommendedBadge => 'Recomendado';

  @override
  String customizationDeliveryLabel(String delivery) {
    return 'Entrega: $delivery';
  }

  @override
  String get customizationRequestButton => 'Solicitar';

  @override
  String get customizationFormOpenErrorMessage =>
      'No se pudo abrir el formulario. Visita forms.gle/LyX6Z2kBNR2BpwVu7 en tu navegador.';

  @override
  String get customizationDisclaimerMessage =>
      'Los precios son indicativos. La cotización final puede variar según la complejidad. El pago se cobra tras acordar el alcance.';

  @override
  String get customizationPdfTemplateTitle => 'Plantilla PDF personalizada';

  @override
  String get customizationPdfTemplateDescription =>
      'Obtén una plantilla de factura diseñada para tu marca: tus colores, fuentes, ubicación del logo y diseño.';

  @override
  String get customizationPdfTemplateDelivery => '2 – 5 días';

  @override
  String get customizationCustomFieldsTitle => 'Campos personalizados';

  @override
  String get customizationCustomFieldsDescription =>
      '¿Necesitas campos adicionales en tus facturas? (número de orden de compra, código de proyecto, departamento, etc.) Los añadiremos por ti.';

  @override
  String get customizationCustomFieldsDelivery => '1 – 3 días';

  @override
  String get customizationWhiteLabelTitle => 'Marca blanca / Eliminar marca';

  @override
  String get customizationWhiteLabelDescription =>
      'Elimina toda la marca Invoiso de la app y los PDF, y reemplázala con la identidad de tu empresa.';

  @override
  String get customizationWhiteLabelDelivery => '3 – 6 días';

  @override
  String get customizationIndustryBuildTitle =>
      'Versión específica por industria';

  @override
  String get customizationIndustryBuildDescription =>
      '¿Necesitas una versión adaptada a tu industria? (construcción, consultoría, comercio minorista, etc.) Personalizaremos el flujo de trabajo según tus necesidades.';

  @override
  String get customizationIndustryBuildDelivery => '5 – 10 días';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle =>
      'Nuevo diseño de la página de creación de facturas';

  @override
  String get accessibilityClassicLayoutLabel => 'Diseño clásico';

  @override
  String get accessibilityNewLayoutLabel => 'Nuevo diseño';

  @override
  String get accessibilityLayoutDescription =>
      'Elige qué diseño de pantalla \"Nueva factura\" usar.';

  @override
  String get accessibilityShortcutsSubtitle =>
      'Agiliza la creación de facturas sin tocar el ratón.';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => 'Total de la factura';

  @override
  String get paymentDialogAmountPaidLabel => 'Importe pagado';

  @override
  String get paymentDialogHistoryTitle => 'Historial de pagos';

  @override
  String get paymentDialogNoPaymentsMessage => 'Aún no se han registrado pagos';

  @override
  String get paymentDialogFullyPaidExclaimMessage =>
      '¡Factura pagada por completo!';

  @override
  String get paymentDialogFullyPaidBannerLabel => 'Factura pagada por completo';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return 'Pago registrado. Pendiente: $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return 'Error al registrar el pago: $error';
  }

  @override
  String get paymentDialogDeleteTitle => 'Eliminar pago';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return '¿Eliminar el recibo $receiptNumber?\n\nEsta acción no se puede deshacer.';
  }

  @override
  String get paymentDialogNewPaymentTitle => 'Nuevo pago';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return 'Importe ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return 'Máx.: $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError => 'Introduce un importe válido';

  @override
  String get paymentDialogExceedsOutstandingError =>
      'Supera el saldo pendiente';

  @override
  String get paymentDialogMethodFieldLabel => 'Método de pago';

  @override
  String get paymentDialogSelectMethodHint => 'Selecciona un método';

  @override
  String get paymentDialogTaxCoveredLabel => 'Impuesto cubierto';

  @override
  String get paymentDialogAutoCalculatedHelper => 'Calculado automáticamente';

  @override
  String get paymentDialogNotesFieldLabel => 'Referencia / Notas (opcional)';

  @override
  String get paymentDialogNotesHint =>
      'ej. n.º de cheque, ID de transacción...';

  @override
  String get paymentDialogReceiptColLabel => 'N.º de recibo';

  @override
  String get paymentDialogMethodColLabel => 'Método';

  @override
  String get paymentDialogDownloadReceiptTooltip => 'Descargar recibo';

  @override
  String get paymentDialogDeletePaymentTooltip => 'Eliminar pago';

  @override
  String get paymentMethodCash => 'Efectivo';

  @override
  String get paymentMethodBankTransfer => 'Transferencia bancaria';

  @override
  String get paymentMethodCheck => 'Cheque';

  @override
  String get paymentMethodOnline => 'En línea';

  @override
  String get paymentMethodOther => 'Otro';

  @override
  String get customerInfoButtonTooltip => 'Ver datos de contacto';

  @override
  String get customerInfoButtonNoContactMessage =>
      'No hay datos de contacto disponibles.';

  @override
  String get updateDialogTitle => 'Actualización disponible';

  @override
  String get updateDialogBodyMessage =>
      'Hay una nueva versión de invoiso disponible. Visita la página de descargas para obtener la última versión.';

  @override
  String get pageSizeA4Label => 'A4 estándar';

  @override
  String get pageSizeA5Label => 'A5 estándar';

  @override
  String get pageSizeA6Label => 'A6 estándar';

  @override
  String get pageSizeThermal80Label => 'Papel térmico 80mm';

  @override
  String get pageSizeThermal58Label => 'Papel térmico 58mm';

  @override
  String get dateFormatDdmmyyyyLabel => 'DD/MM/AAAA  (ej. 15/04/2026)';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/DD/AAAA  (ej. 04/15/2026)';

  @override
  String get dateFormatDdMmmyyyyLabel => 'DD MMM AAAA  (ej. 15 abr 2026)';

  @override
  String get dateFormatYyyymmddLabel => 'AAAA-MM-DD  (ej. 2026-04-15)';

  @override
  String get sizeXSmallLabel => 'Muy pequeño';

  @override
  String get sizeSmallLabel => 'Pequeño';

  @override
  String get sizeMediumLabel => 'Mediano';

  @override
  String get sizeLargeLabel => 'Grande';

  @override
  String get shortcutNewInvoiceDescription =>
      'Nueva factura (desde el Panel) / Restablecer formulario (en Crear factura)';

  @override
  String get shortcutSaveInvoiceDescription => 'Guardar / crear la factura';

  @override
  String get shortcutAddProductDescription => 'Agregar producto a la factura';

  @override
  String get shortcutAddCustomItemDescription =>
      'Agregar artículo personalizado';

  @override
  String get shortcutPreviewPdfDescription =>
      'Vista previa del PDF de la factura';

  @override
  String get shortcutPrintPdfDescription =>
      'Generar / imprimir el PDF de la factura';
}
