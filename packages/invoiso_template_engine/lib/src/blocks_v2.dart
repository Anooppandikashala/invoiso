part of 'block_layout_renderer.dart';

/// Engine v2 building blocks — used only by documents with `"engine": 2`, so
/// v1 layouts keep their exact output. Other block types (header, table,
/// summary, signature, …) fall through to the v1 builders.
extension _BlocksV2 on _BlockLayoutRenderer {
  static const types = {
    'box', 'row', 'column', 'text', 'divider', 'pagenumber', 'if', 'repeat', 'qr',
    'grid',
  };

  pw.Widget? buildV2(String type, Map<String, dynamic> block) {
    switch (type) {
      case 'box':
        return _boxV2(block);
      case 'row':
        return _rowV2(block);
      case 'column':
        return _columnV2(block);
      case 'divider':
        return pw.Divider(
          color: _BlockLayoutRenderer._color(block['color'], fallback: borderColor),
          thickness: _BlockLayoutRenderer._double(block['thickness'], fallback: 0.8),
          height: _BlockLayoutRenderer._double(block['height'], fallback: 8),
        );
      case 'if':
        return buildBlock(_BlockLayoutRenderer._asMap(
            _truthy(block['when']) ? block['then'] : block['else']));
      case 'repeat':
        return _repeatV2(block);
      case 'qr':
        return _qrV2(block);
      case 'grid':
        return _gridV2(block);
      default: // text, pageNumber
        return _textV2(block);
    }
  }

  /// Text with `style` (named, from document `styles`) + inline overrides:
  /// size, bold, italic, color, align, uppercase, letterSpacing, maxLines.
  pw.Widget? _textV2(Map<String, dynamic> block) {
    final s = {
      ..._BlockLayoutRenderer._asMap(_styles[block['style']?.toString()]),
      ...block,
    };
    var text = _resolveLine(
        (s['value'] ?? s['content'] ?? s['text'] ?? '').toString());
    if (text.isEmpty) return null;
    if (s['uppercase'] == true) text = text.toUpperCase();
    final style = pw.TextStyle(
      fontSize: _fs(
          _BlockLayoutRenderer._double(s['size'] ?? s['fontSize'],
              fallback: 9.5),
          s['role']?.toString()),
      color: _BlockLayoutRenderer._color(s['color'], fallback: textColor),
      fontWeight: s['bold'] == true ? pw.FontWeight.bold : null,
      fontStyle: s['italic'] == true ? pw.FontStyle.italic : null,
      letterSpacing: _BlockLayoutRenderer._doubleOrNull(s['letterSpacing']),
    );
    // `**bold**` parts, e.g. "**Vehicle No:** KL-10" (label bold, value plain).
    if (text.contains('**')) {
      final parts = text.split('**');
      return pw.SizedBox(
        width: double.infinity,
        child: pw.RichText(
          textAlign: _BlockLayoutRenderer._textAlign(s['align']),
          maxLines: _BlockLayoutRenderer._doubleOrNull(s['maxLines'])?.toInt(),
          text: pw.TextSpan(style: style, children: [
            for (var i = 0; i < parts.length; i++)
              if (parts[i].isNotEmpty)
                pw.TextSpan(
                    text: parts[i],
                    style: i.isOdd
                        ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        : null),
          ]),
        ),
      );
    }
    return pw.SizedBox(
      width: double.infinity,
      child: pw.Text(
        text,
        textAlign: _BlockLayoutRenderer._textAlign(s['align']),
        maxLines: _BlockLayoutRenderer._doubleOrNull(s['maxLines'])?.toInt(),
        style: style,
      ),
    );
  }

