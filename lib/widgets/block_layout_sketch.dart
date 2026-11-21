import 'package:flutter/material.dart';

/// Renders the *actual* imported block document as a Flutter sketch.
///
/// The PDF settings screen used to show the built-in template thumbnail for
/// inserted layouts, which made a custom layout look like Classic until it was
/// exported. This widget reads the same `page` / `theme` / `layout` document
/// the PDF renderer uses, so the tile and the Mock preview show the inserted
/// layout's own blocks and accent colour.
class BlockLayoutSketch extends StatelessWidget {
  final Map<String, dynamic>? document;
  final Color themeColor;
  final double width;
  final double height;
  final bool showDetails;

  const BlockLayoutSketch({
    super.key,
    required this.document,
    required this.themeColor,
    required this.width,
    required this.height,
    this.showDetails = false,
  });

  static const double _canvasWidth = 390;
  static const double _canvasHeight = 520;

  @override
  Widget build(BuildContext context) {
    final blocks = _blocksOf(document);
    final theme = _asMap(document?['theme'] ?? document?['colors']) ??
        const <String, dynamic>{};
    final primary =
        _color(theme['primary'] ?? theme['primaryColor'] ?? theme['color'] ??
                theme['accent']) ??
            themeColor;
    final textColor =
        _color(theme['text'] ?? theme['textColor'] ?? theme['foreground']) ??
            const Color(0xFF111827);
    final mutedColor =
        _color(theme['muted'] ?? theme['mutedColor'] ?? theme['secondaryText']) ??
            const Color(0xFF6B7280);
    final borderColor =
        _color(theme['border'] ?? theme['borderColor'] ?? theme['divider']) ??
            const Color(0xFFE5E7EB);
    final background = _color(theme['background'] ?? theme['backgroundColor']) ??
        Colors.white;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _canvasWidth,
            height: _canvasHeight,
            child: Container(
              color: background,
              child: ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (blocks.isEmpty)
                        _fallback(
                          primary: primary,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          borderColor: borderColor,
                        )
                      else
                        for (var i = 0; i < blocks.length; i++) ...[
                          _block(
                            blocks[i],
                            primary: primary,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            borderColor: borderColor,
                          ),
                          if (i != blocks.length - 1) const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  Widget _block(
    Map<String, dynamic> block, {
    required Color primary,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final type = (block['type'] ?? _inferType(block))
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
    switch (type) {
      case 'header':
        return _header(block, primary, textColor, mutedColor);
      case 'divider':
        return Divider(color: borderColor, thickness: 0.8, height: 8);
      case 'twocolumn':
      case 'two_column':
        return _twoColumn(block, primary, textColor, mutedColor);
      case 'table':
      case 'items':
      case 'lineitems':
      case 'invoiceitems':
      case 'products':
        return _table(block, primary, textColor, mutedColor, borderColor);
      case 'summary':
      case 'totals':
        return _summary(block, primary, textColor, mutedColor);
      case 'customer':
      case 'billto':
      case 'billing':
      case 'customerinfo':
        return _infoBlock(block, 'BILL TO', primary, textColor, mutedColor);
      case 'company':
      case 'seller':
      case 'from':
      case 'companyinfo':
        return _infoBlock(block, 'FROM', primary, textColor, mutedColor);
      case 'invoicedetails':
      case 'invoicemeta':
      case 'metadata':
      case 'details':
        return _infoBlock(block, 'INVOICE DETAILS', primary, textColor, mutedColor);
      case 'bank':
      case 'bankdetails':
      case 'payment':
      case 'paymentdetails':
        return _infoBlock(block, 'PAYMENT DETAILS', primary, textColor, mutedColor);
      case 'box':
      case 'note':
      case 'notes':
      case 'terms':
        return _box(block, textColor, mutedColor, borderColor);
      case 'signature':
        return _signature(block, mutedColor, borderColor);
      case 'footer':
        return _footer(block, mutedColor, borderColor);
      case 'spacer':
        final height = _number(block['height'], fallback: 12).clamp(0, 400);
        return SizedBox(height: height.toDouble());
      case 'text':
      case 'paragraph':
        return _textBlock(block, textColor);
      case 'row':
      case 'columns':
      case 'column':
      case 'container':
      case 'section':
      case 'group':
        return _container(block,
                primary: primary,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor) ??
            const SizedBox.shrink();
      default:
        return _container(block,
                primary: primary,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor) ??
            _generic(block, textColor, mutedColor, borderColor);
    }
  }

  Widget _header(
    Map<String, dynamic> block,
    Color primary,
    Color textColor,
    Color mutedColor,
  ) {
    final left = _asMap(block['left']) ?? _asMap(block['company']) ?? {};
    final right = _asMap(block['right']) ?? _asMap(block['invoice']) ?? {};
    final company = _value(left['companyName'] ??
        left['company'] ??
        left['name'] ??
        block['companyName'] ??
        '{{company.name}}');
    final tagline = _value(left['tagline'] ??
        left['address'] ??
        block['tagline'] ??
        '{{company.address}}');
    final title = _value(right['title'] ??
        right['document'] ??
        block['title'] ??
        '{{invoice.title}}');
    final invoiceNo =
        _value(right['invoiceNo'] ?? right['number'] ?? '{{invoice.number}}');
    final date = _value(right['date'] ?? '{{invoice.date}}');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(company,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              if (tagline.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: mutedColor)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primary)),
            if (invoiceNo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(invoiceNo,
                  style: TextStyle(fontSize: 10, color: textColor)),
            ],
            if (date.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(date, style: TextStyle(fontSize: 9, color: mutedColor)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _twoColumn(
    Map<String, dynamic> block,
    Color primary,
    Color textColor,
    Color mutedColor,
  ) {
    final left = _asMap(block['left']) ?? {};
    final right = _asMap(block['right']) ?? {};
    if (left.isEmpty && right.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _columnSide(left, primary, textColor, mutedColor)),
        const SizedBox(width: 20),
        Expanded(child: _columnSide(right, primary, textColor, mutedColor)),
      ],
    );
  }

  Widget _columnSide(
    Map<String, dynamic> side,
    Color primary,
    Color textColor,
    Color mutedColor,
  ) {
    final title = _value(side['title'] ?? '');
    final text = _value(side['text'] ?? '');
    final fields = _stringList(side['fields']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: primary)),
          const SizedBox(height: 4),
        ],
        if (text.isNotEmpty) ...[
          Text(text, style: TextStyle(fontSize: 9, color: textColor)),
          const SizedBox(height: 3),
        ],
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.5),
            child: Text(field,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: textColor)),
          ),
      ],
    );
  }

  Widget _table(
    Map<String, dynamic> block,
    Color primary,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final rawColumns = block['columns'];
    final labels = <String>[];
    if (rawColumns is List) {
      for (final raw in rawColumns) {
        final map = _asMap(raw);
        if (map != null) {
          labels.add(_value(map['label'] ?? map['title'] ?? map['key'] ?? ''));
        } else if (raw != null) {
          labels.add(_value(raw));
        }
      }
    }
    if (labels.isEmpty) {
      labels.addAll(const ['ITEM', 'QTY', 'PRICE', 'AMOUNT']);
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.7),
      ),
      child: Column(
        children: [
          Container(
            color: primary,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    flex: i == 0 ? 3 : 1,
                    child: Text(
                      labels[i],
                      textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                      style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          for (var row = 0; row < 3; row++)
            Container(
              color: row.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      flex: i == 0 ? 3 : 1,
                      child: Container(
                        height: 4,
                        alignment: i == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        margin: EdgeInsets.only(
                            right: i == labels.length - 1 ? 0 : 6),
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summary(
    Map<String, dynamic> block,
    Color primary,
    Color textColor,
    Color mutedColor,
  ) {
    final rawRows = block['rows'];
    final rows = <Map<String, dynamic>>[];
    if (rawRows is List) {
      for (final raw in rawRows) {
        final map = _asMap(raw);
        if (map != null) rows.add(map);
      }
    }
    if (rows.isEmpty) {
      rows.addAll([
        {'label': 'Subtotal', 'value': '{{subtotal}}'},
        {'label': 'Tax', 'value': '{{tax}}'},
        {'label': 'Total', 'value': '{{total}}', 'highlight': true},
      ]);
    }
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 190,
        child: Column(
          children: [
            for (final row in rows)
              if (row['highlight'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_value(row['label'] ?? ''),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(_value(row['value'] ?? ''),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                )
              else
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_value(row['label'] ?? ''),
                          style: TextStyle(fontSize: 9, color: mutedColor)),
                      Text(_value(row['value'] ?? ''),
                          style: TextStyle(fontSize: 9, color: textColor)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(
    Map<String, dynamic> block,
    String fallbackTitle,
    Color primary,
    Color textColor,
    Color mutedColor,
  ) {
    final title = _value(block['title'] ?? block['label'] ?? fallbackTitle);
    final fields = _stringList(
      block['fields'] ?? block['lines'] ?? block['values'] ?? block['content'],
    );
    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: primary)),
        const SizedBox(height: 4),
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(field,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: textColor)),
          ),
      ],
    );
  }

  Widget _box(
    Map<String, dynamic> block,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final title = _value(block['title'] ?? block['label'] ?? '');
    final content = _value(block['content'] ?? block['text'] ?? block['note'] ?? '');
    if (title.isEmpty && content.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: borderColor, width: 0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title.toUpperCase(),
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: mutedColor)),
            const SizedBox(height: 4),
          ],
          if (content.isNotEmpty)
            Text(content, style: TextStyle(fontSize: 9, color: textColor)),
        ],
      ),
    );
  }

  Widget _textBlock(Map<String, dynamic> block, Color textColor) {
    final text = _value(block['content'] ?? block['text'] ?? '');
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      textAlign: _textAlign(block['align']),
      style: TextStyle(
        fontSize:
            _number(block['fontSize'], fallback: 9.5).clamp(7, 24).toDouble(),
        color: textColor,
        fontWeight:
            block['bold'] == true ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _footer(
    Map<String, dynamic> block,
    Color mutedColor,
    Color borderColor,
  ) {
    final note = _value(block['note'] ?? block['text'] ?? block['content'] ?? '');
    final branding = _asMap(block['branding']);
    final brandingText =
        _value(branding?['text'] ?? block['brandingText'] ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: borderColor, thickness: 0.7, height: 10),
        if (note.isNotEmpty)
          Text(note,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: mutedColor)),
        if (brandingText.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(brandingText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 7, color: mutedColor)),
        ],
      ],
    );
  }

  Widget _signature(
    Map<String, dynamic> block,
    Color mutedColor,
    Color borderColor,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 28),
          Container(width: 110, height: 0.8, color: borderColor),
          const SizedBox(height: 4),
          Text(_value(block['label'] ?? 'Authorised Signature'),
              style: TextStyle(fontSize: 8, color: mutedColor)),
        ],
      ),
    );
  }

  Widget? _container(
    Map<String, dynamic> block, {
    required Color primary,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final children = _childBlocks(block);
    if (children.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          _block(children[i],
              primary: primary,
              textColor: textColor,
              mutedColor: mutedColor,
              borderColor: borderColor),
          if (i != children.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _generic(
    Map<String, dynamic> block,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final lines = _collectText(block);
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: textColor)),
            ),
        ],
      ),
    );
  }

  Widget _fallback({
    required Color primary,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Company',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 3),
                  Text('Company address',
                      style: TextStyle(fontSize: 9, color: mutedColor)),
                ],
              ),
            ),
            Text('INVOICE',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primary)),
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: borderColor, thickness: 0.8, height: 8),
        const SizedBox(height: 12),
        _table({}, primary, textColor, mutedColor, borderColor),
        const SizedBox(height: 14),
        _summary({}, primary, textColor, mutedColor),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> _blocksOf(Map<String, dynamic>? document) {
    if (document == null) return const [];
    dynamic raw = document['layout'] ??
        document['blocks'] ??
        document['sections'] ??
        document['elements'] ??
        document['children'] ??
        document['body'] ??
        document['content'];
    if (raw is Map) {
      final map = _asMap(raw) ?? {};
      raw = map['layout'] ??
          map['blocks'] ??
          map['sections'] ??
          map['elements'] ??
          map['children'] ??
          map['body'] ??
          map['content'];
    }
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (_asMap(entry) != null) _asMap(entry)!,
    ];
  }

  static List<Map<String, dynamic>> _childBlocks(Map<String, dynamic> block) {
    for (final key in const [
      'children',
      'blocks',
      'sections',
      'elements',
      'layout',
      'content',
      'items',
    ]) {
      final raw = block[key];
      if (raw is List) {
        final maps = <Map<String, dynamic>>[];
        for (final entry in raw) {
          final map = _asMap(entry);
          if (map != null && (map.containsKey('type') || map.length > 1)) {
            maps.add(map);
          }
        }
        if (maps.isNotEmpty) return maps;
      }
      final nested = _asMap(raw);
      if (nested != null) {
        final child = _childBlocks(nested);
        if (child.isNotEmpty) return child;
      }
    }
    final left = _asMap(block['left']);
    final right = _asMap(block['right']);
    if (left != null || right != null) {
      return [
        if (left != null) left,
        if (right != null) right,
      ];
    }
    return const [];
  }

  static List<String> _collectText(
    Map<String, dynamic> block, [
    String? parentKey,
  ]) {
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
          key == 'highlight') {
        continue;
      }
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        result.add(_value(value));
      } else if (value is num) {
        result.add(value.toString());
      } else if (value is Map) {
        result.addAll(_collectText(_asMap(value) ?? {}, key));
      } else if (value is List) {
        for (final child in value) {
          final map = _asMap(child);
          if (map != null) {
            result.addAll(_collectText(map, key));
          } else if (child is String && child.trim().isNotEmpty) {
            result.add(_value(child));
          }
        }
      }
    }
    return result;
  }

  static List<String> _stringList(dynamic value) {
    final result = <String>[];
    if (value is String && value.trim().isNotEmpty) {
      result.add(_value(value));
    } else if (value is List) {
      for (final entry in value) {
        if (entry is String && entry.trim().isNotEmpty) {
          result.add(_value(entry));
        } else {
          final map = _asMap(entry);
          if (map == null) continue;
          final text = map['text'] ?? map['value'] ?? map['label'] ?? map['content'];
          if (text != null && text.toString().trim().isNotEmpty) {
            result.add(_value(text));
          }
        }
      }
    }
    return result;
  }

  static String? _inferType(Map<String, dynamic> block) {
    final keys = block.keys.map((key) => key.toLowerCase()).toSet();
    if (keys.contains('columns')) return 'table';
    if (keys.contains('rows')) return 'summary';
    if (keys.contains('branding') || keys.contains('note')) return 'footer';
    if (keys.contains('children') ||
        keys.contains('blocks') ||
        keys.contains('sections')) {
      return 'container';
    }
    if (keys.contains('left') || keys.contains('right')) {
      if (keys.contains('title')) return 'header';
      return 'twoColumn';
    }
    if (keys.contains('content') || keys.contains('text')) return 'text';
    if (keys.contains('height')) return 'spacer';
    return null;
  }

  /// Replaces placeholders with readable sample values so the sketch mirrors
  /// the live PDF instead of showing raw `{{...}}` tokens.
  static String _value(dynamic raw) {
    var text = raw?.toString() ?? '';
    const replacements = <String, String>{
      '{{company.name}}': 'Your Company',
      '{{company.address}}': 'Company address',
      '{{company.phone}}': '+00 00000 00000',
      '{{company.email}}': 'billing@company.com',
      '{{company.website}}': 'www.company.com',
      '{{company.gstin}}': 'GSTIN 000000000000000',
      '{{company.pan}}': 'PAN 000000000',
      '{{customer.name}}': 'Customer Name',
      '{{customer.businessname}}': 'Customer Business',
      '{{customer.business_name}}': 'Customer Business',
      '{{customer.address}}': 'Customer address',
      '{{customer.phone}}': '+00 00000 00000',
      '{{customer.email}}': 'customer@email.com',
      '{{customer.gstin}}': 'GSTIN 000000000000000',
      '{{invoice.title}}': 'INVOICE',
      '{{invoice.number}}': 'INV-0001',
      '{{invoice.no}}': 'INV-0001',
      '{{invoice.date}}': '01/01/2026',
      '{{invoice.duedate}}': '01/01/2026',
      '{{invoice.due_date}}': '01/01/2026',
      '{{invoice.status}}': 'Paid',
      '{{subtotal}}': '0.00',
      '{{tax}}': '0.00',
      '{{total}}': '0.00',
      '{{grandtotal}}': '0.00',
      '{{discount}}': '0.00',
      '{{amountpaid}}': '0.00',
      '{{balance}}': '0.00',
      '{{amountinwords}}': 'Zero only',
      '{{bank.name}}': 'Bank Name',
      '{{bank.account}}': '0000000000',
      '{{bank.ifsc}}': 'IFSC0000000',
      '{{bank.upi}}': 'company@upi',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAll(RegExp(r'\{\{\s*([^}]+?)\s*\}\}'), '');
    return text.trim();
  }

  static TextAlign _textAlign(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  static num _number(dynamic value, {required num fallback}) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static Color? _color(dynamic value) {
    if (value is! String) return null;
    final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
    if (match == null) return null;
    return Color(int.parse('FF${match.group(1)!}', radix: 16));
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
