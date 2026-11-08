import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/providers/repositories.dart';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/widgets/template_list_tile.dart';
import 'package:invoiso/widgets/block_layout_sketch.dart';
import 'dart:async';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';
import 'package:invoiso/services/pdf/pdf_preview_sample.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:invoiso/services/thermal_printer_service_v1.dart';
import 'package:invoiso/models/custom_invoice_layout.dart';

class PdfSettingsScreenV2 extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCustomization;

  const PdfSettingsScreenV2({super.key, this.onNavigateToCustomization});

  @override
  ConsumerState<PdfSettingsScreenV2> createState() =>
      _PdfSettingsScreenV2State();
}

class _PdfSettingsScreenV2State extends ConsumerState<PdfSettingsScreenV2> {
  Uint8List? _previewPdfBytes;
  bool _previewIsLoading = true;
  bool _useLivePdfPreview = true;
  Timer? _previewDebounceTimer;
  PdfGenerationSettings? _basePdfSettings;
  int _previewVersion = 0;

  InvoiceTemplate _savedTemplate = InvoiceTemplate.classic;
  InvoiceTemplate _previewedTemplate = InvoiceTemplate.classic;
  List<CustomInvoiceLayout> _customLayouts = [];
  String? _selectedCustomLayoutId;
  Map<String, dynamic>? _savedBlockLayout;
  Map<String, dynamic>? _previewedBlockLayout;
  String? _savedThemeColorHex;
  String? _previewedThemeColorHex;
  final _themeColorController = TextEditingController();
  bool _themeColorInputValid = true;
  PageSize _savedPageSize = PageSize.a4;
  PageSize _previewedPageSize = PageSize.a4;
  bool _savedLandscape = false;
  bool _previewedLandscape = false;

  bool _savedShowTotalQuantity = false;
  bool _previewedShowTotalQuantity = false;
  final _thermalWidthMarginController = TextEditingController();
  String _savedThermalWidthMargin = '1';
  String _previewedThermalWidthMargin = '1';
  String _savedThermalItemLayout = 'table';
  String _previewedThermalItemLayout = 'table';
  String _savedThermalCompanyNameSize = 'medium';
  String _previewedThermalCompanyNameSize = 'medium';
  String _savedPdfFontSize = 'medium';
  String _previewedPdfFontSize = 'medium';

  bool _savedLetterheadEnabled = false;
  bool _previewedLetterheadEnabled = false;
  bool _savedLetterheadHideCompanyHeader = true;
  bool _previewedLetterheadHideCompanyHeader = true;
  double _savedPrintMarginTopMm = 40.0;
  double _previewedPrintMarginTopMm = 40.0;
  double _savedPrintMarginBottomMm = 25.0;
  double _previewedPrintMarginBottomMm = 25.0;
  double _savedPrintMarginLeftMm = 10.0;
  double _previewedPrintMarginLeftMm = 10.0;
  double _savedPrintMarginRightMm = 10.0;
  double _previewedPrintMarginRightMm = 10.0;
  double _savedPrintContentScale = 100.0;
  double _previewedPrintContentScale = 100.0;
  bool _savedShowSoftwareBranding = true;
  bool _previewedShowSoftwareBranding = true;

  final _marginTopController = TextEditingController();
  final _marginBottomController = TextEditingController();
  final _marginLeftController = TextEditingController();
  final _marginRightController = TextEditingController();
  String? _marginError;

  // Per-section PDF text sizes; '' = same as overall (_previewedPdfFontSize).
  static const _pdfSectionSizeKeys = [
    SettingKey.pdfCompanyNameFontSize,
    SettingKey.pdfDocTitleFontSize,
    SettingKey.pdfTableHeaderFontSize,
    SettingKey.pdfTableItemsFontSize,
    SettingKey.pdfTotalsFontSize,
  ];
  Map<SettingKey, String> _savedPdfSectionSizes = {};
  Map<SettingKey, String> _previewedPdfSectionSizes = {};
  bool _showPdfSectionSizes = false;
  bool _isSaving = false;

