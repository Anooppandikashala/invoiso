import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/utils/amount_in_words.dart';
import 'pdf_widgets.dart';

/// Renders a user-imported block layout document.
///
/// The document shape is `{ page, theme, layout: [ ...blocks ] }`, where each
/// block has a `type` such as `header`, `divider`, `twoColumn`, `table`,
/// `summary`, `box`, `signature` or `footer`. Values may contain
/// `{{placeholders}}` which are resolved against the invoice/company/bank
/// being rendered.
pw.MultiPage buildBlockLayoutTemplate(
  Invoice invoice,
  CompanyInfo? company,
  String currencySymbol,
  String invoicePrefix,
  Map<String, dynamic> document, {
  String? upiId,
  bool showUpiQr = false,
  bool showGst = true,
  bool showSlNo = true,
  bool showQuantity = true,
  bool showDiscount = true,
  bool showTypeTag = true,
  bool showAliasName = false,
  bool showDescription = false,
  bool showTaxColumn = true,
  bool showCgstSgst = false,
  bool showIgst = false,
  bool showLeadingZeros = true,
  String datePattern = 'dd/MM/yyyy',
  BankAccount? bankAccount,
  Uint8List? logoBytes,
  Uint8List? signatureBytes,
  String signaturePosition = 'left',
  double signatureSizePx = 50,
  bool showFooterBranding = true,
  String thankYouNote = '',
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  PdfColor? themeColor,
}) {
  final renderer = _BlockLayoutRenderer(
    invoice: invoice,
    company: company,
    currencySymbol: currencySymbol,
    invoicePrefix: invoicePrefix,
    document: document,
    upiId: upiId,
    showUpiQr: showUpiQr,
    showGst: showGst,
    showSlNo: showSlNo,
    showQuantity: showQuantity,
    showDiscount: showDiscount,
    showTypeTag: showTypeTag,
    showAliasName: showAliasName,
    showDescription: showDescription,
    showTaxColumn: showTaxColumn,
    showCgstSgst: showCgstSgst,
    showIgst: showIgst,
    showLeadingZeros: showLeadingZeros,
    datePattern: datePattern,
    bankAccount: bankAccount,
    logoBytes: logoBytes,
    signatureBytes: signatureBytes,
    signaturePosition: signaturePosition,
    signatureSizePx: signatureSizePx,
    showFooterBranding: showFooterBranding,
    thankYouNote: thankYouNote,
    fallbackPageFormat: pageFormat,
    themeColor: themeColor,
  );

  return pw.MultiPage(
    pageTheme: renderer.pageTheme,
    build: (context) {
      final widgets = <pw.Widget>[];
      var renderedBlocks = 0;
      for (final block in renderer.blocks) {
        final widget = renderer.buildBlock(block);
        if (widget == null) continue;
        widgets.add(widget);
        renderedBlocks++;
        if (block['type'] != 'divider' && block['type'] != 'footer') {
          widgets.add(pw.SizedBox(height: 12));
        }
      }
      // A layout can be imported with block names this renderer does not know.
      // Never emit an empty page in that case: render the standard invoice
      // structure using the imported document's own page + theme. This is not
      // the built-in Classic template, so the inserted layout's colours and
      // paper size are still the ones the user sees.
      if (renderedBlocks == 0) {
        widgets.addAll(renderer.buildFallbackBlocks());
      }
      return widgets;
    },
  );
}

class _BlockLayoutRenderer {
  _BlockLayoutRenderer({
    required this.invoice,
    required this.company,
    required this.currencySymbol,
    required this.invoicePrefix,
    required Map<String, dynamic> document,
    required this.upiId,
    required this.showUpiQr,
    required this.showGst,
    required this.showSlNo,
    required this.showQuantity,
    required this.showDiscount,
    required this.showTypeTag,
    required this.showAliasName,
    required this.showDescription,
    required this.showTaxColumn,
    required this.showCgstSgst,
    required this.showIgst,
    required this.showLeadingZeros,
    required this.datePattern,
    required this.bankAccount,
    required this.logoBytes,
    required this.signatureBytes,
    required this.signaturePosition,
    required this.signatureSizePx,
    required this.showFooterBranding,
    required this.thankYouNote,
    required PdfPageFormat fallbackPageFormat,
    required this.themeColor,
  })  : document = document,
        blocks = _blocksOf(document),
        pageTheme = _buildPageTheme(document, fallbackPageFormat);

  final Invoice invoice;
  final CompanyInfo? company;
  final String currencySymbol;
  final String invoicePrefix;
  final Map<String, dynamic> document;
  final String? upiId;
  final bool showUpiQr;
  final bool showGst;
  final bool showSlNo;
  final bool showQuantity;
  final bool showDiscount;
  final bool showTypeTag;
  final bool showAliasName;
  final bool showDescription;
  final bool showTaxColumn;
  final bool showCgstSgst;
  final bool showIgst;
  final bool showLeadingZeros;
  final String datePattern;
  final BankAccount? bankAccount;
  final Uint8List? logoBytes;
  final Uint8List? signatureBytes;
  final String signaturePosition;
  final double signatureSizePx;
  final bool showFooterBranding;
  final String thankYouNote;

  /// Accent colour from the saved layout settings, used when the imported
  /// document has no `theme.primary` of its own.
  final PdfColor? themeColor;
  final List<Map<String, dynamic>> blocks;
  final pw.PageTheme pageTheme;

