import 'package:flutter/material.dart';
import 'package:invoiceapp/models/invoice.dart';
import 'package:invoiceapp/services/pdf_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';

class InvoiceList extends StatefulWidget {
  @override
  _InvoiceListState createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  List<Invoice> invoices = [];
  final dbHelper = DatabaseHelper();
  int currentPage = 0;
  final int pageSize = 10;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final result = await dbHelper.getAllInvoices();
    setState(() {
      invoices = result;
    });
  }

  List<Invoice> get paginatedInvoices {
    final filtered = invoices.where((invoice) =>
    invoice.customer.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        invoice.id.toLowerCase().contains(searchQuery.toLowerCase()));
    final start = currentPage * pageSize;
    return filtered.skip(start).take(pageSize).toList();
  }

  void _deleteInvoice(Invoice invoice) async {
    await dbHelper.deleteInvoice(invoice.id);
    _loadInvoices();
  }

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.id}'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${invoice.customer.name}'),
              Text('Date: ${invoice.date.toString().split(' ')[0]}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.product.name} x${item.quantity}'),
                    Text(item.total.toStringAsFixed(2)),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(invoice.subtotal.toStringAsFixed(2)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(invoice.tax.toStringAsFixed(2)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(invoice.total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(invoice.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _generatePDF(Invoice invoice) async {
    try {
      final pdf = await PDFService.generateInvoicePDF(invoice);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  void _previewPDF(Invoice invoice) async {
    try {
      final pdf = await PDFService.generateInvoicePDF(invoice);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error previewing PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (invoices.where((i) => i.customer.name.toLowerCase().contains(searchQuery.toLowerCase()) || i.id.toLowerCase().contains(searchQuery.toLowerCase())).length / pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoice List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search by ID or Customer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: paginatedInvoices.isEmpty
                ? const Center(child: Text('No invoices found', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Invoice ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Items')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: paginatedInvoices.map((invoice) {
                  return DataRow(cells: [
                    DataCell(Text('#${invoice.id}')),
                    DataCell(Text(invoice.customer.name)),
                    DataCell(Text(invoice.date.toString().split(' ')[0])),
                    DataCell(Text(invoice.items.length.toString())),
                    DataCell(Text(invoice.total.toStringAsFixed(2))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.visibility), onPressed: () => _showInvoiceDetails(invoice), tooltip: 'View Details'),
                        IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () => _previewPDF(invoice), tooltip: 'Preview PDF'),
                        IconButton(icon: const Icon(Icons.print), onPressed: () => _generatePDF(invoice), tooltip: 'Print PDF'),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Invoice'),
                              content: const Text('Are you sure you want to delete this invoice?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteInvoice(invoice);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                          tooltip: 'Delete',
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () => setState(() => currentPage--)
                    : null,
              ),
              Text('Page ${currentPage + 1} of $totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (currentPage + 1 < totalPages)
                    ? () => setState(() => currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