  static const _presetThemeColors = [
    Color(0xFF002E78),
    Color(0xFF2563EB),
    Color(0xFF047857),
    Color(0xFF7C2D12),
    Color(0xFF6D28D9),
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final results = await Future.wait([
      ref.read(settingsRepositoryProvider).getInvoiceTemplate(),
      ref.read(settingsRepositoryProvider).getPdfThemeColor(),
      ref.read(settingsRepositoryProvider).getPageSize(),
      ref.read(settingsRepositoryProvider).getShowTotalQuantity(),
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.thermalWidthMargin),
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.thermalItemLayout),
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.thermalCompanyNameSize),
      ref.read(settingsRepositoryProvider).getPdfLandscape(),
      ref.read(settingsRepositoryProvider).getSetting(SettingKey.pdfFontSize),
      for (final key in _pdfSectionSizeKeys)
        ref.read(settingsRepositoryProvider).getSetting(key),
      ref.read(settingsRepositoryProvider).getLetterheadEnabled(),
      ref.read(settingsRepositoryProvider).getLetterheadHideCompanyHeader(),
      ref.read(settingsRepositoryProvider).getPrintMarginTopMm(),
      ref.read(settingsRepositoryProvider).getPrintMarginBottomMm(),
      ref.read(settingsRepositoryProvider).getPrintMarginLeftMm(),
      ref.read(settingsRepositoryProvider).getPrintMarginRightMm(),
      ref.read(settingsRepositoryProvider).getPrintContentScale(),
      ref.read(settingsRepositoryProvider).getShowInvoiceFooterBranding(),
    ]);
    final saved = results[0] as InvoiceTemplate;
    final savedThemeColor = results[1] as String?;
    final savedPageSize = results[2] as PageSize;
    final savedShowTotalQty = results[3] as bool;
    final savedThermalWidthMargin = results[4] as String?;
    final savedThermalItemLayout = results[5] as String?;
    final savedThermalCompanyNameSize = results[6] as String?;
    final savedLandscape = results[7] as bool;
    final savedPdfFontSize = results[8] as String?;
    final savedPdfSectionSizes = {
      for (var i = 0; i < _pdfSectionSizeKeys.length; i++)
        _pdfSectionSizeKeys[i]: (results[9 + i] as String?) ?? '',
    };
    final baseIdx = 9 + _pdfSectionSizeKeys.length;
    final savedLetterheadEnabled = results[baseIdx] as bool;
    final savedLetterheadHideCompanyHeader = results[baseIdx + 1] as bool;
    final savedMarginTop = results[baseIdx + 2] as double;
    final savedMarginBottom = results[baseIdx + 3] as double;
    final savedMarginLeft = results[baseIdx + 4] as double;
    final savedMarginRight = results[baseIdx + 5] as double;
    final savedContentScale = results[baseIdx + 6] as double;
    final savedShowSoftwareBranding = results[baseIdx + 7] as bool;
    final customLayouts =
        await ref.read(settingsRepositoryProvider).getCustomInvoiceLayouts();
    final activeLayoutRaw =
        await ref.read(settingsRepositoryProvider).getSetting(
              SettingKey.activeCustomLayout,
            );
    final activeLayout = _parseStoredLayout(activeLayoutRaw);
    final activeStoredLayout = activeLayout != null &&
            customLayouts.any((layout) => layout.id == activeLayout.id)
        ? activeLayout
        : null;

    final previewedTemplate =
        effectiveInvoiceTemplateForPageSize(saved, savedPageSize);
    final activeThemeColor =
        activeStoredLayout?.effectiveThemeColorHex ?? savedThemeColor;
    setState(() {
      _customLayouts = customLayouts;
      _selectedCustomLayoutId = activeStoredLayout?.id;
      _savedBlockLayout = activeStoredLayout?.blockLayout;
      _previewedBlockLayout = activeStoredLayout?.blockLayout;
      _savedTemplate = saved;
      _previewedTemplate = previewedTemplate;
      _savedThemeColorHex = activeThemeColor;
      _previewedThemeColorHex = activeThemeColor;
      _themeColorController.text = activeThemeColor ?? '';
      _savedPageSize = savedPageSize;
      _previewedPageSize = savedPageSize;
      _savedLandscape = savedLandscape;
      _previewedLandscape = savedLandscape;
      _savedShowTotalQuantity = savedShowTotalQty;
      _previewedShowTotalQuantity = savedShowTotalQty;
      _savedThermalWidthMargin = savedThermalWidthMargin ?? '1';
      _previewedThermalWidthMargin = _savedThermalWidthMargin;
      _thermalWidthMarginController.text = _savedThermalWidthMargin;
      _savedThermalItemLayout = savedThermalItemLayout ?? 'table';
      _previewedThermalItemLayout = _savedThermalItemLayout;
      _savedThermalCompanyNameSize = savedThermalCompanyNameSize ?? 'medium';
      _previewedThermalCompanyNameSize = _savedThermalCompanyNameSize;
      _savedPdfFontSize = savedPdfFontSize ?? 'medium';
      _previewedPdfFontSize = _savedPdfFontSize;
      _savedPdfSectionSizes = savedPdfSectionSizes;
      _previewedPdfSectionSizes = Map.of(savedPdfSectionSizes);

      _savedLetterheadEnabled = savedLetterheadEnabled;
      _previewedLetterheadEnabled = savedLetterheadEnabled;
      _savedLetterheadHideCompanyHeader = savedLetterheadHideCompanyHeader;
      _previewedLetterheadHideCompanyHeader = savedLetterheadHideCompanyHeader;
      _savedPrintMarginTopMm = savedMarginTop;
      _previewedPrintMarginTopMm = savedMarginTop;
      _savedPrintMarginBottomMm = savedMarginBottom;
      _previewedPrintMarginBottomMm = savedMarginBottom;
      _savedPrintMarginLeftMm = savedMarginLeft;
      _previewedPrintMarginLeftMm = savedMarginLeft;
      _savedPrintMarginRightMm = savedMarginRight;
      _previewedPrintMarginRightMm = savedMarginRight;
      _savedPrintContentScale = savedContentScale;
      _previewedPrintContentScale = savedContentScale;
      _savedShowSoftwareBranding = savedShowSoftwareBranding;
      _previewedShowSoftwareBranding = savedShowSoftwareBranding;

      _marginTopController.text = savedMarginTop.toStringAsFixed(0);
      _marginBottomController.text = savedMarginBottom.toStringAsFixed(0);
      _marginLeftController.text = savedMarginLeft.toStringAsFixed(0);
      _marginRightController.text = savedMarginRight.toStringAsFixed(0);
      _marginError = null;
    });
    try {
      _basePdfSettings = await PDFService.fetchPdfSettings();
    } catch (_) {}
    _schedulePdfPreviewUpdate(immediate: true);
  }

  CustomInvoiceLayout? get _activeCustomLayout {
    final id = _selectedCustomLayoutId;
    if (id == null) return null;
    for (final layout in _customLayouts) {
      if (layout.id == id) return layout;
    }
    return null;
  }

  CustomInvoiceLayout? _parseStoredLayout(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CustomInvoiceLayout.fromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTemplate({bool showSavedSnackBar = true}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final activeLayout = _activeCustomLayout;
    final activeLayoutJson = activeLayout == null
        ? null
        : _layoutFromCurrentSettings(
            id: activeLayout.id,
            name: activeLayout.name,
            description: activeLayout.description,
            createdAt: activeLayout.createdAt,
            blockLayout: _previewedBlockLayout,
          ).toJson();
    try {
      await Future.wait([
        ref
            .read(settingsRepositoryProvider)
            .setInvoiceTemplate(_previewedTemplate),
        if (_previewedThemeColorHex == null)
          ref.read(settingsRepositoryProvider).clearPdfThemeColor()
        else
          ref
              .read(settingsRepositoryProvider)
              .setPdfThemeColor(_previewedThemeColorHex!),
        ref.read(settingsRepositoryProvider).setPageSize(_previewedPageSize),
        ref
            .read(settingsRepositoryProvider)
            .setPdfLandscape(_previewedLandscape),
        ref
            .read(settingsRepositoryProvider)
            .setShowTotalQuantity(_previewedShowTotalQuantity),
        ref.read(settingsRepositoryProvider).setSetting(
            SettingKey.thermalWidthMargin,
            (int.tryParse(_previewedThermalWidthMargin.trim()) ?? 1)
                .clamp(-10, 10)
                .toString()),
        ref.read(settingsRepositoryProvider).setSetting(
            SettingKey.thermalItemLayout, _previewedThermalItemLayout),
        ref.read(settingsRepositoryProvider).setSetting(
            SettingKey.thermalCompanyNameSize,
            _previewedThermalCompanyNameSize),
        ref
            .read(settingsRepositoryProvider)
            .setSetting(SettingKey.pdfFontSize, _previewedPdfFontSize),
        for (final key in _pdfSectionSizeKeys)
          ref
              .read(settingsRepositoryProvider)
              .setSetting(key, _previewedPdfSectionSizes[key] ?? ''),
        ref
            .read(settingsRepositoryProvider)
            .setLetterheadEnabled(_previewedLetterheadEnabled),
        ref.read(settingsRepositoryProvider).setLetterheadHideCompanyHeader(
            _previewedLetterheadHideCompanyHeader),
        ref
            .read(settingsRepositoryProvider)
            .setPrintMarginTopMm(_previewedPrintMarginTopMm),
        ref
            .read(settingsRepositoryProvider)
            .setPrintMarginBottomMm(_previewedPrintMarginBottomMm),
        ref
            .read(settingsRepositoryProvider)
            .setPrintMarginLeftMm(_previewedPrintMarginLeftMm),
        ref
            .read(settingsRepositoryProvider)
            .setPrintMarginRightMm(_previewedPrintMarginRightMm),
        ref
            .read(settingsRepositoryProvider)
            .setPrintContentScale(_previewedPrintContentScale),
        ref
            .read(settingsRepositoryProvider)
            .setShowInvoiceFooterBranding(_previewedShowSoftwareBranding),
        if (activeLayoutJson != null)
          ref
              .read(settingsRepositoryProvider)
              .setSetting(SettingKey.activeCustomLayout, activeLayoutJson)
        else
          ref
              .read(settingsRepositoryProvider)
              .deleteSetting(SettingKey.activeCustomLayout),
      ]);
      setState(() {
        _savedTemplate = _previewedTemplate;
        _savedThemeColorHex = _previewedThemeColorHex;
        _savedPageSize = _previewedPageSize;
        _savedLandscape = _previewedLandscape;
        _savedShowTotalQuantity = _previewedShowTotalQuantity;
        _savedThermalWidthMargin = _previewedThermalWidthMargin;
        _savedThermalItemLayout = _previewedThermalItemLayout;
        _savedThermalCompanyNameSize = _previewedThermalCompanyNameSize;
        _savedPdfFontSize = _previewedPdfFontSize;
        _savedPdfSectionSizes = Map.of(_previewedPdfSectionSizes);

        _savedLetterheadEnabled = _previewedLetterheadEnabled;
        _savedLetterheadHideCompanyHeader =
            _previewedLetterheadHideCompanyHeader;
        _savedPrintMarginTopMm = _previewedPrintMarginTopMm;
        _savedPrintMarginBottomMm = _previewedPrintMarginBottomMm;
        _savedPrintMarginLeftMm = _previewedPrintMarginLeftMm;
        _savedPrintMarginRightMm = _previewedPrintMarginRightMm;
        _savedPrintContentScale = _previewedPrintContentScale;
        _savedShowSoftwareBranding = _previewedShowSoftwareBranding;
        _savedBlockLayout = _previewedBlockLayout;
      });
      if (!mounted) return;
      if (showSavedSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.pdfSettingsSavedSnackbar),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _previewDebounceTimer?.cancel();
    _themeColorController.dispose();
    _thermalWidthMarginController.dispose();
    _marginTopController.dispose();
    _marginBottomController.dispose();
    _marginLeftController.dispose();
    _marginRightController.dispose();
    super.dispose();
  }

  void _schedulePdfPreviewUpdate({bool immediate = false}) {
    _previewDebounceTimer?.cancel();
    if (immediate) {
      _generatePdfPreview();
    } else {
      _previewDebounceTimer = Timer(const Duration(milliseconds: 150), () {
        _generatePdfPreview();
      });
    }
  }

  Future<void> _generatePdfPreview() async {
    if (!mounted) return;
    setState(() => _previewIsLoading = true);
    try {
      _basePdfSettings ??= await PDFService.fetchPdfSettings();
      final base = _basePdfSettings!;

      final pageSize = _previewedPageSize;
      final pageFmt = PDFService.pageSizeToFormat(pageSize);
      final isLandscape = _previewedLandscape &&
          (_previewedTemplate == InvoiceTemplate.gridClassic ||
              _previewedBlockLayout != null);
      final effectiveFormat = isLandscape ? pageFmt.landscape : pageFmt;

      final fontSizeScale = pdfFontSizeFromKey(_previewedPdfFontSize).scale;

      final previewSettings = PdfGenerationSettings(
        company: base.company,
        template: _previewedTemplate,
        invoicePrefix: base.invoicePrefix,
        creditNotePrefix: base.creditNotePrefix,
        debitNotePrefix: base.debitNotePrefix,
        quotationPrefix: base.quotationPrefix,
        receiptPrefix: base.receiptPrefix,
        showGst: base.showGst,
        showQuantity: base.showQuantity,
        showDiscount: base.showDiscount,
        showTypeTag: base.showTypeTag,
        businessType: base.businessType,
        upiEntries: base.upiEntries,
        showQrStr: base.showQrStr,
        showBankDetails: base.showBankDetails,
        bankAccounts: base.bankAccounts,
        logoPosition: base.logoPosition,
        logoSizePx: base.logoSizePx,
        logoBytes: base.logoBytes,
        thankYouNote: base.thankYouNote,
        datePattern: base.datePattern,
        showFooterBranding: _previewedShowSoftwareBranding,
        themeColor: _previewedThemeColorHex != null
            ? PdfColor.fromHex(_previewedThemeColorHex!)
            : null,
        signatureBytes: base.signatureBytes,
        signaturePosition: base.signaturePosition,
        signatureSizePx: base.signatureSizePx,
        showPreviousBalance: base.showPreviousBalance,
        pageFormat: effectiveFormat,
        pageSize: pageSize,
        showTotalQuantity: _previewedShowTotalQuantity,
        pdfTheme: base.pdfTheme,
        thermalItemLayout: _previewedThermalItemLayout,
        showAliasName: base.showAliasName,
        watermarkBytes: base.watermarkBytes,
        watermarkOpacity: base.watermarkOpacity,
        showCgstSgst: base.showCgstSgst,
        showTaxColumn: base.showTaxColumn,
        showRoundOff: base.showRoundOff,
        showPhone: base.showPhone,
        showEmail: base.showEmail,
        showCompanyName: base.showCompanyName,
        showPan: base.showPan,
        showFssai: base.showFssai,
        showWebsite: base.showWebsite,
        showAddress: base.showAddress,
        showLogo: base.showLogo,
        thermalCompanyNameSize: _previewedThermalCompanyNameSize,
        showLeadingZeros: base.showLeadingZeros,
        showDescription: base.showDescription,
        descriptionNewLine: base.descriptionNewLine,
        showCustomerBusinessName: base.showCustomerBusinessName,
        showCustomerAddress: base.showCustomerAddress,
        showCustomerPhone: base.showCustomerPhone,
        showCustomerEmail: base.showCustomerEmail,
        showCustomerGstin: base.showCustomerGstin,
        showTimeInPdf: base.showTimeInPdf,
        pdfTimeFormat: base.pdfTimeFormat,
        showSlNo: base.showSlNo,
        landscape: isLandscape,
        watermarkFullPage: base.watermarkFullPage,
        metadataColumns: base.metadataColumns,
        fontSizeScale: fontSizeScale,
        companyNameScale: pdfSectionScale(
            _previewedPdfSectionSizes[SettingKey.pdfCompanyNameFontSize],
            fontSizeScale),
        docTitleScale: pdfSectionScale(
            _previewedPdfSectionSizes[SettingKey.pdfDocTitleFontSize],
            fontSizeScale),
        tableHeaderScale: pdfSectionScale(
            _previewedPdfSectionSizes[SettingKey.pdfTableHeaderFontSize],
            fontSizeScale),
        tableItemsScale: pdfSectionScale(
            _previewedPdfSectionSizes[SettingKey.pdfTableItemsFontSize],
            fontSizeScale),
        totalsScale: pdfSectionScale(
            _previewedPdfSectionSizes[SettingKey.pdfTotalsFontSize],
            fontSizeScale),
        customerFields: base.customerFields,
        letterheadEnabled: _previewedLetterheadEnabled,
        printMarginTopMm: _previewedPrintMarginTopMm,
        printMarginBottomMm: _previewedPrintMarginBottomMm,
        printMarginLeftMm: _previewedPrintMarginLeftMm,
        printMarginRightMm: _previewedPrintMarginRightMm,
        printContentScale: _previewedPrintContentScale,
        letterheadHideCompanyHeader: _previewedLetterheadHideCompanyHeader,
        blockLayout: _previewedBlockLayout,
      );

      final sampleInvoice = PdfPreviewSample.createSampleInvoice(
        company: base.company,
      );
      final doc = PDFService.generateInvoicePDFWithSettings(
        sampleInvoice,
        previewSettings,
      );
      final bytes = await doc.save();
      if (mounted) {
        setState(() {
          _previewPdfBytes = bytes;
          _previewIsLoading = false;
          _previewVersion++;
        });
      }
    } catch (e, st) {
      debugPrint('Error generating PDF preview: $e\n$st');
      if (mounted) {
        setState(() => _previewIsLoading = false);
      }
    }
  }

  void _setPreviewedThemeColor(String? hexColor) {
    setState(() {
      _previewedThemeColorHex = hexColor;
      _themeColorController.text = hexColor ?? '';
      _themeColorInputValid = true;
    });
    _schedulePdfPreviewUpdate();
  }

  void _setPreviewedTemplate(InvoiceTemplate template) {
    if (!template.supportsPageSize(_previewedPageSize)) return;
    setState(() {
      _previewedTemplate = template;
      // Choosing a built-in template must stop an imported block layout from
      // overriding the preview/rendered output.
      _previewedBlockLayout = null;
    });
    _schedulePdfPreviewUpdate(immediate: true);
  }

  void _setPreviewedPageSize(PageSize pageSize) {
    setState(() {
      _previewedPageSize = pageSize;
      _previewedTemplate = effectiveInvoiceTemplateForPageSize(
        _previewedTemplate,
        pageSize,
      );
    });
    _schedulePdfPreviewUpdate(immediate: true);
  }

  void _handleCustomThemeColor(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _previewedThemeColorHex = null;
        _themeColorInputValid = true;
      });
      _schedulePdfPreviewUpdate();
      return;
    }
    try {
      final normalized = SettingsService.normalizePdfThemeColor(value);
      setState(() {
        _previewedThemeColorHex = normalized;
        _themeColorInputValid = true;
      });
      _schedulePdfPreviewUpdate();
    } catch (_) {
      setState(() => _themeColorInputValid = false);
    }
  }

  Future<void> _openColorPicker() async {
    Color picked = _activePreviewColor;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.pdfSettingsPickThemeColorDialogTitle),
          content: SizedBox(
            width: 300,
            child: ColorPicker(
              color: picked,
              onColorChanged: (c) => setDialogState(() => picked = c),
              pickersEnabled: const {
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
                ColorPickerType.wheel: true,
              },
              showColorCode: true,
              colorCodeHasColor: true,
              enableShadesSelection: false,
              wheelDiameter: 220,
              wheelWidth: 24,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionApply),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      _setPreviewedThemeColor(_colorToHex(picked));
    }
  }

  Color get _activePreviewColor =>
      _colorFromHex(_previewedThemeColorHex) ??
      _defaultThemeColor(_previewedTemplate);

  @override
  Widget build(BuildContext context) => _buildV2(context);

  // ============================================================
  // V2 — flat / modern layout. Reuses all v1 state, controllers,
  // validation and repository calls untouched (_setPreviewedTemplate,
  // _setPreviewedPageSize, _setPreviewedThemeColor, _saveTemplate,
  // TemplateListTile (shared), _ThemeColorCard, _PreviewPanel are all reused
  // as-is). New pieces: a 3-column layout (templates | settings |
  // preview) instead of 2, a persistent top header with Save/Reset,
  // pill-style page size buttons, and a real preview zoom control.
  //
  // Honest scope note: the mockup's "Display Options" section shows six
  // toggles (logo, address, items header, total-in-words, signature, QR
  // code) that aren't backed by any setting in this codebase — only
  // "Show total quantity row" (and the thermal-only fields) are real.
  // Rather than fabricate the other five, this only shows what's real.
  // The mockup's "Data Example" preview tab also has no equivalent
  // functionality here, so it isn't included either.
  // ============================================================

  bool get _hasUnsavedChangeV2 =>
      _themeColorInputValid &&
      _marginError == null &&
      (_previewedTemplate != _savedTemplate ||
          _previewedThemeColorHex != _savedThemeColorHex ||
          _previewedPageSize != _savedPageSize ||
          _previewedLandscape != _savedLandscape ||
          _previewedShowTotalQuantity != _savedShowTotalQuantity ||
          _previewedThermalWidthMargin != _savedThermalWidthMargin ||
          _previewedThermalItemLayout != _savedThermalItemLayout ||
          _previewedThermalCompanyNameSize != _savedThermalCompanyNameSize ||
          _previewedPdfFontSize != _savedPdfFontSize ||
          _pdfSectionSizeKeys.any((k) =>
              _previewedPdfSectionSizes[k] != _savedPdfSectionSizes[k]) ||
          _previewedLetterheadEnabled != _savedLetterheadEnabled ||
          _previewedLetterheadHideCompanyHeader !=
              _savedLetterheadHideCompanyHeader ||
          _previewedPrintMarginTopMm != _savedPrintMarginTopMm ||
          _previewedPrintMarginBottomMm != _savedPrintMarginBottomMm ||
          _previewedPrintMarginLeftMm != _savedPrintMarginLeftMm ||
          _previewedPrintMarginRightMm != _savedPrintMarginRightMm ||
          _previewedPrintContentScale != _savedPrintContentScale ||
          _previewedShowSoftwareBranding != _savedShowSoftwareBranding ||
          jsonEncode(_previewedBlockLayout) != jsonEncode(_savedBlockLayout));

  Future<void> _handlePrintPreview() async {
    if (_previewPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preview is still generating, please wait...')),
      );
      return;
    }
    try {
      if (_previewedTemplate == InvoiceTemplate.thermal) {
        final sampleInvoice = PdfPreviewSample.createSampleInvoice(
          company: _basePdfSettings?.company,
        );
        await ThermalPrinterService.printInvoice(context, sampleInvoice);
      } else {
        final pageFmt = PDFService.pageSizeToFormat(_previewedPageSize);
        final isLandscape = _previewedLandscape &&
            (_previewedTemplate == InvoiceTemplate.gridClassic ||
                _previewedBlockLayout != null);
        final effectiveFormat = isLandscape ? pageFmt.landscape : pageFmt;

        await Printing.layoutPdf(
          format: effectiveFormat,
          name: 'Invoiso_${_previewedTemplate.name}_preview',
          onLayout: (format) async => _previewPdfBytes!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _applyCustomLayout(CustomInvoiceLayout layout) {
    final effectiveTemplate = layout.effectiveBaseTemplate;
    final effectiveThemeColor = layout.effectiveThemeColorHex;
    setState(() {
      _selectedCustomLayoutId = layout.id;
      _previewedTemplate = effectiveTemplate;
      _previewedPageSize = layout.pageSize;
      _previewedLandscape = layout.landscape;
      _previewedThemeColorHex = effectiveThemeColor;
      _themeColorController.text = effectiveThemeColor ?? '';
      _themeColorInputValid = true;
      _previewedPdfFontSize = pdfFontSizeFromKey(layout.fontSize).key;
      _previewedPdfSectionSizes = {
        for (final entry in layout.sectionSizes.entries)
          if (SettingKey.values.asNameMap().containsKey(entry.key))
            SettingKey.values.asNameMap()[entry.key]!: entry.value,
      };
      _previewedShowTotalQuantity = layout.showTotalQuantity;
      _previewedShowSoftwareBranding = layout.showSoftwareBranding;
      _previewedLetterheadEnabled = layout.letterheadEnabled;
      _previewedLetterheadHideCompanyHeader =
          layout.letterheadHideCompanyHeader;
      _previewedPrintMarginTopMm = layout.printMarginTopMm;
      _marginTopController.text = layout.printMarginTopMm.toStringAsFixed(0);
      _previewedPrintMarginBottomMm = layout.printMarginBottomMm;
      _marginBottomController.text =
          layout.printMarginBottomMm.toStringAsFixed(0);
      _previewedPrintMarginLeftMm = layout.printMarginLeftMm;
      _marginLeftController.text = layout.printMarginLeftMm.toStringAsFixed(0);
      _previewedPrintMarginRightMm = layout.printMarginRightMm;
      _marginRightController.text =
          layout.printMarginRightMm.toStringAsFixed(0);
      _previewedPrintContentScale = layout.printContentScale;
      _previewedThermalWidthMargin = layout.thermalWidthMargin;
      _thermalWidthMarginController.text = layout.thermalWidthMargin;
      _previewedThermalItemLayout = layout.thermalItemLayout;
      _previewedThermalCompanyNameSize = layout.thermalCompanyNameSize;
      _previewedBlockLayout = layout.blockLayout;
      _marginError = null;
    });
    _schedulePdfPreviewUpdate(immediate: true);
  }

  /// Snapshot of the current preview state as a reusable layout. This is the
  /// same shape used by the JSON editor and by "Save Current Settings as
  /// Layout", so a JSON generated here can always be applied again.
  CustomInvoiceLayout _layoutFromCurrentSettings({
    String? id,
    required String name,
    required String description,
    DateTime? createdAt,
    Map<String, dynamic>? blockLayout,
  }) {
    return CustomInvoiceLayout(
      id: id ?? 'custom_layout_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      baseTemplate: _previewedTemplate,
      pageSize: _previewedPageSize,
      landscape: _previewedLandscape,
      themeColorHex: _previewedThemeColorHex,
      fontSize: pdfFontSizeFromKey(_previewedPdfFontSize).key,
      sectionSizes: {
        for (final entry in _previewedPdfSectionSizes.entries)
          if (entry.value.isEmpty ||
              PdfFontSize.values.any((size) => size.key == entry.value))
            entry.key.name: entry.value,
      },
      showTotalQuantity: _previewedShowTotalQuantity,
      showSoftwareBranding: _previewedShowSoftwareBranding,
      letterheadEnabled: _previewedLetterheadEnabled,
      letterheadHideCompanyHeader: _previewedLetterheadHideCompanyHeader,
      printMarginTopMm: _previewedPrintMarginTopMm,
      printMarginBottomMm: _previewedPrintMarginBottomMm,
      printMarginLeftMm: _previewedPrintMarginLeftMm,
      printMarginRightMm: _previewedPrintMarginRightMm,
      printContentScale:
          _previewedPrintContentScale.clamp(50.0, 150.0).toDouble(),
      thermalWidthMargin: (int.tryParse(_previewedThermalWidthMargin) ?? 1)
          .clamp(-10, 10)
          .toString(),
      thermalItemLayout:
          _previewedThermalItemLayout == 'detailed' ? 'detailed' : 'table',
      thermalCompanyNameSize: ThermalCompanyNameSize.values
              .any((size) => size.key == _previewedThermalCompanyNameSize)
          ? _previewedThermalCompanyNameSize
          : 'medium',
      blockLayout: blockLayout,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Persist an added/edited layout without touching any other saved layout.
  Future<void> _upsertCustomLayout(CustomInvoiceLayout layout) async {
    final next = List<CustomInvoiceLayout>.of(_customLayouts);
    final index = next.indexWhere((l) => l.id == layout.id);
    if (index >= 0) {
      next[index] = layout;
    } else {
      next.add(layout);
    }
    await ref.read(settingsRepositoryProvider).saveCustomInvoiceLayouts(next);
    if (!mounted) return;
    setState(() {
      _customLayouts = next;
      _selectedCustomLayoutId = layout.id;
    });
  }

  Future<void> _removeCustomLayout(CustomInvoiceLayout layout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Custom Layout'),
        content: Text(
            'Are you sure you want to remove \'${layout.name}\'? Default templates cannot be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final wasSelected = _selectedCustomLayoutId == layout.id;
    setState(() {
      _customLayouts.removeWhere((l) => l.id == layout.id);
      if (wasSelected) {
        _selectedCustomLayoutId = null;
        _savedBlockLayout = null;
        _previewedBlockLayout = null;
        _previewedTemplate = InvoiceTemplate.classic;
      }
    });
    await ref
        .read(settingsRepositoryProvider)
        .saveCustomInvoiceLayouts(_customLayouts);
    if (wasSelected) {
      await ref
          .read(settingsRepositoryProvider)
          .deleteSetting(SettingKey.activeCustomLayout);
    }
    _schedulePdfPreviewUpdate(immediate: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed layout \'${layout.name}\'')),
      );
    }
  }

  Future<void> _showAddLayoutDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Custom Layout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Import a custom .json layout file or save current customizations as a new layout.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF3E8FF),
                  child: Icon(Icons.code_rounded, color: Color(0xFF7E22CE)),
                ),
                title: const Text('Create / Edit JSON',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Paste or edit the layout configuration with a live validation check'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showJsonLayoutDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.file_upload_outlined,
                      color: Color(0xFF3730A3)),
                ),
                title: const Text('Import from JSON File',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Select a .json or .invoiso-layout file from your device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importCustomLayoutFile();
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.bookmark_add_outlined,
                      color: Color(0xFF166534)),
                ),
                title: const Text('Save Current Settings as Layout',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Create a reusable template from currently configured options'),
                onTap: () {
                  Navigator.pop(ctx);
                  _saveCurrentAsCustomLayout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showJsonLayoutDialog({CustomInvoiceLayout? existing}) async {
    final seed = existing ??
        _layoutFromCurrentSettings(
          name: 'My Custom Layout',
          description: 'Custom template with personal styling',
          blockLayout: _previewedBlockLayout,
        );
    final controller = TextEditingController(text: seed.toPrettyJson());
    String? error;
    CustomInvoiceLayout? parsed = seed;

    final result = await showDialog<_JsonLayoutResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void parseNow() {
            try {
              final layout = CustomInvoiceLayout.fromJson(
                controller.text,
                fallbackId: existing?.id,
                fallbackCreatedAt: existing?.createdAt,
              );
              setDialogState(() {
                parsed = layout;
                error = null;
              });
            } catch (e) {
              setDialogState(() {
                parsed = null;
                error = _friendlyLayoutError(e);
              });
            }
          }

          return AlertDialog(
            title: Text(existing == null
                ? 'Create Layout from JSON'
                : 'Edit Layout JSON'),
            content: SizedBox(
              width: 680,
              height: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit the JSON configuration. Invalid JSON is rejected and '
                    'never replaces the saved layout.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12),
                        hintText: '{\n  "name": "My Layout",\n  ...\n}',
                      ),
                      onChanged: (_) => parseNow(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              OutlinedButton.icon(
                onPressed: parsed == null
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _JsonLayoutResult(layout: parsed!, save: false),
                        ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Preview'),
              ),
              FilledButton.icon(
                onPressed: parsed == null
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _JsonLayoutResult(layout: parsed!, save: true),
                        ),
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save & Apply'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;

    var layout = result.layout;
    if (existing != null) {
      // Editing keeps the existing identity so it updates in place instead of
      // creating a duplicate layout or overwriting an unrelated one.
      layout = layout.copyWith(
        id: existing.id,
        createdAt: existing.createdAt,
        clearThemeColor: layout.themeColorHex == null,
      );
    }
    _applyCustomLayout(layout);

    if (!result.save) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Layout applied to preview. Use Save Settings to activate it.',
          ),
        ),
      );
      return;
    }

    try {
      await _upsertCustomLayout(layout);
      await _saveTemplate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save layout: ${_friendlyLayoutError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _friendlyLayoutError(Object error) {
    if (error is FormatException) {
      return 'Error on JSON file';
    }
    return error.toString();
  }

  Future<void> _importCustomLayoutFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'invoiso-layout'],
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      // Prefer in-memory bytes (always available on web); fall back to the
      // path for desktop/mobile pickers that only provide a file path.
      String content;
      if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        content = await File(picked.path!).readAsString();
      } else {
        throw const FormatException('The selected layout file is empty.');
      }
      final layout = CustomInvoiceLayout.fromJson(content);

      // Apply the imported payload to the live layout state first. The
      // renderer reads the persisted settings (not this screen's fields), so
      // the layout must also be saved as the active settings below; otherwise
      // imported layouts silently fall back to the previously saved/default
      // theme when an invoice is previewed or generated.
      _applyCustomLayout(layout);

      // Validate first, persist second: an invalid file never mutates the
      // in-memory or stored layout list.
      await _upsertCustomLayout(layout);
      await _saveTemplate(showSavedSnackBar: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported custom layout \'${layout.name}\' successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyLayoutError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCurrentAsCustomLayout() async {
    final nameCtrl = TextEditingController(text: 'My Custom Layout');
    final descCtrl =
        TextEditingController(text: 'Custom template with personal styling');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Custom Layout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Layout Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Layout')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final newLayout = _layoutFromCurrentSettings(
      name:
          nameCtrl.text.trim().isEmpty ? 'Custom Layout' : nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      blockLayout: _previewedBlockLayout,
    );

    await _upsertCustomLayout(newLayout);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved custom layout \'${newLayout.name}\'!')),
      );
    }
  }

  void _resetToDefaultV2() {
    setState(() {
      _selectedCustomLayoutId = null;
      _previewedBlockLayout = null;
      _previewedTemplate = InvoiceTemplate.classic;
      _previewedPageSize = PageSize.a4;
      _previewedLandscape = false;
      _previewedThemeColorHex = null;
      _themeColorController.clear();
      _themeColorInputValid = true;
      _previewedShowTotalQuantity = false;
      _previewedThermalWidthMargin = '1';
      _thermalWidthMarginController.text = '1';
      _previewedThermalItemLayout = 'table';
      _previewedThermalCompanyNameSize = 'medium';
      _previewedPdfFontSize = 'medium';
      _previewedPdfSectionSizes = {for (final k in _pdfSectionSizeKeys) k: ''};

      _previewedLetterheadEnabled = false;
      _previewedLetterheadHideCompanyHeader = true;
      _previewedPrintMarginTopMm = 40.0;
      _marginTopController.text = '40';
      _previewedPrintMarginBottomMm = 25.0;
      _marginBottomController.text = '25';
      _previewedPrintMarginLeftMm = 10.0;
      _marginLeftController.text = '10';
      _previewedPrintMarginRightMm = 10.0;
      _marginRightController.text = '10';
      _previewedPrintContentScale = 100.0;
      _previewedShowSoftwareBranding = true;
      _marginError = null;
    });
    _schedulePdfPreviewUpdate(immediate: true);
  }

  void _validateMargins() {
    final top = double.tryParse(_marginTopController.text.trim());
    final bottom = double.tryParse(_marginBottomController.text.trim());
    final left = double.tryParse(_marginLeftController.text.trim());
    final right = double.tryParse(_marginRightController.text.trim());

    if (top == null || bottom == null || left == null || right == null) {
      _marginError = 'Please enter valid numbers for margins';
      return;
    }
    if (top < 0 || bottom < 0 || left < 0 || right < 0) {
      _marginError = 'Margins cannot be negative';
      return;
    }

    final (pageW, pageH) = switch (_previewedPageSize) {
      PageSize.a4 => (210.0, 297.0),
      PageSize.a5 => (148.0, 210.0),
      PageSize.a6 => (105.0, 148.0),
      PageSize.thermal80 => (80.0, 200.0),
      PageSize.thermal58 => (58.0, 200.0),
    };
    final effectiveW = _previewedLandscape ? pageH : pageW;
    final effectiveH = _previewedLandscape ? pageW : pageH;

    if (top + bottom >= effectiveH - 30) {
      _marginError =
          'Top + Bottom margins exceed page height (${effectiveH.toInt()} mm)';
      return;
    }
    if (left + right >= effectiveW - 20) {
      _marginError =
          'Left + Right margins exceed page width (${effectiveW.toInt()} mm)';
      return;
    }

    _marginError = null;
    _previewedPrintMarginTopMm = top;
    _previewedPrintMarginBottomMm = bottom;
    _previewedPrintMarginLeftMm = left;
    _previewedPrintMarginRightMm = right;
    _schedulePdfPreviewUpdate();
  }

  void _applyMarginPreset(
      double top, double bottom, double left, double right) {
    setState(() {
      _previewedPrintMarginTopMm = top;
      _previewedPrintMarginBottomMm = bottom;
      _previewedPrintMarginLeftMm = left;
      _previewedPrintMarginRightMm = right;
      _marginTopController.text = top.toStringAsFixed(0);
      _marginBottomController.text = bottom.toStringAsFixed(0);
      _marginLeftController.text = left.toStringAsFixed(0);
      _marginRightController.text = right.toStringAsFixed(0);
      _marginError = null;
    });
    _schedulePdfPreviewUpdate();
  }

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  Widget _headerBarV2() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.pdfSettingsTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(l10n.pdfSettingsSubtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _resetToDefaultV2,
                  child: Text(l10n.pdfSettingsResetToDefaultButton),
                ),
                FilledButton.icon(
                  onPressed: (_hasUnsavedChangeV2 && !_isSaving)
                      ? _saveTemplate
                      : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_isSaving
                      ? l10n.createInvoiceSavingEllipsisLabel
                      : l10n.pdfSettingsSaveSettingsButton),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _templatesColumnV2() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: _flatCardDecorationV2(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(l10n.onboardingPageSizeLabel),
          const SizedBox(height: 8),
          _pageSizeDropdownV2(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel(l10n.pdfSettingsTemplatesLabel),
              TextButton.icon(
                onPressed: _showAddLayoutDialog,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Add Layout',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Builder(builder: (context) {
              // Only templates that actually support the selected page
              // size are shown — nothing greyed-out to browse past.
              final visibleTemplates = templateCatalog
                  .where((e) => (e["template"] as InvoiceTemplate)
                      .supportsPageSize(_previewedPageSize))
                  .toList();
              final matchingCustomLayouts = _customLayouts
                  .where((l) => l.pageSize == _previewedPageSize)
                  .toList();

              if (visibleTemplates.isEmpty && matchingCustomLayouts.isEmpty) {
                return Center(
                  child: Text(
                      l10n.pdfSettingsNoTemplatesForPageSizeMessage(
                          pageSizeLabel(context, _previewedPageSize)),
                      style: TextStyle(
                          fontSize: 12.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (matchingCustomLayouts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'YOUR INSERTED LAYOUTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      for (final customLayout in matchingCustomLayouts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TemplateListTile(
                            template: customLayout.baseTemplate,
                            name: customLayout.name,
                            description: customLayout.description,
                            themeColor: customLayout.effectiveThemeColorHex !=
                                    null
                                ? (_colorFromHex(
                                        customLayout.effectiveThemeColorHex!) ??
                                    _activePreviewColor)
                                : _activePreviewColor,
                            isPreviewed:
                                _selectedCustomLayoutId == customLayout.id,
                            isSaved: false,
                            isDefault: false,
                            isInserted: true,
                            blockLayout: customLayout.blockLayout,
                            thermalDetailedTemplate:
                                customLayout.thermalItemLayout != "table",
                            onTap: () => _applyCustomLayout(customLayout),
                            onEdit: () =>
                                _showJsonLayoutDialog(existing: customLayout),
                            onDelete: () => _removeCustomLayout(customLayout),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'DEFAULT TEMPLATES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    for (final entry in visibleTemplates)
                      Builder(builder: (context) {
                        final template = entry["template"] as InvoiceTemplate;
                        final name = templateName(context, template);
                        final description =
                            templateDescription(context, template);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TemplateListTile(
                            template: template,
                            name: name,
                            description: description,
                            themeColor: _activePreviewColor,
                            isPreviewed: _selectedCustomLayoutId == null &&
                                _previewedTemplate == template,
                            isSaved: _savedTemplate == template,
                            thermalDetailedTemplate:
                                _previewedThermalItemLayout != "table",
                            isDefault: template == InvoiceTemplate.classic,
                            isInserted: false,
                            onDelete: null,
                            onTap: () {
                              setState(() => _selectedCustomLayoutId = null);
                              _setPreviewedTemplate(template);
                            },
                            isDisabled: false,
                            disabledLabel: null,
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _pageSizeDropdownV2() {
    return DropdownButtonFormField<PageSize>(
      value: _previewedPageSize,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      items: PageSize.values
          .map((s) => DropdownMenuItem<PageSize>(
              value: s, child: Text(pageSizeLabel(context, s))))
          .toList(),
      onChanged: (val) {
        if (val != null) _setPreviewedPageSize(val);
      },
    );
  }

  Widget _settingsColumnV2() {
    final l10n = AppLocalizations.of(context)!;
    final name = templateName(context, _previewedTemplate);
    final description = templateDescription(context, _previewedTemplate);
    final isActive = _savedTemplate == _previewedTemplate;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: _flatCardDecorationV2(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Theme.of(context).primaryColor, size: 13),
                        const SizedBox(width: 4),
                        Text(l10n.commonActiveLabel,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            _sectionLabel(l10n.pdfSettingsDisplayOptionsLabel),
            const SizedBox(height: 8),
            if (_previewedTemplate == InvoiceTemplate.compact ||
                _previewedTemplate == InvoiceTemplate.gridClassic ||
                _previewedTemplate == InvoiceTemplate.thermal)
              _buildTotalQuantityToggle(),
            if (_previewedTemplate == InvoiceTemplate.gridClassic) ...[
              const SizedBox(height: 8),
              _buildOrientationField(),
            ],
            if (_previewedTemplate == InvoiceTemplate.thermal) ...[
              const SizedBox(height: 8),
              _buildThermalItemLayoutField(),
              const SizedBox(height: 8),
              _buildThermalCompanyNameSizeField(),
            ] else ...[
              if (_previewedTemplate == InvoiceTemplate.compact ||
                  _previewedTemplate == InvoiceTemplate.gridClassic)
                const SizedBox(height: 8),
              _buildPdfFontSizeField(),
              const SizedBox(height: 12),
              _buildLetterheadField(),
              const SizedBox(height: 12),
              _buildSoftwareBrandingField(),
            ],
            const SizedBox(height: 18),
            _sectionLabel(l10n.pdfSettingsThemeColorLabel),
            const SizedBox(height: 8),
            _ThemeColorCard(
              controller: _themeColorController,
              presetColors: _presetThemeColors,
              selectedHex: _previewedThemeColorHex,
              isValid: _themeColorInputValid,
              onPresetSelected: (color) =>
                  _setPreviewedThemeColor(_colorToHex(color)),
              onCustomChanged: _handleCustomThemeColor,
              onUseTemplateDefault: () => _setPreviewedThemeColor(null),
              onPickColor: _openColorPicker,
            ),
            const SizedBox(height: 12),
            _buildCustomTemplatePromo(),
          ],
        ),
      ),
    );
  }

  Widget _previewColumnV2() {
    final l10n = AppLocalizations.of(context)!;
    final previewPanel = _PreviewPanel(
      previewedTemplate: _previewedTemplate,
      savedTemplate: _savedTemplate,
      customLayout: _activeCustomLayout,
      themeColor: _activePreviewColor,
      thermalDetailedTemplate: _previewedThermalItemLayout != "table",
      landscape: _previewedLandscape,
      letterheadMode: _previewedLetterheadEnabled &&
          _previewedTemplate != InvoiceTemplate.thermal,
      marginTop: _previewedPrintMarginTopMm,
      marginBottom: _previewedPrintMarginBottomMm,
      contentScale: _previewedPrintContentScale,
      pdfBytes: _previewPdfBytes,
      isLoading: _previewIsLoading,
      useLivePdf: _useLivePdfPreview,
      onToggleLivePdf: () =>
          setState(() => _useLivePdfPreview = !_useLivePdfPreview),
      previewVersion: _previewVersion,
      onPrint: _handlePrintPreview,
    );

    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(l10n.createInvoicePreviewLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
          Expanded(child: previewPanel),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.pdfSettingsPreviewDisclaimer,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildV2(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _headerBarV2(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  if (isNarrow) {
                    // Below the 3-column breakpoint, stack templates+settings
                    // above the preview and let the whole thing scroll,
                    // rather than force three squeezed columns.
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SizedBox(height: 400, child: _templatesColumnV2()),
                          const SizedBox(height: 12),
                          SizedBox(height: 520, child: _settingsColumnV2()),
                          const SizedBox(height: 12),
                          SizedBox(height: 520, child: _previewColumnV2()),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _templatesColumnV2(),
                        const SizedBox(width: 12),
                        _settingsColumnV2(),
                        const SizedBox(width: 12),
                        Expanded(child: _previewColumnV2()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: AppFontSize.xsmall,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _buildOrientationField() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pdfSettingsOrientationLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.pdfSettingsOrientationPortrait)),
              ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.pdfSettingsOrientationLandscape)),
            ],
            selected: {_previewedLandscape},
            onSelectionChanged: (s) {
              setState(() => _previewedLandscape = s.first);
              _schedulePdfPreviewUpdate(immediate: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalQuantityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.pdfSettingsShowTotalQtyRowLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Switch(
            value: _previewedShowTotalQuantity,
            onChanged: (v) {
              setState(() => _previewedShowTotalQuantity = v);
              _schedulePdfPreviewUpdate();
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildThermalItemLayoutField() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pdfSettingsItemLayoutLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'table',
                label: Text(l10n.pdfSettingsItemLayoutTableLabel),
                icon: const Icon(Icons.table_rows_outlined, size: 16),
              ),
              ButtonSegment(
                value: 'detailed',
                label: Text(l10n.pdfSettingsItemLayoutDetailedLabel),
                icon: const Icon(Icons.view_agenda_outlined, size: 16),
              ),
            ],
            selected: {_previewedThermalItemLayout},
            onSelectionChanged: (selection) {
              setState(() => _previewedThermalItemLayout = selection.first);
              _schedulePdfPreviewUpdate();
            },
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pdfSettingsItemLayoutHelpText,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalCompanyNameSizeField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.pdfSettingsCompanyNameSizeLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _previewedThermalCompanyNameSize,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              ),
            ),
            items: [
              for (final size in ThermalCompanyNameSize.values)
                DropdownMenuItem(
                    value: size.key,
                    child: Text(thermalCompanyNameSizeLabel(context, size))),
            ],
            onChanged: (value) {
              setState(() => _previewedThermalCompanyNameSize = value!);
              _schedulePdfPreviewUpdate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfFontSizeField() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pdfSettingsFontSizeLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _previewedPdfFontSize,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xsmall),
                    ),
                  ),
                  items: [
                    for (final size in PdfFontSize.values)
                      DropdownMenuItem(
                          value: size.key,
                          child: Text(pdfFontSizeLabel(context, size))),
                  ],
                  onChanged: (value) {
                    setState(() => _previewedPdfFontSize = value!);
                    _schedulePdfPreviewUpdate();
                  },
                ),
              ),
              // Back to the default sizes (overall + sections) without
              // resetting the other options.
              if (_previewedPdfFontSize != PdfFontSize.medium.key ||
                  _previewedPdfSectionSizes.values
                      .any((v) => v.isNotEmpty)) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _previewedPdfFontSize = PdfFontSize.medium.key;
                      _previewedPdfSectionSizes = {
                        for (final k in _pdfSectionSizeKeys) k: ''
                      };
                    });
                    _schedulePdfPreviewUpdate();
                  },
                  child: Text(l10n.actionReset),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () =>
                setState(() => _showPdfSectionSizes = !_showPdfSectionSizes),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                      _showPdfSectionSizes
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    l10n.pdfSettingsSectionSizesLabel,
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showPdfSectionSizes)
            for (final key in _pdfSectionSizeKeys) ...[
              const SizedBox(height: 8),
              _buildPdfSectionSizeRow(key),
            ],
        ],
      ),
    );
  }

  Widget _buildPdfSectionSizeRow(SettingKey key) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (key) {
      SettingKey.pdfCompanyNameFontSize => l10n.pdfSettingsCompanyNameSizeLabel,
      SettingKey.pdfDocTitleFontSize => l10n.pdfSettingsDocTitleSizeLabel,
      SettingKey.pdfTableHeaderFontSize => l10n.pdfSettingsTableHeaderSizeLabel,
      SettingKey.pdfTableItemsFontSize => l10n.pdfSettingsTableItemsSizeLabel,
      _ => l10n.pdfSettingsTotalsSizeLabel,
    };
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: Theme.of(context).colorScheme.onSurface)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _previewedPdfSectionSizes[key] ?? '',
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              ),
            ),
            items: [
              DropdownMenuItem(
                  value: '', child: Text(l10n.pdfFontSizeSameAsOverallLabel)),
              for (final size in PdfFontSize.values)
                DropdownMenuItem(
                    value: size.key,
                    child: Text(pdfFontSizeLabel(context, size))),
            ],
            onChanged: (value) {
              setState(() => _previewedPdfSectionSizes[key] = value!);
              _schedulePdfPreviewUpdate();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSoftwareBrandingField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Show Invoiceo Branding on Invoice',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: _previewedShowSoftwareBranding,
                onChanged: (v) {
                  setState(() => _previewedShowSoftwareBranding = v);
                  _schedulePdfPreviewUpdate();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'When turned off, removes application-owned branding such as "Generated by Invoiso" from all invoice pages without altering your business logo or details.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterheadField() {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: _previewedLetterheadEnabled
              ? primaryColor.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outlineVariant,
          width: _previewedLetterheadEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 16,
                          color: _previewedLetterheadEnabled
                              ? primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pre-printed Letterhead Mode',
                            style: TextStyle(
                              fontSize: AppFontSize.small,
                              fontWeight: FontWeight.w600,
                              color: _previewedLetterheadEnabled
                                  ? primaryColor
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Print invoices on physical company paper with pre-printed header and footer.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _previewedLetterheadEnabled,
                onChanged: (v) {
                  setState(() => _previewedLetterheadEnabled = v);
                  _schedulePdfPreviewUpdate(immediate: true);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (_previewedLetterheadEnabled) ...[
            const Divider(height: 18),
            // Header suppression toggle
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _previewedLetterheadHideCompanyHeader,
                    onChanged: (v) {
                      setState(() =>
                          _previewedLetterheadHideCompanyHeader = v ?? true);
                      _schedulePdfPreviewUpdate(immediate: true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Omit digital company header & logo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Margins section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRINT MARGINS (MM)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    InkWell(
                      onTap: () => _applyMarginPreset(40, 25, 10, 10),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Standard (40/25)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _applyMarginPreset(25, 20, 8, 8),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Compact (25/20)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _marginInputField(
                    label: 'Top',
                    controller: _marginTopController,
                    onChanged: (_) => setState(_validateMargins),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _marginInputField(
                    label: 'Bottom',
                    controller: _marginBottomController,
                    onChanged: (_) => setState(_validateMargins),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _marginInputField(
                    label: 'Left',
                    controller: _marginLeftController,
                    onChanged: (_) => setState(_validateMargins),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _marginInputField(
                    label: 'Right',
                    controller: _marginRightController,
                    onChanged: (_) => setState(_validateMargins),
                  ),
                ),
              ],
            ),
            if (_marginError != null) ...[
              const SizedBox(height: 4),
              Text(
                _marginError!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
            const SizedBox(height: 14),
            // Content Scaling section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTENT SCALE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${_previewedPrintContentScale.round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: _previewedPrintContentScale.clamp(50.0, 150.0),
                min: 50.0,
                max: 150.0,
                divisions: 20,
                onChanged: (v) {
                  setState(() => _previewedPrintContentScale = v);
                  _schedulePdfPreviewUpdate();
                },
              ),
            ),
            Wrap(
              spacing: 6,
              children: [70.0, 80.0, 90.0, 100.0].map((preset) {
                final isSelected =
                    (_previewedPrintContentScale - preset).abs() < 1;
                return ChoiceChip(
                  label: Text('${preset.toInt()}%'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _previewedPrintContentScale = preset);
                    _schedulePdfPreviewUpdate();
                  },
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              'Scaling adjusts table typography, spacing and totals proportionally while keeping text sharp and readable.',
              style: TextStyle(
                fontSize: 10.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _marginInputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'mm',
        suffixStyle: const TextStyle(fontSize: 9.5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildCustomTemplatePromo() {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 14, color: primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.pdfSettingsCustomTemplatePromoTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pdfSettingsCustomTemplatePromoBody,
            style: TextStyle(
              fontSize: AppFontSize.xsmall,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddLayoutDialog,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 14),
                  label: const Text(
                    'Insert Layout',
                    style: TextStyle(
                      fontSize: AppFontSize.xsmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side:
                        BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.small),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onNavigateToCustomization,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: Text(
                    l10n.pdfSettingsCustomizationOptionsButton,
                    style: const TextStyle(
                      fontSize: AppFontSize.xsmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side:
                        BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.small),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? _colorFromHex(String? hexColor) {
  if (hexColor == null || hexColor.trim().isEmpty) return null;
  try {
    final normalized = SettingsService.normalizePdfThemeColor(hexColor);
    return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
  } catch (_) {
    return null;
  }
}

Color _defaultThemeColor(InvoiceTemplate template) {
  return switch (template) {
    InvoiceTemplate.classic => const Color(0xFF1A237E),
    InvoiceTemplate.modern => const Color(0xFF1E88E5),
    InvoiceTemplate.minimal => const Color(0xFF616161),
    InvoiceTemplate.executive => const Color(0xFF37474F),
    InvoiceTemplate.compact => const Color(0xFF000000),
    InvoiceTemplate.thermal => const Color(0xFF000000),
    InvoiceTemplate.gridClassic => const Color(0xFF000000),
  };
}

// ── Right preview panel ──────────────────────────────────────────────────────

class _PreviewPanel extends StatelessWidget {
  final InvoiceTemplate previewedTemplate;
  final InvoiceTemplate savedTemplate;
  final CustomInvoiceLayout? customLayout;
  final Color themeColor;
  final bool thermalDetailedTemplate;
  final bool landscape;
  final bool letterheadMode;
  final double marginTop;
  final double marginBottom;
  final double contentScale;
  final Uint8List? pdfBytes;
  final bool isLoading;
  final bool useLivePdf;
  final VoidCallback onToggleLivePdf;
  final int previewVersion;
  final VoidCallback? onPrint;

  const _PreviewPanel({
    required this.previewedTemplate,
    required this.savedTemplate,
    this.customLayout,
    required this.themeColor,
    required this.thermalDetailedTemplate,
    this.landscape = false,
    this.letterheadMode = false,
    this.marginTop = 40.0,
    this.marginBottom = 25.0,
    this.contentScale = 100.0,
    this.pdfBytes,
    this.isLoading = false,
    this.useLivePdf = true,
    required this.onToggleLivePdf,
    this.previewVersion = 0,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = customLayout?.name ?? templateName(context, previewedTemplate);
    final description = customLayout?.description ??
        templateDescription(context, previewedTemplate);
    final isSaved = savedTemplate == previewedTemplate;
    final hasBlockLayout = customLayout?.blockLayout?['layout'] is List;

    return Column(
      children: [
        // Header strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 420;
              final infoBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: AppFontSize.medium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSaved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 12),
                              const SizedBox(width: 3),
                              Text(
                                l10n.commonActiveLabel,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (letterheadMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.layers_outlined,
                                  color: Colors.teal, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                'Letterhead (${contentScale.round()}%)',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pdfBytes != null && onPrint != null) ...[
                    FilledButton.tonalIcon(
                      onPressed: onPrint,
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('Print',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.picture_as_pdf_outlined, size: 13),
                        label: Text('PDF', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.brush_outlined, size: 13),
                        label: Text('Mock', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {useLivePdf},
                    onSelectionChanged: (_) => onToggleLivePdf(),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    infoBlock,
                    const SizedBox(height: 8),
                    actionButtons,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: infoBlock),
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              );
            },
          ),
        ),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        // Preview content
        Expanded(
          child: useLivePdf
              ? Stack(
                  children: [
                    if (pdfBytes != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.small),
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SfPdfViewer.memory(
                            pdfBytes!,
                            key: ValueKey(previewVersion),
                            pageLayoutMode: PdfPageLayoutMode.continuous,
                            canShowPageLoadingIndicator: false,
                            canShowScrollStatus: false,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              'Generating accurate print preview...',
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isLoading && pdfBytes != null)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth < 520 ? 16.0 : 32.0;
                    final verticalPadding =
                        constraints.maxHeight < 620 ? 16.0 : 32.0;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: FittedBox(
                          key: ValueKey(
                              '${customLayout?.id ?? previewedTemplate.name}-${_colorToHex(themeColor)}-$landscape-$letterheadMode-$marginTop-$marginBottom-$contentScale'),
                          fit: BoxFit.contain,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                if (hasBlockLayout)
                                  BlockLayoutSketch(
                                    document: customLayout!.blockLayout,
                                    themeColor: themeColor,
                                    width: landscape ? 520 : 390,
                                    height: landscape ? 390 : 520,
                                    showDetails: true,
                                  )
                                else
                                  TemplatePreviewSketch(
                                    template: previewedTemplate,
                                    themeColor: themeColor,
                                    width: landscape ? 520 : 390,
                                    height: landscape ? 390 : 520,
                                    showDetails: true,
                                    thermalDetailedTemplate:
                                        thermalDetailedTemplate,
                                  ),
                                if (letterheadMode) ...[
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: (marginTop *
                                            (landscape ? 390.0 : 520.0) /
                                            297.0)
                                        .clamp(20.0, 180.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706)
                                            .withValues(alpha: 0.22),
                                        border: const Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFD97706),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'PRE-PRINTED HEADER AREA (${marginTop.toInt()} mm)',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: (marginBottom *
                                            (landscape ? 390.0 : 520.0) /
                                            297.0)
                                        .clamp(16.0, 120.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706)
                                            .withValues(alpha: 0.22),
                                        border: const Border(
                                          top: BorderSide(
                                            color: Color(0xFFD97706),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'PRE-PRINTED FOOTER AREA (${marginBottom.toInt()} mm)',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ThemeColorCard extends StatelessWidget {
  final TextEditingController controller;
  final List<Color> presetColors;
  final String? selectedHex;
  final bool isValid;
  final ValueChanged<Color> onPresetSelected;
  final ValueChanged<String> onCustomChanged;
  final VoidCallback onUseTemplateDefault;
  final VoidCallback onPickColor;

  const _ThemeColorCard({
    required this.controller,
    required this.presetColors,
    required this.selectedHex,
    required this.isValid,
    required this.onPresetSelected,
    required this.onCustomChanged,
    required this.onUseTemplateDefault,
    required this.onPickColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pdfSettingsThemeColorLabel,
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...presetColors.map((color) {
                final hex = _colorToHex(color);
                final selected = selectedHex == hex;
                return Tooltip(
                  message: hex,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onPresetSelected(color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.surfaceContainer,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              TextButton(
                onPressed: onUseTemplateDefault,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.dashboardLayoutDefaultTitle,
                  style: const TextStyle(fontSize: AppFontSize.xsmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLength: 7,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
            ],
            decoration: InputDecoration(
              hintText: '#002E78',
              errorText: isValid ? null : l10n.pdfSettingsHexErrorText,
              counterText: '',
              isDense: true,
              prefixIcon: GestureDetector(
                onTap: onPickColor,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _colorFromHex(selectedHex) ??
                          Theme.of(context).colorScheme.outlineVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              suffixIcon: Tooltip(
                message: l10n.pdfSettingsPickColorTooltip,
                child: IconButton(
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  onPressed: onPickColor,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onChanged: onCustomChanged,
          ),
        ],
      ),
    );
  }
}

class _JsonLayoutResult {
  final CustomInvoiceLayout layout;
  final bool save;

  const _JsonLayoutResult({required this.layout, required this.save});
}