  late final Map<String, dynamic> _theme =
      _asMap(document['theme'] ?? document['colors']);
  late final PdfColor primary = _color(
      _theme['primary'] ??
          _theme['primaryColor'] ??
          _theme['color'] ??
          _theme['accent'],
      fallback: themeColor ?? PdfColor.fromHex('#2563EB'));
  late final PdfColor textColor = _color(
      _theme['text'] ?? _theme['textColor'] ?? _theme['foreground'],
      fallback: PdfColor.fromHex('#111827'));
  late final PdfColor mutedColor = _color(
      _theme['muted'] ?? _theme['mutedColor'] ?? _theme['secondaryText'],
      fallback: PdfColor.fromHex('#6B7280'));
  late final PdfColor borderColor = _color(
      _theme['border'] ?? _theme['borderColor'] ?? _theme['divider'],
      fallback: PdfColor.fromHex('#E5E7EB'));

  pw.Widget? buildBlock(Map<String, dynamic> block) {
    final type = (block['type'] ?? _inferBlockType(block))
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
    switch (type) {
      case 'header':
        return _header(block);
      case 'divider':
        return pw.Divider(color: borderColor, thickness: 0.8, height: 8);
      case 'twocolumn':
      case 'two_column':
        return _twoColumn(block);
      case 'table':
      case 'items':
      case 'lineitems':
      case 'line_items':
      case 'invoiceitems':
      case 'invoice_items':
      case 'products':
        return _table(block);
      case 'summary':
      case 'totals':
        return _summary(block);
      case 'customer':
      case 'billto':
      case 'bill_to':
      case 'billing':
      case 'customerinfo':
      case 'customer_info':
        return _customerBlock(block);
      case 'company':
      case 'seller':
      case 'from':
      case 'companyinfo':
      case 'company_info':
        return _companyBlock(block);
      case 'invoicedetails':
      case 'invoice_details':
      case 'invoicemeta':
      case 'invoice_meta':
      case 'metadata':
      case 'details':
        return _invoiceDetailsBlock(block);
      case 'bank':
      case 'bankdetails':
      case 'bank_details':
      case 'payment':
      case 'paymentdetails':
      case 'payment_details':
        return _bankBlock(block);
      case 'box':
      case 'note':
      case 'notes':
      case 'terms':
        return _box(block);
      case 'signature':
        return _signature(block);
      case 'footer':
        return _footer(block);
      case 'spacer':
        final height = _double(block['height'], fallback: 12);
        return pw.SizedBox(height: height.clamp(0.0, 400.0));
      case 'text':
      case 'paragraph':
        return _textBlock(block);
      case 'row':
      case 'columns':
      case 'column':
      case 'container':
      case 'section':
      case 'group':
        return _containerBlock(block);
      case 'image':
      case 'logo':
        return _imageBlock(block);
      default:
        // Unknown custom block names still render their readable content
        // instead of being silently dropped. Nested containers are rendered
        // recursively before falling back to plain text collection.
        return _containerBlock(block) ?? _genericBlock(block);
    }
  }

  String? _inferBlockType(Map<String, dynamic> block) {
    final keys = block.keys.map((key) => key.toLowerCase()).toSet();
    if (keys.contains('columns')) return 'table';
    if (keys.contains('rows')) return 'summary';
    if (keys.contains('branding') || keys.contains('note')) return 'footer';
    if (keys.contains('children') ||
        keys.contains('blocks') ||
        keys.contains('sections') ||
        keys.contains('elements')) {
      return 'container';
    }
    if (keys.contains('customer') || keys.contains('billto')) {
      return 'customer';
    }
    if (keys.contains('company') || keys.contains('seller')) {
      return 'company';
    }
    if (keys.contains('items') || keys.contains('lineitems')) return 'table';
    if (keys.contains('totals')) return 'summary';
    if (keys.contains('bank') || keys.contains('payment')) return 'bank';
    if (keys.contains('left') || keys.contains('right')) {
      if (keys.contains('title') ||
          block['right'] is Map &&
              (_asMap(block['right'])['title'] != null ||
                  _asMap(block['right'])['invoiceNo'] != null)) {
        return 'header';
      }
      return 'twoColumn';
    }
    if (keys.contains('content') || keys.contains('text')) return 'text';
    if (keys.contains('label') && keys.contains('signature')) {
      return 'signature';
    }
    if (keys.contains('title')) return 'box';
    if (keys.contains('height')) return 'spacer';
    return null;
  }

