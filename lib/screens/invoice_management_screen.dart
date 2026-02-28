import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';


import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';

class InvoiceManagementScreen extends StatefulWidget {
  final Function(Invoice) onEditInvoice;
  const InvoiceManagementScreen({super.key, required this.onEditInvoice});

  @override
  _InvoiceManagementScreenState createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  List<Invoice> invoices = [];
  int currentPage = 0;
  final int pageSize = 10;
  String searchQuery = '';
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => isLoading = true);
    final result = await InvoiceService.getAllInvoices();
    setState(() {
      invoices = result;
      isLoading = false;
    });
  }

  List<Invoice> get filteredInvoices {
    return invoices.where((invoice) =>
    invoice.customer.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        invoice.id.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  List<Invoice> get paginatedInvoices {
    final start = currentPage * pageSize;
    return filteredInvoices.skip(start).take(pageSize).toList();
  }

  void _deleteInvoice(Invoice invoice) async {
    await InvoiceService.deleteInvoice(invoice.id);
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (filteredInvoices.length / pageSize).ceil();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invoice Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header Section with Search and Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Search by Invoice ID or Customer Name',
                            hintText: 'Enter invoice ID or customer name...',
                            prefixIcon: const Icon(Icons.search, size: 22),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (value) => setState(() {
                            searchQuery = value;
                            currentPage = 0;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Stats Summary
                    _buildStatChip(
                      'Total',
                      invoices.length.toString(),
                      Colors.blue,
                      Icons.receipt_long,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      'Showing',
                      filteredInvoices.length.toString(),
                      Colors.green,
                      Icons.visibility,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Table Container
          Expanded(
            child: paginatedInvoices.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isEmpty
                        ? 'No invoices found'
                        : 'No results for "$searchQuery"',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isEmpty
                        ? 'Create your first invoice to see it here'
                        : 'Try adjusting your search',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
                : SizedBox(
              width: MediaQuery.sizeOf(context).width*0.75,
                  child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(80),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1),
                            4: FixedColumnWidth(80),
                            5: FlexColumnWidth(1.2),
                            6: FixedColumnWidth(280),
                          },
                          children: [
                            TableRow(
                              children: [
                                _buildTableHeader('#'),
                                _buildTableHeader('Invoice ID'),
                                _buildTableHeader('Customer'),
                                _buildTableHeader('Date'),
                                _buildTableHeader('Items'),
                                _buildTableHeader('Total'),
                                _buildTableHeader('Actions'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Table Body
                      ...paginatedInvoices.asMap().entries.map((entry) {
                        final invoice = entry.value;
                        final index = entry.key;
                        final globalIndex = (currentPage * pageSize) + index + 1;
                        return _buildInvoiceRow(invoice, globalIndex, index.isEven);
                      }).toList(),
                    ],
                  ),
                                ),
                              ),
                ),
          ),

          // Pagination Footer
          if (paginatedInvoices.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: currentPage > 0
                        ? () => setState(() => currentPage--)
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 20),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      elevation: 0,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Page ${currentPage + 1} of ${totalPages > 0 ? totalPages : 1}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: (currentPage + 1 < totalPages)
                        ? () => setState(() => currentPage++)
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      elevation: 0,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(Invoice invoice, int index, bool isEven) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey[50] : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(80),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1),
          4: FixedColumnWidth(80),
          5: FlexColumnWidth(1.2),
          6: FixedColumnWidth(280),
        },
        children: [
          TableRow(
            children: [
              _buildTableCell(
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              _buildTableCell(
                Text(
                  '#${invoice.id}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildTableCell(
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invoice.customer.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTableCell(
                Text(
                  invoice.date.toString().split(' ')[0],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              _buildTableCell(
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${invoice.items.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
              ),
              _buildTableCell(
                Text(
                  '${invoice.currencySymbol} ${invoice.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              _buildTableCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.visibility_outlined,
                      Colors.green,
                      'View',
                          () => InvoicePdfServices.showInvoiceDetails(context, invoice),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.edit_outlined,
                      Colors.blue,
                      'Edit',
                          () => widget.onEditInvoice(invoice),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.picture_as_pdf_outlined,
                      Colors.orange,
                      'PDF',
                          () => InvoicePdfServices.previewPDF(context, invoice),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.print_outlined,
                      Colors.blueGrey,
                      'Print',
                          () => InvoicePdfServices.generatePDF(context, invoice),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.delete_outline,
                      Colors.red,
                      'Delete',
                          () => _showDeleteDialog(invoice),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: child,
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon,
      Color color,
      String tooltip,
      VoidCallback onPressed,
      ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  void _showDeleteDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Invoice'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete Invoice #${invoice.id}? This action cannot be undone.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInvoice(invoice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


class InvoiceManagementScreen1 extends StatefulWidget {
  final Function(Invoice) onEditInvoice;
  const InvoiceManagementScreen1({super.key, required this.onEditInvoice});

  @override
  _InvoiceManagementScreenState1 createState() => _InvoiceManagementScreenState1();
}

class _InvoiceManagementScreenState1 extends State<InvoiceManagementScreen1> {
  List<Invoice> invoices = [];
  int currentPage = 0;
  final int pageSize = 10;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final result = await InvoiceService.getAllInvoices();
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
    await InvoiceService.deleteInvoice(invoice.id);
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
                  DataColumn(label: Text('Type',style: TextStyle(color: Colors.white,fontSize: 18),)),
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
                    DataCell(Text(invoice.type.toString(),style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Text(invoice.items.length.toString(),style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Text("Rs: ${invoice.total.toStringAsFixed(2)}",style: TextStyle(color: Colors.black,fontSize: 16),)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit,color: Colors.blue,), onPressed: () =>  widget.onEditInvoice(invoice), tooltip: 'Edit Invoice'),
                        IconButton(icon: const Icon(Icons.visibility,color: Colors.green,), onPressed: () =>  InvoicePdfServices.showInvoiceDetails(context,invoice), tooltip: 'View Details'),
                        IconButton(icon: const Icon(Icons.picture_as_pdf,color: Colors.purple,), onPressed: () => InvoicePdfServices.previewPDF(context,invoice), tooltip: 'Preview PDF'),
                        IconButton(icon: const Icon(Icons.print,color: Colors.black,), onPressed: () => InvoicePdfServices.generatePDF(context,invoice), tooltip: 'Print PDF'),
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
