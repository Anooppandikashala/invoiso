import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<String> exportInvoicesToCsv(List<Invoice> invoices) async {
    final rows = <List<dynamic>>[
      ['Invoice ID', 'Date', 'Customer', 'Type', 'Subtotal', 'Tax', 'Total', 'Currency'],
      ...invoices.map((inv) => [
        inv.id,
        AppFormatters.formatShortDate(inv.date),
        inv.customer.name,
        inv.type,
        inv.subtotal.toStringAsFixed(2),
        inv.tax.toStringAsFixed(2),
        inv.total.toStringAsFixed(2),
        inv.currencyCode,
      ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'invoices_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    return file.path;
  }
}