  pw.Widget? _genericBlock(Map<String, dynamic> block) {
    final title = _resolve(block['title']?.toString() ?? '');
    final explicitContent = _resolve(
      block['content']?.toString() ??
          block['text']?.toString() ??
          block['value']?.toString() ??
          '',
    );
    final lines = <String>[];
    if (explicitContent.trim().isNotEmpty) {
      lines.add(explicitContent);
    } else {
      lines.addAll(_collectTextValues(block, skip: const {'title'}));
    }
    if (title.isEmpty && lines.isEmpty) return null;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor)),
            pw.SizedBox(height: 4),
          ],
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(line,
                  style: pw.TextStyle(fontSize: 9.5, color: textColor)),
            ),
        ],
      ),
    );
  }

  /// Renders nested/unknown layout containers instead of dropping them.
  pw.Widget? _containerBlock(Map<String, dynamic> block) {
    final children = _childBlocks(block);
    if (children.isEmpty) return null;
    final widgets = <pw.Widget>[];
    for (final child in children) {
      final widget = buildBlock(child);
      if (widget == null) continue;
      if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 8));
      widgets.add(widget);
    }
    if (widgets.isEmpty) return null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Map<String, dynamic>> _childBlocks(Map<String, dynamic> block) {
    for (final key in const [
      'children',
      'blocks',
      'sections',
      'elements',
      'layout',
      'items',
    ]) {
      final raw = block[key];
      if (raw is List) {
        final result = <Map<String, dynamic>>[];
        for (final entry in raw) {
          final map = _asMap(entry);
          if (map.isNotEmpty &&
              (map.containsKey('type') || map.length > 1)) {
            result.add(map);
          }
        }
        if (result.isNotEmpty) return result;
      }
      final nested = _asMap(raw);
      if (nested.isNotEmpty) {
        final child = _childBlocks(nested);
        if (child.isNotEmpty) return child;
      }
    }
    final left = _asMap(block['left']);
    final right = _asMap(block['right']);
    if (left.isNotEmpty || right.isNotEmpty) {
      return [
        if (left.isNotEmpty) left,
        if (right.isNotEmpty) right,
      ];
    }
    return const [];
  }

  List<String> _collectTextValues(
    Map<String, dynamic> block, {
    Set<String> skip = const {},
  }) {
    final result = <String>[];
    for (final entry in block.entries) {
      final key = entry.key.toLowerCase();
      if (key == 'type' ||
          key == 'align' ||
          key == 'color' ||
          key == 'background' ||
          key == 'border' ||
          key == 'width' ||
          key == 'height' ||
          key == 'bold' ||
          key == 'highlight' ||
          skip.contains(key)) {
        continue;
      }
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        final text = _resolve(value).trim();
        if (text.isNotEmpty) result.add(text);
      } else if (value is num) {
        result.add(value.toString());
      } else if (value is Map) {
        final map = _asMap(value);
        result.addAll(_collectTextValues(map));
      } else if (value is List) {
        for (final child in value) {
          final map = _asMap(child);
          if (map.isNotEmpty) {
            result.addAll(_collectTextValues(map));
          } else if (child is String && child.trim().isNotEmpty) {
            final text = _resolve(child).trim();
            if (text.isNotEmpty) result.add(text);
          }
        }
      }
    }
    return result;
  }

  List<String> _fieldStrings(dynamic value) {
    final result = <String>[];
    if (value is String && value.trim().isNotEmpty) {
      result.add(_resolve(value));
    } else if (value is List) {
      for (final entry in value) {
        if (entry is String && entry.trim().isNotEmpty) {
          result.add(_resolve(entry));
        } else {
          final map = _asMap(entry);
          if (map.isEmpty) continue;
          final text = map['text'] ??
              map['value'] ??
              map['label'] ??
              map['content'] ??
              map['line'];
          if (text != null && text.toString().trim().isNotEmpty) {
            result.add(_resolve(text.toString()));
          }
        }
      }
    }
    return result;
  }

  pw.Widget? _infoBlock(
    Map<String, dynamic> block, {
    required String fallbackTitle,
    required List<String> fallbackFields,
  }) {
    final title =
        _resolve(block['title']?.toString() ?? block['label']?.toString() ?? '');
    final fields = _fieldStrings(
      block['fields'] ??
          block['lines'] ??
          block['values'] ??
          block['content'] ??
          block['text'],
    );
    final effectiveFields = fields.isEmpty ? fallbackFields : fields;
    if (title.isEmpty && effectiveFields.isEmpty) return null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text((title.isEmpty ? fallbackTitle : title).toUpperCase(),
            style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.6,
                color: primary)),
        pw.SizedBox(height: 5),
        for (final field in effectiveFields)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: pw.Text(field,
                style: pw.TextStyle(fontSize: 9.5, color: textColor)),
          ),
      ],
    );
  }

  pw.Widget? _customerBlock(Map<String, dynamic> block) {
    final customer = invoice.customer;
    return _infoBlock(
      block,
      fallbackTitle: 'Bill To',
      fallbackFields: [
        if (customer.name.trim().isNotEmpty) customer.name,
        if (customer.businessName.trim().isNotEmpty) customer.businessName,
        if (customer.address.trim().isNotEmpty) customer.address,
        if (customer.phone.trim().isNotEmpty) customer.phone,
        if (customer.email.trim().isNotEmpty) customer.email,
        if (showGst && customer.gstin.trim().isNotEmpty) customer.gstin,
      ],
    );
  }

  pw.Widget? _companyBlock(Map<String, dynamic> block) {
    return _infoBlock(
      block,
      fallbackTitle: 'From',
      fallbackFields: [
        if ((company?.name ?? '').trim().isNotEmpty) company!.name,
        if ((company?.address ?? '').trim().isNotEmpty) company!.address,
        if ((company?.phone ?? '').trim().isNotEmpty) company!.phone,
        if ((company?.email ?? '').trim().isNotEmpty) company!.email,
        if ((company?.website ?? '').trim().isNotEmpty) company!.website,
        if (showGst && (company?.gstin ?? '').trim().isNotEmpty)
          company!.gstin,
      ],
    );
  }

  pw.Widget? _invoiceDetailsBlock(Map<String, dynamic> block) {
    final number = invoice.pdfNumberText(
          invoicePrefix,
          showLeadingZeros: showLeadingZeros,
        ) ??
        '';
    return _infoBlock(
      block,
      fallbackTitle: 'Invoice Details',
      fallbackFields: [
        if (number.isNotEmpty) 'Invoice No: $number',
        'Date: ${formatPdfDate(invoice.date, datePattern)}',
        if (invoice.dueDate != null)
          'Due Date: ${formatPdfDate(invoice.dueDate!, datePattern)}',
        if ((invoice.status ?? '').isNotEmpty) 'Status: ${invoice.status}',
      ],
    );
  }

  pw.Widget? _bankBlock(Map<String, dynamic> block) {
    return _infoBlock(
      block,
      fallbackTitle: 'Payment Details',
      fallbackFields: [
        if ((bankAccount?.bankName ?? '').trim().isNotEmpty)
          'Bank: ${bankAccount!.bankName}',
        if ((bankAccount?.accountNumber ?? '').trim().isNotEmpty)
          'Account: ${bankAccount!.accountNumber}',
        if ((bankAccount?.ifscCode ?? '').trim().isNotEmpty)
          'IFSC: ${bankAccount!.ifscCode}',
        if ((bankAccount?.iban ?? '').trim().isNotEmpty)
          'IBAN: ${bankAccount!.iban}',
        if ((upiId ?? '').trim().isNotEmpty) 'UPI: $upiId',
      ],
    );
  }

  pw.Widget? _imageBlock(Map<String, dynamic> block) {
    final source = (block['source'] ?? block['src'] ?? block['image'] ?? '')
        .toString()
        .toLowerCase();
    final wantsSignature = source.contains('signature');
    final bytes =
        wantsSignature ? signatureBytes : (logoBytes ?? signatureBytes);
    if (bytes == null) return null;
    final height = _double(block['height'], fallback: wantsSignature ? 40 : 42);
    return pw.Align(
      alignment: _alignment(block['align'] ?? 'left'),
      child: pw.Image(
        pw.MemoryImage(bytes),
        height: height.clamp(12.0, 120.0),
        fit: pw.BoxFit.contain,
      ),
    );
  }

  /// The invoice body used when a layout contains only block names this
  /// renderer does not recognise. It intentionally uses the imported
  /// document's theme/page rather than the built-in Classic template.
  List<pw.Widget> buildFallbackBlocks() {
    final defaults = <Map<String, dynamic>>[
      {
        'type': 'header',
        'left': {
          'companyName': '{{company.name}}',
          'tagline': '{{company.address}}',
        },
        'right': {
          'title': '{{invoice.title}}',
          'invoiceNo': '{{invoice.number}}',
          'date': '{{invoice.date}}',
        },
      },
      {
        'type': 'twoColumn',
        'left': {
          'title': 'Bill To',
          'fields': [
            '{{customer.name}}',
            '{{customer.address}}',
            '{{customer.phone}}',
            '{{customer.email}}',
            '{{customer.gstin}}',
          ],
        },
        'right': {
          'title': 'Invoice Details',
          'fields': [
            '{{invoice.number}}',
            '{{invoice.date}}',
            '{{invoice.status}}',
          ],
        },
      },
      {'type': 'table'},
      {
        'type': 'summary',
        'rows': [
          {'label': 'Subtotal', 'value': '{{subtotal}}'},
          {'label': 'Tax', 'value': '{{tax}}'},
          {'label': 'Total', 'value': '{{total}}', 'highlight': true},
        ],
      },
      {'type': 'footer'},
    ];
    final widgets = <pw.Widget>[];
    for (final block in defaults) {
      final widget = buildBlock(block);
      if (widget == null) continue;
      if (widgets.isNotEmpty) widgets.add(pw.SizedBox(height: 12));
      widgets.add(widget);
    }
    return widgets;
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  pw.Widget? _header(Map<String, dynamic> block) {
    final left = _asMap(block['left'] ??
        block['company'] ??
        block['seller'] ??
        block['from']);
    final right = _asMap(block['right'] ??
        block['invoice'] ??
        block['meta'] ??
        block['details']);
    final height = _double(block['height'], fallback: 0);
    final showLogo = left['logo'] == true && logoBytes != null;
    final companyName = _resolve(left['companyName']?.toString() ??
        left['company']?.toString() ??
        left['name']?.toString() ??
        block['companyName']?.toString() ??
        '');
    final tagline = _resolve(left['tagline']?.toString() ??
        left['address']?.toString() ??
        block['tagline']?.toString() ??
        '');
    final title = _resolve(right['title']?.toString() ??
        right['document']?.toString() ??
        block['title']?.toString() ??
        '');
    final invoiceNo = _resolve(right['invoiceNo']?.toString() ??
        right['number']?.toString() ??
        right['invoiceNumber']?.toString() ??
        '');
    final date = _resolve(right['date']?.toString() ?? '');

    if (!showLogo &&
        companyName.isEmpty &&
        tagline.isEmpty &&
        title.isEmpty &&
        invoiceNo.isEmpty &&
        date.isEmpty) {
      return null;
    }

    final leftColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (showLogo) ...[
          pw.Image(pw.MemoryImage(logoBytes!),
              height: 42, fit: pw.BoxFit.contain),
          pw.SizedBox(height: 6),
        ],
        if (companyName.isNotEmpty)
          pw.Text(companyName,
              style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor)),
        if (tagline.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(tagline,
              style: pw.TextStyle(fontSize: 9.5, color: mutedColor)),
        ],
      ],
    );

    final rightColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        if (title.isNotEmpty)
          pw.Text(title,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primary)),
        if (invoiceNo.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(invoiceNo,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, color: textColor)),
        ],
        if (date.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(date,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 9.5, color: mutedColor)),
        ],
      ],
    );

    final content = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(child: leftColumn),
        pw.SizedBox(width: 16),
        pw.Expanded(child: rightColumn),
      ],
    );
    return height > 0 ? pw.Container(height: height, child: content) : content;
  }

  pw.Widget _twoColumn(Map<String, dynamic> block) {
    final left = _asMap(block['left']);
    final right = _asMap(block['right']);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _columnSide(left)),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _columnSide(right)),
      ],
    );
  }

  pw.Widget _columnSide(Map<String, dynamic> side) {
    final title = _resolve(side['title']?.toString() ?? '');
    final text = _resolve(side['text']?.toString() ?? '');
    final fields = <String>[];
    final rawFields = side['fields'];
    if (rawFields is List) {
      for (final field in rawFields) {
        final value = _resolve(field?.toString() ?? '');
        if (value.trim().isNotEmpty) fields.add(value);
      }
    }
    final showSignature = side['signature'] == true;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          pw.Text(title.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.6,
                  color: primary)),
          pw.SizedBox(height: 5),
        ],
        if (text.isNotEmpty) ...[
          pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 9.5, color: textColor, lineSpacing: 2)),
          pw.SizedBox(height: 4),
        ],
        for (final field in fields)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: pw.Text(field,
                style: pw.TextStyle(
                    fontSize: 9.5, color: textColor, lineSpacing: 2)),
          ),
        if (showSignature) _signatureContent(),
      ],
    );
  }

  pw.Widget _signatureContent() {
    if (signatureBytes != null) {
      return buildSignatureWidget(
        pw.MemoryImage(signatureBytes!),
        signaturePosition,
        imageHeight: signatureSizePx,
      );
    }
    final align = signaturePosition == 'right'
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;
    return pw.Column(
      crossAxisAlignment: align,
      children: [
        pw.SizedBox(height: signatureSizePx),
        pw.Container(width: 120, height: 0.8, color: borderColor),
        pw.SizedBox(height: 4),
        pw.Text('Authorised Signature',
            style: pw.TextStyle(fontSize: 8.5, color: mutedColor)),
      ],
    );
  }

  pw.Widget _signature(Map<String, dynamic> block) {
    final label =
        _resolve(block['label']?.toString() ?? 'Authorised Signature');
    if (signatureBytes != null) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          buildSignatureWidget(
            pw.MemoryImage(signatureBytes!),
            signaturePosition,
            imageHeight: signatureSizePx,
            labelFontSize: 8.5,
          ),
          if (label.isNotEmpty && label != 'Authorised Signature')
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8.5, color: mutedColor)),
        ],
      );
    }
    return pw.Align(
      alignment: signaturePosition == 'right'
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: signaturePosition == 'right'
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: signatureSizePx),
          pw.Container(width: 120, height: 0.8, color: borderColor),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: mutedColor)),
        ],
      ),
    );
  }

  pw.Widget _table(Map<String, dynamic> block) {
    final title = _resolve(block['title']?.toString() ?? '');
    final columns = <Map<String, dynamic>>[];
    final rawColumns = block['columns'];
    if (rawColumns is List) {
      for (final raw in rawColumns) {
        final map = _asMap(raw);
        if (map.isNotEmpty) columns.add(map);
      }
    }
    final effectiveColumns = columns.isEmpty
        ? [
            {'key': 'item', 'label': 'Item', 'width': '40%'},
            {'key': 'qty', 'label': 'Qty', 'width': '15%', 'align': 'center'},
            {
              'key': 'price',
              'label': 'Price',
              'width': '20%',
              'align': 'right'
            },
            {
              'key': 'amount',
              'label': 'Amount',
              'width': '25%',
              'align': 'right'
            },
          ]
        : columns;

    final columnWidths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < effectiveColumns.length; i++)
        i: _columnWidth(effectiveColumns[i]['width']),
    };

    final header = pw.TableRow(
      decoration: pw.BoxDecoration(color: primary),
      children: [
        for (final column in effectiveColumns)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: pw.Align(
              alignment: _alignment(column['align']),
              child: pw.Text(
                _resolve(column['label']?.toString() ?? ''),
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
              ),
            ),
          ),
      ],
    );

    final rows = <pw.TableRow>[];
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      rows.add(
        pw.TableRow(
          decoration:
              i.isOdd ? pw.BoxDecoration(color: PdfColors.grey50) : null,
          children: [
            for (final column in effectiveColumns)
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Align(
                  alignment: _alignment(column['align']),
                  child: pw.Text(
                    _itemCell(column['key']?.toString() ?? '', item, i),
                    style: pw.TextStyle(fontSize: 9, color: textColor),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        pw.TableRow(children: [
          for (var i = 0; i < effectiveColumns.length; i++)
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: pw.Text(i == 0 ? 'No items' : '',
                  style: pw.TextStyle(fontSize: 9, color: mutedColor)),
            ),
        ]),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor)),
          pw.SizedBox(height: 6),
        ],
        pw.Table(
          columnWidths: columnWidths,
          border: pw.TableBorder(
            top: pw.BorderSide(color: borderColor, width: 0.7),
            bottom: pw.BorderSide(color: borderColor, width: 0.7),
            horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
          ),
          children: [header, ...rows],
        ),
      ],
    );
  }

  pw.Widget? _summary(Map<String, dynamic> block) {
    final rows = <Map<String, dynamic>>[];
    final rawRows = block['rows'];
    if (rawRows is List) {
      for (final raw in rawRows) {
        final map = _asMap(raw);
        if (map.isNotEmpty) rows.add(map);
      }
    }
    if (rows.isEmpty) return null;

    final width = _double(block['width'], fallback: 0);
    final content = pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        for (final row in rows)
          _summaryRow(
            label: _resolve(row['label']?.toString() ?? ''),
            value: _resolve(row['value']?.toString() ?? ''),
            bold: row['bold'] == true,
            highlight: row['highlight'] == true,
          ),
      ],
    );
    return pw.Align(
      alignment: _alignment(block['align'] ?? 'right'),
      child: width > 0 ? pw.SizedBox(width: width, child: content) : content,
    );
  }

  pw.Widget _summaryRow({
    required String label,
    required String value,
    required bool bold,
    required bool highlight,
  }) {
    if (highlight) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          color: primary,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Flexible(
                child: pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white))),
            pw.SizedBox(width: 12),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ],
        ),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Flexible(
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: mutedColor))),
          pw.SizedBox(width: 12),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: textColor)),
        ],
      ),
    );
  }

  pw.Widget? _box(Map<String, dynamic> block) {
    final title = _resolve(block['title']?.toString() ?? '');
    final content = _resolve(block['content']?.toString() ??
        block['text']?.toString() ??
        block['note']?.toString() ??
        '');
    if (title.isEmpty && content.isEmpty) return null;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: borderColor, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            pw.Text(title.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.6,
                    color: mutedColor)),
            pw.SizedBox(height: 4),
          ],
          if (content.isNotEmpty)
            pw.Text(content,
                style: pw.TextStyle(
                    fontSize: 9.5, color: textColor, lineSpacing: 2)),
        ],
      ),
    );
  }

  pw.Widget? _textBlock(Map<String, dynamic> block) {
    final text = _resolve(
        block['content']?.toString() ?? block['text']?.toString() ?? '');
    if (text.isEmpty) return null;
    return pw.Text(
      text,
      textAlign: _textAlign(block['align']),
      style: pw.TextStyle(
        fontSize: _double(block['fontSize'], fallback: 9.5),
        color: textColor,
        fontWeight:
            block['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  pw.Widget _footer(Map<String, dynamic> block) {
    final branding = _asMap(block['branding']);
    final brandingEnabled = branding['enabled'] is bool
        ? branding['enabled'] as bool
        : showFooterBranding;
    final brandingText = _resolve(branding['text']?.toString() ?? '');
    final note = _resolve(block['note']?.toString() ?? '');
    final effectiveNote = note.isNotEmpty ? note : thankYouNote;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: borderColor, thickness: 0.6, height: 10),
        if (effectiveNote.isNotEmpty)
          pw.Text(effectiveNote,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8.5, color: mutedColor)),
        if (brandingEnabled && brandingText.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(brandingText,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 7.5, color: mutedColor)),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Values / placeholders
  // ---------------------------------------------------------------------------

  String _itemCell(String key, InvoiceItem item, int index) {
    switch (key.toLowerCase()) {
      case 'slno':
      case 'sl_no':
      case '#':
      case 'no':
        return '${index + 1}';
      case 'item':
      case 'name':
      case 'product':
        return item.product.displayName(showAliasName);
      case 'alias':
        return item.product.aliasName ?? '';
      case 'description':
      case 'desc':
        return showDescription ? item.printedDescription : '';
      case 'hsn':
      case 'hsncode':
      case 'hsn_code':
        return item.product.hsncode;
      case 'qty':
      case 'quantity':
        return _quantity(item.quantity);
      case 'unit':
        return item.effectiveUnit;
      case 'price':
      case 'rate':
        return _money(item.effectivePrice);
      case 'discount':
        return _money(item.totalDiscount);
      case 'tax':
        return _money(item.taxAmount);
      case 'amount':
      case 'total':
        return _money(item.total);
      default:
        return '';
    }
  }

  String _resolve(String input) {
    if (!input.contains('{{')) return input;
    return input.replaceAllMapped(RegExp(r'\{\{\s*([^}]+?)\s*\}\}'), (match) {
      return _placeholder(match.group(1)!.trim());
    });
  }

  String _placeholder(String rawKey) {
    final key = rawKey.toLowerCase();
    final customer = invoice.customer;
    switch (key) {
      case 'invoice.number':
      case 'invoice.no':
        return invoice.pdfNumberText(invoicePrefix,
                showLeadingZeros: showLeadingZeros) ??
            '';
      case 'invoice.date':
        return formatPdfDate(invoice.date, datePattern);
      case 'invoice.duedate':
      case 'invoice.due_date':
        return invoice.dueDate == null
            ? ''
            : formatPdfDate(invoice.dueDate!, datePattern);
      case 'invoice.type':
        return invoice.type;
      case 'invoice.title':
        return invoice.invoiceTitle?.isNotEmpty == true
            ? invoice.invoiceTitle!
            : invoice.type;
      case 'invoice.status':
        return invoice.status ?? '';
      case 'invoice.notes':
        return invoice.notes ?? '';
      case 'invoice.paymentmethod':
      case 'invoice.payment_method':
        return invoice.payments.isEmpty
            ? ''
            : (invoice.payments.last.paymentMethod ?? '');
      case 'invoice.salesperson':
        return _customFieldValue(['salesperson', 'sales person', 'sales']);
      case 'invoice.ponumber':
      case 'invoice.po':
        return _customFieldValue(['po', 'purchase order', 'po number']);
      case 'customer.name':
        return customer.name;
      case 'customer.businessname':
      case 'customer.business_name':
        return customer.businessName;
      case 'customer.address':
        return customer.address;
      case 'customer.phone':
        return customer.phone;
      case 'customer.email':
        return customer.email;
      case 'customer.gstin':
        return customer.gstin;
      case 'company.name':
        return company?.name ?? '';
      case 'company.address':
        return company?.address ?? '';
      case 'company.phone':
        return company?.phone ?? '';
      case 'company.email':
        return company?.email ?? '';
      case 'company.website':
        return company?.website ?? '';
      case 'company.gstin':
        return company?.gstin ?? '';
      case 'company.pan':
        return company?.panNumber ?? '';
      case 'subtotal':
        return _money(invoice.subtotal);
      case 'grosssubtotal':
      case 'gross_subtotal':
        return _money(invoice.grossSubtotal);
      case 'discount':
        return _money(invoice.totalDiscount + invoice.invoiceDiscountAmount);
      case 'tax':
        return _money(invoice.tax);
      case 'cgst':
        if (invoice.isInterState || invoice.tax == 0) return _money(0);
        return _money(invoice.tax / 2);
      case 'sgst':
        if (invoice.isInterState || invoice.tax == 0) return _money(0);
        return _money(invoice.tax / 2);
      case 'igst':
        return _money(invoice.isInterState ? invoice.tax : 0);
      case 'total':
      case 'grandtotal':
        return _money(invoice.total);
      case 'amountpaid':
        return _money(invoice.amountPaid);
      case 'balance':
      case 'outstanding':
      case 'amountdue':
        return _money(invoice.outstandingBalance);
      case 'previousbalance':
        return _money(invoice.previousBalance);
      case 'amountinwords':
      case 'amount_in_words':
        return AmountInWords.amount(invoice.total);
      case 'bank.name':
        return bankAccount?.bankName ?? '';
      case 'bank.account':
      case 'bank.accountnumber':
        return bankAccount?.accountNumber ?? '';
      case 'bank.ifsc':
        return bankAccount?.ifscCode ?? '';
      case 'bank.iban':
        return bankAccount?.iban ?? '';
      case 'bank.upi':
        return upiId ?? '';
      case 'items':
        return '';
      default:
        return '';
    }
  }

  String _customFieldValue(List<String> labels) {
    for (final field in invoice.customFields) {
      final label = field.label.toLowerCase();
      if (labels.any((keyword) => label.contains(keyword))) return field.value;
    }
    return '';
  }

  String _money(double value) => '$currencySymbol ${value.toStringAsFixed(2)}';

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  // ---------------------------------------------------------------------------
  // Document-level helpers
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> _blocksOf(Map<String, dynamic> document) {
    dynamic layout = document['layout'] ??
        document['blocks'] ??
        document['sections'] ??
        document['elements'] ??
        document['children'] ??
        document['body'] ??
        document['content'];
    if (layout is Map) {
      final map = _asMap(layout);
      layout = map['layout'] ??
          map['blocks'] ??
          map['sections'] ??
          map['elements'] ??
          map['children'] ??
          map['body'] ??
          map['content'];
    }
    if (layout is! List) return const [];
    final result = <Map<String, dynamic>>[];
    for (final block in layout) {
      final map = _asMap(block);
      if (map.isNotEmpty) {
        result.add(map);
      } else if (block is String && block.trim().isNotEmpty) {
        result.add({'type': 'text', 'content': block});
      }
    }
    return result;
  }

  static pw.PageTheme _buildPageTheme(
    Map<String, dynamic> document,
    PdfPageFormat fallback,
  ) {
    final page = _asMap(document['page'] ?? document['paper']);
    final unit = _pageUnit(page);
    final format = _pageFormat(page, fallback, unit);
    final margin = _pageMargin(page, unit);
    dynamic backgroundValue = page['background'];
    backgroundValue ??=
        _asMap(document['theme'] ?? document['colors'])['background'];
    final background = _color(backgroundValue, fallback: PdfColors.white);
    return pw.PageTheme(
      pageFormat: format,
      margin: margin,
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: background),
      ),
    );
  }

  static PdfPageFormat _pageFormat(
    Map<String, dynamic> page,
    PdfPageFormat fallback,
    _PageUnit unit,
  ) {
    PdfPageFormat format = fallback;

    // Custom physical size. Imported designs often use CSS pixels (A4 is
    // 794×1123 px), so treating every number as millimetres used to create a
    // ~794 mm-wide page that made the invoice look tiny in the preview.
    final width = _doubleOrNull(page['width']);
    final height = _doubleOrNull(page['height']);
    if (width != null && height != null && width > 0 && height > 0) {
      if (unit == _PageUnit.px) {
        // 794×1123 (A4 @96 DPI), 1240×1754 (@150) and 2480×3508 (@300) all
        // mean A4. Snap them to the real paper size instead of scaling a
        // possibly wrong DPI assumption.
        format = _standardFormatForPixels(width, height) ??
            PdfPageFormat(
              width * _unitToPoints(unit),
              height * _unitToPoints(unit),
            );
      } else {
        final scale = _unitToPoints(unit);
        format = PdfPageFormat(width * scale, height * scale);
      }
    } else {
      final rawSize = page['size']?.toString().trim().toLowerCase() ?? '';
      final sizeToken = rawSize.split(RegExp(r'[\s_-]+')).first;
      switch (sizeToken) {
        case 'a3':
          format = PdfPageFormat.a3;
          break;
        case 'a4':
          format = PdfPageFormat.a4;
          break;
        case 'a5':
          format = PdfPageFormat.a5;
          break;
        case 'a6':
          format = PdfPageFormat.a6;
          break;
        case 'letter':
        case 'usletter':
          format = PdfPageFormat.letter;
          break;
        case 'legal':
          format = PdfPageFormat.legal;
          break;
      }
    }
    final orientation = page['orientation']?.toString().trim().toLowerCase() ??
        page['size']?.toString().trim().toLowerCase() ??
        '';
    if (orientation.contains('landscape')) return format.landscape;
    if (orientation.contains('portrait')) return format.portrait;
    return format;
  }

  static double? _doubleOrNull(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// Physical unit used by `page.width` / `page.height` / `page.margin`.
  ///
  /// An explicit `unit` always wins. Otherwise common paper sizes are
  /// recognised so pixel, point and inch based designs are not mistaken for
  /// millimetres.
  static _PageUnit _pageUnit(Map<String, dynamic> page) {
    final raw = (page['unit'] ??
            page['units'] ??
            page['measurement'] ??
            page['uom'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    if (raw.contains('px') || raw.contains('pixel')) return _PageUnit.px;
    if (raw.contains('pt') || raw.contains('point')) return _PageUnit.point;
    if (raw == 'in' ||
        raw == 'inchs' ||
        raw == 'inch' ||
        raw == 'inches' ||
        raw.contains('inch')) {
      return _PageUnit.inch;
    }
    if (raw.contains('cm')) return _PageUnit.cm;
    if (raw.contains('mm') || raw.contains('millimet')) return _PageUnit.mm;

    final width = _doubleOrNull(page['width']);
    final height = _doubleOrNull(page['height']);
    if (width != null && height != null && width > 0 && height > 0) {
      if (_nearPaperSize(width, height, _paperSizesInPoints)) {
        return _PageUnit.point;
      }
      if (width > 500 || height > 500) return _PageUnit.px;
      if (width <= 40 && height <= 40) return _PageUnit.inch;
    }
    return _PageUnit.mm;
  }

  static bool _nearPaperSize(
    double width,
    double height,
    List<List<double>> sizes,
  ) {
    for (final size in sizes) {
      if ((width - size[0]).abs() <= 6 && (height - size[1]).abs() <= 6) {
        return true;
      }
      if ((width - size[1]).abs() <= 6 && (height - size[0]).abs() <= 6) {
        return true;
      }
    }
    return false;
  }

  /// Matches a pixel page against common paper sizes at 72/96/150/300 DPI.
  static PdfPageFormat? _standardFormatForPixels(
    double width,
    double height,
  ) {
    for (final dpi in const [96.0, 150.0, 300.0]) {
      for (final size in _paperSizesInPoints) {
        final expectedWidth = size[0] / 72.0 * dpi;
        final expectedHeight = size[1] / 72.0 * dpi;
        final toleranceWidth = expectedWidth * 0.02 + 4;
        final toleranceHeight = expectedHeight * 0.02 + 4;
        if ((width - expectedWidth).abs() <= toleranceWidth &&
            (height - expectedHeight).abs() <= toleranceHeight) {
          return PdfPageFormat(size[0], size[1]);
        }
        if ((width - expectedHeight).abs() <= toleranceWidth &&
            (height - expectedWidth).abs() <= toleranceHeight) {
          return PdfPageFormat(size[1], size[0]);
        }
      }
    }
    return null;
  }

  static final List<List<double>> _paperSizesInPoints = [
    [PdfPageFormat.a3.width, PdfPageFormat.a3.height],
    [PdfPageFormat.a4.width, PdfPageFormat.a4.height],
    [PdfPageFormat.a5.width, PdfPageFormat.a5.height],
    [PdfPageFormat.a6.width, PdfPageFormat.a6.height],
    [PdfPageFormat.letter.width, PdfPageFormat.letter.height],
    [PdfPageFormat.legal.width, PdfPageFormat.legal.height],
  ];

  static double _unitToPoints(_PageUnit unit) {
    switch (unit) {
      case _PageUnit.mm:
        return PdfPageFormat.mm;
      case _PageUnit.cm:
        return 10 * PdfPageFormat.mm;
      case _PageUnit.inch:
        return 72.0;
      case _PageUnit.px:
        return 72.0 / 96.0;
      case _PageUnit.point:
        return 1.0;
    }
  }

  static pw.EdgeInsets _pageMargin(Map<String, dynamic> page, _PageUnit unit) {
    final scale = _unitToPoints(unit);
    final raw = page['margin'];
    if (raw is num) {
      return pw.EdgeInsets.all(raw.toDouble() * scale);
    }
    final map = _asMap(raw);
    // A missing margin is a physical default, not "12 of whatever unit".
    final defaultAll = 12 * PdfPageFormat.mm;
    if (map.isEmpty) {
      return pw.EdgeInsets.all(defaultAll);
    }
    double readPoints(String key, double fallbackPoints) {
      final value = map[key];
      if (value is num) return value.toDouble() * scale;
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        return parsed == null ? fallbackPoints : parsed * scale;
      }
      return fallbackPoints;
    }

    final all = readPoints('all', defaultAll);
    return pw.EdgeInsets.fromLTRB(
      readPoints('left', all),
      readPoints('top', all),
      readPoints('right', all),
      readPoints('bottom', all),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static PdfColor _color(dynamic value, {required PdfColor fallback}) {
    if (value is! String) return fallback;
    final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
    if (match == null) return fallback;
    return PdfColor.fromHex(match.group(1)!);
  }

  static double _double(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static pw.Alignment _alignment(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'center':
        return pw.Alignment.center;
      case 'right':
        return pw.Alignment.centerRight;
      case 'left':
        return pw.Alignment.centerLeft;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  static pw.TextAlign _textAlign(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  static pw.TableColumnWidth _columnWidth(dynamic value) {
    if (value is num) {
      return pw.FixedColumnWidth(value.toDouble());
    }
    if (value is String) {
      final text = value.trim();
      if (text.endsWith('%')) {
        final percent = double.tryParse(text.substring(0, text.length - 1));
        if (percent != null && percent > 0) {
          return pw.FlexColumnWidth(percent);
        }
      } else {
        final fixed = double.tryParse(text);
        if (fixed != null && fixed > 0) return pw.FixedColumnWidth(fixed);
      }
    }
    return const pw.FlexColumnWidth(1);
  }
}

/// Unit used by an imported block document's page dimensions.
enum _PageUnit { mm, cm, inch, px, point }

