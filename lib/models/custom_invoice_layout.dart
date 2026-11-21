import 'dart:convert';
import 'package:invoiso/common/common.dart';

/// A saved, reusable invoice layout.
///
/// Layouts are plain data: they never contain executable code. They are
/// stored as JSON in the `custom_invoice_layouts` setting and are applied to
/// the existing PDF settings when selected.
class CustomInvoiceLayout {
  final String id;
  final String name;
  final String description;
  final InvoiceTemplate baseTemplate;
  final PageSize pageSize;
  final bool landscape;
  final String? themeColorHex;
  final String fontSize; // 'small' | 'medium' | 'large' | 'xlarge'
  final Map<String, String> sectionSizes;
  final bool showTotalQuantity;
  final String thermalWidthMargin;
  final String thermalItemLayout;
  final String thermalCompanyNameSize;
  final DateTime createdAt;

  /// Optional block-based document, used by layout JSON files that describe
  /// the invoice as a list of blocks (`page` + `theme` + `layout`). When
  /// present this is rendered by the block-layout PDF renderer instead of the
  /// built-in template named by [baseTemplate].
  final Map<String, dynamic>? blockLayout;

  const CustomInvoiceLayout({
    required this.id,
    required this.name,
    required this.description,
    required this.baseTemplate,
    this.pageSize = PageSize.a4,
    this.landscape = false,
    this.themeColorHex,
    this.fontSize = 'medium',
    this.sectionSizes = const {},
    this.showTotalQuantity = false,
    this.thermalWidthMargin = '1',
    this.thermalItemLayout = 'table',
    this.thermalCompanyNameSize = 'medium',
    this.blockLayout,
    required this.createdAt,
  });

  /// True when this layout carries a renderable block document.
  bool get hasBlockLayout {
    final blocks = blockLayout?['layout'];
    return blocks is List && blocks.isNotEmpty;
  }

  /// The accent colour this layout actually prints with.
  ///
  /// Block documents usually put their colour in `theme.primary` rather than
  /// the settings-only `themeColorHex` field. Reading both here keeps the
  /// preview, the inserted-layout tile and the rendered PDF on the layout's
  /// real theme instead of falling back to the built-in template's colour.
  String? get effectiveThemeColorHex {
    if (themeColorHex != null && themeColorHex!.trim().isNotEmpty) {
      return themeColorHex;
    }
    final document = blockLayout;
    if (document == null) return null;
    final theme = _asMap(document['theme']) ?? _asMap(document['colors']);
    if (theme == null) return null;
    return _normalizedColor(
      theme['primary'] ??
          theme['primaryColor'] ??
          theme['color'] ??
          theme['accent'],
    );
  }

  static String? _normalizedColor(dynamic value) {
    if (value == null) return null;
    final match = RegExp(r'^#?([0-9a-fA-F]{6})$')
        .firstMatch(value.toString().trim());
    if (match == null) return null;
    return '#${match.group(1)!.toUpperCase()}';
  }

  static const List<String> pdfSectionSizeKeys = [
    'pdfCompanyNameFontSize',
    'pdfDocTitleFontSize',
    'pdfTableHeaderFontSize',
    'pdfTableItemsFontSize',
    'pdfTotalsFontSize',
  ];

  static const Set<String> _fontSizeKeys = {
    'small',
    'medium',
    'large',
    'xlarge',
  };

  static const Set<String> _thermalCompanyNameSizes = {
    'xsmall',
    'small',
    'medium',
    'large',
  };

  static const Set<String> _thermalItemLayouts = {'table', 'detailed'};

