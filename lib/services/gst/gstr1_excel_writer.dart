import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/models/gstr1_report.dart';

/// Writes a [Gstr1Report] as an .xlsx in the GST Offline Tool's GSTR-1 Excel
/// template v2.1 layout (Gstr1ExportPlan.md Part D): same sheet names, row 1
/// title, rows 2–3 summary, row 4 headers, data from row 5. Hand-written
/// SpreadsheetML (inline strings) — no extra dependency.
class Gstr1ExcelWriter {
  const Gstr1ExcelWriter._();

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec'];

  /// Template date format dd-MMM-yyyy, English month whatever the app language.
  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${_months[d.month - 1]}-${d.year}';

  /// Table 8 descriptions, in [Gstr1Report.exemp] order.
  static String exempDescription(Gstr1ExempRow e) =>
      '${e.interState ? 'Inter' : 'Intra'}-State supplies to '
      '${e.registered ? 'registered' : 'unregistered'} persons';

  static Uint8List build(Gstr1Report r, {bool includeRegister = false}) {
    String pos(String code) => GstUtils.stateLabel(code);
    String rc(bool v) => v ? 'Y' : 'N';
    double sum<T>(Iterable<T> rows, double Function(T) f) =>
        rows.fold(0.0, (a, x) => a + f(x));
    int distinct<T>(Iterable<T> rows, Object? Function(T) f) =>
        rows.map(f).toSet().length;
    // Document value counts once per document, not per rate line.
    double docValue(List<Gstr1DocRow> rows) => sum(
        {for (final x in rows) x.invoiceId: x}.values, (Gstr1DocRow x) => x.value);

    final hsnHeader = [
      'HSN', 'Description', 'UQC', 'Total Quantity', 'Total Value', 'Rate',
      'Taxable Value', 'Integrated Tax Amount', 'Central Tax Amount',
      'State/UT Tax Amount', 'Cess Amount',
    ];
    _Sheet hsn(String name, List<Gstr1HsnRow> rows) => _Sheet(
          name,
          'Summary For HSN(12)',
          {
            0: ('No. of HSN', distinct(rows, (Gstr1HsnRow x) => x.hsn)),
            4: ('Total Value', sum(rows, (Gstr1HsnRow x) => x.totalValue)),
            6: ('Total Taxable Value', sum(rows, (Gstr1HsnRow x) => x.taxable)),
            7: ('Total Integrated Tax', sum(rows, (Gstr1HsnRow x) => x.igst)),
            8: ('Total Central Tax', sum(rows, (Gstr1HsnRow x) => x.cgst)),
            9: ('Total State/UT Tax', sum(rows, (Gstr1HsnRow x) => x.sgst)),
            10: ('Total Cess', 0),
          },
          hsnHeader,
          [
            for (final x in rows)
              [
                x.hsn, x.description,
                x.uqc == 'NA' ? 'NA' : GstUtils.uqcLabel(x.uqc),
                x.quantity, x.totalValue, x.rate, x.taxable, x.igst, x.cgst,
                x.sgst, 0,
              ],
          ],
        );

    final sheets = <_Sheet>[
      _Sheet(
        'b2b,sez,de',
        'Summary For B2B, SEZ, DE (4A, 4B, 6B, 6C)',
        {
          0: ('No. of Recipients', distinct(r.b2b, (Gstr1DocRow x) => x.gstin)),
          2: ('No. of Invoices', distinct(r.b2b, (Gstr1DocRow x) => x.invoiceId)),
          4: ('Total Invoice Value', docValue(r.b2b)),
          11: ('Total Taxable Value', sum(r.b2b, (Gstr1DocRow x) => x.taxable)),
          12: ('Total Cess', 0),
        },
        [
          'GSTIN/UIN of Recipient', 'Receiver Name', 'Invoice Number',
          'Invoice date', 'Invoice Value', 'Place Of Supply', 'Reverse Charge',
          'Applicable % of Tax Rate', 'Invoice Type', 'E-Commerce GSTIN', 'Rate',
          'Taxable Value', 'Cess Amount',
        ],
        [
          for (final x in r.b2b)
            [
              x.gstin, x.name, x.number, _date(x.date), x.value,
              pos(x.pos), rc(x.reverseCharge), '', 'Regular B2B', '', x.rate,
              x.taxable, 0,
            ],
        ],
      ),
      _Sheet(
        'b2cl',
        'Summary For B2CL(5)',
        {
          0: ('No. of Invoices', distinct(r.b2cl, (Gstr1DocRow x) => x.invoiceId)),
          2: ('Total Invoice Value', docValue(r.b2cl)),
          6: ('Total Taxable Value', sum(r.b2cl, (Gstr1DocRow x) => x.taxable)),
          7: ('Total Cess', 0),
        },
        [
          'Invoice Number', 'Invoice date', 'Invoice Value', 'Place Of Supply',
          'Applicable % of Tax Rate', 'Rate', 'Taxable Value', 'Cess Amount',
          'E-Commerce GSTIN',
        ],
        [
          for (final x in r.b2cl)
            [x.number, _date(x.date), x.value, pos(x.pos), '', x.rate,
              x.taxable, 0, ''],
        ],
      ),
      _Sheet(
        'b2cs',
        'Summary For B2CS(7)',
        {
          4: ('Total Taxable  Value', sum(r.b2cs, (Gstr1B2csRow x) => x.taxable)),
          5: ('Total Cess', 0),
        },
        [
          'Type', 'Place Of Supply', 'Applicable % of Tax Rate', 'Rate',
          'Taxable Value', 'Cess Amount', 'E-Commerce GSTIN',
        ],
        [
          for (final x in r.b2cs)
            ['OE', pos(x.pos), '', x.rate, x.taxable, 0, ''],
        ],
      ),
      _Sheet(
        'cdnr',
        'Summary For CDNR(9B)',
        {
          0: ('No. of Recipients', distinct(r.cdnr, (Gstr1DocRow x) => x.gstin)),
          2: ('No. of Notes', distinct(r.cdnr, (Gstr1DocRow x) => x.invoiceId)),
          8: ('Total Note Value', docValue(r.cdnr)),
          11: ('Total Taxable Value', sum(r.cdnr, (Gstr1DocRow x) => x.taxable)),
          12: ('Total Cess', 0),
        },
        [
          'GSTIN/UIN of Recipient', 'Receiver Name', 'Note Number', 'Note Date',
          'Note Type', 'Place Of Supply', 'Reverse Charge', 'Note Supply Type',
          'Note Value', 'Applicable % of Tax Rate', 'Rate', 'Taxable Value',
          'Cess Amount',
        ],
        [
          for (final x in r.cdnr)
            [
              x.gstin, x.name, x.number, _date(x.date), x.noteType,
              pos(x.pos), rc(x.reverseCharge), 'Regular B2B', x.value, '',
              x.rate, x.taxable, 0,
            ],
        ],
      ),
      _Sheet(
        'cdnur',
        'Summary For CDNUR(9B)',
        {
          1: ('No. of Notes/Vouchers',
              distinct(r.cdnur, (Gstr1DocRow x) => x.invoiceId)),
          5: ('Total Note Value', docValue(r.cdnur)),
          8: ('Total Taxable Value', sum(r.cdnur, (Gstr1DocRow x) => x.taxable)),
          9: ('Total Cess', 0),
        },
        [
          'UR Type', 'Note Number', 'Note Date', 'Note Type', 'Place Of Supply',
          'Note Value', 'Applicable % of Tax Rate', 'Rate', 'Taxable Value',
          'Cess Amount',
        ],
        [
          for (final x in r.cdnur)
            [
              'B2CL', x.number, _date(x.date), x.noteType, pos(x.pos),
              x.value, '', x.rate, x.taxable, 0,
            ],
        ],
      ),
      _Sheet(
        'exp',
        'Summary For EXP(6)',
        {1: ('No. of Invoices', 0), 3: ('Total Invoice Value', 0),
          5: ('No. of Shipping Bill', 0), 9: ('Total Taxable Value', 0)},
        [
          'Export Type', 'Invoice Number', 'Invoice date', 'Invoice Value',
          'Port Code', 'Shipping Bill Number', 'Shipping Bill Date', 'Rate',
          'Taxable Value', 'Cess Amount',
        ],
        const [],
      ),
      _Sheet(
        'at',
        'Summary For Advance Received (11B) ',
        {3: ('Total Advance Received', 0), 4: ('Total Cess', 0)},
        ['Place Of Supply', 'Applicable % of Tax Rate', 'Rate',
          'Gross Advance Received', 'Cess Amount'],
        const [],
      ),
      _Sheet(
        'atadj',
        'Summary For Advance Adjusted (11B) ',
        {3: ('Total Advance Adjusted', 0), 4: ('Total Cess', 0)},
        ['Place Of Supply', 'Applicable % of Tax Rate', 'Rate',
          'Gross Advance Adjusted', 'Cess Amount'],
        const [],
      ),
      _Sheet(
        'exemp',
        'Summary For Nil rated, exempted and non GST outward supplies (8)',
        {
          1: ('Total Nil Rated Supplies', sum(r.exemp, (Gstr1ExempRow x) => x.nil)),
          2: ('Total Exempted Supplies', sum(r.exemp, (Gstr1ExempRow x) => x.exempt)),
          3: ('Total Non-GST Supplies', sum(r.exemp, (Gstr1ExempRow x) => x.nonGst)),
        },
        ['Description', 'Nil Rated Supplies',
          'Exempted(other than nil rated/non GST supply)', 'Non-GST Supplies'],
        [
          for (final x in r.exemp)
            [exempDescription(x), x.nil, x.exempt, x.nonGst],
        ],
      ),
      hsn('hsn(b2b)', r.hsnB2b),
      hsn('hsn(b2c)', r.hsnB2c),
      _Sheet(
        'docs',
        'Summary of documents issued during the tax period (13)',
        {
          3: ('Total Number', r.docs.fold(0, (a, d) => a + d.total)),
          4: ('Total Cancelled', r.docs.fold(0, (a, d) => a + d.cancelled)),
        },
        ['Nature of Document', 'Sr. No. From', 'Sr. No. To', 'Total Number',
          'Cancelled'],
        [
          for (final d in r.docs)
            [
              switch (d.type) {
                'Credit Note' => 'Credit Note',
                'Debit Note' => 'Debit Note',
                _ => 'Invoices for outward supply',
              },
              d.from, d.to, d.total, d.cancelled,
            ],
        ],
      ),
      _Sheet(
        'eco',
        'Summary For Supplies through ECO-14',
        {1: ('No. of E-Commerce Operator', 0),
          3: ('Total Net Value of Supplies', 0), 4: ('Total Integrated Tax', 0),
          5: ('Total Central Tax ', 0), 6: ('Total State/UT Tax ', 0),
          7: ('Total Cess', 0)},
        ['Nature of Supply', 'GSTIN of E-Commerce Operator',
          'E-Commerce Operator Name', 'Net value of supplies', 'Integrated tax',
          'Central tax', 'State/UT tax', 'Cess'],
        const [],
      ),
      if (includeRegister)
        _Sheet(
          'Invoices',
          'Invoice register (for review — not imported by the Offline Tool)',
          const {},
          ['Document Type', 'Number', 'Date', 'Customer', 'GSTIN/UIN',
            'Place Of Supply', 'Taxable Value', 'Tax', 'Total'],
          [
            for (final x in r.register)
              [x.type, x.number, _date(x.date), x.name, x.gstin,
                pos(x.pos), x.taxable, x.tax, x.total],
          ],
        ),
    ];

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes(sheets.length)))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRels))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook(sheets)))
      ..addFile(ArchiveFile.string(
          'xl/_rels/workbook.xml.rels', _workbookRels(sheets.length)))
      ..addFile(ArchiveFile.string('xl/styles.xml', _styles));
    for (var i = 0; i < sheets.length; i++) {
      archive.addFile(ArchiveFile.string(
          'xl/worksheets/sheet${i + 1}.xml', sheets[i].xml()));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  static String _contentTypes(int n) => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '${[for (var i = 1; i <= n; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
      '</Types>';

  static const _rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static String _workbook(List<_Sheet> sheets) => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
      '${[for (var i = 0; i < sheets.length; i++) '<sheet name="${_esc(sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
      '</sheets></workbook>';

  static String _workbookRels(int n) => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '${[for (var i = 1; i <= n; i++) '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}'
      '<Relationship Id="rId${n + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  // Style 0 = default, 1 = bold (title / headers).
  static const _styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>';
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// One template sheet: row 1 title, row 2 summary labels, row 3 summary
/// values (at the same columns), row 4 headers, data from row 5.
class _Sheet {
  final String name;
  final String title;
  final Map<int, (String, num)> summary;
  final List<String> header;
  final List<List<Object?>> rows;

