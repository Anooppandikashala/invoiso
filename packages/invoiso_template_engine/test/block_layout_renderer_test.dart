import 'package:invoiso_template_engine/invoiso_template_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/test.dart';

Map<String, dynamic> _data({int items = 3}) => {
      'company': {'name': 'Sample Co', 'gstin': '00AAAAA0000A0Z0'},
      'customer': {'name': 'Sample Customer'},
      'invoice': {
        'number': 'INV-0001',
        'title': 'Tax Invoice',
        'date': '2026-11-21T10:30:00.000',
        'isInterState': false,
      },
      'items': [
        for (var i = 0; i < items; i++)
          {'name': 'Item $i', 'qty': 2, 'rate': 100, 'amount': 200},
      ],
      'totals': {'tax': 36, 'total': 236, 'amountInWords': 'Two Hundred'},
      'bank': {'upi': 'sample@upi'},
    };

const _document = {
  'page': {'size': 'a4'},
  'layout': [
    {
      'type': 'header',
      'left': {'companyName': '{{company.name}}'},
      'right': {'title': '{{invoice.title}}', 'invoiceNo': '{{invoice.number}}'},
    },
    {'type': 'table'},
    {
      'type': 'summary',
      'rows': [
        {'label': 'CGST', 'value': '{{cgst}}'},
        {'label': 'Total', 'value': '{{total}}', 'highlight': true},
      ],
    },
    {'type': 'text', 'content': 'Words: {{amountinwords}} / UPI {{bank.upi}}'},
  ],
};

void main() {
  test('renders a layout from plain data, without the app', () async {
    final pdf = pw.Document()
      ..addPage(buildBlockLayoutPage(
        document: _document,
        data: _data(),
        options: const TemplateOptions(currencySymbol: 'Rs'),
      ));
    expect(await pdf.save(), isNotEmpty);
    expect(pdf.document.pdfPageList.pages, hasLength(1));
  });

  test('long item lists split across pages', () async {
    final pdf = pw.Document()
      ..addPage(buildBlockLayoutPage(document: _document, data: _data(items: 120)));
    expect(await pdf.save(), isNotEmpty);
    expect(pdf.document.pdfPageList.pages.length, greaterThan(1));
  });

  test('missing data sections render as empty, not crash', () async {
    final pdf = pw.Document()
      ..addPage(buildBlockLayoutPage(document: _document, data: const {}));
    expect(await pdf.save(), isNotEmpty);
  });
}