  /// The template actually used for rendering. An incompatible pair (for
  /// example `classic` + `a6`) falls back to the app's normal page-size
  /// mapping instead of producing a broken PDF.
  InvoiceTemplate get effectiveBaseTemplate =>
      effectiveInvoiceTemplateForPageSize(baseTemplate, pageSize);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'baseTemplate': baseTemplate.name,
      'pageSize': pageSize.name,
      'landscape': landscape,
      'themeColorHex': themeColorHex,
      'fontSize': fontSize,
      'sectionSizes': sectionSizes,
      'showTotalQuantity': showTotalQuantity,
      'thermalWidthMargin': thermalWidthMargin,
      'thermalItemLayout': thermalItemLayout,
      'thermalCompanyNameSize': thermalCompanyNameSize,
      if (blockLayout != null) 'blockLayout': blockLayout,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CustomInvoiceLayout copyWith({
    String? id,
    String? name,
    String? description,
    InvoiceTemplate? baseTemplate,
    PageSize? pageSize,
    bool? landscape,
    String? themeColorHex,
    bool clearThemeColor = false,
    String? fontSize,
    Map<String, String>? sectionSizes,
    bool? showTotalQuantity,
    String? thermalWidthMargin,
    String? thermalItemLayout,
    String? thermalCompanyNameSize,
    Map<String, dynamic>? blockLayout,
    bool clearBlockLayout = false,
    DateTime? createdAt,
  }) {
    return CustomInvoiceLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseTemplate: baseTemplate ?? this.baseTemplate,
      pageSize: pageSize ?? this.pageSize,
      landscape: landscape ?? this.landscape,
      themeColorHex:
          clearThemeColor ? null : (themeColorHex ?? this.themeColorHex),
      fontSize: fontSize ?? this.fontSize,
      sectionSizes: sectionSizes ?? this.sectionSizes,
      showTotalQuantity: showTotalQuantity ?? this.showTotalQuantity,
      thermalWidthMargin: thermalWidthMargin ?? this.thermalWidthMargin,
      thermalItemLayout: thermalItemLayout ?? this.thermalItemLayout,
      thermalCompanyNameSize:
          thermalCompanyNameSize ?? this.thermalCompanyNameSize,
      blockLayout: clearBlockLayout ? null : (blockLayout ?? this.blockLayout),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Lenient parser used for already-stored layouts, so a single old or
  /// slightly malformed entry never prevents existing layouts from loading.
  factory CustomInvoiceLayout.fromMap(
    Map<String, dynamic> map, {
    bool strict = false,
    String? fallbackId,
    DateTime? fallbackCreatedAt,
  }) {
    final id = _stringValue(
      map['id'],
      field: 'id',
      fallback: fallbackId ?? 'layout_${DateTime.now().millisecondsSinceEpoch}',
      strict: strict,
    );
    final rawName = _stringValue(
      map['name'],
      field: 'name',
      fallback: 'Custom Layout',
      strict: strict,
    ).trim();
    final description = _stringValue(
      map['description'],
      field: 'description',
      fallback: 'Imported custom invoice layout',
      strict: strict,
    );

    final page = _asMap(map['page'] ?? map['paper'] ?? map['pageSettings']);
    final theme = _asMap(map['theme'] ?? map['colors'] ?? map['colorScheme']);
    final displayOptions = _asMap(map['displayOptions']) ??
        _asMap(map['display']) ??
        _asMap(map['options']);
    final blockLayout = _blockLayoutValue(
      map['blockLayout'],
      document: map,
      page: page,
      theme: theme,
    );

    final baseTemplate = _templateValue(
      map['baseTemplate'] ?? map['template'],
      strict: strict,
    );
    final pageSize = _pageSizeValue(
      map['pageSize'] ?? page?['size'],
      strict: strict,
    );
    final themeColorHex = _colorValue(
      map['themeColorHex'] ??
          map['themeColor'] ??
          map['primaryColor'] ??
          theme?['primary'] ??
          theme?['primaryColor'] ??
          theme?['color'] ??
          theme?['accent'],
      strict: strict,
    );

    final fontSize = _enumValue(
        map['fontSize'] ?? displayOptions?['fontSize'],
        _fontSizeKeys,
        'fontSize',
        'medium',
        strict);
    final thermalWidthMargin = _thermalWidthValue(
      map['thermalWidthMargin'],
      strict: strict,
    );
    final thermalItemLayout = _enumValue(
      map['thermalItemLayout'],
      _thermalItemLayouts,
      'thermalItemLayout',
      'table',
      strict,
    );
    final thermalCompanyNameSize = _enumValue(
      map['thermalCompanyNameSize'],
      _thermalCompanyNameSizes,
      'thermalCompanyNameSize',
      'medium',
      strict,
    );

    final orientationText = (map['orientation'] ??
            page?['orientation'] ??
            page?['size'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final landscape = _boolValue(
      map['landscape'],
      field: 'landscape',
      fallback: orientationText.contains('landscape'),
      strict: strict,
    );

    final createdAt = _dateValue(
      map['createdAt'],
      fallback: fallbackCreatedAt ?? DateTime.now(),
    );

    return CustomInvoiceLayout(
      id: id,
      name: rawName.isEmpty ? 'Custom Layout' : rawName,
      description: description,
      baseTemplate: baseTemplate,
      pageSize: pageSize,
      landscape: landscape,
      themeColorHex: themeColorHex,
      fontSize: fontSize,
      sectionSizes: _sectionSizesValue(map['sectionSizes'], strict: strict),
      showTotalQuantity: _boolValue(
        map['showTotalQuantity'] ?? displayOptions?['showTotalQuantity'],
        field: 'showTotalQuantity',
        fallback: false,
        strict: strict,
      ),
      thermalWidthMargin: thermalWidthMargin,
      thermalItemLayout: thermalItemLayout,
      thermalCompanyNameSize: thermalCompanyNameSize,
      blockLayout: blockLayout,
      createdAt: createdAt,
    );
  }

  /// Lenient parser for user-authored/imported JSON. Only a broken JSON
  /// document is rejected: missing or differently named layout fields are
  /// normalised with sensible defaults so a partial design never silently
  /// falls back to the built-in Classic template.
  factory CustomInvoiceLayout.fromJson(
    String source, {
    String? fallbackId,
    DateTime? fallbackCreatedAt,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Error on JSON file');
    }

    final Map<String, dynamic> map;
    if (decoded is Map) {
      map = decoded.map((key, value) => MapEntry(key.toString(), value));
    } else if (decoded is List) {
      // A bare block array is a perfectly valid way to describe a layout.
      map = {'layout': decoded};
    } else {
      throw const FormatException('Error on JSON file');
    }

    return CustomInvoiceLayout.fromMap(
      map,
      fallbackId: fallbackId,
      fallbackCreatedAt: fallbackCreatedAt,
    );
  }

  String toJson() => jsonEncode(toMap());

  String toPrettyJson() {
    final encoder = const JsonEncoder.withIndent('  ');
    if (blockLayout != null) {
      // Keep the editor in the same block document shape the user imported,
      // so editing a block layout does not silently convert it to the
      // settings-only layout schema.
      return encoder.convert(<String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        ...blockLayout!,
        'createdAt': createdAt.toIso8601String(),
      });
    }
    return encoder.convert(toMap());
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static const List<String> _blockListKeys = [
    'layout',
    'blocks',
    'sections',
    'elements',
    'children',
    'body',
    'content',
    'block',
  ];

  static const Set<String> _blockTypes = {
    'header',
    'divider',
    'twocolumn',
    'table',
    'items',
    'lineitems',
    'invoiceitems',
    'products',
    'summary',
    'totals',
    'box',
    'note',
    'notes',
    'terms',
    'signature',
    'footer',
    'spacer',
    'text',
    'paragraph',
    'customer',
    'billto',
    'billing',
    'customerinfo',
    'company',
    'seller',
    'from',
    'companyinfo',
    'invoicedetails',
    'invoicemeta',
    'metadata',
    'details',
    'bank',
    'bankdetails',
    'payment',
    'paymentdetails',
    'row',
    'columns',
    'column',
    'container',
    'section',
    'group',
    'image',
    'logo',
  };

  /// Normalises either the app's own `blockLayout` wrapper or a user-authored
  /// document (`{ page, theme, layout }`) into one predictable shape.
  ///
  /// The import path deliberately accepts loose/partial JSON: block lists may
  /// be called `layout`, `blocks`, `sections`, `elements`, `children`, `body`
  /// or `content`, a single block may be supplied instead of a list, and a
  /// design that only sets a page/theme still gets a usable default layout
  /// instead of falling back to Classic.
  static Map<String, dynamic>? _blockLayoutValue(
    dynamic stored, {
    Map<String, dynamic>? document,
    Map<String, dynamic>? page,
    Map<String, dynamic>? theme,
  }) {
    final wrapped = _asMap(stored);
    final rawBlocks = _rawBlocksOf(stored) ??
        (document == null ? null : _rawBlocksOf(document));

    final normalized = <Map<String, dynamic>>[];
    if (rawBlocks != null) {
      for (final block in rawBlocks) {
        final map = _asMap(block);
        if (map != null) {
          normalized.add(map);
        } else if (block is String && block.trim().isNotEmpty) {
          normalized.add({'type': 'text', 'content': block});
        }
      }
    }

    if (normalized.isEmpty && document != null) {
      normalized.addAll(_blocksFromNamedSections(document));
    }
    if (normalized.isEmpty && document != null) {
      // A whole document may itself be one block, e.g. `{ "type": "header" }`.
      final rawType = document['type']?.toString().trim() ?? '';
      if (rawType.isNotEmpty) {
        normalized.add(document);
      }
    }
    if (normalized.isEmpty && document != null) {
      // Named sections may be nested under a container key, e.g.
      // `{ "layout": { "header": { ... }, "table": { ... } } }`.
      for (final key in _blockListKeys) {
        final nested = _asMap(document[key]);
        if (nested == null) continue;
        normalized.addAll(_blocksFromNamedSections(nested));
        if (normalized.isNotEmpty) break;
      }
    }
    if (normalized.isEmpty &&
        document != null &&
        _looksLikeBlockDocument(document)) {
      normalized.addAll(_defaultLayoutBlocks());
    }
    if (normalized.isEmpty) return null;

    return {
      'page': _asMap(wrapped?['page']) ??
          page ??
          _asMap(document?['page']) ??
          <String, dynamic>{},
      'theme': _asMap(wrapped?['theme']) ??
          theme ??
          _asMap(document?['theme']) ??
          <String, dynamic>{},
      'layout': normalized,
      // Template engine v2 document settings (engine version, block gap,
      // named styles, repeated page header/footer).
      for (final key in const ['engine', 'gap', 'styles', 'pageHeader', 'pageFooter'])
        if ((wrapped ?? document)?[key] != null) key: (wrapped ?? document)![key],
    };
  }

  /// Finds a block list under any of the friendly keys users naturally write.
  static List<dynamic>? _rawBlocksOf(dynamic value) {
    if (value is List) return value;
    final map = _asMap(value);
    if (map == null) return null;
    for (final key in _blockListKeys) {
      final candidate = map[key];
      if (candidate is List) return candidate;
      if (candidate is Map) {
        final nested = _rawBlocksOf(candidate);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  /// Supports documents that name sections directly, e.g.
  /// `{ "header": { ... }, "table": { ... } }`.
  ///
  /// Names are compared after removing punctuation/spaces, so `"Bill To"`,
  /// `"bill_to"` and `"billTo"` all keep their own customer content instead of
  /// being dropped and replaced by the default layout.
  static List<Map<String, dynamic>> _blocksFromNamedSections(
    Map<String, dynamic> document,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final entry in document.entries) {
      final key = _normalizedToken(entry.key);
      if (!_blockTypes.contains(key)) continue;
      final value = _asMap(entry.value);
      if (value != null) {
        result.add({'type': key, ...value});
        continue;
      }
      final list = entry.value;
      if (list is List) {
        for (final child in list) {
          final childMap = _asMap(child);
          if (childMap != null) result.add(childMap);
        }
      }
    }
    return result;
  }

  static bool _looksLikeBlockDocument(Map<String, dynamic> document) {
    if (document.keys.any((key) => _blockTypes.contains(_normalizedToken(key)))) {
      return true;
    }
    return document.containsKey('page') ||
        document.containsKey('paper') ||
        document.containsKey('theme') ||
        document.containsKey('colors') ||
        _blockListKeys.any(document.containsKey);
  }

  /// Minimal, valid invoice structure used when a user supplies only page or
  /// theme information. This keeps the output a custom block layout rather
  /// than silently rendering the built-in Classic template.
  static List<Map<String, dynamic>> _defaultLayoutBlocks() => [
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

  static String _stringValue(
    dynamic value, {
    required String field,
    required String fallback,
    required bool strict,
  }) {
    if (value == null) return fallback;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (strict) {
      throw FormatException('"$field" must be text.');
    }
    return fallback;
  }

  static bool _boolValue(
    dynamic value, {
    required String field,
    required bool fallback,
    required bool strict,
  }) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (strict) {
      throw FormatException('"$field" must be true or false.');
    }
    return fallback;
  }

  /// Normalises user-authored enum values so layouts exported by hand (or by
  /// another build) still import: `"Grid Classic"`, `"grid-classic"` and
  /// `"gridClassic"` all resolve to [InvoiceTemplate.gridClassic].
  static String _normalizedToken(dynamic value) => value
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  static InvoiceTemplate _templateValue(dynamic value, {required bool strict}) {
    // A missing template is not an error: imported layouts that only override
    // colours/margins should inherit the normal Classic renderer instead of
    // failing the whole import (and leaving the previous/default theme active).
    if (value == null) return InvoiceTemplate.classic;
    final normalized = _normalizedToken(value);
    for (final template in InvoiceTemplate.values) {
      if (_normalizedToken(template.name) == normalized) return template;
    }
    // Common human-readable aliases used in exported/hand-edited JSON.
    if (normalized == 'grid') return InvoiceTemplate.gridClassic;
    if (normalized == 'receipt' || normalized == 'thermalreceipt') {
      return InvoiceTemplate.thermal;
    }
    if (strict) {
      throw FormatException(
        '"baseTemplate" must be one of: '
        '${InvoiceTemplate.values.map((e) => e.name).join(', ')}.',
      );
    }
    return InvoiceTemplate.classic;
  }

  static PageSize _pageSizeValue(dynamic value, {required bool strict}) {
    // Same rule as the template: absent means the standard A4 default.
    if (value == null) return PageSize.a4;
    final normalized = _normalizedToken(value);
    for (final pageSize in PageSize.values) {
      if (_normalizedToken(pageSize.name) == normalized) return pageSize;
    }
    // Accept the forms people naturally write for thermal paper.
    switch (normalized) {
      case '80':
      case '80mm':
      case 'thermal80mm':
        return PageSize.thermal80;
      case '58':
      case '58mm':
      case 'thermal58mm':
        return PageSize.thermal58;
    }
    if (strict) {
      throw FormatException(
        '"pageSize" must be one of: '
        '${PageSize.values.map((e) => e.name).join(', ')}.',
      );
    }
    return PageSize.a4;
  }

  static String? _colorValue(dynamic value, {required bool strict}) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(raw);
    if (match == null) {
      if (strict) {
        throw const FormatException(
          '"themeColorHex" must be a 6-digit hex color, e.g. "#2563EB".',
        );
      }
      return null;
    }
    return '#${match.group(1)!.toUpperCase()}';
  }

  static String _enumValue(
    dynamic value,
    Set<String> allowed,
    String field,
    String fallback,
    bool strict,
  ) {
    if (value == null) return fallback;
    final normalized = value.toString().trim().toLowerCase();
    if (allowed.contains(normalized)) return normalized;
    if (strict) {
      throw FormatException(
        '"$field" must be one of: ${allowed.join(', ')}.',
      );
    }
    return fallback;
  }

  static String _thermalWidthValue(dynamic value, {required bool strict}) {
    if (value == null) return '1';
    final text = value.toString().trim();
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < -10 || parsed > 10) {
      if (strict) {
        throw const FormatException(
          '"thermalWidthMargin" must be a whole number between -10 and 10.',
        );
      }
      return '1';
    }
    return parsed.toString();
  }

  static Map<String, String> _sectionSizesValue(
    dynamic value, {
    required bool strict,
  }) {
    if (value == null) return const {};
    if (value is! Map) {
      if (strict) {
        throw const FormatException(
          '"sectionSizes" must be an object of setting-name to font size.',
        );
      }
      return const {};
    }
    final result = <String, String>{};
    for (final entry in value.entries) {
      final rawKey = entry.key.toString();
      final key = _canonicalSectionSizeKey(rawKey);
      if (key == null) {
        if (strict) {
          throw FormatException(
            'Unknown sectionSizes key "$rawKey". Expected one of: '
            '${pdfSectionSizeKeys.join(', ')}.',
          );
        }
        continue;
      }
      final raw = entry.value?.toString().trim() ?? '';
      if (raw.isEmpty) {
        result[key] = '';
      } else if (_fontSizeKeys.contains(raw.toLowerCase())) {
        result[key] = raw.toLowerCase();
      } else if (strict) {
        throw FormatException(
          'sectionSizes["$rawKey"] must be one of: '
          '${_fontSizeKeys.join(', ')}, or an empty string.',
        );
      }
    }
    return result;
  }

  /// Settings-only layout files often use short names (`companyName`,
  /// `tableItems`, ...) while the stored setting keys are prefixed with
  /// `pdf...FontSize`. Both spellings (and case/punctuation variants) point at
  /// the same setting.
  static String? _canonicalSectionSizeKey(String rawKey) {
    if (pdfSectionSizeKeys.contains(rawKey)) return rawKey;
    final token = _normalizedToken(rawKey);
    const aliases = <String, String>{
      'companyname': 'pdfCompanyNameFontSize',
      'companynamefontsize': 'pdfCompanyNameFontSize',
      'doctitle': 'pdfDocTitleFontSize',
      'doctitlefontsize': 'pdfDocTitleFontSize',
      'documenttitle': 'pdfDocTitleFontSize',
      'tableheader': 'pdfTableHeaderFontSize',
      'tableheaderfontsize': 'pdfTableHeaderFontSize',
      'tableitems': 'pdfTableItemsFontSize',
      'tableitemsfontsize': 'pdfTableItemsFontSize',
      'items': 'pdfTableItemsFontSize',
      'totals': 'pdfTotalsFontSize',
      'totalsfontsize': 'pdfTotalsFontSize',
    };
    return aliases[token];
  }

  static DateTime _dateValue(dynamic value, {required DateTime fallback}) {
    if (value == null) return fallback;
    return DateTime.tryParse(value.toString()) ?? fallback;
  }
}
