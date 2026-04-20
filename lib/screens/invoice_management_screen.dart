import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/invoisoColors.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/providers/invoice_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invoiso/services/export_service.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';
import 'package:invoiso/utils/error_handler.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/widgets/customer_info_button.dart';

class InvoiceManagementScreen extends ConsumerStatefulWidget {
  final Function(Invoice) onEditInvoice;
  final Function(Invoice, String) onCloneInvoice;
  final User user;
  final String filterType; // 'Invoice' | 'Quotation'

  const InvoiceManagementScreen({
    super.key,
    required this.onEditInvoice,
    required this.onCloneInvoice,
    required this.user,
    this.filterType = 'Invoice',
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
  bool _hidePaid = false;
  String _dueDateFilter = 'all'; // 'all' | 'overdue' | 'due_today' | 'due_week' | 'due_month'
  int _totalCount = 0;
  List<Invoice> _pageInvoices = [];
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  /// Shared column widths used by both the header table and every row table so
  /// they always align pixel-perfectly.
  static const List<(String, String, Color)> _dueDateFilterOptions = [
    ('all',        'All Dues',      Colors.grey),
    ('overdue',    'Overdue',       Colors.red),
    ('due_today',  'Due Today',     Colors.orange),
    ('due_week',   'Due This Week', Colors.blue),
    ('due_month',  'Due This Month',Colors.teal),
  ];

  // Invoice table: checkbox | # | ID | Customer | Date | Items | Total | Status | Outstanding | Actions
  static const Map<int, TableColumnWidth> _invoiceColumnWidths = {
    0: FixedColumnWidth(48),
    1: FixedColumnWidth(56),
    2: FlexColumnWidth(0.6),
    3: FlexColumnWidth(0.9),
    4: FixedColumnWidth(150),
    5: FixedColumnWidth(80),
    6: FlexColumnWidth(1.0),
    7: FixedColumnWidth(90),
    8: FlexColumnWidth(1.0),
    9: FixedColumnWidth(360),
  };

  // Quotation table: checkbox | # | ID | Customer | Date | Items | Total | Actions
  static const Map<int, TableColumnWidth> _quotationColumnWidths = {
    0: FixedColumnWidth(48),
    1: FixedColumnWidth(56),
    2: FlexColumnWidth(0.9),
    3: FlexColumnWidth(1.0),
    4: FixedColumnWidth(120),
    5: FixedColumnWidth(80),
    6: FlexColumnWidth(1.0),
    7: FixedColumnWidth(320),
  };

  Map<int, TableColumnWidth> get _columnWidths =>
      widget.filterType == 'Quotation' ? _quotationColumnWidths : _invoiceColumnWidths;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
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
          filterType: widget.filterType,
        ),
        InvoiceService.getInvoiceCount(
          searchQuery: _searchQuery,
          filterType: widget.filterType,
        ),
      ]);
      if (mounted) {
        var pageInvoices = results[0] as List<Invoice>;
        if (_hidePaid) {
          // Keep Quotations; for Invoices only keep those with an outstanding balance
          pageInvoices = pageInvoices
              .where((inv) => inv.type != 'Invoice' || inv.outstandingBalance > 0)
              .toList();
        }
        if (_dueDateFilter != 'all') {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          pageInvoices = pageInvoices.where((inv) {
            if (inv.dueDate == null) return false;
            final due = DateTime(inv.dueDate!.year, inv.dueDate!.month, inv.dueDate!.day);
            switch (_dueDateFilter) {
              case 'overdue':
                return due.isBefore(today) && inv.paymentStatus != PaymentStatus.paid;
              case 'due_today':
                return due == today;
              case 'due_week':
                return !due.isBefore(today) && due.isBefore(today.add(const Duration(days: 7)));
              case 'due_month':
                return !due.isBefore(today) && due.isBefore(DateTime(today.year, today.month + 1, today.day));
              default:
                return true;
            }
          }).toList();
        }
        setState(() {
          _pageInvoices = pageInvoices;
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
    final fmt = DateFormat('dd/MM/yyyy');
    DateTime? fromDate;
    DateTime? toDate;
    bool exportAll = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.file_download_outlined,
                  color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Text('Export ${widget.filterType}s to CSV'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Export All toggle
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setS(() {
                    exportAll = !exportAll;
                    if (exportAll) {
                      fromDate = null;
                      toDate = null;
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: exportAll,
                          onChanged: (v) => setS(() {
                            exportAll = v ?? false;
                            if (exportAll) {
                              fromDate = null;
                              toDate = null;
                            }
                          }),
                        ),
                        const SizedBox(width: 4),
                        const Text('Export All Records',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                // Date range pickers
                Opacity(
                  opacity: exportAll ? 0.35 : 1.0,
                  child: AbsorbPointer(
                    absorbing: exportAll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Or filter by date range:',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                label: 'From Date',
                                value: fromDate,
                                formatter: fmt,
                                onPicked: (d) => setS(() => fromDate = d),
                                onCleared: () => setS(() => fromDate = null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DatePickerField(
                                label: 'To Date',
                                value: toDate,
                                formatter: fmt,
                                onPicked: (d) => setS(() => toDate = d),
                                onCleared: () => setS(() => toDate = null),
                              ),
                            ),
                          ],
                        ),
                        if (fromDate != null &&
                            toDate != null &&
                            toDate!.isBefore(fromDate!)) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'To date must be after From date.',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: (!exportAll &&
                      fromDate != null &&
                      toDate != null &&
                      toDate!.isBefore(fromDate!))
                  ? null
                  : () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final invoices = await InvoiceService.getInvoicesForExport(
        fromDate: exportAll ? null : fromDate,
        toDate: exportAll ? null : toDate,
        filterType: widget.filterType,
      );
      final path = await ExportService.exportInvoicesToCsv(invoices, type: widget.filterType);
      if (mounted) {
        AppError.showSuccess(context,
            'Exported ${invoices.length} record${invoices.length == 1 ? '' : 's'} to: $path');
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

    // Ask the user: save as folder or as a ZIP?
    final saveMode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Theme.of(ctx).primaryColor),
            const SizedBox(width: 12),
            const Text('Download PDFs'),
          ],
        ),
        content: Text(
          'How would you like to save ${selected.length} PDF${selected.length == 1 ? '' : 's'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Save to Folder'),
            onPressed: () => Navigator.pop(ctx, 'folder'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.folder_zip_outlined),
            label: const Text('Save as ZIP'),
            onPressed: () => Navigator.pop(ctx, 'zip'),
          ),
        ],
      ),
    );
    if (saveMode == null || !mounted) return;

    String? outputDir;
    String? zipSavePath;

    if (saveMode == 'folder') {
      outputDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose folder to save PDFs',
      );
      if (outputDir == null || !mounted) return;
    } else {
      zipSavePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ZIP file',
        fileName: 'invoices_${DateFormat('yyyyMMdd').format(DateTime.now())}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (zipSavePath == null || !mounted) return;
    }

    setState(() => _isBulkLoading = true);

    final progress = ValueNotifier<int>(0);

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              saveMode == 'zip' ? Icons.folder_zip_outlined : Icons.picture_as_pdf,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Text(saveMode == 'zip' ? 'Creating ZIP' : 'Generating PDFs'),
          ],
        ),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, done, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Processing ${selected.length} PDF${selected.length == 1 ? '' : 's'}...',
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
      final String path;
      if (saveMode == 'zip') {
        path = await ExportService.exportInvoicesToZip(
          selected,
          zipSavePath!,
          onProgress: (done, _) => progress.value = done,
        );
      } else {
        path = await ExportService.exportInvoicesToPdfFolder(
          selected,
          onProgress: (done, _) => progress.value = done,
          outputDirectory: outputDir,
        );
      }
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppError.showSuccess(context, 'Saved to: $path');
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
        title: Text('${widget.filterType} Management'),
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
          if (widget.user.isAdmin())
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
                            focusNode: _searchFocusNode,
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
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 400),
                                _loadPage,
                              );
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
                      if (widget.filterType == 'Invoice') ...[
                      const SizedBox(width: 16),
                      // Hide Paid toggle
                      InkWell(
                        onTap: () {
                          setState(() {
                            _hidePaid = !_hidePaid;
                            _currentPage = 0;
                          });
                          _loadPage();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _hidePaid
                                ? Colors.orange.withValues(alpha:0.12)
                                : Colors.grey.withValues(alpha:0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _hidePaid
                                  ? Colors.orange.withValues(alpha:0.4)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hidePaid
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: _hidePaid ? Colors.orange[700] : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Hide Paid',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _hidePaid ? Colors.orange[700] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ], // end filterType == 'Invoice'
                      if (widget.filterType == 'Invoice') ...[
                      const SizedBox(width: 16),
                      // Due date filter chips
                      ..._dueDateFilterOptions.map((option) {
                        final isActive = _dueDateFilter == option.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _dueDateFilter = option.$1;
                                _currentPage = 0;
                              });
                              _loadPage();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? option.$3.withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive ? option.$3.withValues(alpha: 0.4) : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                option.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isActive ? option.$3 : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      ], // end filterType == 'Invoice' (due date chips)
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
                                    ? 'No ${widget.filterType.toLowerCase()}s found'
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
                                    ? 'Create your first ${widget.filterType.toLowerCase()} to see it here'
                                    : 'Try adjusting your search',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                      : Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthWide),
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
                                      gradient: InvoiceManagementScreenColors.topBarBackgroundGradientColor,
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
                                            if (widget.filterType == 'Invoice') ...[
                                              _buildTableHeader('Status'),
                                              _buildTableHeader('Outstanding'),
                                            ],
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
                                .withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha:0.3)),
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

          if (widget.user.isAdmin())
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
              color: onPressed != null ? c.withValues(alpha:0.5) : Colors.white24),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  // ─── Table helpers ─────────────────────────────────────────────────────────

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
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
            ? Theme.of(context).primaryColor.withValues(alpha:0.08)
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha:0.1),
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
              _buildTableCell(
                Text('#${invoice.id}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              _buildTableCell(
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showIcon = constraints.maxWidth > 60;
                    final showInfoBtn = constraints.maxWidth > 30;
                    return Row(
                      children: [
                        if (showIcon) ...[
                          Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            invoice.customer.name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showInfoBtn)
                          CustomerInfoButton(customer: invoice.customer),
                      ],
                    );
                  },
                ),
              ),
              _buildTableCell(_buildDateCell(invoice)),
              // Items count
              _buildTableCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha:0.1),
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
              _buildTableCell(
                Text(
                  '${invoice.currencySymbol} ${invoice.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              if (widget.filterType == 'Invoice') ...[
                // Payment status chip
                _buildTableCell(_buildPaymentStatusChip(invoice.paymentStatus)),
                // Outstanding balance
                _buildTableCell(
                  invoice.paymentStatus == PaymentStatus.paid
                      ? Text('—', style: TextStyle(color: Colors.grey[400]))
                      : Text(
                          '${invoice.currencySymbol} ${invoice.outstandingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: invoice.paymentStatus == PaymentStatus.partial
                                ? Colors.orange[700]
                                : Colors.red[700],
                          ),
                        ),
                ),
              ],
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
                    if (widget.filterType == 'Invoice') ...[
                    _buildActionButton(
                      Icons.payments_outlined,
                      invoice.paymentStatus == PaymentStatus.paid
                          ? Colors.green
                          : Colors.purple,
                      'Apply Payment',
                      () => _showApplyPaymentDialog(invoice),
                    ),
                    const SizedBox(width: 4),
                    ],
                    _buildActionButton(
                        Icons.copy_all_outlined, Colors.teal, 'Duplicate',
                        () => _showCloneDialog(invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.picture_as_pdf_outlined,
                        Colors.orange,
                        'PDF Preview',
                        () => InvoicePdfServices.previewPDF(
                            context, invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.download_outlined,
                        Colors.deepPurple,
                        'Download PDF',
                        () => PDFService.downloadPDF(context, invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.print_outlined, Colors.blueGrey, 'Print',
                        () => InvoicePdfServices.generatePDF(
                            context, invoice)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.delete_outline, Colors.red, 'Move to Trash',
                        widget.user.isAdmin() ? () => _softDelete(invoice) : null),
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

  Widget _buildDateCell(Invoice invoice) {
    final orderStr = invoice.date.toString().split(' ')[0];
    if (invoice.dueDate == null) {
      return Text(orderStr, style: const TextStyle(fontSize: 13));
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(invoice.dueDate!.year, invoice.dueDate!.month, invoice.dueDate!.day);
    final isOverdue = due.isBefore(today) && invoice.paymentStatus != PaymentStatus.paid;
    final isToday = due == today;
    final dueStr = invoice.dueDate!.toString().split(' ')[0];
    final dueColor = isOverdue
        ? Colors.red[700]!
        : isToday
            ? Colors.orange[700]!
            : Colors.grey[600]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(orderStr, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(dueStr, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: dueColor, fontWeight: (isOverdue || isToday) ? FontWeight.w600 : FontWeight.normal)),
            ),
            if (isOverdue || isToday) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: dueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: dueColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isOverdue ? 'Overdue' : 'Today',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: dueColor),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
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
      IconData icon, Color color, String tooltip, VoidCallback? onPressed) {
    final effectiveColor = onPressed != null ? color : Colors.grey[400]!;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: effectiveColor, size: 18),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    final Color color;
    final String label;
    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        label = 'Paid';
      case PaymentStatus.partial:
        color = Colors.orange;
        label = 'Partial';
      case PaymentStatus.unpaid:
        color = Colors.red;
        label = 'Unpaid';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha:0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Future<void> _showApplyPaymentDialog(Invoice invoice) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ApplyPaymentDialog(
        invoice: invoice,
        onPaymentRecorded: () {
          ref.read(invoicesProvider.notifier).refresh();
          _loadPage();
        },
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
                    color: Colors.red.withValues(alpha:0.1),
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


class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCleared;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onPicked,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onCleared,
                )
              : const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value != null ? formatter.format(value!) : 'Any',
          style: TextStyle(
            fontSize: 13,
            color: value != null ? Colors.black87 : Colors.black38,
          ),
        ),
      ),
    );
  }
}