  /// Container: border, background, padding, margin, radius, width, height,
  /// align, and `child` (or `children`, stacked).
  pw.Widget _boxV2(Map<String, dynamic> block) {
    final border = _border(block['border'], block['borderColor']);
    final radius = _BlockLayoutRenderer._doubleOrNull(block['radius']);
    return pw.Container(
      // A "30%" width belongs to the row cell, so only points size the box.
      width: _BlockLayoutRenderer._doubleOrNull(block['width']),
      height: _BlockLayoutRenderer._doubleOrNull(block['height']),
      margin: _insets(block['margin']),
      padding: _insets(block['padding']),
      alignment: block['align'] == null
          ? null
          : _BlockLayoutRenderer._alignment(block['align']),
      decoration: pw.BoxDecoration(
        color: block['background'] == null
            ? null
            : _BlockLayoutRenderer._color(block['background'],
                fallback: PdfColors.white),
        border: border,
        // pdf only supports rounded corners on uniform borders.
        borderRadius: radius == null || (border != null && !border.isUniform)
            ? null
            : pw.BorderRadius.all(pw.Radius.circular(radius)),
      ),
      child: _childrenV2(block, gap: block['gap']),
    );
  }

  /// Children side by side. Widths per child: `width` (points or "30%") or
  /// `flex`. With `border`, renders as a one-row table so every cell has the
  /// same height and cells share their border lines.
  pw.Widget? _rowV2(Map<String, dynamic> block) {
    final children = _childBlocks(block);
    if (children.isEmpty) return null;
    final widths = _widths(children);
    final cells = [for (final c in children) buildBlock(c) ?? pw.SizedBox()];
    final border = _BlockLayoutRenderer._doubleOrNull(block['border']);
    if (border != null && border > 0) {
      final color = _BlockLayoutRenderer._color(block['borderColor'],
          fallback: borderColor);
      return pw.Table(
        border: pw.TableBorder.all(width: border, color: color),
        columnWidths: {
          for (var i = 0; i < widths.length; i++)
            i: widths[i].fixed != null
                ? pw.FixedColumnWidth(widths[i].fixed!)
                : pw.FlexColumnWidth(widths[i].flex),
        },
        children: [
          pw.TableRow(
            verticalAlignment: _verticalAlign(block['align']),
            children: cells,
          ),
        ],
      );
    }
    final gap = _BlockLayoutRenderer._double(block['gap'], fallback: 0);
    return pw.Row(
      crossAxisAlignment: _crossAlign(block['align']),
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0 && gap > 0) pw.SizedBox(width: gap),
          widths[i].fixed != null
              ? pw.SizedBox(width: widths[i].fixed, child: cells[i])
              : pw.Expanded(
                  flex: (widths[i].flex * 100).round().clamp(1, 1 << 20),
                  child: cells[i]),
        ],
      ],
    );
  }

  /// Children stacked; `gap` between them, `align` left/center/right.
  pw.Widget? _columnV2(Map<String, dynamic> block) =>
      _childrenV2(block, gap: block['gap'], align: block['align']);

  pw.Widget? _childrenV2(Map<String, dynamic> block,
      {dynamic gap, dynamic align}) {
    final single = _BlockLayoutRenderer._asMap(block['child']);
    final children = single.isNotEmpty ? [single] : _childBlocks(block);
    final space = _BlockLayoutRenderer._double(gap, fallback: 0);
    final widgets = <pw.Widget>[];
    for (final child in children) {
      final widget = buildBlock(child);
      if (widget == null) continue;
      if (widgets.isNotEmpty && space > 0) widgets.add(pw.SizedBox(height: space));
      widgets.add(widget);
    }
    if (widgets.isEmpty) return null;
    if (widgets.length == 1) return widgets.first;
    return pw.Column(
      crossAxisAlignment: switch (align?.toString().toLowerCase()) {
        'center' => pw.CrossAxisAlignment.center,
        'right' => pw.CrossAxisAlignment.end,
        _ => pw.CrossAxisAlignment.start,
      },
      children: widgets,
    );
  }

  /// `width` "30%" / points, or `flex`. When some children use %, the others
  /// share what is left of 100 %.
  List<({double flex, double? fixed})> _widths(
      List<Map<String, dynamic>> children) {
    double? percentOf(dynamic w) => w is String && w.trim().endsWith('%')
        ? double.tryParse(w.trim().replaceAll('%', ''))
        : null;
    final percents = [for (final c in children) percentOf(c['width'])];
    final used = percents.whereType<double>().fold<double>(0, (a, b) => a + b);
    final usesPercent = percents.any((p) => p != null);
    final open = [
      for (var i = 0; i < children.length; i++)
        if (percents[i] == null && children[i]['width'] is! num) i
    ].length;
    final share = open == 0 ? 1.0 : ((100 - used) / open).clamp(1.0, 100.0);
    return [
      for (var i = 0; i < children.length; i++)
        children[i]['width'] is num
            ? (flex: 1.0, fixed: (children[i]['width'] as num).toDouble())
            : (
                flex: percents[i] ??
                    (usesPercent
                        ? share
                        : _BlockLayoutRenderer._double(children[i]['flex'],
                            fallback: 1)),
                fixed: null,
              ),
    ];
  }

  /// `0.8` → all sides; `{width, color, top, right, bottom, left}` where a
  /// side is true/false or its own width.
  pw.Border? _border(dynamic value, dynamic colorValue) {
    if (value == null || value == false) return null;
    final map = _BlockLayoutRenderer._asMap(value);
    final color = _BlockLayoutRenderer._color(map['color'] ?? colorValue,
        fallback: borderColor);
    final width = value is num
        ? value.toDouble()
        : _BlockLayoutRenderer._double(map['width'], fallback: 0.8);
    final hasSides = ['top', 'right', 'bottom', 'left'].any(map.containsKey);
    pw.BorderSide side(String name) {
      if (!hasSides) return pw.BorderSide(width: width, color: color);
      final v = map[name];
      if (v == null || v == false) return pw.BorderSide.none;
      return pw.BorderSide(
          width: v is num ? v.toDouble() : width, color: color);
    }
    return pw.Border(
        top: side('top'),
        right: side('right'),
        bottom: side('bottom'),
        left: side('left'));
  }

  /// `6` → all; `[v, h]` or `[t, r, b, l]`; `{top, right, bottom, left,
  /// horizontal, vertical}`.
  pw.EdgeInsets? _insets(dynamic value) {
    if (value == null) return null;
    double d(dynamic v) => _BlockLayoutRenderer._double(v, fallback: 0);
    if (value is num) return pw.EdgeInsets.all(value.toDouble());
    if (value is List) {
      if (value.length == 2) {
        return pw.EdgeInsets.symmetric(vertical: d(value[0]), horizontal: d(value[1]));
      }
      if (value.length == 4) {
        return pw.EdgeInsets.fromLTRB(d(value[3]), d(value[0]), d(value[1]), d(value[2]));
      }
      return null;
    }
    final m = _BlockLayoutRenderer._asMap(value);
    return pw.EdgeInsets.fromLTRB(
      d(m['left'] ?? m['horizontal']),
      d(m['top'] ?? m['vertical']),
      d(m['right'] ?? m['horizontal']),
      d(m['bottom'] ?? m['vertical']),
    );
  }

  pw.CrossAxisAlignment _crossAlign(dynamic value) =>
      switch (value?.toString().toLowerCase()) {
        'center' => pw.CrossAxisAlignment.center,
        'bottom' => pw.CrossAxisAlignment.end,
        _ => pw.CrossAxisAlignment.start,
      };

  pw.TableCellVerticalAlignment _verticalAlign(dynamic value) =>
      switch (value?.toString().toLowerCase()) {
        'center' => pw.TableCellVerticalAlignment.middle,
        'bottom' => pw.TableCellVerticalAlignment.bottom,
        'fill' || 'stretch' => pw.TableCellVerticalAlignment.full,
        _ => pw.TableCellVerticalAlignment.top,
      };

  /// Blocks of `pageHeader` / `pageFooter`, built per page so `{{page}}` and
  /// `{{pages}}` resolve.
  pw.Widget? pageSection(String key, pw.Context context) {
    final raw = document[key];
    if (raw is! List || raw.isEmpty) return null;
    _pageContext = context;
    try {
      return _childrenV2({'children': raw});
    } finally {
      _pageContext = null;
    }
  }

  /// One child block per list item (`source`: data path), `{{row.*}}` = item.
  pw.Widget? _repeatV2(Map<String, dynamic> block) {
    final list = _rawLookup((block['source'] ?? 'items').toString().toLowerCase());
    if (list is! List || list.isEmpty) return null;
    final child = _BlockLayoutRenderer._asMap(block['child']);
    final gap = _BlockLayoutRenderer._double(block['gap'], fallback: 0);
    final saved = _row;
    final widgets = <pw.Widget>[];
    try {
      for (final item in list) {
        _row = _rowOf(item);
        final widget = buildBlock(child);
        if (widget == null) continue;
        if (widgets.isNotEmpty && gap > 0) widgets.add(pw.SizedBox(height: gap));
        widgets.add(widget);
      }
    } finally {
      _row = saved;
    }
    if (widgets.isEmpty) return null;
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  /// Payment QR. `source`: "upi" (UPI link from data `payment.upiPayload`),
  /// "image" (uploaded payment QR asset) or "auto" (image if set, else UPI).
  /// Optional `title` / `caption` text, `size` in points.
  pw.Widget? _qrV2(Map<String, dynamic> block) {
    final source = (block['source'] ?? 'auto').toString().toLowerCase();
    final size = _BlockLayoutRenderer._double(block['size'], fallback: 90);
    final payload = _BlockLayoutRenderer._s(_BlockLayoutRenderer._asMap(data['payment']), 'upiPayload');
    pw.Widget? code;
    if (source != 'upi' && assets.paymentQr != null) {
      code = pw.Image(pw.MemoryImage(assets.paymentQr!),
          width: size, height: size, fit: pw.BoxFit.contain);
    } else if (source != 'image' && payload.isNotEmpty) {
      // drawText off: a QR has no caption text, and the default would pull
      // in the built-in Courier font (no Unicode, debug warning).
      code = pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(), data: payload, width: size, height: size, drawText: false);
    }
    if (code == null) return null;
    final title = _resolveLine((block['title'] ?? '').toString());
    final caption = _resolveLine((block['caption'] ?? '').toString());
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: _fs(10), fontWeight: pw.FontWeight.bold, color: textColor)),
          ),
        code,
        if (caption.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(caption,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: _fs(7.5), color: mutedColor)),
          ),
      ],
    );
  }

  /// Table over any data list. Columns: `label`, `width`, `align`, `if`, and
  /// cell content as `value` (template, `{{row.x|money}}`), `cell` (several
  /// text lines with their own style) or v1 `key` (items only). Options:
  /// `source`, `border` grid|horizontal|outer|none, `borderWidth`,
  /// `borderColor`, `header` {background, color, bold, size} or false,
  /// `size`, `cellPadding`, `zebra` colour, `footerRows` [{cells: {columnId:
  /// text|{value, bold, italic, align}}, bold, italic, background, if,
  /// repeat: data list path → one row per entry, `{{row.x}}` like body rows
  /// (e.g. charges)}],
  /// `repeatHeader` (true / false; omitted → the user's "repeat table header"
  /// setting), `detailRow` {value, if, style…}: a full-width line under each
  /// row (e.g. description on its own line) when its `if` holds,
  /// `headerGroups` [{label, columns: [column ids]}]: a label over adjacent
  /// columns (e.g. CGST over Rate | Amount; hidden columns drop out; a group
  /// whose columns aren't adjacent or mix fixed and % widths is ignored),
  /// `minRows`: blank rows after the data up to N rows (printed-stationery look).
  /// Returned as separate widgets so a top-level table splits across pages.
  List<pw.Widget> tableV2Parts(Map<String, dynamic> block) {
    final columns = <Map<String, dynamic>>[];
    for (final c in (block['columns'] is List ? block['columns'] as List : const [])) {
      final column = _BlockLayoutRenderer._asMap(c);
      if (!_truthy(column['if'])) continue;
      // `each`: one column per entry of a list (e.g. the enabled product
      // metadata columns) — label = entry.label, value = row.meta.<key>.
      final each = column['each'];
      if (each != null) {
        final entries = _rawLookup(each.toString().toLowerCase());
        for (final raw in (entries is List ? entries : const [])) {
          final entry = _BlockLayoutRenderer._asMap(raw);
          final key = entry['key']?.toString() ?? '';
          columns.add({
            ...column,
            'label': entry['label'] ?? key,
            'value': '{{row.meta.$key}}',
            'width': column['width'] ??
                '${(_BlockLayoutRenderer._double(entry['width'], fallback: 1.4) * 5).toStringAsFixed(1)}%',
          }..remove('each'));
        }
        continue;
      }
      columns.add(column);
    }
    if (columns.isEmpty) return _tableParts(block); // no columns → v1 default
    final sourcePath = (block['source'] ?? 'items').toString().toLowerCase();
    final list = _rawLookup(sourcePath);
    final rows = list is List ? list : const [];
    final size = _BlockLayoutRenderer._double(block['size'], fallback: 9);
    final padding = _insets(block['cellPadding']) ??
        const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4);
    final lineColor =
        _BlockLayoutRenderer._color(block['borderColor'], fallback: borderColor);
    final lineWidth = _BlockLayoutRenderer._double(block['borderWidth'], fallback: 0.6);
    final side = pw.BorderSide(color: lineColor, width: lineWidth);
    final tableBorder = switch ((block['border'] ?? 'horizontal').toString()) {
      'grid' => pw.TableBorder.all(color: lineColor, width: lineWidth),
      'outer' => pw.TableBorder(top: side, bottom: side, left: side, right: side),
      'none' => null,
      _ => pw.TableBorder(top: side, bottom: side, horizontalInside: side),
    };
    final header = block['header'] == false
        ? null
        : _BlockLayoutRenderer._asMap(block['header']);
    final zebra = block['zebra'] is String
        ? _BlockLayoutRenderer._color(block['zebra'], fallback: PdfColors.white)
        : null;

    String columnId(int i) =>
        (columns[i]['id'] ?? columns[i]['key'] ?? '$i').toString();

    pw.Widget cellText(String text, Map<String, dynamic> style, dynamic align,
        {required String role, bool bold = false, bool italic = false, PdfColor? color}) {
      return pw.Text(
        text,
        textAlign: _BlockLayoutRenderer._textAlign(style['align'] ?? align),
        style: pw.TextStyle(
          fontSize: _fs(_BlockLayoutRenderer._double(style['size'], fallback: size), role),
          color: _BlockLayoutRenderer._color(style['color'], fallback: color ?? textColor),
          fontWeight: (style['bold'] ?? bold) == true ? pw.FontWeight.bold : null,
          fontStyle: (style['italic'] ?? italic) == true ? pw.FontStyle.italic : null,
        ),
      );
    }

    pw.Widget bodyCell(Map<String, dynamic> column, int index) {
      final lines = <pw.Widget>[];
      if (column['cell'] is List) {
        for (final raw in column['cell'] as List) {
          final spec = raw is String ? {'value': raw} : _BlockLayoutRenderer._asMap(raw);
          if (!_truthy(spec['if'])) continue;
          final text = _resolveLine((spec['value'] ?? '').toString());
          if (text.isNotEmpty) {
            lines.add(cellText(text, spec, column['align'], role: 'tableItems'));
          }
        }
      } else {
        final text = column['value'] != null
            ? _resolve(column['value'].toString())
            : _itemCell(column['key']?.toString() ?? '', _row ?? const {}, index);
        lines.add(cellText(text, column, column['align'], role: 'tableItems'));
      }
      return pw.Padding(
        padding: padding,
        child: pw.Column(
          crossAxisAlignment: switch (column['align']?.toString()) {
            'right' => pw.CrossAxisAlignment.end,
            'center' => pw.CrossAxisAlignment.center,
            _ => pw.CrossAxisAlignment.start,
          },
          children: lines,
        ),
      );
    }

    // Header on every page: the template's `repeatHeader` if set, else the
    // user's setting.
    final repeatHeader = block['repeatHeader'] is bool
        ? block['repeatHeader'] as bool
        : options.repeatTableHeader;
    pw.TableRow? headerRow;
    pw.BoxDecoration? headerDecoration;
    pw.Widget headerText(String text, dynamic align) => cellText(text, header!, align,
        role: 'tableHeader',
        bold: header['bold'] != false,
        color: _BlockLayoutRenderer._color(header['color'], fallback: PdfColors.white));
    final headerCells = [
      if (header != null)
        for (final column in columns)
          pw.Padding(
            padding: padding,
            child: headerText(_resolve((column['label'] ?? '').toString()), column['align']),
          ),
    ];
    if (header != null) {
      headerDecoration = pw.BoxDecoration(
          color: _BlockLayoutRenderer._color(header['background'], fallback: primary));
      headerRow = pw.TableRow(
        repeat: repeatHeader,
        decoration: headerDecoration,
        children: headerCells,
      );
    }
    // `detailRow`: a full-width line under each item (e.g. the description
    // when "description on new line" is on), when its `if` holds.
    final detail = _BlockLayoutRenderer._asMap(block['detailRow']);
    final detailOn = detail.isNotEmpty && _truthy(detail['if']);
    // Items table: rows carry the table watermark slice (built-in behaviour).
    final itemsTable = sourcePath == 'items';
    final bodyRows = <({pw.TableRow row, String detail, PdfColor? color})>[];
    final saved = _row;
    try {
      for (var i = 0; i < rows.length; i++) {
        _row = _rowOf(rows[i]);
        final color = zebra != null && i.isOdd ? zebra : null;
        bodyRows.add((
          row: pw.TableRow(
            decoration: itemsTable
                ? _itemRowDecoration(color)
                : color != null ? pw.BoxDecoration(color: color) : null,
            children: [for (final c in columns) bodyCell(c, i)],
          ),
          detail: detailOn ? _resolveLine((detail['value'] ?? '').toString()) : '',
          color: color,
        ));
      }
    } finally {
      _row = saved;
    }
    final minRows = _BlockLayoutRenderer._double(block['minRows'], fallback: 0).toInt();
    for (var i = rows.length; i < minRows; i++) {
      final color = zebra != null && i.isOdd ? zebra : null;
      bodyRows.add((
        row: pw.TableRow(
          decoration: itemsTable
              ? _itemRowDecoration(color)
              : color != null ? pw.BoxDecoration(color: color) : null,
          children: [
            for (final c in columns)
              // One text line high (blank text has no height).
              pw.Padding(
                  padding: padding,
                  child: pw.SizedBox(
                      height: _fs(_BlockLayoutRenderer._double(c['size'], fallback: size), 'tableItems') * 1.2)),
          ],
        ),
        detail: '',
        color: color,
      ));
    }
    final footerRows = <pw.TableRow>[];
    final savedFooterRow = _row;
    for (final raw in (block['footerRows'] is List ? block['footerRows'] as List : const [])) {
      final footer = _BlockLayoutRenderer._asMap(raw);
      if (!_truthy(footer['if'])) continue;
      final cells = _BlockLayoutRenderer._asMap(footer['cells']);
      // `repeat`: one row per entry of a data list; otherwise a single row.
      final repeat = footer['repeat'];
      final repeated = repeat is String ? _rawLookup(repeat.toLowerCase()) : null;
      final entries = repeat is String ? (repeated is List ? repeated : const []) : const [null];
      for (final entry in entries) {
        if (repeat is String) _row = _rowOf(entry);
        footerRows.add(pw.TableRow(
          decoration: footer['background'] == null
              ? null
              : pw.BoxDecoration(
                  color: _BlockLayoutRenderer._color(footer['background'],
                      fallback: PdfColors.white)),
          children: [
            for (var i = 0; i < columns.length; i++)
              () {
                final cell = cells[columnId(i)] is Map
                    ? _BlockLayoutRenderer._asMap(cells[columnId(i)])
                    : {'value': cells[columnId(i)] ?? ''};
                final spec = _truthy(cell['if']) ? cell : {'value': ''};
                return pw.Padding(
                  padding: padding,
                  child: cellText(_resolve(spec['value'].toString()), spec,
                      columns[i]['align'],
                      role: 'totals',
                      bold: footer['bold'] == true, italic: footer['italic'] == true),
                );
              }(),
          ],
        ));
      }
    }
    _row = savedFooterRow;

    final columnWidths = {
      for (var i = 0; i < columns.length; i++)
        i: _BlockLayoutRenderer._columnWidth(columns[i]['width']),
    };
    final title = _resolve((block['title'] ?? '').toString());
    final titleWidgets = [
      if (title.isNotEmpty) ...[
        pw.Text(title,
            style: pw.TextStyle(fontSize: _fs(11), fontWeight: pw.FontWeight.bold, color: textColor)),
        pw.SizedBox(height: 6),
      ],
    ];
    // With full-width detail lines a single table can't be used (no
    // column spanning), so — like the built-in templates — each item is its
    // own one-row table followed by its detail line. These sit as rows of an
    // outer one-column table so the header can still repeat on every page.
    final style = (block['border'] ?? 'horizontal').toString();
    final grid = style == 'grid' || style == 'outer';
    final none = style == 'none';
    pw.Widget segment(List<pw.TableRow> segRows,
            {bool top = false, bool bottom = true, Map<int, pw.TableColumnWidth>? widths, bool middle = false}) =>
        pw.Table(
          columnWidths: widths ?? columnWidths,
          defaultVerticalAlignment:
              middle ? pw.TableCellVerticalAlignment.middle : pw.TableCellVerticalAlignment.top,
          border: none
              ? null
              : pw.TableBorder(
                  top: top ? side : pw.BorderSide.none,
                  bottom: bottom ? side : pw.BorderSide.none,
                  left: grid ? side : pw.BorderSide.none,
                  right: grid ? side : pw.BorderSide.none,
                  verticalInside: style == 'grid' ? side : pw.BorderSide.none,
                  horizontalInside: style == 'outer' ? pw.BorderSide.none : side,
                ),
          children: segRows,
        );

    // Grouped header: one row; a group's cell = its label over a small table
    // of its columns' labels, other labels centred over the full height.
    pw.Widget? groupedHeader;
    final groupSpecs = block['headerGroups'] is List ? block['headerGroups'] as List : const [];
    if (headerRow != null && groupSpecs.isNotEmpty) {
      final groupOf = <int, ({String label, List<int> cols})>{};
      for (final raw in groupSpecs) {
        final g = _BlockLayoutRenderer._asMap(raw);
        final ids = [for (final id in (g['columns'] is List ? g['columns'] as List : const [])) id.toString()];
        final cols = [for (var i = 0; i < columns.length; i++) if (ids.contains(columnId(i))) i];
        if (cols.isEmpty || cols.last - cols.first != cols.length - 1 || cols.any(groupOf.containsKey)) continue;
        final group = (label: _resolve((g['label'] ?? '').toString()), cols: cols);
        for (final i in cols) {
          groupOf[i] = group;
        }
      }
      pw.TableColumnWidth? merged(List<int> cols) {
        final ws = [for (final i in cols) columnWidths[i]!];
        if (ws.every((w) => w is pw.FlexColumnWidth)) {
          return pw.FlexColumnWidth(ws.fold(0.0, (t, w) => t + (w as pw.FlexColumnWidth).flex));
        }
        if (ws.every((w) => w is pw.FixedColumnWidth)) {
          return pw.FixedColumnWidth(ws.fold(0.0, (t, w) => t + (w as pw.FixedColumnWidth).width));
        }
        return null;
      }
      final cells = <pw.Widget>[];
      final widths = <int, pw.TableColumnWidth>{};
      for (var i = 0; i < columns.length; i++) {
        final g = groupOf[i];
        if (g != null && g.cols.first != i) continue;
        final w = merged(g?.cols ?? [i]) ?? (g == null ? columnWidths[i]! : null);
        if (w == null) {
          // Mixed widths in a group: print its columns ungrouped.
          for (final c in g!.cols) {
            widths[widths.length] = columnWidths[c]!;
            cells.add(headerCells[c]);
          }
          continue;
        }
        widths[widths.length] = w;
        cells.add(g == null
            ? headerCells[i]
            : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
                pw.Padding(padding: padding, child: headerText(g.label, 'center')),
                pw.Table(
                  columnWidths: {for (var k = 0; k < g.cols.length; k++) k: columnWidths[g.cols[k]]!},
                  border: none
                      ? null
                      : pw.TableBorder(
                          top: side,
                          verticalInside: style == 'grid' ? side : pw.BorderSide.none),
                  children: [pw.TableRow(children: [for (final c in g.cols) headerCells[c]])],
                ),
              ]));
      }
      groupedHeader = segment(
          [pw.TableRow(decoration: headerDecoration, children: cells)],
          top: true, widths: widths, middle: true);
    }

    if (groupedHeader == null && !bodyRows.any((r) => r.detail.isNotEmpty)) {
      return [
        ...titleWidgets,
        pw.Table(
          border: tableBorder,
          columnWidths: columnWidths,
          children: [
            if (headerRow != null) headerRow,
            for (final r in bodyRows) r.row,
            ...footerRows,
          ],
        ),
      ];
    }

    return [
      ...titleWidgets,
      pw.Table(
        columnWidths: const {0: pw.FlexColumnWidth()},
        children: [
          if (headerRow != null)
            pw.TableRow(
                repeat: repeatHeader,
                children: [groupedHeader ?? segment([headerRow], top: true)]),
          for (final r in bodyRows)
            pw.TableRow(children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
        // Line under the item only when it has no detail line of its own.
        segment([r.row], top: headerRow == null && r == bodyRows.first,
            bottom: r.detail.isEmpty),
        if (r.detail.isNotEmpty)
          pw.Container(
            width: double.infinity,
            padding: padding,
            decoration: () {
              final border = none
                  ? null
                  : pw.Border(
                      bottom: side,
                      left: grid ? side : pw.BorderSide.none,
                      right: grid ? side : pw.BorderSide.none,
                    );
              return itemsTable
                  ? _itemRowDecoration(r.color, border: border)
                  : pw.BoxDecoration(color: r.color, border: border);
            }(),
            child: cellText(r.detail, detail, 'left', role: 'tableItems'),
          ),
                ],
              ),
            ]),
          if (footerRows.isNotEmpty)
            pw.TableRow(children: [segment(footerRows)]),
        ],
      ),
    ];
  }

  /// A list item as a row: maps as-is, plain values as `{{row.value}}`.
  Map<String, dynamic> _rowOf(dynamic item) =>
      item is Map ? _BlockLayoutRenderer._asMap(item) : {'value': item};

  /// A list as cells, `columns` per row (default 2), each cell built from
  /// `cell` with `{{row.*}}` = the item. `border`: inner lines width
  /// (`outerBorder: true` adds the outside). A short last row is filled
  /// with blank cells so grid lines stay continuous, or — with
  /// `spanLast: true` — its cells span the full width.
  pw.Widget? _gridV2(Map<String, dynamic> block) {
    final list = _rawLookup((block['source'] ?? '').toString().toLowerCase());
    if (list is! List || list.isEmpty) return null;
    final perRow = _BlockLayoutRenderer._double(block['columns'], fallback: 2)
        .round()
        .clamp(1, 12);
    final cellBlock = _BlockLayoutRenderer._asMap(block['cell']);
    final cells = <pw.Widget>[];
    final saved = _row;
    try {
      for (final item in list) {
        _row = _rowOf(item);
        cells.add(buildBlock(cellBlock) ?? pw.SizedBox());
      }
    } finally {
      _row = saved;
    }
    final width = _BlockLayoutRenderer._double(block['border'], fallback: 0);
    final color =
        _BlockLayoutRenderer._color(block['borderColor'], fallback: borderColor);
    final side = pw.BorderSide(width: width, color: color);
    final leftover = cells.length % perRow;
    final spanned = block['spanLast'] == true && leftover != 0
        ? cells.sublist(cells.length - leftover)
        : const <pw.Widget>[];
    if (spanned.isNotEmpty) cells.removeRange(cells.length - leftover, cells.length);
    while (cells.length % perRow != 0) {
      cells.add(pw.SizedBox());
    }
    final table = cells.isEmpty
        ? null
        : pw.Table(
      border: width <= 0
          ? null
          : block['outerBorder'] == true
              ? pw.TableBorder.all(width: width, color: color)
              : pw.TableBorder(verticalInside: side, horizontalInside: side),
      columnWidths: {
        for (var i = 0; i < perRow; i++) i: const pw.FlexColumnWidth(1),
      },
      children: [
        for (var r = 0; r < cells.length; r += perRow)
          pw.TableRow(children: cells.sublist(r, r + perRow)),
      ],
    );
    if (spanned.isEmpty) return table;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (table != null) table,
        for (final cell in spanned)
          pw.Container(
            decoration: table == null || width <= 0
                ? null
                : pw.BoxDecoration(border: pw.Border(top: side)),
            child: cell,
          ),
      ],
    );
  }
}