  const _Sheet(this.name, this.title, this.summary, this.header, this.rows);

  static String _col(int i) =>
      i < 26 ? String.fromCharCode(65 + i) : _col(i ~/ 26 - 1) + _col(i % 26);

  static String _cell(int col, int row, Object? v, {bool bold = false}) {
    final ref = '${_col(col)}$row';
    final s = bold ? ' s="1"' : '';
    if (v == null || v == '') return '';
    if (v is num) return '<c r="$ref"$s><v>${_num(v)}</v></c>';
    return '<c r="$ref"$s t="inlineStr"><is><t xml:space="preserve">${_esc('$v')}</t></is></c>';
  }

  // Rounded to 2 dp, no trailing ".0" for whole numbers.
  static String _num(num v) {
    final r = (v * 100).round() / 100;
    return r == r.roundToDouble() ? '${r.toInt()}' : '$r';
  }

  String xml() {
    final b = StringBuffer(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>');
    void row(int r, Iterable<String> cells) =>
        b.write('<row r="$r">${cells.join()}</row>');
    final cols = summary.keys.toList()..sort();
    row(1, [_cell(0, 1, title, bold: true)]);
    row(2, [for (final c in cols) _cell(c, 2, summary[c]!.$1, bold: true)]);
    row(3, [for (final c in cols) _cell(c, 3, summary[c]!.$2)]);
    row(4, [for (var c = 0; c < header.length; c++) _cell(c, 4, header[c], bold: true)]);
    for (var i = 0; i < rows.length; i++) {
      row(i + 5, [for (var c = 0; c < rows[i].length; c++) _cell(c, i + 5, rows[i][c])]);
    }
    b.write('</sheetData></worksheet>');
    return b.toString();
  }
}
