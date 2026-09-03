// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Invoiso';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSkip => 'Passer';

  @override
  String get actionNext => 'Suivant';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionGetStarted => 'Commencer';

  @override
  String get commonLanguage => 'Langue';

  @override
  String get commonBeta => 'Bêta';

  @override
  String get commonSystemDefault => 'Par défaut du système';

  @override
  String get commonTheme => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get onboardingStepCompanyTitle => 'Entreprise';

  @override
  String get onboardingStepCompanySubtitle => 'Parlez-nous de votre entreprise';

  @override
  String get onboardingStepInvoiceTitle => 'Paramètres de facturation';

  @override
  String get onboardingStepInvoiceSubtitle =>
      'Configurez le fonctionnement de vos factures';

  @override
  String get onboardingStepAppearanceTitle => 'Apparence de la facture';

  @override
  String get onboardingStepAppearanceSubtitle =>
      'Choisissez un format de page et un modèle';

  @override
  String get onboardingStepDoneTitle => 'Tout est prêt';

  @override
  String get onboardingCompanyNameLabel => 'Nom de l\'entreprise';

  @override
  String get onboardingCountryLabel => 'Pays';

  @override
  String get onboardingLogoLabel => 'Logo de l\'entreprise';

  @override
  String get onboardingCurrencyLabel => 'Devise';

  @override
  String get onboardingDateFormatLabel => 'Format de date';

  @override
  String get onboardingInvoiceStartingNumberLabel =>
      'Numéro de départ des factures';

  @override
  String get onboardingLeadingZerosLabel => 'Zéros initiaux';

  @override
  String get onboardingLeadingZerosSubtitle =>
      'Compléter les numéros de facture sur 8 chiffres (ex. 00000007)';

  @override
  String get onboardingDefaultTaxRateLabel => 'Taux de taxe par défaut (%)';

  @override
  String get onboardingPageSizeLabel => 'Format de page';

  @override
  String get onboardingTemplateLabel => 'Modèle de facture';

  @override
  String get onboardingDoneHeadline => 'Tout est prêt !';

  @override
  String get onboardingDoneBody =>
      'Les informations de votre entreprise, de vos factures et du modèle sont enregistrées. Vous pouvez les modifier à tout moment depuis les Paramètres.';

  @override
  String get splashInitErrorTitle => 'Erreur d\'initialisation';

  @override
  String splashInitErrorMessage(String error) {
    return 'Échec de l\'initialisation de la base de données.\n\n$error';
  }

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get splashInitializingMessage => 'Initialisation de l\'application...';

  @override
  String get testGateNoInternetTitle =>
      'Le programme d\'installation de test nécessite un accès internet pour vérifier.';

  @override
  String get testGateExpiredTitle => 'Cette version de test a expiré.';

  @override
  String get testGateNoInternetSubtitle =>
      'Connectez-vous à internet et réessayez.';

  @override
  String testGateExpiredSubtitle(String email) {
    return 'Contactez le support : $email';
  }

  @override
  String get dashboardSessionExpiredMessage =>
      'Session expirée en raison d\'inactivité.';

  @override
  String get dashboardUnknownTabLabel => 'Onglet inconnu';

  @override
  String dashboardInvoiceLayoutTooltip(String layout) {
    return 'Mise en page facture : $layout — appuyez pour info';
  }

  @override
  String get dashboardLayoutNew => 'Nouvelle';

  @override
  String get dashboardLayoutClassic => 'Classique';

  @override
  String get dashboardInvoiceLayoutDialogTitle => 'Mise en page de la facture';

  @override
  String dashboardInvoiceLayoutDialogBody(String layout) {
    return 'Vous utilisez la mise en page $layout de \"Nouvelle facture\". Vous pouvez la changer depuis Paramètres > Accessibilité. Remarque : changer en cours d\'édition annule les modifications non enregistrées de ce formulaire.';
  }

  @override
  String get actionClose => 'Fermer';

  @override
  String get dashboardOpenSettingsAction => 'Ouvrir les paramètres';

  @override
  String get dashboardCollapseSidebarTooltip => 'Réduire la barre latérale';

  @override
  String get dashboardExpandSidebarTooltip => 'Développer la barre latérale';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navNewInvoice => 'Nouvelle facture';

  @override
  String get navInvoices => 'Factures';

  @override
  String get navQuotations => 'Devis';

  @override
  String get navReceipts => 'Reçus';

  @override
  String get navCustomers => 'Clients';

  @override
  String get navProducts => 'Produits';

  @override
  String get navReports => 'Rapports';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get dashboardRoleAdmin => 'Administrateur';

  @override
  String get dashboardRoleUser => 'Utilisateur';

  @override
  String get dashboardSupportTooltip => 'Support';

  @override
  String get dashboardLogoutTooltip => 'Déconnexion';

  @override
  String get dashboardTestBuildBadge => 'VERSION TEST';

  @override
  String get dashboardTestBadgeShort => 'TEST';

  @override
  String get dashboardKeyboardShortcutsTitle => 'Raccourcis clavier';

  @override
  String get dashboardShortcutsBannerTitle => 'Nouveau : raccourcis clavier';

  @override
  String get dashboardShortcutsBannerSubtitle =>
      'Ctrl+Q pour une nouvelle facture, Ctrl+S pour enregistrer, et plus encore.';

  @override
  String get dashboardViewAllAction => 'Tout voir';

  @override
  String get dashboardLayoutBannerTitle =>
      'Nouveau : plusieurs mises en page du tableau de bord';

  @override
  String get dashboardLayoutBannerSubtitle =>
      'Basculez entre Par défaut, Classique, Bento et Flux simple avec l\'icône de grille en haut à droite.';

  @override
  String get actionGotIt => 'Compris';

  @override
  String get dashboardThemeBannerTitle => 'Nouveau : mode sombre';

  @override
  String get dashboardThemeBannerSubtitle =>
      'Nous continuons à l\'améliorer — activez-le depuis Paramètres > Infos entreprise et dites-nous ce qui semble à revoir.';

  @override
  String dashboardSupportBannerTitle(String count) {
    return 'Vous avez créé $count factures !';
  }

  @override
  String get dashboardSupportBannerReviewSubtitle =>
      'Vous appréciez Invoiso ? Un avis rapide aide beaucoup.';

  @override
  String get dashboardSupportBannerSupportSubtitle =>
      'Il semble qu\'Invoiso fasse partie de votre quotidien. Si l\'application vous a été utile, envisagez de soutenir le projet — quand vous le souhaitez.';

  @override
  String get dashboardReviewAction => 'Avis';

  @override
  String get dashboardSupportAction => 'Soutenir';

  @override
  String get dashboardOverviewTitle => 'Aperçu du tableau de bord';

  @override
  String get actionRefresh => 'Actualiser';

  @override
  String dashboardOutOfStockCountLabel(int count) {
    return '$count en rupture de stock';
  }

  @override
  String get dashboardRevenueCollectedLabel => 'Revenus encaissés';

  @override
  String get dashboardOutstandingLabel => 'En attente';

  @override
  String dashboardOverdueCountLabel(int count) {
    return '$count en retard';
  }

  @override
  String get dashboardRecentInvoicesTitle => 'Factures récentes';

  @override
  String get dashboardLastFiveInvoicesLabel => '5 dernières factures';

  @override
  String get dashboardNoInvoicesYetTitle => 'Aucune facture pour l\'instant';

  @override
  String get dashboardNoInvoicesYetSubtitle =>
      'Créez votre première facture pour la voir ici';

  @override
  String get actionView => 'Voir';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionDuplicate => 'Dupliquer';

  @override
  String get actionPdfPreview => 'Aperçu PDF';

  @override
  String get actionDownloadPdf => 'Télécharger le PDF';

  @override
  String get actionPrint => 'Imprimer';

  @override
  String get actionPayment => 'Paiement';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionRecordPayment => 'Enregistrer un paiement';

  @override
  String dashboardDueDateLabel(String date) {
    return 'Échéance : $date';
  }

  @override
  String get labelInvoice => 'Facture';

  @override
  String get labelQuotation => 'Devis';

  @override
  String get labelReceipt => 'Reçu';

  @override
  String dashboardWelcomeBackMessage(String username) {
    return 'Bon retour, $username';
  }

  @override
  String get dashboardBusinessGlanceSubtitle =>
      'Voici un aperçu de votre activité';

  @override
  String get dashboardDueSoonTitle => 'Échéance proche';

  @override
  String dashboardInvoiceCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures',
      one: '1 facture',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTodayTomorrowLabel => 'Aujourd\'hui et demain';

  @override
  String get dashboardDueTodayBadge => 'Échéance aujourd\'hui';

  @override
  String get dashboardDueTomorrowBadge => 'Échéance demain';

  @override
  String get dashboardOverdueSectionTitle => 'En retard';

  @override
  String get dashboardOldestFirstLabel => 'Plus anciennes d\'abord';

  @override
  String dashboardDaysOverdueLabel(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours de retard',
      one: '1 jour de retard',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNewStockQuantityLabel => 'Nouvelle quantité en stock';

  @override
  String get actionUpdate => 'Mettre à jour';

  @override
  String get labelService => 'Service';

  @override
  String get labelProduct => 'Produit';

  @override
  String dashboardStockLabel(int count) {
    return 'Stock : $count';
  }

  @override
  String get actionUpdateStock => 'Mettre à jour le stock';

  @override
  String get paymentStatusPaid => 'Payée';

  @override
  String get paymentStatusPartial => 'Partielle';

  @override
  String get paymentStatusUnpaid => 'Impayée';

  @override
  String get dashboardDuplicateInvoiceTitle => 'Dupliquer la facture';

  @override
  String dashboardDuplicateInvoiceBody(String number, String customerName) {
    return 'Créer une copie de la facture n°$number\n($customerName) en tant que :';
  }

  @override
  String get dashboardDeleteInvoiceTitle => 'Supprimer la facture';

  @override
  String dashboardDeleteInvoiceBody(String number) {
    return 'Êtes-vous sûr de vouloir supprimer la facture n°$number ? Cette action est irréversible.';
  }

  @override
  String get dashboardLayoutTooltip => 'Mise en page du tableau de bord';

  @override
  String get dashboardLayoutDefaultTitle => 'Par défaut';

  @override
  String get dashboardLayoutDefaultSubtitle => 'Mise en page d\'origine';

  @override
  String get dashboardLayoutClassicSubtitle => 'Graphiques + grille KPI';

  @override
  String get dashboardLayoutBentoTitle => 'Bento';

  @override
  String get dashboardLayoutBentoSubtitle =>
      'Graphique principal + grille de cartes';

  @override
  String get dashboardLayoutSimpleTitle => 'Flux simple';

  @override
  String get dashboardLayoutSimpleSubtitle => 'Vue en liste épurée';

  @override
  String get dashboardTotalInvoicesLabel => 'Total des factures';

  @override
  String get dashboardRevenueLast6MonthsTitle => 'Revenus — 6 derniers mois';

  @override
  String get dashboardNoPaymentDataYetLabel =>
      'Aucune donnée de paiement pour l\'instant';

  @override
  String get dashboardFinancialOverviewTitle => 'Aperçu financier';

  @override
  String get dashboardCollectedLabel => 'Encaissé';

  @override
  String dashboardInvoiceCountOverdueLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures en retard',
      one: '1 facture en retard',
    );
    return '$_temp0';
  }

  @override
  String dashboardLastNLabel(int n) {
    return '$n dernières';
  }

  @override
  String get labelCustomer => 'Client';

  @override
  String get labelAmount => 'Montant';

  @override
  String get dashboardZeroLeftLabel => '0 restant';

  @override
  String get labelStock => 'Stock';

  @override
  String get actionPay => 'Payer';

  @override
  String get dashboardQuickActionsTitle => 'Actions rapides';

  @override
  String get dashboardPdfActionsTooltip => 'Actions PDF';

  @override
  String get dashboardActionsTooltip => 'Actions';

  @override
  String get dashboardTopCustomersTitle => 'Meilleurs clients';

  @override
  String get dashboardTopProductsTitle => 'Meilleurs produits';

  @override
  String dashboardUnitsLabel(String qty) {
    return '$qty unités';
  }

  @override
  String get dashboardBetaBadge => 'BÊTA';

  @override
  String get dashboardOutOfStockSectionTitle => 'Rupture de stock';

  @override
  String dashboardItemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTapToRestockLabel => 'Appuyez pour réapprovisionner';

  @override
  String get createInvoiceUnsavedChangesTitle =>
      'Modifications non enregistrées';

  @override
  String get createInvoiceUnsavedChangesMessage =>
      'Vous avez des modifications non enregistrées dans cette facture. Les enregistrer avant de quitter ?';

  @override
  String get createInvoiceKeepEditingButton => 'Continuer la modification';

  @override
  String get actionDiscard => 'Abandonner';

  @override
  String createInvoiceErrorLoadingDataMessage(String e) {
    return 'Erreur de chargement des données : $e';
  }

  @override
  String get createInvoiceInsufficientStockTitle => 'Stock insuffisant';

  @override
  String createInvoiceInsufficientStockMessage(int stock, double qty) {
    return 'Seulement $stock unité(s) disponible(s). Ajouter $qty quand même ?';
  }

  @override
  String get createInvoiceAddAnywayButton => 'Ajouter quand même';

  @override
  String get createInvoiceOutOfStockTitle => 'Rupture de stock';

  @override
  String createInvoiceOutOfStockMessage(String name) {
    return '$name est en rupture de stock. Ajouter quand même ?';
  }

  @override
  String get createInvoiceUnlimitedStockLabel => 'Stock illimité';

  @override
  String createInvoiceAvailableStockLabel(int stock) {
    return 'Stock disponible : $stock';
  }

  @override
  String get fieldDiscountLabel => 'Remise';

  @override
  String get fieldUnitPriceOverrideLabel => 'Prix unitaire (remplacer)';

  @override
  String get fieldExtraCostLabel => 'Coût supplémentaire (facultatif)';

  @override
  String get fieldInsertAtPositionLabel => 'Insérer à la position';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get createInvoiceProductAlreadyAddedMessage =>
      'Ce produit a déjà été ajouté';

  @override
  String get createInvoiceCustomerNameRequiredMessage =>
      'Veuillez indiquer le nom du client';

  @override
  String get createInvoiceAtLeastOneItemRequiredMessage =>
      'Veuillez ajouter au moins un article';

  @override
  String createInvoiceCreatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel créé(e) avec succès !';
  }

  @override
  String createInvoiceErrorCreatingMessage(String e) {
    return 'Erreur lors de la création de la facture : $e';
  }

  @override
  String get createInvoiceEditItemTitle => 'Modifier l\'article';

  @override
  String get createInvoiceCustomItemTitle => 'Article personnalisé';

  @override
  String get fieldItemNameLabel => 'Nom de l\'article';

  @override
  String get fieldAliasForPdfLabel => 'Alias (pour le PDF)';

  @override
  String get fieldUnitPriceLabel => 'Prix unitaire';

  @override
  String get fieldRateLabel => 'Taux';

  @override
  String get fieldTaxRateLabel => 'Taux de taxe (%)';

  @override
  String get fieldPriceIncludesTaxLabel => 'Le prix inclut la taxe';

  @override
  String get createInvoicePhoneAlreadyInUseTitle =>
      'Numéro de téléphone déjà utilisé';

  @override
  String createInvoicePhoneAlreadyInUseMessage(String ownerName) {
    return 'Ce numéro de téléphone appartient à « $ownerName ».\n\nImpossible d\'enregistrer ce client avec un numéro de téléphone appartenant déjà à quelqu\'un d\'autre.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get createInvoiceCustomerNameRequiredBeforeSavingMessage =>
      'Veuillez saisir un nom de client avant d\'enregistrer';

  @override
  String get createInvoicePhoneChangedTitle => 'Numéro de téléphone modifié';

  @override
  String createInvoicePhoneChangedMessage(String name) {
    return 'Le numéro de téléphone de « $name » a été modifié.\n\nMettre à jour sa fiche existante, ou enregistrer ces informations comme nouveau client ?';
  }

  @override
  String get createInvoiceSaveAsNewButton => 'Enregistrer comme nouveau';

  @override
  String get createInvoiceUpdateExistingButton => 'Mettre à jour l\'existant';

  @override
  String createInvoiceCustomerUpdatedMessage(String name) {
    return '$name mis à jour dans la liste des clients';
  }

  @override
  String get createInvoiceCustomerAlreadyExistsTitle => 'Le client existe déjà';

  @override
  String createInvoiceCustomerAlreadyExistsMessage(String name) {
    return '« $name » est déjà enregistré avec ce numéro de téléphone.\n\nUtiliser ses informations existantes, ou mettre à jour sa fiche avec les informations actuelles ?';
  }

  @override
  String get createInvoiceUseExistingButton => 'Utiliser l\'existant';

  @override
  String createInvoiceUsingExistingCustomerMessage(String name) {
    return 'Utilisation du client existant « $name »';
  }

  @override
  String createInvoiceCustomerSavedMessage(String name) {
    return '$name enregistré dans la liste des clients';
  }

  @override
  String get createInvoiceCustomerRecordGoneMessage =>
      'La fiche client n\'existe plus';

  @override
  String get createInvoiceCustomerRefreshedMessage =>
      'Informations du client actualisées';

  @override
  String get fieldLabelLabel => 'Libellé';

  @override
  String get hintLabelExample => 'ex. Livraison';

  @override
  String get tooltipRemove => 'Supprimer';

  @override
  String get createInvoiceAddRowButton => 'Ajouter une ligne';

  @override
  String get fieldDiscountPerUnitLabel => 'Remise par unité';

  @override
  String get createInvoiceDiscountPerUnitFormulaOn => '(prix − remise) × qté';

  @override
  String get createInvoiceDiscountPerUnitFormulaOff => '(prix × qté) − remise';

  @override
  String get createInvoicePrevBalanceShortLabel => 'Solde préc.';

  @override
  String get createInvoicePreviousBalanceDueLabel => 'Solde précédent dû';

  @override
  String get createInvoiceDueShortLabel => 'Dû';

  @override
  String get createInvoiceTotalDueLabel => 'Total dû';

  @override
  String createInvoiceUpdatedSuccessMessage(String invoiceTypeLabel) {
    return '$invoiceTypeLabel mis(e) à jour avec succès !';
  }

  @override
  String createInvoiceErrorUpdatingMessage(String e) {
    return 'Erreur lors de la mise à jour de la facture : $e';
  }

  @override
  String createInvoiceCreatedHeadline(String invoiceTypeLabel) {
    return '$invoiceTypeLabel créé(e) avec succès !';
  }

  @override
  String createInvoiceIdLabel(String invoiceTypeLabel, String invoiceNumber) {
    return 'N° de $invoiceTypeLabel : $invoiceNumber';
  }

  @override
  String get createInvoiceViewDetailsLabel => 'Voir les détails';

  @override
  String get createInvoicePreviewPdfLabel => 'Aperçu du PDF';

  @override
  String get createInvoicePreviewPdfTooltip =>
      'Aperçu du PDF (Raccourci : Ctrl+o)';

  @override
  String get createInvoicePrintPdfLabel => 'Imprimer le PDF';

  @override
  String get createInvoicePrintPdfTooltip =>
      'Imprimer le PDF (Raccourci : Ctrl+p)';

  @override
  String get actionDismiss => 'Fermer';

  @override
  String get createInvoiceCreateNewInvoiceButton =>
      'Créer une nouvelle facture (Raccourci : Ctrl+q)';

  @override
  String createInvoiceAppBarTitle(String invoiceTypeLabel) {
    return 'Créer un(e) nouveau/nouvelle $invoiceTypeLabel';
  }

  @override
  String get commonLoadingDataMessage => 'Chargement des données…';

  @override
  String get createInvoiceAddItemBeforeCreatingMessage =>
      'Ajoutez au moins un article avant de créer la facture.';

  @override
  String createInvoiceCreatedTitleShort(String invoiceTypeLabel) {
    return '$invoiceTypeLabel créé(e)';
  }

  @override
  String createInvoiceEditTitle(String invoiceTypeLabel) {
    return 'Modifier $invoiceTypeLabel';
  }

  @override
  String createInvoiceDuplicateAsTitle(String invoiceTypeLabel) {
    return 'Dupliquer en tant que $invoiceTypeLabel';
  }

  @override
  String get createInvoiceNewShortLabel => 'Nouveau';

  @override
  String get createInvoiceNewInvoiceShortcutLabel =>
      'Nouvelle facture (Raccourci : Ctrl+q)';

  @override
  String get createInvoiceSavingEllipsisLabel => 'Enregistrement…';

  @override
  String get createInvoiceSaveCustomerLabel => 'Enregistrer le client';

  @override
  String get createInvoiceSelectExistingCustomerButton =>
      'Sélectionner parmi les existants';

  @override
  String get createInvoiceRefreshCustomerTooltip =>
      'Actualiser depuis le client enregistré';

  @override
  String get createInvoiceClearCustomerTooltip =>
      'Effacer la sélection du client';

  @override
  String get fieldCustomerNameRequiredLabel => 'Nom du client *';

  @override
  String get fieldBusinessNameLabel => 'Nom de l\'entreprise';

  @override
  String get fieldPhoneLabel => 'Téléphone';

  @override
  String get fieldGstinVatLabel => 'N° TVA / GSTIN';

  @override
  String get fieldEmailLabel => 'E-mail';

  @override
  String get fieldAddressLabel => 'Adresse';

  @override
  String get tooltipEditInLargerView => 'Modifier en vue agrandie';

  @override
  String get createInvoiceChooseCustomerTitle => 'Choisir un client';

  @override
  String get createInvoiceSearchCustomerLabel => 'Rechercher un client';

  @override
  String get createInvoiceNoCustomersFoundMessage => 'Aucun client trouvé';

  @override
  String createInvoiceDetailsHeading(String invoiceTypeLabel) {
    return 'DÉTAILS DE $invoiceTypeLabel';
  }

  @override
  String get createInvoiceTypeFieldLabel => 'Type de facture';

  @override
  String get createInvoiceTypeLockedHelperText =>
      'Le type ne peut pas être modifié après création';

  @override
  String get createInvoiceOrderDateLabel => 'Date de commande';

  @override
  String get createInvoiceDueDateLabel => 'Date d\'échéance';

  @override
  String get createInvoiceGstTitleLabel => 'Titre GST';

  @override
  String get createInvoiceTaxTitleLabel => 'Titre de la taxe';

  @override
  String get gstTitleTaxInvoiceLabel => 'Facture fiscale';

  @override
  String get gstTitleBillOfSupplyLabel => 'Bordereau de livraison';

  @override
  String get gstTitleInvoiceCumBillLabel => 'Facture-bordereau de livraison';

  @override
  String get gstTitleCashBillLabel => 'Cash Bill';

  @override
  String get gstTitleCreditNoteLabel => 'Note de crédit';

  @override
  String get gstTitleDebitNoteLabel => 'Note de débit';

  @override
  String get gstTitleRevisedInvoiceLabel => 'Facture révisée';

  @override
  String get createInvoiceSearchProductLabel =>
      'Rechercher et ajouter un produit ou service (Ctrl+F)';

  @override
  String get createInvoiceCustomItemButton => 'Article personnalisé (Ctrl+M)';

  @override
  String get createInvoiceNoProductsFoundMessage => 'Aucun produit trouvé';

  @override
  String createInvoiceItemAlreadyInProductListMessage(String name) {
    return '« $name » existe déjà dans la liste des produits';
  }

  @override
  String createInvoiceProductSavedMessage(String name) {
    return '$name enregistré dans la liste des produits';
  }

  @override
  String get createInvoiceSaveToProductListTooltip =>
      'Enregistrer dans la liste des produits';

  @override
  String get tooltipEditItem => 'Modifier l\'article';

  @override
  String get tooltipRemoveItem => 'Supprimer l\'article';

  @override
  String get createInvoiceNoItemsAddedMessage =>
      'Aucun article ajouté pour le moment';

  @override
  String get createInvoiceSearchHintMessage =>
      'Recherchez ci-dessous ou appuyez sur Ctrl+F';

  @override
  String get createInvoiceDiscountFieldLabel => 'Remise sur la facture';

  @override
  String get discountTypeAmountShortLabel => 'Mnt';

  @override
  String get createInvoiceNotesOptionalLabel => 'Notes (facultatif)';

  @override
  String get createInvoiceNotesHint =>
      'Conditions de paiement, mot de remerciement…';

  @override
  String get createInvoiceNotesTitle => 'Notes';

  @override
  String get createInvoiceHideNumberInPdfLabel =>
      'Masquer le numéro de facture dans le PDF';

  @override
  String get createInvoiceCustomNumberLabel =>
      'Numéro personnalisé (facultatif)';

  @override
  String get createInvoiceCustomNumberHint =>
      'ex. QUO-2026-014 — affiché dans le PDF à la place';

  @override
  String get createInvoiceEnableTaxLabel => 'Activer la taxe';

  @override
  String get createInvoiceGlobalRateTooltip => 'Taux global';

  @override
  String get createInvoicePerItemRateTooltip => 'Taux par article';

  @override
  String get createInvoiceDefaultTaxRateLabel => 'Taux de taxe par défaut';

  @override
  String get createInvoiceTaxRateFromProductMessage =>
      'Taux de taxe de chaque produit';

  @override
  String get createInvoiceInterStateLabel => 'Interstate supply (IGST)';

  @override
  String get createInvoicePaymentUpiAccountLabel => 'Compte UPI de paiement';

  @override
  String get commonNoneLabel => 'Aucun';

  @override
  String get createInvoiceBankAccountLabel => 'Compte bancaire';

  @override
  String get fieldSubtotalLabel => 'Sous-total';

  @override
  String get createInvoiceDiscountColonLabel => 'Remise :';

  @override
  String get fieldTaxLabel => 'Taxe';

  @override
  String get createInvoiceExtraCostFallbackLabel => 'Coût supplémentaire';

  @override
  String createInvoiceDiscountPercentLabel(String toStringAsFixed) {
    return 'Remise sur la facture ($toStringAsFixed%) :';
  }

  @override
  String get createInvoiceInvoiceDiscountColonLabel =>
      'Remise sur la facture :';

  @override
  String get fieldTotalLabel => 'Total';

  @override
  String get createInvoicePreviewLabel => 'Aperçu';

  @override
  String get createInvoicePreviewTooltip => 'Aperçu (Raccourci : Ctrl+o)';

  @override
  String get createInvoiceDownloadLabel => 'Télécharger';

  @override
  String get createInvoicePrintTooltip => 'Imprimer (Raccourci : Ctrl+p)';

  @override
  String get fieldUnitOverrideLabel => 'Unité (remplacer)';

  @override
  String get commonCustomEllipsisLabel => 'Personnalisé…';

  @override
  String get fieldCustomUnitLabel => 'Unité personnalisée';

  @override
  String get invoiceMgmtMoveToTrashTitle => 'Déplacer vers la corbeille';

  @override
  String invoiceMgmtMoveToTrashBody(String number) {
    return 'Déplacer la facture #$number vers la corbeille ?';
  }

  @override
  String get invoiceMgmtMovedToTrashMessage =>
      'Facture déplacée vers la corbeille.';

  @override
  String invoiceMgmtFailedToLoadMessage(String error) {
    return 'Échec du chargement des factures : $error';
  }

  @override
  String invoiceMgmtExportToCsvTitle(String type) {
    return 'Exporter $type au format CSV';
  }

  @override
  String get invoiceMgmtExportAllRecordsLabel =>
      'Exporter tous les enregistrements';

  @override
  String get invoiceMgmtFilterByDateRangeLabel =>
      'Ou filtrer par plage de dates :';

  @override
  String get invoiceMgmtFromDateLabel => 'Date de début';

  @override
  String get invoiceMgmtToDateLabel => 'Date de fin';

  @override
  String get invoiceMgmtDateRangeInvalidMessage =>
      'La date de fin doit être postérieure à la date de début.';

  @override
  String get actionExport => 'Exporter';

  @override
  String invoiceMgmtExportedRecordsMessage(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements exportés vers : $path',
      one: '1 enregistrement exporté vers : $path',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtExportFailedMessage(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String invoiceMgmtBulkMoveToTrashBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Déplacer $count factures vers la corbeille ?',
      one: 'Déplacer 1 facture vers la corbeille ?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkMovedToTrashMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures déplacées vers la corbeille.',
      one: '1 facture déplacée vers la corbeille.',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtBulkDeleteFailedMessage(String error) {
    return 'Échec de la suppression groupée : $error';
  }

  @override
  String invoiceMgmtBulkExportedCsvMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures exportées en CSV',
      one: '1 facture exportée en CSV',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtCsvExportFailedMessage(String error) {
    return 'Échec de l\'exportation CSV : $error';
  }

  @override
  String get invoiceMgmtDownloadPdfsTitle => 'Télécharger les PDF';

  @override
  String invoiceMgmtSavePdfsPromptMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Comment souhaitez-vous enregistrer $count PDF ?',
      one: 'Comment souhaitez-vous enregistrer 1 PDF ?',
    );
    return '$_temp0';
  }

  @override
  String get invoiceMgmtSaveToFolderLabel => 'Enregistrer dans un dossier';

  @override
  String get invoiceMgmtSaveAsZipLabel => 'Enregistrer en ZIP';

  @override
  String get invoiceMgmtChooseFolderDialogTitle =>
      'Choisir le dossier pour enregistrer les PDF';

  @override
  String get invoiceMgmtSaveZipDialogTitle => 'Enregistrer le fichier ZIP';

  @override
  String get invoiceMgmtCreatingZipLabel => 'Création du ZIP';

  @override
  String get invoiceMgmtGeneratingPdfsLabel => 'Génération des PDF';

  @override
  String invoiceMgmtProcessingPdfsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Traitement de $count PDF...',
      one: 'Traitement de 1 PDF...',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtSavedToMessage(String path) {
    return 'Enregistré dans : $path';
  }

  @override
  String invoiceMgmtPdfExportFailedMessage(String error) {
    return 'Échec de l\'exportation PDF : $error';
  }

  @override
  String get invoiceMgmtDownloadByFilterTitle =>
      'Télécharger les PDF par filtre';

  @override
  String get invoiceMgmtByDateLabel => 'Par date';

  @override
  String get invoiceMgmtByInvoiceNumberLabel => 'Par numéro de facture';

  @override
  String get invoiceMgmtFromInvoiceNumberLabel => 'De la facture n°';

  @override
  String get invoiceMgmtToInvoiceNumberLabel => 'À la facture n°';

  @override
  String get invoiceMgmtCheckCountLabel => 'Vérifier le nombre';

  @override
  String invoiceMgmtInvoicesExceedLimitMessage(int count, int limit) {
    return '$count factures — dépasse la limite de $limit';
  }

  @override
  String invoiceMgmtInvoicesMatchMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures correspondent',
      one: '1 facture correspond',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMaxPdfsPerDownloadMessage(int limit) {
    return 'Maximum $limit PDF par téléchargement. Affinez votre filtre.';
  }

  @override
  String get invoiceMgmtNoInvoicesForFilterMessage =>
      'Aucune facture trouvée pour le filtre sélectionné.';

  @override
  String invoiceMgmtFilterExceedsLimitMessage(int count, int limit) {
    return 'Le filtre a renvoyé $count factures — le maximum est $limit.';
  }

  @override
  String get invoiceMgmtFilterInvoicesTitle => 'Filtrer les factures';

  @override
  String get invoiceMgmtHideFullyPaidLabel =>
      'Masquer les factures entièrement payées';

  @override
  String get invoiceMgmtPaymentStatusLabel => 'Statut de paiement';

  @override
  String get invoiceMgmtDueDateLabel => 'Date d\'échéance';

  @override
  String get invoiceMgmtInvoiceDateRangeLabel => 'Plage de dates de facture';

  @override
  String get invoiceMgmtInvoiceNumberRangeLabel =>
      'Plage de numéros de facture';

  @override
  String get invoiceMgmtFromHashLabel => 'De n°';

  @override
  String get invoiceMgmtToHashLabel => 'À n°';

  @override
  String get actionReset => 'Réinitialiser';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get invoiceMgmtSortByTitle => 'Trier par';

  @override
  String get invoiceMgmtSearchHintMessage =>
      'Rechercher par n° de facture ou nom du client…';

  @override
  String get invoiceMgmtFilterLabel => 'Filtrer';

  @override
  String get invoiceMgmtSortLabel => 'Trier';

  @override
  String invoiceMgmtTotalPageStatusLabel(int total, int page, int totalPages) {
    return 'Total : $total   ·   Page $page/$totalPages';
  }

  @override
  String invoiceMgmtSelectedCountLabel(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get invoiceMgmtDeselectLabel => 'Désélectionner';

  @override
  String get invoiceMgmtSelectPageLabel => 'Sélectionner la page';

  @override
  String get invoiceMgmtMarkPaidLabel => 'Marquer comme payé';

  @override
  String get invoiceMgmtCsvLabel => 'CSV';

  @override
  String get invoiceMgmtPdfsLabel => 'PDF';

  @override
  String get invoiceMgmtTrashLabel => 'Corbeille';

  @override
  String get actionApplyPayment => 'Appliquer un paiement';

  @override
  String get invoiceMgmtMoreActionsTooltip => 'Plus d\'actions';

  @override
  String get invoiceMgmtColSlNo => 'N°';

  @override
  String get invoiceMgmtColInvoiceCustomer => 'Facture / Client';

  @override
  String get invoiceMgmtColTitle => 'Titre';

  @override
  String get invoiceMgmtColDate => 'Date';

  @override
  String get invoiceMgmtColItems => 'Articles';

  @override
  String get invoiceMgmtColStatus => 'Statut';

  @override
  String get invoiceMgmtColOutstanding => 'Solde dû';

  @override
  String get invoiceMgmtColActions => 'Actions';

  @override
  String get invoiceMgmtRowsPerPageLabel => 'Lignes par page :';

  @override
  String get actionPrevious => 'Précédent';

  @override
  String invoiceMgmtPageOfLabel(int page, int totalPages) {
    return 'Page $page sur $totalPages';
  }

  @override
  String invoiceMgmtNoResultsForQueryMessage(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String invoiceMgmtNoFilteredTypeFoundMessage(String type) {
    return 'Aucun(e) $type trouvé(e)';
  }

  @override
  String invoiceMgmtCreateFirstTypeMessage(String type) {
    return 'Créez votre premier(ère) $type pour le/la voir ici';
  }

  @override
  String get invoiceMgmtTryAdjustingFiltersMessage =>
      'Essayez d\'ajuster votre recherche ou vos filtres';

  @override
  String get invoiceMgmtDownloadByRangeTooltip =>
      'Télécharger les PDF par date ou plage de factures';

  @override
  String get invoiceMgmtExportAllCsvTooltip => 'Tout exporter en CSV';

  @override
  String get invoiceMgmtDownloadByRangeMenuLabel =>
      'Télécharger les PDF par plage';

  @override
  String invoiceMgmtManagementTitle(String type) {
    return 'Gestion des $type';
  }

  @override
  String get invoiceMgmtOverdueBadge => 'En retard';

  @override
  String get invoiceMgmtTodayBadge => 'Aujourd\'hui';

  @override
  String get invoiceMgmtTrashIsEmptyLabel => 'La corbeille est vide';

  @override
  String get actionRestore => 'Restaurer';

  @override
  String get invoiceMgmtPermanentlyDeleteTitle => 'Supprimer définitivement';

  @override
  String invoiceMgmtPermanentlyDeleteBody(String number) {
    return 'Supprimer définitivement la facture #$number ? Cette action est irréversible.';
  }

  @override
  String get invoiceMgmtInvoiceRestoredMessage => 'Facture restaurée.';

  @override
  String get invoiceMgmtAnyDateLabel => 'Toutes';

  @override
  String get invoiceMgmtStatusAllLabel => 'Tous';

  @override
  String get invoiceMgmtDueAllLabel => 'Toutes échéances';

  @override
  String get invoiceMgmtDueTodayLabel => 'Échéance aujourd\'hui';

  @override
  String get invoiceMgmtDueWeekLabel => 'Échéance cette semaine';

  @override
  String get invoiceMgmtDueMonthLabel => 'Échéance ce mois-ci';

  @override
  String get invoiceMgmtSortRecentlyAdded => 'Ajouté récemment';

  @override
  String get invoiceMgmtSortOldestAdded => 'Ajouté le plus anciennement';

  @override
  String get invoiceMgmtSortDateNewest =>
      'Date de facture (plus récent d\'abord)';

  @override
  String get invoiceMgmtSortDateOldest =>
      'Date de facture (plus ancien d\'abord)';

  @override
  String get invoiceMgmtSortCustomerAZ => 'Nom du client (A–Z)';

  @override
  String get invoiceMgmtSortCustomerZA => 'Nom du client (Z–A)';

  @override
  String get invoiceMgmtMarkAsPaidTitle => 'Marquer comme payé';

  @override
  String invoiceMgmtMarkAsPaidBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marquer $count factures comme entièrement payées ?',
      one: 'Marquer 1 facture comme entièrement payée ?',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtAlreadyPaidNoteMessage(int count) {
    return '\n($count déjà payée(s) — sera(seront) ignorée(s))';
  }

  @override
  String get invoiceMgmtAllAlreadyPaidMessage =>
      'Toutes les factures sélectionnées sont déjà entièrement payées.';

  @override
  String invoiceMgmtMarkedAsPaidMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count factures marquées comme payées.',
      one: '1 facture marquée comme payée.',
    );
    return '$_temp0';
  }

  @override
  String invoiceMgmtMarkAsPaidFailedMessage(String error) {
    return 'Échec du marquage comme payé : $error';
  }

  @override
  String get fieldNameLabel => 'Nom';

  @override
  String get customerMgmtEditCustomerTitle => 'Modifier le client';

  @override
  String get customerMgmtViewCustomerTitle => 'Voir le client';

  @override
  String fieldTaxVatNumberLabel(String taxWord) {
    return '$taxWord / Numéro de TVA';
  }

  @override
  String get customerMgmtUpdatedMessage => 'Client mis à jour avec succès !';

  @override
  String fieldRequiredMessage(String field) {
    return 'Veuillez saisir $field';
  }

  @override
  String get customerMgmtConfirmDeleteTitle => 'Confirmer la suppression';

  @override
  String customerMgmtDeleteConfirmBody(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?';
  }

  @override
  String get customerMgmtDeletedMessage => 'Client supprimé avec succès !';

  @override
  String get customerMgmtSaveSampleCsvDialogTitle =>
      'Enregistrer l\'exemple CSV';

  @override
  String get customerMgmtSampleSavedMessage =>
      'Exemple CSV enregistré avec succès !';

  @override
  String customerMgmtErrorSavingSampleMessage(String error) {
    return 'Erreur lors de l\'enregistrement de l\'exemple : $error';
  }

  @override
  String get customerMgmtImportCsvDialogTitle =>
      'Importer des clients depuis un CSV';

  @override
  String get customerMgmtCsvFormatInstructionMessage =>
      'Votre fichier CSV doit utiliser les en-têtes de colonne suivants (orthographe exacte, ordre indifférent) :';

  @override
  String get customerMgmtCsvColColumnHeader => 'Colonne';

  @override
  String get customerMgmtCsvColRequiredHeader => 'Requis';

  @override
  String get customerMgmtCsvColDescriptionHeader => 'Description';

  @override
  String get commonYesLabel => 'Oui';

  @override
  String get commonNoLabel => 'Non';

  @override
  String get customerMgmtCsvDescName => 'Nom complet du client';

  @override
  String get customerMgmtCsvDescEmail => 'Adresse e-mail';

  @override
  String get customerMgmtCsvDescPhone => 'Numéro de téléphone';

  @override
  String get customerMgmtCsvDescAddress => 'Adresse complète';

  @override
  String get customerMgmtCsvDescBusinessName => 'Nom de l\'entreprise';

  @override
  String get customerMgmtCsvDescTaxNumber => 'Numéro de taxe / TVA / GSTIN';

  @override
  String customerMgmtCsvMaxRowsNote(int max) {
    return 'Maximum $max lignes par importation.';
  }

  @override
  String get customerMgmtCsvDuplicatesNote =>
      'Les doublons sont détectés par e-mail ou téléphone. Il vous sera demandé d\'écraser ou d\'ignorer chacun d\'eux.';

  @override
  String get customerMgmtCsvMissingNameNote =>
      'Les lignes sans nom sont ignorées et signalées à la fin.';

  @override
  String get customerMgmtCsvEncodingNote =>
      'Encodage UTF-8 recommandé. Le BOM Excel est géré automatiquement.';

  @override
  String get customerMgmtDownloadSampleCsvButton =>
      'Télécharger l\'exemple CSV';

  @override
  String get customerMgmtChooseFileButton => 'Choisir un fichier';

  @override
  String get customerMgmtSelectCsvDialogTitle =>
      'Sélectionner le CSV des clients';

  @override
  String get customerMgmtCsvEmptyMessage => 'Le fichier CSV est vide.';

  @override
  String get customerMgmtCsvMissingNameColumnMessage =>
      'Colonne requise manquante dans le CSV : \"name\"';

  @override
  String customerMgmtUnknownColumnMessage(String col, String expected) {
    return 'Colonne inconnue \"$col\". Attendu : $expected';
  }

  @override
  String customerMgmtCsvTooManyRowsMessage(int count, int max) {
    return 'Le CSV contient $count lignes. Le maximum est $max. Veuillez diviser le fichier.';
  }

  @override
  String get customerMgmtImportingTitle => 'Importation des clients';

  @override
  String customerMgmtValidatingRowsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vérification des doublons et validation de $count lignes...',
      one: 'Vérification des doublons et validation de 1 ligne...',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtRowMissingNameMessage(int n) {
    return 'Ligne $n : nom manquant — ignorée';
  }

  @override
  String customerMgmtCsvReadErrorMessage(String error) {
    return 'Erreur de lecture du CSV : $error';
  }

  @override
  String get customerMgmtImportPreviewTitle => 'Aperçu de l\'importation';

  @override
  String customerMgmtNewCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux',
      one: '1 nouveau',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtDuplicatesCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doublons',
      one: '1 doublon',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtErrorsCountChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erreurs',
      one: '1 erreur',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDuplicatesMatchedLabel =>
      'Doublons (identifiés par e-mail ou téléphone) :';

  @override
  String get customerMgmtOverwriteAllButton => 'Tout écraser';

  @override
  String get customerMgmtSkipAllButton => 'Tout ignorer';

  @override
  String get customerMgmtOverwriteLabel => 'Écraser';

  @override
  String get customerMgmtSkippedRowsLabel => 'Lignes ignorées (erreurs) :';

  @override
  String customerMgmtErrorBulletLabel(String error) {
    return '• $error';
  }

  @override
  String customerMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total clients seront importés.',
      one: '1 client sera importé.',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportCountButton(int total) {
    return 'Importer $total';
  }

  @override
  String get customerMgmtDeleteAllTitle => 'Supprimer tous les clients';

  @override
  String get customerMgmtNoCustomersToDeleteMessage =>
      'Aucun client à supprimer.';

  @override
  String customerMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cela supprimera définitivement les $count clients. Les factures existantes ne sont pas affectées. Cette action est irréversible.',
      one:
          'Cela supprimera définitivement le 1 client. Les factures existantes ne sont pas affectées. Cette action est irréversible.',
    );
    return '$_temp0';
  }

  @override
  String get customerMgmtDeleteAllButton => 'Tout supprimer';

  @override
  String get customerMgmtAllDeletedMessage =>
      'Tous les clients ont été supprimés.';

  @override
  String customerMgmtDeleteAllErrorMessage(String error) {
    return 'Erreur lors de la suppression des clients : $error';
  }

  @override
  String get customerMgmtSaveCsvDialogTitle => 'Enregistrer le CSV des clients';

  @override
  String get customerMgmtCsvExportedMessage => 'CSV exporté avec succès !';

  @override
  String customerMgmtCsvExportErrorMessage(String error) {
    return 'Erreur lors de l\'exportation du CSV : $error';
  }

  @override
  String get customerMgmtSavePdfDialogTitle => 'Enregistrer le PDF des clients';

  @override
  String get customerMgmtPdfExportedMessage => 'PDF exporté avec succès !';

  @override
  String customerMgmtPdfExportErrorMessage(String error) {
    return 'Erreur lors de l\'exportation du PDF : $error';
  }

  @override
  String get customerMgmtTotalCustomersLabel => 'Total des clients';

  @override
  String get customerMgmtAllCustomersSubtitle => 'Tous les clients';

  @override
  String get customerMgmtBusinessesLabel => 'Entreprises';

  @override
  String get customerMgmtRegisteredBusinessesSubtitle =>
      'Entreprises enregistrées';

  @override
  String get customerMgmtIndividualsLabel => 'Particuliers';

  @override
  String get customerMgmtIndividualCustomersSubtitle => 'Clients particuliers';

  @override
  String customerMgmtTaxRegisteredLabel(String taxWord) {
    return '$taxWord enregistrés';
  }

  @override
  String customerMgmtWithTaxNumberSubtitle(String taxWord) {
    return 'Avec numéro de $taxWord';
  }

  @override
  String customerMgmtWithoutTaxLabel(String taxWord) {
    return 'Sans $taxWord';
  }

  @override
  String get customerMgmtTitle => 'Gestion des clients';

  @override
  String get customerMgmtSubtitle => 'Gérez vos clients et leurs coordonnées';

  @override
  String get actionImport => 'Importer';

  @override
  String get customerMgmtExportPdfMenuLabel => 'Exporter en PDF';

  @override
  String get customerMgmtNewCustomerButton => 'Nouveau client';

  @override
  String get customerMgmtSortNameAZ => 'Nom A-Z';

  @override
  String get customerMgmtSortNameZA => 'Nom Z-A';

  @override
  String get customerMgmtSortIdOldest => 'ID (plus ancien d\'abord)';

  @override
  String get customerMgmtSortIdNewest => 'ID (plus récent d\'abord)';

  @override
  String get customerMgmtSortOutstandingHighLow => 'Solde dû (décroissant)';

  @override
  String get customerMgmtSortOutstandingLowHigh => 'Solde dû (croissant)';

  @override
  String get customerMgmtWithOutstandingLabel => 'Avec solde dû';

  @override
  String customerMgmtSearchHint(String taxWord) {
    return 'Rechercher des clients par nom, entreprise, téléphone, $taxWord, e-mail…';
  }

  @override
  String customerMgmtAllTaxStatusesLabel(String taxWord) {
    return 'Tous les statuts $taxWord';
  }

  @override
  String customerMgmtTaxRegisteredLowerLabel(String taxWord) {
    return '$taxWord enregistrés';
  }

  @override
  String customerMgmtSortWithLabel(String label) {
    return 'Trier : $label';
  }

  @override
  String get customerMgmtColumnsLabel => 'Colonnes';

  @override
  String customerMgmtTaxVatNoColumnLabel(String taxWord) {
    return '$taxWord / N° TVA';
  }

  @override
  String get customerMgmtHideStatCardsTooltip => 'Masquer les statistiques';

  @override
  String get customerMgmtShowStatCardsTooltip => 'Afficher les statistiques';

  @override
  String customerMgmtTabChipLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get customerMgmtColSlNo => 'N°';

  @override
  String get customerMgmtColNameBusiness => 'NOM / ENTREPRISE';

  @override
  String get customerMgmtColPhone => 'TÉLÉPHONE';

  @override
  String get customerMgmtColEmail => 'E-MAIL';

  @override
  String customerMgmtColTaxVatNo(String taxWord) {
    return '$taxWord / N° TVA';
  }

  @override
  String get customerMgmtColAddress => 'ADRESSE';

  @override
  String get customerMgmtColActions => 'ACTIONS';

  @override
  String get customerMgmtViewStatementTooltip =>
      'Voir le relevé (dans Rapports)';

  @override
  String customerMgmtShowingRangeLabel(int from, int to, int total) {
    return 'Affichage de $from à $to sur $total clients';
  }

  @override
  String get customerMgmtRowsPerPageLabel => 'Lignes par page';

  @override
  String customerMgmtOfTotalPagesLabel(int totalPages) {
    return 'sur $totalPages';
  }

  @override
  String get customerMgmtAddAnotherLabel =>
      'Ajouter un autre après l\'enregistrement';

  @override
  String get customerMgmtSaveCustomerButton => 'Enregistrer le client';

  @override
  String get customerMgmtAddFirstCustomerSubtitle =>
      'Ajoutez votre premier client pour commencer';

  @override
  String get customerMgmtTryAdjustingSearchSubtitle =>
      'Essayez d\'ajuster votre recherche';

  @override
  String customerMgmtLoadErrorMessage(String error) {
    return 'Erreur lors du chargement des clients : $error';
  }

  @override
  String get customerMgmtAddedMessage => 'Client ajouté avec succès !';

  @override
  String customerMgmtSaveErrorMessage(String error) {
    return 'Erreur lors de l\'enregistrement du client : $error';
  }

  @override
  String customerMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients importés avec succès !',
      one: '1 client importé avec succès !',
    );
    return '$_temp0';
  }

  @override
  String customerMgmtImportErrorMessage(String error) {
    return 'Erreur d\'importation : $error';
  }

  @override
  String get taxWordGst => 'TPS';

  @override
  String get taxWordTax => 'Taxe';

  @override
  String get commonMoreLabel => 'Plus';

  @override
  String get productMgmtSellingAtLossTitle => 'Vente à perte';

  @override
  String productMgmtSellingAtLossMessage(String purchase, String sale) {
    return 'Le prix d\'achat ($purchase) est supérieur au prix de vente ($sale). Enregistrer quand même ?';
  }

  @override
  String get actionSaveAnyway => 'Enregistrer quand même';

  @override
  String get productMgmtAdvancedInformationLabel => 'Informations avancées';

  @override
  String get productMgmtStorageLocationLabel => 'Emplacement de stockage';

  @override
  String get productMgmtContainerNumberLabel => 'Numéro de conteneur';

  @override
  String get productMgmtBatchNumberLabel => 'Numéro de lot';

  @override
  String get productMgmtExpiryDateLabel => 'Date d\'expiration';

  @override
  String get productMgmtManufactureDateLabel => 'Date de fabrication';

  @override
  String get productMgmtSupplierNameLabel => 'Nom du fournisseur';

  @override
  String get productMgmtSkuCodeLabel => 'Code SKU';

  @override
  String get productMgmtNotesLabel => 'Notes';

  @override
  String get fieldEnterValidPriceMessage => 'Saisissez un prix valide';

  @override
  String get fieldEnterValidStockMessage => 'Saisissez un stock valide';

  @override
  String get fieldTaxRangeMessage =>
      'La taxe doit être comprise entre 0 et 100';

  @override
  String get productMgmtImportProductsCsvTitle =>
      'Importer des produits depuis un CSV';

  @override
  String get productMgmtCsvDescName => 'Nom du produit';

  @override
  String get productMgmtCsvDescPrice => 'Prix unitaire (numérique)';

  @override
  String get productMgmtCsvDescHsnCode => 'Code HSN / SAC';

  @override
  String get productMgmtCsvDescDescription => 'Description courte';

  @override
  String get productMgmtCsvDescTaxRate => 'Taxe % (0–100), par défaut 0';

  @override
  String get productMgmtCsvDescStock => 'Quantité en stock, par défaut 0';

  @override
  String get productMgmtCsvDescType =>
      '« product » ou « service », par défaut product';

  @override
  String get productMgmtCsvDescDefaultDiscount =>
      'Montant de la remise fixe (devise), par défaut 0';

  @override
  String get productMgmtCsvDescPurchasePrice =>
      'Prix de revient (numérique), par défaut 0';

  @override
  String get productMgmtCsvDescAliasName =>
      'Nom d\'affichage en langue locale pour les PDF';

  @override
  String get productMgmtCsvDescUnit =>
      'Unité de mesure (ex. kg, sac, pcs), par défaut pcs';

  @override
  String get productMgmtCsvDescUnlimitedStock =>
      '1/true pour un stock illimité, par défaut 0';

  @override
  String get productMgmtCsvDescPriceIncludesTax =>
      '1/true si le prix inclut déjà la taxe, par défaut 0';

  @override
  String get productMgmtCsvDescStorageLocation =>
      'Emplacement d\'entrepôt/étagère';

  @override
  String get productMgmtCsvDescContainerNumber => 'Numéro de conteneur/boîte';

  @override
  String get productMgmtCsvDescBatchNumber => 'Numéro de lot';

  @override
  String get productMgmtCsvDescExpiryDate => 'Date d\'expiration';

  @override
  String get productMgmtCsvDescManufactureDate => 'Date de fabrication';

  @override
  String get productMgmtCsvDescSupplierName => 'Nom du fournisseur';

  @override
  String get productMgmtCsvDescSkuCode => 'Code SKU';

  @override
  String get productMgmtCsvDescNotes => 'Notes en texte libre';

  @override
  String get productMgmtCsvDuplicateNote =>
      'Les doublons sont détectés par nom de produit (insensible à la casse). Vous serez invité à écraser ou ignorer chacun.';

  @override
  String get productMgmtCsvMissingRequiredNote =>
      'Les lignes sans nom ou prix sont ignorées et signalées.';

  @override
  String get productMgmtSelectCsvDialogTitle =>
      'Sélectionner le CSV des produits';

  @override
  String get productMgmtCsvMissingPriceColumnMessage =>
      'Colonne requise manquante dans le CSV : « price »';

  @override
  String productMgmtRowInvalidPriceMessage(int n, String price) {
    return 'Ligne $n : prix invalide « $price » — ignorée';
  }

  @override
  String get productMgmtImportingTitle => 'Importation des produits';

  @override
  String get productMgmtDuplicatesMatchedByNameLabel =>
      'Doublons (correspondant par nom) :';

  @override
  String productMgmtWillImportMessage(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total produits seront importés.',
      one: '1 produit sera importé.',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtNoProductsToDeleteMessage =>
      'Aucun produit à supprimer.';

  @override
  String get productMgmtDeleteAllTitle => 'Supprimer tous les produits';

  @override
  String productMgmtDeleteAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cela supprimera définitivement les $count produits. Les factures existantes ne sont pas affectées. Cette action est irréversible.',
      one:
          'Cela supprimera définitivement le seul produit. Les factures existantes ne sont pas affectées. Cette action est irréversible.',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtAllDeletedMessage =>
      'Tous les produits ont été supprimés.';

  @override
  String productMgmtDeleteAllErrorMessage(String error) {
    return 'Erreur lors de la suppression des produits : $error';
  }

  @override
  String get productMgmtSaveProductsCsvDialogTitle =>
      'Enregistrer le CSV des produits';

  @override
  String get productMgmtExportToPdfTitle => 'Exporter en PDF';

  @override
  String productMgmtExportPdfChoiceMessage(int pageSize, int allCount) {
    return 'Exporter la page actuelle ($pageSize produits) ou tous les $allCount produits ?';
  }

  @override
  String get productMgmtCurrentPageLabel => 'Page actuelle';

  @override
  String get productMgmtAllProductsLabel => 'Tous les produits';

  @override
  String get productMgmtSaveProductsPdfDialogTitle =>
      'Enregistrer le PDF des produits';

  @override
  String get productMgmtTitle => 'Gestion des produits';

  @override
  String get productMgmtSubtitle => 'Gérez vos produits et services';

  @override
  String get productMgmtNewProductButton => 'Nouveau produit';

  @override
  String get productMgmtSearchHint =>
      'Rechercher des produits par nom, alias, HSN/SAC, SKU…';

  @override
  String get productMgmtFilterByStockStatusTooltip =>
      'Filtrer par statut de stock';

  @override
  String get productMgmtAllStockLevelsLabel => 'Tous les niveaux de stock';

  @override
  String get productMgmtLowStockLabel => 'Stock faible';

  @override
  String get productMgmtLowStockTabLabel => 'Stock faible';

  @override
  String get productMgmtOutOfStockLabel => 'Rupture de stock';

  @override
  String get productMgmtOutOfStockTabLabel => 'Rupture de stock';

  @override
  String get productMgmtExpiredLabel => 'Expiré';

  @override
  String get productMgmtSortPriceLowHigh => 'Prix croissant';

  @override
  String get productMgmtSortPriceHighLow => 'Prix décroissant';

  @override
  String get productMgmtSortStockLowHigh => 'Stock croissant';

  @override
  String get productMgmtSortStockHighLow => 'Stock décroissant';

  @override
  String get productMgmtServicesTabLabel => 'Services';

  @override
  String get productMgmtColSlNo => 'N° SÉQ.';

  @override
  String get productMgmtColNameAlias => 'NOM / ALIAS';

  @override
  String get productMgmtColHsnSac => 'HSN / SAC';

  @override
  String get productMgmtColPrice => 'PRIX';

  @override
  String get productMgmtColPurchase => 'ACHAT';

  @override
  String get productMgmtColStock => 'STOCK';

  @override
  String get productMgmtColTaxPercent => 'TAXE %';

  @override
  String get productMgmtColExpiryDate => 'DATE D\'EXPIRATION';

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
    return 'Affichage de $from à $to sur $total produits';
  }

  @override
  String get productMgmtAddFirstProductSubtitle =>
      'Ajoutez votre premier produit pour commencer';

  @override
  String get productMgmtColumnsBannerTitle =>
      'Nouveau : personnalisez les champs produit';

  @override
  String get productMgmtColumnsBannerSubtitle =>
      'Choisissez les champs à afficher pour un catalogue plus simple. Paramètres > Personnaliser les détails du produit.';

  @override
  String get productMgmtConfigureAction => 'Configurer';

  @override
  String productMgmtAddNewItemTitle(String type) {
    return 'Ajouter un nouveau $type';
  }

  @override
  String get productMgmtEnterProductDetailsSubtitle =>
      'Saisissez les détails du produit';

  @override
  String get productMgmtSaveProductButton => 'Enregistrer le produit';

  @override
  String get productMgmtAliasNameLabel =>
      'Nom d\'alias (pour le PDF de la facture)';

  @override
  String get productMgmtAliasHelperText =>
      'Nom d\'affichage optionnel en langue locale utilisé uniquement sur les factures PDF.';

  @override
  String get productMgmtDescriptionLabel => 'Description';

  @override
  String get productMgmtHsnSacLabel => 'HSN/SAC';

  @override
  String get productMgmtSalePriceLabel => 'Prix de vente';

  @override
  String get productMgmtPurchasePriceLabel => 'Prix d\'achat';

  @override
  String get productMgmtDefaultDiscountLabel => 'Remise par défaut';

  @override
  String get productMgmtTaxPercentLabel => 'Taxe (%)';

  @override
  String get productMgmtPerItemTaxModeOnlyLabel =>
      'Mode taxe par article uniquement';

  @override
  String get productMgmtSectionGeneral => 'Général';

  @override
  String get productMgmtSectionPricing => 'Tarification';

  @override
  String get productMgmtSectionInventory => 'Inventaire';

  @override
  String get productMgmtUnlimitedStockLabel => 'Stock illimité';

  @override
  String get productMgmtTrackInfiniteStockSubtitle =>
      'Suivre un stock infini pour ce produit';

  @override
  String get productMgmtTipEnableCustomFieldsMessage =>
      'Astuce : activez des champs personnalisés depuis Colonnes pour ajouter plus de détails.';

  @override
  String get productMgmtEditProductTitle => 'Modifier le produit';

  @override
  String get productMgmtViewProductTitle => 'Voir le produit';

  @override
  String get productMgmtUpdateProductDetailsSubtitle =>
      'Mettre à jour les détails du produit';

  @override
  String get productMgmtProductDetailsSubtitle => 'Détails du produit';

  @override
  String get productMgmtUpdatedMessage =>
      'Produit/Service mis à jour avec succès !';

  @override
  String get productMgmtDeleteProductButton => 'Supprimer le produit';

  @override
  String get productMgmtSaveChangesButton => 'Enregistrer les modifications';

  @override
  String get fieldUnitLabel => 'Unité';

  @override
  String get productMgmtAddedMessage => 'Produit ajouté avec succès !';

  @override
  String productMgmtAddErrorMessage(String error) {
    return 'Erreur lors de l\'ajout du produit : $error';
  }

  @override
  String productMgmtLoadErrorMessage(String error) {
    return 'Erreur lors du chargement des produits : $error';
  }

  @override
  String get productMgmtDeletedMessage => 'Produit supprimé avec succès !';

  @override
  String productMgmtImportedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits importés avec succès !',
      one: '1 produit importé avec succès !',
    );
    return '$_temp0';
  }

  @override
  String get productMgmtTotalItemsSubtitle => 'Total des articles';

  @override
  String get productMgmtTangibleProductsSubtitle => 'Produits tangibles';

  @override
  String get productMgmtNonTangibleServicesSubtitle => 'Services intangibles';

  @override
  String get productMgmtNeedAttentionSubtitle => 'Nécessite une attention';

  @override
  String get productMgmtProductNameLabel => 'Nom du produit';

  @override
  String get productMgmtPriceLabel => 'Prix';

  @override
  String get actionClear => 'Effacer';

  @override
  String get reportsAboutConversionRateTitle =>
      'À propos du taux de conversion';

  @override
  String reportsAgedReceivablesTitle(int count) {
    return 'Créances échues ($count)';
  }

  @override
  String get reportsAllCurrenciesLabel => 'Toutes les devises';

  @override
  String get reportsAvgInvoiceValueLabel => 'Valeur moyenne des factures';

  @override
  String get reportsBalanceColumnLabel => 'Solde';

  @override
  String get reportsBilledLabel => 'Facturé';

  @override
  String get reportsBucket0to30Label => '0 à 30 jours';

  @override
  String get reportsBucket31to60Label => '31 à 60 jours';

  @override
  String get reportsBucket61to90Label => '61 à 90 jours';

  @override
  String get reportsBucket90PlusLabel => '90+ jours';

  @override
  String get reportsBucketLabel => 'Catégorie';

  @override
  String get reportsClosingLabel => 'Solde de clôture';

  @override
  String get reportsCogsColumnLabel => 'COGS';

  @override
  String get reportsConversionRateExplanationBody =>
      'Taux de conversion = Factures créées ÷ Devis émis × 100.\nUn taux supérieur à 100 % signifie que plus de factures que de devis ont été émis pendant la période sélectionnée (courant lorsque les factures sont créées directement sans devis préalable).\n\nRemarque : il s\'agit d\'un ratio au niveau de la période, pas d\'un suivi individuel devis-vers-facture.';

  @override
  String get reportsConversionRateLabel => 'Taux de conversion';

  @override
  String get reportsCreditColumnLabel => 'Crédit';

  @override
  String get reportsCurrencySectionLabel => 'DEVISE';

  @override
  String get reportsCurrentBucketLabel => 'En cours';

  @override
  String reportsCurrentSelectedCurrencyLabel(String currency) {
    return 'Devise actuellement sélectionnée ($currency)';
  }

  @override
  String get reportsCustomRangeLabel => 'Plage personnalisée';

  @override
  String get reportsDailySalesProfitTitle => 'Ventes et bénéfices quotidiens';

  @override
  String reportsDaysCountLabel(int d) {
    return '$d jours';
  }

  @override
  String get reportsDaysOverdueLabel => 'Jours de retard';

  @override
  String get reportsDebitColumnLabel => 'Débit';

  @override
  String get reportsDiscountGivenColumnLabel => 'Remise accordée';

  @override
  String get reportsExportCsvLabel => 'Exporter en CSV';

  @override
  String reportsFilteredToDateLabel(String date) {
    return 'Filtré au $date';
  }

  @override
  String reportsInvoiceCountInPeriodLabel(int count, String scope) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString factures sur la période · $scope',
      one: '1 facture sur la période · $scope',
    );
    return '$_temp0';
  }

  @override
  String get reportsInvoiceIdLabel => 'N° de facture';

  @override
  String get reportsInvoicedLabel => 'Facturé';

  @override
  String get reportsInvoicesColumnLabel => 'Factures';

  @override
  String get reportsInvoicesInPeriodLabel => 'Factures sur la période';

  @override
  String reportsLabelWithCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get reportsMarginColumnLabel => 'Marge';

  @override
  String get reportsMaxRangeOneYearMessage =>
      'La plage maximale est de 1 an. La date de fin a été limitée.';

  @override
  String get reportsMaxRangeThirtyOneDaysMessage =>
      'La plage maximale est de 31 jours. La date de fin a été limitée.';

  @override
  String reportsMissingCostBannerMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count articles vendus durant cette période n\'ont pas de prix d\'achat défini — le profit/la marge est sous-évalué pour ces articles jusqu\'à l\'ajout d\'un prix d\'achat au produit.',
      one:
          '1 article vendu durant cette période n\'a pas de prix d\'achat défini — le profit/la marge est sous-évalué pour cet article jusqu\'à l\'ajout d\'un prix d\'achat au produit.',
    );
    return '$_temp0';
  }

  @override
  String get reportsMonthYearLabel => 'Mois et année';

  @override
  String get reportsMonthlyRevenueTrendTitle => 'Tendance des revenus mensuels';

  @override
  String get reportsNavDailyReportLabel => 'Rapport quotidien';

  @override
  String get reportsNavInvoiceStatusLabel => 'Statut des factures';

  @override
  String get reportsNavReceivablesLabel => 'Créances';

  @override
  String get reportsNavRevenueLabel => 'Revenus';

  @override
  String get reportsNavTaxLabel => 'Taxe';

  @override
  String get reportsNoCustomerDataMessage =>
      'Aucune donnée client pour cette période';

  @override
  String get reportsNoCustomersMatchSearchMessage =>
      'Aucun client ne correspond à cette recherche';

  @override
  String get reportsNoCustomersWithInvoicesMessage =>
      'Aucun client avec des factures';

  @override
  String get reportsNoDueDateLabel => 'Aucune échéance';

  @override
  String get reportsNoInvoiceDataMessage =>
      'Aucune donnée de facture pour cette période';

  @override
  String get reportsNoInvoicesInPeriodMessage =>
      'Aucune facture pour cette période';

  @override
  String get reportsNoInvoicesMatchFilterMessage =>
      'Aucune facture ne correspond à ce filtre';

  @override
  String get reportsNoOutstandingInvoicesMessage => 'Aucune facture en attente';

  @override
  String get reportsNoProductDataMessage =>
      'Aucune donnée produit pour cette période';

  @override
  String get reportsNoSalesInPeriodMessage => 'Aucune vente pour cette période';

  @override
  String get reportsNoStatementActivityMessage =>
      'Aucune activité de relevé pour ce client';

  @override
  String get reportsNoTaxableItemsMessage =>
      'Aucun article taxable pour cette période';

  @override
  String get reportsNoTransactionsMessage =>
      'Aucune transaction pour cette période';

  @override
  String get reportsOpeningLabel => 'Solde d\'ouverture';

  @override
  String get reportsOverviewLabel => 'Aperçu';

  @override
  String get reportsPaymentStatusBreakdownTitle =>
      'Répartition du statut de paiement';

  @override
  String get reportsPeriodSectionLabel => 'PÉRIODE';

  @override
  String get reportsPresetLast30DaysLabel => '30 derniers jours';

  @override
  String get reportsPresetLast3MonthsLabel => '3 derniers mois';

  @override
  String get reportsPresetLast6MonthsLabel => '6 derniers mois';

  @override
  String get reportsPresetLastFYLabel => 'Exercice précédent';

  @override
  String get reportsPresetThisFYLabel => 'Exercice en cours';

  @override
  String get reportsPresetThisYearLabel => 'Cette année';

  @override
  String get reportsProductServiceColumnLabel => 'Produit / Service';

  @override
  String get reportsProfitLabel => 'Bénéfice';

  @override
  String get reportsQuotationsIssuedLabel => 'Devis émis';

  @override
  String get reportsRankByProfitLabel => 'Classement : Bénéfice';

  @override
  String get reportsRankByRevenueLabel => 'Classement : Revenus';

  @override
  String get reportsReferenceColumnLabel => 'Référence';

  @override
  String get reportsSalesColumnLabel => 'Ventes';

  @override
  String get reportsSaveCsvReportTitle => 'Enregistrer le rapport CSV';

  @override
  String get reportsSavePdfReportTitle => 'Enregistrer le rapport PDF';

  @override
  String reportsSavedAtMessage(String path) {
    return 'Enregistré : $path';
  }

  @override
  String get reportsSelectCustomerTitle => 'Sélectionner un client';

  @override
  String get reportsSelectDailyRangeMaxDaysHelpText =>
      'Sélectionnez une date ou une plage de dates (max 31 jours)';

  @override
  String get reportsSelectDateRangeMaxYearHelpText =>
      'Sélectionnez une plage de dates (max 1 an)';

  @override
  String get reportsShareLabel => 'Part';

  @override
  String reportsShowingInvoicesDatedLabel(String range) {
    return 'Affichage des factures datées $range';
  }

  @override
  String reportsShowingRangeLabel(int start, int end, int total) {
    return '$start – $end sur $total';
  }

  @override
  String get reportsSlColumnLabel => 'N°';

  @override
  String get reportsStatementsLabel => 'Relevés';

  @override
  String get reportsTaxCollectedByRateTitle => 'Taxe collectée par taux';

  @override
  String get reportsTaxCollectedLabel => 'Taxe collectée';

  @override
  String get reportsTaxRateBucketsLabel => 'Tranches de taux de taxe';

  @override
  String get reportsTodayLabel => 'Aujourd\'hui';

  @override
  String reportsTopCustomersByRevenueTitle(int count) {
    return 'Top $count clients par revenus';
  }

  @override
  String reportsTopProductsByMetricTitle(int count, String metric) {
    return 'Top $count produits / services par $metric';
  }

  @override
  String get reportsTotalBilledLabel => 'Total facturé';

  @override
  String get reportsTotalCollectedLabel => 'Total collecté';

  @override
  String reportsTotalInvoicesCountLabel(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString factures au total',
      one: '1 facture au total',
    );
    return '$_temp0';
  }

  @override
  String get reportsTotalInvoicesLabel => 'Total des factures';

  @override
  String get reportsTotalProfitLabel => 'Bénéfice total';

  @override
  String get reportsTotalTaxCollectedLabel => 'Total des taxes collectées';

  @override
  String get reportsTypeColumnLabel => 'Type';

  @override
  String get reportsUnitsSoldColumnLabel => 'Unités vendues';

  @override
  String userMgmtLoadErrorMessage(String error) {
    return 'Erreur lors du chargement des utilisateurs : $error';
  }

  @override
  String get userMgmtAddedMessage => 'Utilisateur ajouté avec succès';

  @override
  String get userMgmtUpdatedMessage => 'Utilisateur mis à jour avec succès';

  @override
  String userMgmtSaveErrorMessage(String error) {
    return 'Erreur lors de l\'enregistrement de l\'utilisateur : $error';
  }

  @override
  String get userMgmtChangePasswordTitle => 'Changer le mot de passe';

  @override
  String userMgmtUserColonLabel(String username) {
    return 'Utilisateur : $username';
  }

  @override
  String get userMgmtCurrentPasswordLabel => 'Mot de passe actuel';

  @override
  String get userMgmtCurrentPasswordRequiredMessage =>
      'Le mot de passe actuel est requis';

  @override
  String get userMgmtNewPasswordLabel => 'Nouveau mot de passe';

  @override
  String get userMgmtNewPasswordRequiredMessage =>
      'Le nouveau mot de passe est requis';

  @override
  String get userMgmtPasswordMinLengthMessage =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get userMgmtConfirmNewPasswordLabel =>
      'Confirmer le nouveau mot de passe';

  @override
  String get userMgmtConfirmPasswordRequiredMessage =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get userMgmtPasswordsDoNotMatchMessage =>
      'Les mots de passe ne correspondent pas';

  @override
  String get userMgmtPasswordChangedMessage =>
      'Mot de passe changé avec succès';

  @override
  String get userMgmtCurrentPasswordIncorrectMessage =>
      'Le mot de passe actuel est incorrect';

  @override
  String get userMgmtDeleteUserTitle => 'Supprimer l\'utilisateur';

  @override
  String get userMgmtDeleteUserConfirmLabel =>
      'Êtes-vous sûr de vouloir supprimer l\'utilisateur :';

  @override
  String get userMgmtActionCannotBeUndoneMessage =>
      'Cette action est irréversible.';

  @override
  String get userMgmtDeletedMessage => 'Utilisateur supprimé avec succès';

  @override
  String get userMgmtCantDeleteOwnAccountMessage =>
      'Vous ne pouvez pas supprimer votre propre compte';

  @override
  String get userMgmtCantDemoteLastAdminMessage =>
      'Vous ne pouvez pas modifier le rôle du seul administrateur';

  @override
  String get userMgmtCantChangeOwnRoleMessage =>
      'Vous ne pouvez pas modifier votre propre rôle';

  @override
  String get userMgmtUsernameTakenMessage =>
      'Ce nom d\'utilisateur est déjà pris';

  @override
  String get userMgmtDeleteSelectedTitle =>
      'Supprimer les utilisateurs sélectionnés ?';

  @override
  String userMgmtBulkDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cela supprimera définitivement $count utilisateurs. Cette action est irréversible.',
      one:
          'Cela supprimera définitivement 1 utilisateur. Cette action est irréversible.',
    );
    return '$_temp0';
  }

  @override
  String get userMgmtOwnAccountSkippedMessage =>
      'Votre propre compte faisait partie de la sélection mais sera ignoré.';

  @override
  String userMgmtBulkDeletedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utilisateurs supprimés',
      one: '1 utilisateur supprimé',
    );
    return '$_temp0';
  }

  @override
  String userMgmtBulkDeleteErrorMessage(String error) {
    return 'Erreur lors de la suppression des utilisateurs : $error';
  }

  @override
  String get userMgmtTitle => 'Gestion des utilisateurs';

  @override
  String get userMgmtSubtitle =>
      'Gérer les utilisateurs de l\'application et les autorisations d\'accès';

  @override
  String get userMgmtAddUserButton => 'Ajouter un utilisateur';

  @override
  String get userMgmtSearchHint =>
      'Rechercher des utilisateurs par nom ou rôle…';

  @override
  String get userMgmtFilterByRoleTooltip => 'Filtrer par rôle';

  @override
  String get userMgmtAllRolesLabel => 'Tous les rôles';

  @override
  String get userMgmtAllLabel => 'Tous';

  @override
  String userMgmtRoleColonLabel(String role) {
    return 'Rôle : $role';
  }

  @override
  String get userMgmtColUser => 'UTILISATEUR';

  @override
  String get userMgmtColRole => 'RÔLE';

  @override
  String get userMgmtYouBadgeLabel => 'Vous';

  @override
  String get userMgmtDeleteSelectedMenuLabel => 'Supprimer la sélection';

  @override
  String get userMgmtBulkActionsTooltip => 'Actions groupées';

  @override
  String get userMgmtBulkActionsLabel => 'Actions groupées';

  @override
  String userMgmtShowingRangeLabel(int from, int to, int total) {
    return 'Affichage de $from à $to sur $total utilisateurs';
  }

  @override
  String get userMgmtNoUsersFoundMessage => 'Aucun utilisateur trouvé';

  @override
  String get userMgmtAddNewUserTitle => 'Ajouter un nouvel utilisateur';

  @override
  String get userMgmtEditUserTitle => 'Modifier l\'utilisateur';

  @override
  String get userMgmtUsernameRequiredLabel => 'Nom d\'utilisateur *';

  @override
  String get userMgmtEnterUsernameHint => 'Entrez le nom d\'utilisateur';

  @override
  String get userMgmtUsernameRequiredMessage =>
      'Le nom d\'utilisateur est requis';

  @override
  String get userMgmtUsernameMinLengthMessage =>
      'Le nom d\'utilisateur doit contenir au moins 3 caractères';

  @override
  String get userMgmtPasswordRequiredLabel => 'Mot de passe *';

  @override
  String get userMgmtEnterPasswordHint => 'Entrez le mot de passe';

  @override
  String get userMgmtPasswordRequiredMessage => 'Le mot de passe est requis';

  @override
  String get userMgmtMinimum6CharsMessage => 'Minimum 6 caractères';

  @override
  String get userMgmtRoleRequiredLabel => 'Rôle *';

  @override
  String get userMgmtRoleRequiredMessage => 'Le rôle est requis';

  @override
  String get userMgmtSaveUserButton => 'Enregistrer l\'utilisateur';

  @override
  String get userMgmtThisIsYourAccountMessage => 'Ceci est votre compte';

  @override
  String get invoiceSettingsAppBarTitle => 'Paramètres de facturation';

  @override
  String get invoiceSettingsSavedMessage =>
      'Paramètres de facturation enregistrés avec succès !';

  @override
  String get invoiceSettingsSignatureTooLargeMessage =>
      'L\'image de signature doit faire moins de 2 Mo.';

  @override
  String get invoiceSettingsWatermarkTooLargeMessage =>
      'L\'image du filigrane doit faire moins de 2 Mo.';

  @override
  String get invoiceSettingsSectionGeneral => 'Général';

  @override
  String get invoiceSettingsSectionBranding => 'Image de marque';

  @override
  String get invoiceSettingsSectionTax => 'Taxe et TPS';

  @override
  String get invoiceSettingsSectionItems => 'Articles de facture';

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
  String get invoiceSettingsPrefixLabel => 'Préfixe de facture';

  @override
  String get invoiceSettingsStartingNumberHelper =>
      'La première facture commencera à ce numéro';

  @override
  String get invoiceSettingsStartingNumberLockedMessage =>
      'Le numéro de départ des factures ne peut pas être modifié tant que des factures existent. Veuillez supprimer définitivement toutes les factures/devis (y compris la corbeille) et réessayer.';

  @override
  String get invoiceSettingsQuantityColumnLabel =>
      'Libellé de la colonne Quantité';

  @override
  String get invoiceSettingsQuantityColumnHint => 'ex. Mots, Heures, Unités';

  @override
  String get invoiceSettingsQuantityColumnHelper =>
      'Laisser vide pour utiliser \"Qté\" par défaut';

  @override
  String get invoiceSettingsAdditionalInfoLabel =>
      'Informations complémentaires';

  @override
  String get invoiceSettingsThankYouNoteLabel => 'Mot de remerciement';

  @override
  String get invoiceSettingsHideInvoiceNumberLabel =>
      'Masquer le numéro de facture par défaut';

  @override
  String get invoiceSettingsHideInvoiceNumberSubtitle =>
      'Activer \"Masquer le numéro de facture dans le PDF\" par défaut lors de la création de nouvelles factures.';

  @override
  String get invoiceSettingsTaxRateHint => 'ex. 18';

  @override
  String get invoiceSettingsTaxRateHelper => 'Appliqué aux nouvelles factures';

  @override
  String get invoiceSettingsTaxEnabledLabel => 'Taxe activée par défaut';

  @override
  String get invoiceSettingsTaxEnabledSubtitle =>
      'Activer le bouton Taxe par défaut lors de la création de nouvelles factures.';

  @override
  String get invoiceSettingsTaxModeLabel => 'Mode de taux de taxe par défaut';

  @override
  String get invoiceSettingsAppliesNewInvoicesOnly =>
      'S\'applique uniquement aux nouvelles factures';

  @override
  String get invoiceSettingsTaxModeGlobal => 'Global';

  @override
  String get invoiceSettingsTaxModePerItem => 'Par article';

  @override
  String get invoiceSettingsShowGstFieldsLabel => 'Afficher les champs TPS';

  @override
  String get invoiceSettingsShowGstFieldsSubtitle =>
      'Afficher les champs GSTIN (HSN/SAC) sur les factures, PDF et exports CSV';

  @override
  String get invoiceSettingsShowCgstSgstLabel => 'Afficher CGST/SGST';

  @override
  String get invoiceSettingsShowCgstSgstSubtitle =>
      'Diviser la taxe en CGST + SGST sur les factures (Inde uniquement).';

  @override
  String get invoiceSettingsDefaultGstTitleLabel =>
      'Titre de facture GST par défaut';

  @override
  String get invoiceSettingsDefaultTaxTitleLabel =>
      'Titre de facture Taxe par défaut';

  @override
  String get invoiceSettingsGstTitleHelperGst =>
      'Présélectionné sur les nouvelles factures — ex. \"Bill of Supply\" pour les commerçants sous régime de composition GST';

  @override
  String get invoiceSettingsGstTitleHelperGeneric =>
      'Présélectionné sur les nouvelles factures';

  @override
  String get invoiceSettingsShowRoundOffLabel => 'Afficher l\'arrondi';

  @override
  String get invoiceSettingsShowRoundOffSubtitle =>
      'Afficher une ligne d\'arrondi + le montant net (arrondi au plus proche) et le montant en lettres sur les PDF de facture.';

  @override
  String get invoiceSettingsShowAliasNameLabel =>
      'Afficher le nom d\'alias dans le PDF';

  @override
  String get invoiceSettingsShowAliasNameSubtitle =>
      'Imprimer l\'alias en langue locale d\'un produit (s\'il est défini) au lieu de son nom réel sur les PDF';

  @override
  String get invoiceSettingsShowDescriptionLabel =>
      'Afficher la description du produit';

  @override
  String get invoiceSettingsShowDescriptionSubtitle =>
      'Imprimer la description de chaque article sur une ligne en dessous dans les PDF A4 (pas sur les reçus thermiques)';

  @override
  String get invoiceSettingsDescriptionNewLineLabel =>
      'Description sur une nouvelle ligne';

  @override
  String get invoiceSettingsDescriptionNewLineSubtitle =>
      'Imprimer la description sur une ligne pleine largeur sous l\'article au lieu d\'une ligne sous son nom';

  @override
  String get invoiceSettingsAllowFractionalQtyLabel =>
      'Autoriser les quantités décimales';

  @override
  String get invoiceSettingsAllowFractionalQtySubtitle =>
      'Activer les quantités décimales (ex. 1,5 h, 0,5 kg)';

  @override
  String get invoiceSettingsShowQuantityLabel => 'Afficher le champ Quantité';

  @override
  String get invoiceSettingsShowQuantitySubtitle =>
      'Masquer la quantité pour la facturation de services ; la colonne prix devient \"Taux\"';

  @override
  String get invoiceSettingsShowDiscountLabel => 'Afficher la colonne Remise';

  @override
  String get invoiceSettingsShowDiscountSubtitle =>
      'Masquer la colonne remise pour les clients qui n\'utilisent pas de remises par article';

  @override
  String get invoiceSettingsShowTypeTagLabel =>
      'Afficher l\'étiquette Produit/Service';

  @override
  String get invoiceSettingsShowTypeTagSubtitle =>
      'Afficher ou masquer l\'étiquette Produit/Service sur chaque article de facture';

  @override
  String get invoiceSettingsAllowDuplicateItemsLabel =>
      'Autoriser les articles de facture en double';

  @override
  String get invoiceSettingsAllowDuplicateItemsSubtitle =>
      'Autoriser l\'ajout du même produit plusieurs fois à une facture';

  @override
  String get invoiceSettingsShowPrevBalanceLabel =>
      'Afficher le solde précédent dû';

  @override
  String get invoiceSettingsShowPrevBalanceSubtitle =>
      'Afficher le solde impayé antérieur calculé sur les PDF de facture';

  @override
  String get invoiceSettingsLogoPositionLabel =>
      'Position du logo de l\'entreprise';

  @override
  String get invoiceSettingsLogoSizeLabel => 'Taille du logo de l\'entreprise';

  @override
  String get commonLeftLabel => 'Gauche';

  @override
  String get commonRightLabel => 'Droite';

  @override
  String get invoiceSettingsSignatureImageLabel => 'Image de signature';

  @override
  String get invoiceSettingsSignatureImageSubtitle =>
      'Imprimée sur les factures comme Signature autorisée';

  @override
  String get invoiceSettingsImageFormatHint => 'PNG, JPG ou JPEG — max 2 Mo';

  @override
  String get invoiceSettingsChangeSignatureButton => 'Changer la signature';

  @override
  String get invoiceSettingsUploadSignatureButton => 'Téléverser une signature';

  @override
  String get invoiceSettingsSignatureSizeLabel => 'Taille de la signature';

  @override
  String get invoiceSettingsSignaturePositionLabel =>
      'Position de la signature';

  @override
  String get invoiceSettingsWatermarkImageLabel => 'Image du filigrane';

  @override
  String get invoiceSettingsWatermarkImageSubtitle =>
      'Affiché derrière le tableau des articles sur les PDF de facture (non imprimé sur les reçus thermiques)';

  @override
  String get invoiceSettingsChangeWatermarkButton => 'Changer le filigrane';

  @override
  String get invoiceSettingsUploadWatermarkButton => 'Téléverser un filigrane';

  @override
  String invoiceSettingsOpacityLabel(int value) {
    return 'Opacité : $value %';
  }

  @override
  String invoiceSettingsPercentValueLabel(int value) {
    return '$value %';
  }

  @override
  String get invoiceSettingsPromoTitle =>
      'Besoin de plus de champs sur vos factures ?';

  @override
  String get invoiceSettingsPromoBody =>
      'Ajoutez un numéro de bon de commande, un code de projet, un service, ou tout champ personnalisé.';

  @override
  String get invoiceSettingsPromoButton => 'Voir les options';

  @override
  String get pdfSettingsTitle => 'Paramètres PDF';

  @override
  String get pdfSettingsSubtitle =>
      'Personnalisez les modèles PDF de factures, devis et reçus';

  @override
  String get pdfSettingsResetToDefaultButton => 'Réinitialiser par défaut';

  @override
  String get pdfSettingsSaveSettingsButton => 'Enregistrer les paramètres';

  @override
  String get pdfSettingsTemplatesLabel => 'Modèles';

  @override
  String pdfSettingsNoTemplatesForPageSizeMessage(String pageSize) {
    return 'Aucun modèle pour $pageSize';
  }

  @override
  String get pdfSettingsSavedSnackbar => 'Paramètres PDF enregistrés';

  @override
  String get commonActiveLabel => 'Actif';

  @override
  String get commonUnavailableLabel => 'Indisponible';

  @override
  String get pdfSettingsDisplayOptionsLabel => 'Options d\'affichage';

  @override
  String get pdfSettingsShowTotalQtyRowLabel =>
      'Afficher la ligne de quantité totale';

  @override
  String get pdfSettingsOrientationLabel => 'Orientation';

  @override
  String get pdfSettingsOrientationPortrait => 'Portrait';

  @override
  String get pdfSettingsOrientationLandscape => 'Landscape';

  @override
  String get pdfSettingsItemLayoutLabel => 'Disposition des articles';

  @override
  String get pdfSettingsItemLayoutTableLabel => 'Tableau';

  @override
  String get pdfSettingsItemLayoutDetailedLabel => 'Détaillé';

  @override
  String get pdfSettingsItemLayoutHelpText =>
      'Tableau : une ligne par article (Sl/Nom/Qté/Prix/Total). Détaillé : nom sur sa propre ligne, puis Qté/Prix/Total en dessous.';

  @override
  String get pdfSettingsCompanyNameSizeLabel =>
      'Taille du nom de l\'entreprise';

  @override
  String get pdfSettingsThemeColorLabel => 'Couleur du thème';

  @override
  String get pdfSettingsHexErrorText => 'Utilisez #RRGGBB';

  @override
  String get pdfSettingsPickColorTooltip => 'Ouvrir le sélecteur de couleur';

  @override
  String get pdfSettingsPickThemeColorDialogTitle =>
      'Choisir la couleur du thème';

  @override
  String get pdfSettingsPreviewDisclaimer =>
      'L\'aperçu peut légèrement différer du PDF final.';

  @override
  String get pdfSettingsCustomTemplatePromoTitle =>
      'Vous voulez un modèle personnalisé ?';

  @override
  String get pdfSettingsCustomTemplatePromoBody =>
      'Obtenez un design qui correspond à votre marque — couleurs, polices et mise en page.';

  @override
  String get pdfSettingsCustomizationOptionsButton =>
      'Options de personnalisation';

  @override
  String get pdfTemplateClassicName => 'Classique';

  @override
  String get pdfTemplateClassicDescription =>
      'Mise en page traditionnelle avec une structure claire';

  @override
  String get pdfTemplateModernName => 'Moderne';

  @override
  String get pdfTemplateModernDescription =>
      'En-tête audacieux avec un style contemporain';

  @override
  String get pdfTemplateMinimalName => 'Minimal';

  @override
  String get pdfTemplateMinimalDescription => 'Simple et sans distraction';

  @override
  String get pdfTemplateExecutiveName => 'Exécutif';

  @override
  String get pdfTemplateExecutiveDescription =>
      'Mise en page professionnelle haut de gamme avec blocs de facturation structurés';

  @override
  String get pdfTemplateCompactName => 'Compact';

  @override
  String get pdfTemplateCompactDescription =>
      'Mise en page de reçu économe en espace, idéale pour l\'impression A6';

  @override
  String get pdfTemplateThermalName => 'Thermique';

  @override
  String get pdfTemplateThermalDescription =>
      'Mise en page de reçu étroite pour imprimantes thermiques 80mm et 58mm';

  @override
  String get pdfTemplateGridClassicName => 'Grille classique';

  @override
  String get pdfTemplateGridClassicDescription =>
      'Facture tabulaire bordée à l\'ancienne, pour A4, A5 et A6';

  @override
  String get companyInfoAppBarTitle => 'Informations sur l\'entreprise';

  @override
  String get companyInfoUploadLogoLabel => 'Télécharger le logo';

  @override
  String get companyInfoClickToBrowseLabel => 'Cliquez pour parcourir';

  @override
  String get companyInfoRemoveLogoButton => 'Supprimer le logo';

  @override
  String get companyInfoShowOnPdfLabel => 'Afficher sur le PDF';

  @override
  String get companyInfoLogoRequirementsHint =>
      'Max 1080×1080 px · 2 Mo\nPNG ou JPG uniquement';

  @override
  String get companyInfoLogoSectionLabel => 'LOGO DE L\'ENTREPRISE';

  @override
  String get companyInfoDetailsSectionLabel => 'COORDONNÉES DE L\'ENTREPRISE';

  @override
  String get companyInfoBusinessTypeSectionLabel => 'TYPE D\'ACTIVITÉ';

  @override
  String get companyInfoPaymentSettingsSectionLabel => 'PARAMÈTRES DE PAIEMENT';

  @override
  String get companyInfoUpiAccountsSectionLabel => 'COMPTES UPI';

  @override
  String get companyInfoBankAccountsSectionLabel => 'COMPTES BANCAIRES';

  @override
  String get fieldGstinLabel => 'GSTIN';

  @override
  String get fieldTaxVatNoLabel => 'N° Taxe/TVA';

  @override
  String get fieldPanLabel => 'PAN';

  @override
  String get fieldTinLabel => 'TIN';

  @override
  String get companyInfoFssaiCodeLabel => 'Code FSSAI';

  @override
  String get companyInfoPhoneHelperText =>
      'Plusieurs numéros : séparez-les par une virgule';

  @override
  String get fieldWebsiteLabel => 'Site web';

  @override
  String get companyInfoBusinessTypeTitle => 'Type d\'activité';

  @override
  String get companyInfoBusinessTypeSubtitle =>
      'Contrôle les options de type d\'article dans la liste des produits et les factures';

  @override
  String get labelBoth => 'Les deux';

  @override
  String get companyInfoSetAsDefaultTooltip => 'Définir par défaut';

  @override
  String get companyInfoUpiIdLabel => 'ID UPI';

  @override
  String get companyInfoAddUpiAccountButton => 'Ajouter un compte UPI';

  @override
  String get companyInfoShowQrToggleTitle =>
      'Afficher le code QR sur les factures';

  @override
  String get companyInfoShowQrToggleSubtitle =>
      'Ajoute des codes QR de paiement UPI scannables aux PDF générés';

  @override
  String get companyInfoShowBankDetailsToggleTitle =>
      'Afficher les coordonnées bancaires sur les factures';

  @override
  String get companyInfoShowBankDetailsToggleSubtitle =>
      'Imprime les coordonnées bancaires sur les PDF générés';

  @override
  String get fieldBankNameLabel => 'Nom de la banque';

  @override
  String get fieldAccountNumberLabel => 'Numéro de compte';

  @override
  String get fieldIfscCodeLabel => 'Code IFSC';

  @override
  String get companyInfoAddBankAccountButton => 'Ajouter un compte bancaire';

  @override
  String get tooltipShowOnInvoicePdf => 'Afficher sur le PDF de la facture';

  @override
  String get companyInfoSavedSuccessMessage =>
      'Informations de l\'entreprise enregistrées avec succès';

  @override
  String get companyInfoImageTooLargeMessage =>
      'Le fichier image doit faire moins de 2 Mo.';

  @override
  String get companyInfoInvalidImageMessage => 'Fichier image invalide.';

  @override
  String get companyInfoImageDimensionsMessage =>
      'L\'image doit faire au maximum 1080x1080 pixels.';

  @override
  String get companyInfoHintExampleBankName => 'ex. Banque HDFC';

  @override
  String get companyInfoHintExampleAccountLabel => 'ex. Compte principal';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionShare => 'Partager';

  @override
  String get appInfoTitle => 'Informations sur le logiciel';

  @override
  String get appInfoAppDetailsTitle => 'DÉTAILS DE L\'APPLICATION';

  @override
  String get appInfoAppNameLabel => 'Nom de l\'application';

  @override
  String get appInfoVersionLabel => 'Version';

  @override
  String get appInfoLicenseLabel => 'Licence';

  @override
  String get appInfoDeveloperTitle => 'DÉVELOPPEUR';

  @override
  String get appInfoDeveloperLabel => 'Développeur';

  @override
  String get appInfoSupportEmailLabel => 'E-mail d\'assistance';

  @override
  String appInfoFooterCopyright(int year, String developer, String license) {
    return '© $year $developer  |  Publié sous licence $license';
  }

  @override
  String get appInfoCheckingLabel => 'Vérification...';

  @override
  String get appInfoUpdateAvailableLabel => 'Mise à jour disponible';

  @override
  String get appInfoUpToDateLabel => 'À jour';

  @override
  String get appInfoCheckFailedLabel => 'Échec de la vérification';

  @override
  String get appInfoUpdatesTitle => 'MISES À JOUR';

  @override
  String get appInfoCurrentVersionLabel => 'Version actuelle';

  @override
  String get appInfoLatestVersionLabel => 'Dernière version';

  @override
  String get appInfoCheckNowButton => 'Vérifier maintenant';

  @override
  String get backupManagementTitle => 'Gestion des sauvegardes';

  @override
  String get backupCreateDbButton => 'Créer une sauvegarde BD';

  @override
  String get backupExportJsonButton => 'Exporter en JSON';

  @override
  String get backupImportButton => 'Importer une sauvegarde';

  @override
  String get backupNoBackupsFoundMessage => 'Aucune sauvegarde trouvée';

  @override
  String backupSizeLabel(String size) {
    return 'Taille : $size';
  }

  @override
  String backupCreatedLabel(String date) {
    return 'Créée : $date';
  }

  @override
  String backupLoadErrorMessage(String error) {
    return 'Échec du chargement des sauvegardes : $error';
  }

  @override
  String get backupCreatedSuccessMessage => 'Sauvegarde créée avec succès !';

  @override
  String backupCreateErrorMessage(String error) {
    return 'Échec de la création de la sauvegarde : $error';
  }

  @override
  String get backupRestoreConfirmTitle => 'Restaurer la sauvegarde';

  @override
  String get backupRestoreConfirmBody =>
      'Cela remplacera toutes les données actuelles par la sauvegarde. Êtes-vous sûr ?';

  @override
  String backupRestoreErrorMessage(String error) {
    return 'Échec de la restauration de la sauvegarde : $error';
  }

  @override
  String get backupDeleteConfirmTitle => 'Supprimer la sauvegarde';

  @override
  String get backupDeleteConfirmBody =>
      'Voulez-vous vraiment supprimer cette sauvegarde ?';

  @override
  String get backupDeletedSuccessMessage =>
      'Sauvegarde supprimée avec succès !';

  @override
  String get backupDeleteFailedMessage =>
      'Échec de la suppression de la sauvegarde';

  @override
  String backupDeleteErrorMessage(String error) {
    return 'Échec de la suppression de la sauvegarde : $error';
  }

  @override
  String get backupSavedToDownloadsMessage =>
      'Sauvegarde enregistrée dans le dossier Téléchargements.';

  @override
  String backupDownloadErrorMessage(String error) {
    return 'Échec du téléchargement de la sauvegarde : $error';
  }

  @override
  String backupShareErrorMessage(String error) {
    return 'Échec du partage de la sauvegarde : $error';
  }

  @override
  String backupImportErrorMessage(String error) {
    return 'Échec de l\'importation de la sauvegarde : $error';
  }

  @override
  String get backupRestoreSuccessTitle => 'Restauration réussie';

  @override
  String get backupRestoreSuccessBody =>
      'La base de données a été restaurée avec succès.\n\nL\'application doit redémarrer pour appliquer les modifications. Veuillez fermer et rouvrir l\'application.';

  @override
  String get backupCloseLaterButton => 'Fermer plus tard';

  @override
  String get backupCloseAppNowButton => 'Fermer l\'application maintenant';

  @override
  String get commonSuccessTitle => 'Succès';

  @override
  String get commonErrorTitle => 'Erreur';

  @override
  String get productColumnsScreenTitle =>
      'Personnaliser les détails du produit';

  @override
  String get productColumnsSavedMessage => 'Colonnes de produit enregistrées.';

  @override
  String get productColumnsIntroText =>
      'Choisissez les champs qui apparaissent sur les formulaires d\'ajout/modification de produit, la liste des produits et les lignes de facture. Le nom et le prix sont toujours obligatoires.';

  @override
  String get productColumnsNameLabel => 'Nom';

  @override
  String get productColumnsPriceLabel => 'Prix';

  @override
  String get productColumnsAlwaysRequiredSubtitle =>
      'Toujours affiché — obligatoire.';

  @override
  String get productColumnsStockLabel => 'Stock';

  @override
  String get productColumnsStockSubtitle =>
      'Désactivez si vous ne suivez jamais le stock — les produits ont alors un stock illimité par défaut.';

  @override
  String get productColumnsProductFieldsSectionTitle => 'Champs produit';

  @override
  String get productColumnsAliasNameLabel => 'Nom alternatif';

  @override
  String get productColumnsAliasNameSubtitle =>
      'Nom d\'affichage en langue locale pour les PDF/impressions.';

  @override
  String get productColumnsTaxRateLabel => 'Taux de taxe';

  @override
  String get productColumnsTaxRateSubtitle =>
      'Pourcentage de taxe par produit.';

  @override
  String get productColumnsHsnSacLabel => 'HSN/SAC';

  @override
  String get productColumnsHsnSacSubtitle => 'Champ de code HSN ou SAC.';

  @override
  String get productColumnsDescriptionLabel => 'Description';

  @override
  String get productColumnsDescriptionSubtitle =>
      'Description libre du produit.';

  @override
  String get productColumnsPurchasePriceLabel => 'Prix d\'achat';

  @override
  String get productColumnsPurchasePriceSubtitle =>
      'Prix de revient, pour le suivi des marges.';

  @override
  String get productColumnsDefaultDiscountLabel => 'Remise par défaut';

  @override
  String get productColumnsDefaultDiscountSubtitle =>
      'Remise préremplie lors de l\'ajout de ce produit à une facture.';

  @override
  String get productColumnsUnitLabel => 'Unité';

  @override
  String get productColumnsUnitSubtitle =>
      'Unité de mesure (pièces, kg, heures...).';

  @override
  String get productColumnsProductServiceTypeLabel => 'Type Produit/Service';

  @override
  String get productColumnsProductServiceTypeSubtitle =>
      'Sélecteur segmenté Produit vs Service.';

  @override
  String get productColumnsMetadataLabel => 'Métadonnées du produit';

  @override
  String get productColumnsMetadataSubtitle =>
      'Emplacement de stockage, numéro de conteneur/lot, expiration, date de fabrication, fournisseur, SKU, notes.';

  @override
  String get productColumnsMetaStorageLocationLabel =>
      'Emplacement de stockage';

  @override
  String get productColumnsMetaContainerNumberLabel => 'Numéro de conteneur';

  @override
  String get productColumnsMetaBatchNumberLabel => 'Numéro de lot';

  @override
  String get productColumnsMetaExpiryDateLabel => 'Date d\'expiration';

  @override
  String get productColumnsMetaManufactureDateLabel => 'Date de fabrication';

  @override
  String get productColumnsMetaSupplierNameLabel => 'Nom du fournisseur';

  @override
  String get productColumnsMetaSkuCodeLabel => 'Code SKU';

  @override
  String get productColumnsMetaNotesLabel => 'Notes';

  @override
  String get productColumnsExtraCostLabel => 'Coût supplémentaire';

  @override
  String get productColumnsExtraCostSubtitle =>
      'Frais supplémentaires fixes facultatifs sur une ligne de facture.';

  @override
  String get settingsOptionsComingSoonMessage =>
      'Options bientôt disponibles...';

  @override
  String get settingsNavCompanyInfoLabel => 'Infos entreprise';

  @override
  String get settingsNavTeamLabel => 'Équipe';

  @override
  String get settingsNavBackupLabel => 'Sauvegarde';

  @override
  String get settingsNavUsersLabel => 'Utilisateurs';

  @override
  String get settingsNavProductDetailsLabel => 'Détails produit';

  @override
  String get settingsNavCustomizeLabel => 'Personnaliser';

  @override
  String get settingsNavAccessibilityLabel => 'Accessibilité';

  @override
  String get settingsNavSoftwareInfoLabel => 'Infos logiciel';

  @override
  String get customizationEyebrowLabel => 'PERSONNALISATION';

  @override
  String get customizationHeadline => 'Adapté à votre entreprise';

  @override
  String get customizationSubtitle =>
      'Choisissez ce dont vous avez besoin et envoyez une demande. Nous vous répondrons sous 24 heures.';

  @override
  String get customizationRecommendedBadge => 'Recommandé';

  @override
  String customizationDeliveryLabel(String delivery) {
    return 'Livraison : $delivery';
  }

  @override
  String get customizationRequestButton => 'Demander';

  @override
  String get customizationFormOpenErrorMessage =>
      'Impossible d\'ouvrir le formulaire. Veuillez visiter forms.gle/LyX6Z2kBNR2BpwVu7 dans votre navigateur.';

  @override
  String get customizationDisclaimerMessage =>
      'Les prix sont indicatifs. Le devis final peut varier selon la complexité. Le paiement est perçu après accord sur le périmètre.';

  @override
  String get customizationPdfTemplateTitle => 'Modèle PDF personnalisé';

  @override
  String get customizationPdfTemplateDescription =>
      'Obtenez un modèle de facture conçu selon votre marque — vos couleurs, polices, emplacement du logo et mise en page.';

  @override
  String get customizationPdfTemplateDelivery => '2 à 5 jours';

  @override
  String get customizationCustomFieldsTitle => 'Champs personnalisés';

  @override
  String get customizationCustomFieldsDescription =>
      'Besoin de champs supplémentaires sur vos factures ? (numéro de bon de commande, code projet, service, etc.) Nous les ajouterons pour vous.';

  @override
  String get customizationCustomFieldsDelivery => '1 à 3 jours';

  @override
  String get customizationWhiteLabelTitle =>
      'Marque blanche / Suppression de la marque';

  @override
  String get customizationWhiteLabelDescription =>
      'Supprimez toute la marque Invoiso de l\'application et des PDF, et remplacez-la par l\'identité de votre entreprise.';

  @override
  String get customizationWhiteLabelDelivery => '3 à 6 jours';

  @override
  String get customizationIndustryBuildTitle =>
      'Version spécifique à un secteur';

  @override
  String get customizationIndustryBuildDescription =>
      'Besoin d\'une version adaptée à votre secteur ? (construction, conseil, commerce de détail, etc.) Nous personnaliserons le flux de travail selon vos besoins.';

  @override
  String get customizationIndustryBuildDelivery => '5 à 10 jours';

  @override
  String get accessibilityCreateInvoiceLayoutSectionTitle =>
      'Nouvelle mise en page de création de facture';

  @override
  String get accessibilityClassicLayoutLabel => 'Mise en page classique';

  @override
  String get accessibilityNewLayoutLabel => 'Nouvelle mise en page';

  @override
  String get accessibilityLayoutDescription =>
      'Choisissez quelle conception d\'écran \"Nouvelle facture\" utiliser.';

  @override
  String get accessibilityShortcutsSubtitle =>
      'Accélérez la création de factures sans toucher la souris.';

  @override
  String paymentDialogInvoiceRefLabel(String number, String customer) {
    return '#$number — $customer';
  }

  @override
  String get paymentDialogInvoiceTotalLabel => 'Total de la facture';

  @override
  String get paymentDialogAmountPaidLabel => 'Montant payé';

  @override
  String get paymentDialogHistoryTitle => 'Historique des paiements';

  @override
  String get paymentDialogNoPaymentsMessage =>
      'Aucun paiement enregistré pour le moment';

  @override
  String get paymentDialogFullyPaidExclaimMessage =>
      'Facture entièrement payée !';

  @override
  String get paymentDialogFullyPaidBannerLabel => 'Facture entièrement payée';

  @override
  String paymentDialogRecordedMessage(String symbol, String amount) {
    return 'Paiement enregistré. En attente : $symbol $amount';
  }

  @override
  String paymentDialogRecordFailedMessage(String error) {
    return 'Échec de l\'enregistrement du paiement : $error';
  }

  @override
  String get paymentDialogDeleteTitle => 'Supprimer le paiement';

  @override
  String paymentDialogDeleteConfirmBody(String receiptNumber) {
    return 'Supprimer le reçu $receiptNumber ?\n\nCette action est irréversible.';
  }

  @override
  String get paymentDialogNewPaymentTitle => 'Nouveau paiement';

  @override
  String paymentDialogAmountFieldLabel(String symbol) {
    return 'Montant ($symbol)';
  }

  @override
  String paymentDialogMaxHelperText(String symbol, String amount) {
    return 'Max : $symbol $amount';
  }

  @override
  String get paymentDialogInvalidAmountError => 'Entrez un montant valide';

  @override
  String get paymentDialogExceedsOutstandingError => 'Dépasse le solde restant';

  @override
  String get paymentDialogMethodFieldLabel => 'Méthode de paiement';

  @override
  String get paymentDialogSelectMethodHint => 'Choisir une méthode';

  @override
  String get paymentDialogTaxCoveredLabel => 'Taxe couverte';

  @override
  String get paymentDialogAutoCalculatedHelper => 'Calculé automatiquement';

  @override
  String get paymentDialogNotesFieldLabel => 'Référence / Notes (facultatif)';

  @override
  String get paymentDialogNotesHint => 'ex. n° de chèque, ID de transaction...';

  @override
  String get paymentDialogReceiptColLabel => 'N° de reçu';

  @override
  String get paymentDialogMethodColLabel => 'Méthode';

  @override
  String get paymentDialogDownloadReceiptTooltip => 'Télécharger le reçu';

  @override
  String get paymentDialogDeletePaymentTooltip => 'Supprimer le paiement';

  @override
  String get paymentMethodCash => 'Espèces';

  @override
  String get paymentMethodBankTransfer => 'Virement bancaire';

  @override
  String get paymentMethodCheck => 'Chèque';

  @override
  String get paymentMethodOnline => 'En ligne';

  @override
  String get paymentMethodOther => 'Autre';

  @override
  String get customerInfoButtonTooltip => 'Voir les coordonnées';

  @override
  String get customerInfoButtonNoContactMessage =>
      'Aucune coordonnée disponible.';

  @override
  String get updateDialogTitle => 'Mise à jour disponible';

  @override
  String get updateDialogBodyMessage =>
      'Une nouvelle version d\'invoiso est disponible. Visitez la page de téléchargement pour obtenir la dernière version.';

  @override
  String get pageSizeA4Label => 'A4 standard';

  @override
  String get pageSizeA5Label => 'A5 standard';

  @override
  String get pageSizeA6Label => 'A6 standard';

  @override
  String get pageSizeThermal80Label => 'Papier thermique 80mm';

  @override
  String get pageSizeThermal58Label => 'Papier thermique 58mm';

  @override
  String get dateFormatDdmmyyyyLabel => 'JJ/MM/AAAA  (ex. 15/04/2026)';

  @override
  String get dateFormatMmddyyyyLabel => 'MM/JJ/AAAA  (ex. 04/15/2026)';

  @override
  String get dateFormatDdMmmyyyyLabel => 'JJ MMM AAAA  (ex. 15 avr. 2026)';

  @override
  String get dateFormatYyyymmddLabel => 'AAAA-MM-JJ  (ex. 2026-04-15)';

  @override
  String get sizeXSmallLabel => 'Très petit';

  @override
  String get sizeSmallLabel => 'Petit';

  @override
  String get sizeMediumLabel => 'Moyen';

  @override
  String get sizeLargeLabel => 'Grand';

  @override
  String get shortcutNewInvoiceDescription =>
      'Nouvelle facture (depuis le tableau de bord) / Réinitialiser le formulaire (dans Créer une facture)';

  @override
  String get shortcutSaveInvoiceDescription => 'Enregistrer / créer la facture';

  @override
  String get shortcutAddProductDescription => 'Ajouter un produit à la facture';

  @override
  String get shortcutAddCustomItemDescription =>
      'Ajouter un article personnalisé';

  @override
  String get shortcutPreviewPdfDescription => 'Aperçu du PDF de la facture';

  @override
  String get shortcutPrintPdfDescription =>
      'Générer / imprimer le PDF de la facture';
}
