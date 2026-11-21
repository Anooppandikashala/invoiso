part of 'block_layout_renderer.dart';

/// Engine v2 building blocks — used only by documents with `"engine": 2`, so
/// v1 layouts keep their exact output. Other block types (header, table,
/// summary, signature, …) fall through to the v1 builders.
extension _BlocksV2 on _BlockLayoutRenderer {
  static const types = {'box', 'row', 'column', 'text', 'divider', 'pagenumber'};

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
    return pw.SizedBox(
      width: double.infinity,
      child: pw.Text(
        text,
        textAlign: _BlockLayoutRenderer._textAlign(s['align']),
        maxLines: _BlockLayoutRenderer._doubleOrNull(s['maxLines'])?.toInt(),
        style: pw.TextStyle(
          fontSize: _BlockLayoutRenderer._double(s['size'] ?? s['fontSize'],
              fallback: 9.5),
          color: _BlockLayoutRenderer._color(s['color'], fallback: textColor),
          fontWeight: s['bold'] == true ? pw.FontWeight.bold : null,
          fontStyle: s['italic'] == true ? pw.FontStyle.italic : null,
          letterSpacing: _BlockLayoutRenderer._doubleOrNull(s['letterSpacing']),
        ),
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
}
