import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/providers/invoice_provider.dart';
import 'package:invoiso/services/export_service.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/utils/error_handler.dart';
import 'package:open_file/open_file.dart';

class InvoiceManagementScreen extends ConsumerStatefulWidget {
  final Function(Invoice) onEditInvoice;
  final Function(Invoice, String) onCloneInvoice;

  const InvoiceManagementScreen({
    super.key,
    required this.onEditInvoice,
    required this.onCloneInvoice,
  });

  @override
  ConsumerState<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState
    extends ConsumerState<InvoiceManagementScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;
  String _searchQuery = '';
  bool _isLoadingPage = false;
  bool _isBulkLoading = false;
  int _totalCount = 0;
  List<Invoice> _pageInvoices = [];
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();

  /// Shared column widths used by both the header table and every row table so
  /// they always align pixel-perfectly.
  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FixedColumnWidth(48),   // checkbox
    1: FixedColumnWidth(64),   // #
    2: FlexColumnWidth(1.5),   // Invoice ID
    3: FlexColumnWidth(1.2),   // Customer
    4: FlexColumnWidth(1.0),   // Date
    5: FixedColumnWidth(64),   // Items
    6: FlexColumnWidth(1.2),   // Total
    7: FixedColumnWidth(320),  // Actions
  };

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadPage() async {
    setState(() {
      _isLoadingPage = true;
      _selectedIds.clear(); // selection reset on every page/search change
    });
    try {
      final results = await Future.wait([
        InvoiceService.getInvoicesPaginated(
          page: _currentPage,
          pageSize: _pageSize,
          searchQuery: _searchQuery,
        ),
        InvoiceService.getInvoiceCount(searchQuery: _searchQuery),
      ]);
      if (mounted) {
        setState(() {
          _pageInvoices = results[0] as List<Invoice>;
          _totalCount = results[1] as int;
          _isLoadingPage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPage = false);
        AppError.show(context, 'Failed to load invoices: $e', onRetry: _loadPage);
      }
    }
  }

  // ─── Selection helpers ─────────────────────────────────────────────────────

  bool get _isAllPageSelected =>
      _pageInvoices.isNotEmpty &&
      _pageInvoices.every((inv) => _selectedIds.contains(inv.id));

  bool get _isSomePageSelected =>
      _pageInvoices.any((inv) => _selectedIds.contains(inv.id));

  void _toggleSelectAll() {
    setState(() {
      if (_isAllPageSelected) {
        for (final inv in _pageInvoices) {
          _selectedIds.remove(inv.id);
        }
      } else {
        for (final inv in _pageInvoices) {
          _selectedIds.add(inv.id);
        }
      }
    });
  }

  void _toggleOne(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // ─── Per-row actions ───────────────────────────────────────────────────────

  Future<void> _showCloneDialog(Invoice invoice) async {
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.copy_all, color: Colors.teal),
            SizedBox(width: 12),
            Text('Duplicate Invoice'),
          ],
        ),
        content: Text(
          'Create a copy of Invoice #${invoice.id}\n(${invoice.customer.name}) as:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Quotation'),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Quotation'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.receipt),
            label: const Text('Invoice'),
          ),
        ],
      ),
    );
    if (type != null) {
      widget.onCloneInvoice(invoice, type);
    }
  }

  Future<void> _softDelete(Invoice invoice) async {
    final confirmed = await AppError.confirm(
      context,
      title: 'Move to Trash',
      message: 'Move Invoice #${invoice.id} to trash?',
      confirmLabel: 'Move to Trash',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    await InvoiceService.softDeleteInvoice(invoice.id);
    ref.read(invoicesProvider.notifier).refresh();
    await _loadPage();
    if (mounted) AppError.showSuccess(context, 'Invoice moved to trash.');
  }

  // ─── Toolbar actions ───────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    try {
      final all = await InvoiceService.getAllInvoices();
      final path = await ExportService.exportInvoicesToCsv(all);
      if (mounted) {
        AppError.showSuccess(context, 'Exported to: $path');
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) AppError.show(context, 'Export failed: $e');
    }
  }

  void _showTrashDialog() async {
    final deleted = await InvoiceService.getDeletedInvoices();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _TrashDialog(
        deletedInvoices: deleted,
        onRestored: () async {
          ref.read(invoicesProvider.notifier).refresh();
          await _loadPage();
        },
      ),
    );
  }

  // ─── Bulk actions ──────────────────────────────────────────────────────────

  Future<void> _bulkSoftDelete() async {
    final count = _selectedIds.length;
    final confirmed = await AppError.confirm(
      context,
      title: 'Move to Trash',
      message: 'Move $count invoice${count == 1 ? '' : 's'} to trash?',
      confirmLabel: 'Move to Trash',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    setState(() => _isBulkLoading = true);
    try {
      for (final id in List<String>.from(_selectedIds)) {
        await InvoiceService.softDeleteInvoice(id);
      }
      ref.read(invoicesProvider.notifier).refresh();
      await _loadPage(); // also clears _selectedIds
      if (mounted) {
        AppError.showSuccess(
            context, '$count invoice${count == 1 ? '' : 's'} moved to trash.');
      }
    } catch (e) {
      if (mounted) AppError.show(context, 'Bulk delete failed: $e');
    } finally {
      if (mounted) setState(() => _isBulkLoading = false);
    }
  }

  Future<void> _bulkExportCsv() async {
    final selected =
        _pageInvoices.where((inv) => _selectedIds.contains(inv.id)).toList();
    if (selected.isEmpty) return;

    setState(() => _isBulkLoading = true);
    try {
      final path = await ExportService.exportInvoicesToCsv(selected);
      if (mounted) {
        AppError.showSuccess(
            context,
            'Exported ${selected.length} invoice${selected.length == 1 ? '' : 's'} to CSV');
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) AppError.show(context, 'CSV export failed: $e');
    } finally {
      if (mounted) setState(() => _isBulkLoading = false);
    }
  }

  Future<void> _bulkExportPdfs() async {
    final selected =
        _pageInvoices.where((inv) => _selectedIds.contains(inv.id)).toList();
    if (selected.isEmpty) return;

    setState(() => _isBulkLoading = true);

    // ValueNotifier drives the progress bar inside the dialog without needing
    // StatefulBuilder + captured setDialogState.
    final progress = ValueNotifier<int>(0);

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.orange),
            SizedBox(width: 12),
            Text('Generating PDFs'),
          ],
        ),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, done, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generating ${selected.length} PDF${selected.length == 1 ? '' : 's'}...',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: done / selected.length,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Text(
                '$done / ${selected.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ));

    try {
      final path = await ExportService.exportInvoicesToPdfFolder(
        selected,
        onProgress: (done, _) => progress.value = done,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close dialog
        AppError.showSuccess(context, 'PDFs saved to: $path');
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppError.show(context, 'PDF export failed: $e');
      }
    } finally {
      progress.dispose();
      if (mounted) setState(() => _isBulkLoading = false);
    }
  }

  // ─── Pagination ────────────────────────────────────────────────────────────

  int get _totalPages => (_totalCount / _pageSize).ceil();

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invoice Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isBulkLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportCsv,
            tooltip: 'Export all to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _showTrashDialog,
            tooltip: 'Trash',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentPage = 0;
              _loadPage();
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingPage
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Search + stats ────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText:
                                  'Search by Invoice ID or Customer Name',
                              hintText:
                                  'Enter invoice ID or customer name...',
                              prefixIcon:
                                  const Icon(Icons.search, size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _currentPage = 0;
                                        });
                                        _loadPage();
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.xsmall),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.xsmall),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.xsmall),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _currentPage = 0;
                              });
                              _loadPage();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildStatChip('Total', _totalCount.toString(),
                          Colors.blue, Icons.receipt_long),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        'Page',
                        '${_currentPage + 1}/${_totalPages > 0 ? _totalPages : 1}',
                        Colors.green,
                        Icons.pages,
                      ),
                    ],
                  ),
                ),

                // ── Bulk-actions bar (animated in/out) ────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedIds.isEmpty
                      ? const SizedBox.shrink(key: ValueKey('no_selection'))
                      : _buildBulkActionsBar(),
                ),

                const SizedBox(height: 16),

                // ── Table ─────────────────────────────────────────────────
                Expanded(
                  child: _pageInvoices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No invoices found'
                                    : 'No results for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Create your first invoice to see it here'
                                    : 'Try adjusting your search',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.75,
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Card(
                              elevation: 2,
                              shadowColor:
                                  Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.xsmall),
                              ),
                              child: Column(
                                children: [
                                  // Table header
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Table(
                                      columnWidths: _columnWidths,
                                      children: [
                                        TableRow(
                                          children: [
                                            // Select-all checkbox
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 4),
                                              child: Checkbox(
                                                value: _isAllPageSelected,
                                                tristate: _isSomePageSelected &&
                                                    !_isAllPageSelected,
                                                onChanged: (_) =>
                                                    _toggleSelectAll(),
                                                activeColor: Colors.white,
                                                checkColor: Theme.of(context)
                                                    .primaryColor,
                                                side: const BorderSide(
                                                    color: Colors.white70,
                                                    width: 2),
                                              ),
                                            ),
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
                                  // Table rows
                                  ..._pageInvoices.asMap().entries.map(
                                    (entry) {
                                      final invoice = entry.value;
                                      final index = entry.key;
                                      final globalIndex =
                                          (_currentPage * _pageSize) +
                                              index +
                                              1;
                                      return _buildInvoiceRow(
                                          invoice, globalIndex, index.isEven);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),

                // ── Pagination ────────────────────────────────────────────
                if (_pageInvoices.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() => _currentPage--);
                                  _loadPage();
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left, size: 20),
                          label: const Text('Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                Theme.of(context).primaryColor,
                            disabledBackgroundColor: Colors.grey[200],
                            disabledForegroundColor: Colors.grey[400],
                            elevation: 0,
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3)),
                          ),
                          child: Text(
                            'Page ${_currentPage + 1} of ${_totalPages > 0 ? _totalPages : 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: (_currentPage + 1 < _totalPages)
                              ? () {
                                  setState(() => _currentPage++);
                                  _loadPage();
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right, size: 20),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                Theme.of(context).primaryColor,
                            disabledBackgroundColor: Colors.grey[200],
                            disabledForegroundColor: Colors.grey[400],
                            elevation: 0,
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  // ─── Bulk actions bar ──────────────────────────────────────────────────────

  Widget _buildBulkActionsBar() {
    final count = _selectedIds.length;
    return Container(
      key: const ValueKey('bulk_bar'),
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          // Selected count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count selected',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          _buildBulkButton(
            icon: Icons.deselect,
            label: 'Deselect All',
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
          const SizedBox(width: 8),

          _buildBulkButton(
            icon: Icons.select_all,
            label: 'Select Page',
            onPressed: _isAllPageSelected
                ? null
                : () => setState(() {
                      for (final inv in _pageInvoices) {
                        _selectedIds.add(inv.id);
                      }
                    }),
          ),

          const Spacer(),

          _buildBulkButton(
            icon: Icons.table_chart_outlined,
            label: 'Export CSV',
            onPressed: _isBulkLoading ? null : _bulkExportCsv,
          ),
          const SizedBox(width: 8),

          _buildBulkButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Export PDFs',
            onPressed: _isBulkLoading ? null : _bulkExportPdfs,
          ),
          const SizedBox(width: 8),

          _buildBulkButton(
            icon: Icons.delete_outline,
            label: 'Move to Trash',
            color: Colors.red[300]!,
            onPressed: _isBulkLoading ? null : _bulkSoftDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBulkButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final c = color ?? Colors.white;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c,
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: onPressed != null ? c.withOpacity(0.5) : Colors.white24),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  // ─── Table helpers ─────────────────────────────────────────────────────────

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
    final isSelected = _selectedIds.contains(invoice.id);
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.08)
            : (isEven ? Colors.grey[50] : Colors.white),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          left: isSelected
              ? BorderSide(
                  color: Theme.of(context).primaryColor, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Table(
        columnWidths: _columnWidths,
        children: [
          TableRow(
            children: [
              // Per-row checkbox
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 4),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleOne(invoice.id),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
              _buildTableCell(
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              _buildTableCell(
                Text('#${invoice.id}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              _buildTableCell(
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[600]),
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
                Text(invoice.date.toString().split(' ')[0],
                    style: const TextStyle(fontSize: 14)),
              ),
              _buildTableCell(
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${invoice.items.length}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700]),
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
                      color: Colors.green),
                ),
              ),
              _buildTableCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                        Icons.visibility_outlined, Colors.green, 'View',
                        () => InvoicePdfServices.showInvoiceDetails(
                            context, invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.edit_outlined, Colors.blue, 'Edit',
                        () => widget.onEditInvoice(invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.copy_all_outlined, Colors.teal, 'Duplicate',
                        () => _showCloneDialog(invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.picture_as_pdf_outlined,
                        Colors.orange,
                        'PDF',
                        () => InvoicePdfServices.previewPDF(
                            context, invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.print_outlined, Colors.blueGrey, 'Print',
                        () => InvoicePdfServices.generatePDF(
                            context, invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.delete_outline, Colors.red, 'Move to Trash',
                        () => _softDelete(invoice)),
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

  Widget _buildStatChip(
      String label, String value, Color color, IconData icon) {
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
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, String tooltip, VoidCallback onPressed) {
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
}

// Silence the unawaited future lint for the showDialog call used to drive the
// progress overlay (we close it programmatically via Navigator.pop).
void unawaited(Future<void> future) {}

// ─────────────────────────────────────────────
// Trash Dialog
class _TrashDialog extends StatefulWidget {
  final List<Invoice> deletedInvoices;
  final VoidCallback onRestored;

  const _TrashDialog({required this.deletedInvoices, required this.onRestored});

  @override
  State<_TrashDialog> createState() => _TrashDialogState();
}

class _TrashDialogState extends State<_TrashDialog> {
  late List<Invoice> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = List.from(widget.deletedInvoices);
  }

  Future<void> _restore(Invoice invoice) async {
    await InvoiceService.restoreInvoice(invoice.id);
    setState(() => _invoices.removeWhere((i) => i.id == invoice.id));
    widget.onRestored();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invoice restored.'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _permanentDelete(Invoice invoice) async {
    final confirmed = await AppError.confirm(
      context,
      title: 'Permanently Delete',
      message:
          'Permanently delete Invoice #${invoice.id}? This cannot be undone.',
    );
    if (!confirmed) return;
    await InvoiceService.permanentDeleteInvoice(invoice.id);
    setState(() => _invoices.removeWhere((i) => i.id == invoice.id));
    widget.onRestored();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text('Trash',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Trash is empty',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _invoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final inv = _invoices[index];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long,
                          color: Colors.grey),
                      title: Text('#${inv.id} — ${inv.customer.name}'),
                      subtitle:
                          Text(inv.date.toString().split(' ')[0]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => _restore(inv),
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('Restore'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.green),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () => _permanentDelete(inv),
                            icon: const Icon(Icons.delete_forever,
                                size: 16),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
