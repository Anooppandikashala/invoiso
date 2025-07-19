import 'package:flutter/material.dart';
import 'package:invoiceapp/constants.dart';
import 'package:invoiceapp/models/invoice.dart';
import 'package:invoiceapp/services/invoice_services.dart';
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

  @override
  Widget build(BuildContext context) {
    final totalPages = (invoices.where((i) => i.customer.name.toLowerCase().contains(searchQuery.toLowerCase()) || i.id.toLowerCase().contains(searchQuery.toLowerCase())).length / pageSize).ceil();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice List'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppSpacing.hLarge,
          SizedBox(
            width: MediaQuery.sizeOf(context).width*0.6,
            child: Padding(
              padding: const EdgeInsets.only(left: 30,right: 30),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by ID or Customer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),
          AppSpacing.hLarge,
          Expanded(
            child: paginatedInvoices.isEmpty
                ? const Center(child: Text('No invoices found', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    return Theme.of(context).primaryColor; // Set your desired color here
                  },
                ),
                headingTextStyle: TextStyle(color: Colors.white),
                columns: const [
                  DataColumn(label: Text('Invoice ID',style: TextStyle(color: Colors.white,fontSize: 18),)),
                  DataColumn(label: Text('Customer',style: TextStyle(color: Colors.white,fontSize: 18),)),
                  DataColumn(label: Text('Date',style: TextStyle(color: Colors.white,fontSize: 18),)),
                  DataColumn(label: Text('Items',style: TextStyle(color: Colors.white,fontSize: 18),)),
                  DataColumn(label: Text('Total',style: TextStyle(color: Colors.white,fontSize: 18),)),
                  DataColumn(label: Text('Actions',style: TextStyle(color: Colors.white,fontSize: 18),)),
                ],
                rows: paginatedInvoices.asMap().entries.map((entry)
                {
                  final invoice  = entry.value;
                  final index = entry.key+1;
                  return DataRow(
                      color: WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                          return index.isEven ? Colors.grey.shade200 : Colors.white;
                        },
                      ),
                      cells: [
                    DataCell(Text('#${invoice.id}',style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Text(invoice.customer.name,style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Text(invoice.date.toString().split(' ')[0],style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Text(invoice.items.length.toString(),style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Text("Rs: ${invoice.total.toStringAsFixed(2)}",style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.visibility,color: Colors.green,), onPressed: () =>  InvoiceServices.showInvoiceDetails(context,invoice), tooltip: 'View Details'),
                        IconButton(icon: const Icon(Icons.picture_as_pdf,color: Colors.purple,), onPressed: () => InvoiceServices.previewPDF(context,invoice), tooltip: 'Preview PDF'),
                        IconButton(icon: const Icon(Icons.print,color: Colors.black,), onPressed: () => InvoiceServices.generatePDF(context,invoice), tooltip: 'Print PDF'),
                        IconButton(
                          icon: const Icon(Icons.delete,color: Colors.red,),
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
