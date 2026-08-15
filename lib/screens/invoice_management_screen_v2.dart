import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/common/invoiso_colors.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/providers/invoice_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/services/export_service.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';
import 'package:invoiso/utils/error_handler.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/widgets/customer_info_button.dart';
import 'package:invoiso/utils/formatters.dart';

class InvoiceManagementScreenV2 extends ConsumerStatefulWidget {
  final Function(Invoice) onEditInvoice;
  final Function(Invoice, String) onCloneInvoice;
  final User user;
  final String filterType; // 'Invoice' | 'Quotation'

  const InvoiceManagementScreenV2({
    super.key,
    required this.onEditInvoice,
    required this.onCloneInvoice,
    required this.user,
    this.filterType = 'Invoice',
  });

  @override
  ConsumerState<InvoiceManagementScreenV2> createState() =>
      _InvoiceManagementScreenV2State();
}

class _InvoiceManagementScreenV2State
    extends ConsumerState<InvoiceManagementScreenV2> {
  int _currentPage = 0;
  int _pageSize = 10;
  String _searchQuery = '';
  bool _isLoadingPage = false;
  bool _isBulkLoading = false;
  bool _hidePaid = false;
  String _dueDateFilter =
      'all'; // 'all' | 'overdue' | 'due_today' | 'due_week' | 'due_month'
  String _paymentStatusFilterV2 = 'all'; // 'all' | 'paid' | 'partial' | 'unpaid'
  String _datePattern = 'dd/MM/yyyy';
  int _totalCount = 0;
  List<Invoice> _pageInvoices = [];
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _statsBarScrollController = ScrollController();
  Timer? _searchDebounce;

  /// Shared column widths used by both the header table and every row table so
  /// they always align pixel-perfectly.
  static const List<(String, String, Color)> _dueDateFilterOptions = [
    ('all', 'All Dues', Colors.grey),
    ('overdue', 'Overdue', Colors.red),
    ('due_today', 'Due Today', Colors.orange),
    ('due_week', 'Due This Week', Colors.blue),
    ('due_month', 'Due This Month', Colors.teal),
  ];

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadPage();
    _loadDateFormat();
  }

  Future<void> _loadDateFormat() async {
    final opt = await ref.read(settingsRepositoryProvider).getDateFormat();
    if (mounted) setState(() => _datePattern = opt.key);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _statsBarScrollController.dispose();
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
        ref.read(invoiceRepositoryProvider).getInvoicesPaginated(
          page: _currentPage,
          pageSize: _pageSize,
          searchQuery: _searchQuery,
          filterType: widget.filterType,
        ),
        ref.read(invoiceRepositoryProvider).getInvoiceCount(
          searchQuery: _searchQuery,
          filterType: widget.filterType,
        ),
      ]);
      if (mounted) {
        var pageInvoices = results[0] as List<Invoice>;
        if (_hidePaid) {
          // Keep Quotations; for Invoices only keep those with an outstanding balance
          pageInvoices = pageInvoices
              .where((inv) =>
                  inv.type != 'Invoice' ||
                  inv.outstandingBalance > InvoiceCalculator.moneyEpsilon)
              .toList();
        }
        if (_dueDateFilter != 'all') {
          pageInvoices = pageInvoices.where((inv) {
            if (inv.dueDate == null) return false;
            final today = InvoiceCalculator.dateOnly(DateTime.now());
            final due = InvoiceCalculator.dateOnly(inv.dueDate!);
            switch (_dueDateFilter) {
              case 'overdue':
                return InvoiceCalculator.isOverdue(
                  dueDate: inv.dueDate,
                  outstanding: inv.outstandingBalance,
                );
              case 'due_today':
                return due == today;
              case 'due_week':
                return !due.isBefore(today) &&
                    due.isBefore(today.add(const Duration(days: 7)));
              case 'due_month':
                return !due.isBefore(today) &&
                    due.isBefore(
                        DateTime(today.year, today.month + 1, today.day));
              default:
                return true;
            }
          }).toList();
        }
        // V2: additional payment-status filter (All / Paid / Partial /
        // Unpaid) — same client-side-on-the-loaded-page approach as the
        // existing hidePaid/dueDate filters above, for consistency.
        if (widget.filterType == 'Invoice' && _paymentStatusFilterV2 != 'all') {
          pageInvoices = pageInvoices.where((inv) {
            switch (_paymentStatusFilterV2) {
              case 'paid':
                return inv.paymentStatus == PaymentStatus.paid;
              case 'partial':
                return inv.paymentStatus == PaymentStatus.partial;
              case 'unpaid':
                return inv.paymentStatus == PaymentStatus.unpaid;
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
        AppError.show(context, 'Failed to load invoices: $e',
            onRetry: _loadPage);
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
          'Create a copy of Invoice #${invoice.invoiceNumber ?? invoice.id}\n(${invoice.customer.name}) as:',
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
      message: 'Move Invoice #${invoice.invoiceNumber ?? invoice.id} to trash?',
      confirmLabel: 'Move to Trash',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    await ref.read(invoiceRepositoryProvider).softDeleteInvoice(invoice.id);
    ref.read(invoicesProvider.notifier).refresh();
    await _loadPage();
    if (mounted) AppError.showSuccess(context, 'Invoice moved to trash.');
  }

  // ─── Toolbar actions ───────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    final fmt = DateFormat(_datePattern);
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
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
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
                        Text(
                          'Or filter by date range:',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      final invoices = await ref.read(invoiceRepositoryProvider).getInvoicesForExport(
        fromDate: exportAll ? null : fromDate,
        toDate: exportAll ? null : toDate,
        filterType: widget.filterType,
      );
      final path = await ExportService.exportInvoicesToCsv(invoices,
          type: widget.filterType);
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
    final deleted = await ref.read(invoiceRepositoryProvider).getDeletedInvoices();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _TrashDialog(
        deletedInvoices: deleted,
        datePattern: _datePattern,
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
        await ref.read(invoiceRepositoryProvider).softDeleteInvoice(id);
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
        AppError.showSuccess(context,
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
        fileName:
            'invoices_${DateFormat('yyyyMMdd').format(DateTime.now())}.zip',
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
              saveMode == 'zip'
                  ? Icons.folder_zip_outlined
                  : Icons.picture_as_pdf,
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
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 8),
              Text(
                '$done / ${selected.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ));

    try {
      final dateFmt = await BackendServices.settings.getDateFormat();
      final settings = await PDFService.fetchPdfSettings(datePattern: dateFmt.key);
      final String path;
      if (saveMode == 'zip') {
        path = await ExportService.exportInvoicesToZip(
          selected,
          zipSavePath!,
          onProgress: (done, _) => progress.value = done,
          settings: settings,
        );
      } else {
        path = await ExportService.exportInvoicesToPdfFolder(
          selected,
          onProgress: (done, _) => progress.value = done,
          outputDirectory: outputDir,
          settings: settings,
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

  static const int _maxBulkPdfExport = 100;

  Future<void> _showFilteredDownloadDialog() async {
    DateTime? fromDate;
    DateTime? toDate;
    final fromIdCtrl = TextEditingController();
    final toIdCtrl = TextEditingController();
    int filterMode = 0; // 0 = date, 1 = invoice number
    int matchCount = 0;
    bool counting = false;

    Future<int> fetchCount(StateSetter setS) async {
      setS(() => counting = true);
      try {
        return await ref.read(invoiceRepositoryProvider).countInvoicesForExport(
          fromDate: filterMode == 0 ? fromDate : null,
          toDate: filterMode == 0 ? toDate : null,
          fromId: filterMode == 1 ? int.tryParse(fromIdCtrl.text) : null,
          toId: filterMode == 1 ? int.tryParse(toIdCtrl.text) : null,
          filterType: widget.filterType,
        );
      } finally {
        setS(() => counting = false);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.filter_alt_outlined),
              SizedBox(width: 10),
              Text('Download PDFs by Filter'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        label: Text('By Date'),
                        icon: Icon(Icons.calendar_today_outlined, size: 16)),
                    ButtonSegment(
                        value: 1,
                        label: Text('By Invoice Number'),
                        icon: Icon(Icons.tag_outlined, size: 16)),
                  ],
                  selected: {filterMode},
                  onSelectionChanged: (v) async {
                    setS(() {
                      filterMode = v.first;
                      matchCount = 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (filterMode == 0) ...[
                  Row(children: [
                    Expanded(
                        child: _DatePickerField(
                      label: 'From date',
                      value: fromDate,
                      formatter: DateFormat('dd/MM/yyyy'),
                      onPicked: (d) {
                        setS(() {
                          fromDate = d;
                          matchCount = 0;
                        });
                      },
                      onCleared: () => setS(() {
                        fromDate = null;
                        matchCount = 0;
                      }),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _DatePickerField(
                      label: 'To date',
                      value: toDate,
                      formatter: DateFormat('dd/MM/yyyy'),
                      onPicked: (d) {
                        setS(() {
                          toDate = d;
                          matchCount = 0;
                        });
                      },
                      onCleared: () => setS(() {
                        toDate = null;
                        matchCount = 0;
                      }),
                    )),
                  ]),
                ] else ...[
                  Row(children: [
                    Expanded(
                        child: TextField(
                      controller: fromIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'From invoice #',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setS(() => matchCount = 0),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextField(
                      controller: toIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'To invoice #',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setS(() => matchCount = 0),
                    )),
                  ]),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  FilledButton.tonal(
                    onPressed: counting
                        ? null
                        : () async {
                            final c = await fetchCount(setS);
                            setS(() => matchCount = c);
                          },
                    child: counting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Check count'),
                  ),
                  const SizedBox(width: 12),
                  if (matchCount > 0)
                    Text(
                      matchCount > _maxBulkPdfExport
                          ? '$matchCount invoices — exceeds limit of $_maxBulkPdfExport'
                          : '$matchCount invoice${matchCount == 1 ? '' : 's'} match',
                      style: TextStyle(
                        color: matchCount > _maxBulkPdfExport
                            ? Colors.red
                            : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ]),
                if (matchCount > _maxBulkPdfExport)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Max $_maxBulkPdfExport PDFs per download. Narrow your filter.',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Save to Folder'),
              onPressed: matchCount > 0 && matchCount <= _maxBulkPdfExport
                  ? () => Navigator.pop(ctx, 'folder')
                  : null,
            ),
            FilledButton.icon(
              icon: const Icon(Icons.folder_zip_outlined),
              label: const Text('Save as ZIP'),
              onPressed: matchCount > 0 && matchCount <= _maxBulkPdfExport
                  ? () => Navigator.pop(ctx, 'zip')
                  : null,
            ),
          ],
        ),
      ),
    ).then((saveMode) async {
      if (saveMode == null || !mounted) return;

      final invoices = await ref.read(invoiceRepositoryProvider).getInvoicesForExport(
        fromDate: filterMode == 0 ? fromDate : null,
        toDate: filterMode == 0 ? toDate : null,
        fromId: filterMode == 1 ? int.tryParse(fromIdCtrl.text) : null,
        toId: filterMode == 1 ? int.tryParse(toIdCtrl.text) : null,
        filterType: widget.filterType,
      );

      if (invoices.isEmpty) {
        if (mounted) {
          AppError.show(context, 'No invoices found for the selected filter.');
        }
        return;
      }
      if (invoices.length > _maxBulkPdfExport) {
        if (mounted) {
          AppError.show(context,
              'Filter returned ${invoices.length} invoices — max is $_maxBulkPdfExport.');
        }
        return;
      }

      String? outputDir;
      String? zipSavePath;
      if (saveMode == 'folder') {
        outputDir = await FilePicker.platform
            .getDirectoryPath(dialogTitle: 'Choose folder to save PDFs');
        if (outputDir == null || !mounted) return;
      } else {
        zipSavePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save ZIP file',
          fileName:
              'invoices_${DateFormat('yyyyMMdd').format(DateTime.now())}.zip',
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(
                saveMode == 'zip'
                    ? Icons.folder_zip_outlined
                    : Icons.picture_as_pdf,
                color: Colors.orange),
            const SizedBox(width: 12),
            Text(saveMode == 'zip' ? 'Creating ZIP' : 'Generating PDFs'),
          ]),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, done, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Processing ${invoices.length} PDF${invoices.length == 1 ? '' : 's'}...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                    value: done / invoices.length,
                    backgroundColor: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Text('$done / ${invoices.length}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ),
      ));

      try {
        // Fetch PDF settings once for the entire batch.
        final dateFmt = await BackendServices.settings.getDateFormat();
        final settings = await PDFService.fetchPdfSettings(
          datePattern: dateFmt.key,
        );
        final String path;
        if (saveMode == 'zip') {
          path = await ExportService.exportInvoicesToZip(
            invoices,
            zipSavePath!,
            onProgress: (done, _) => progress.value = done,
            settings: settings,
          );
        } else {
          path = await ExportService.exportInvoicesToPdfFolder(
            invoices,
            onProgress: (done, _) => progress.value = done,
            outputDirectory: outputDir,
            settings: settings,
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
          AppError.show(context, 'Export failed: $e');
        }
      } finally {
        progress.dispose();
        if (mounted) setState(() => _isBulkLoading = false);
      }
    });

    fromIdCtrl.dispose();
    toIdCtrl.dispose();
  }

  Future<void> _bulkMarkAsPaid() async {
    final unpaid = _pageInvoices
        .where((inv) =>
            _selectedIds.contains(inv.id) &&
            inv.outstandingBalance > InvoiceCalculator.moneyEpsilon)
        .toList();
    final alreadyPaid = _selectedIds.length - unpaid.length;

    if (unpaid.isEmpty) {
      AppError.show(context, 'All selected invoices are already fully paid.');
      return;
    }

    final confirmed = await AppError.confirm(
      context,
      title: 'Mark as Paid',
      message:
          'Mark ${unpaid.length} invoice${unpaid.length == 1 ? '' : 's'} as fully paid?'
          '${alreadyPaid > 0 ? '\n($alreadyPaid already paid — will be skipped)' : ''}',
      confirmLabel: 'Mark as Paid',
      confirmColor: Colors.green,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isBulkLoading = true);
    try {
      final count = await ref.read(paymentRepositoryProvider).addPaymentBatch(
        invoices: unpaid,
        datePaid: DateTime.now(),
      );
      ref.read(invoicesProvider.notifier).refresh();
      await _loadPage();
      if (mounted) {
        AppError.showSuccess(
            context, '$count invoice${count == 1 ? '' : 's'} marked as paid.');
      }
    } catch (e) {
      if (mounted) AppError.show(context, 'Failed to mark as paid: $e');
    } finally {
      if (mounted) setState(() => _isBulkLoading = false);
    }
  }

  // ─── Pagination ────────────────────────────────────────────────────────────

  int get _totalPages => (_totalCount / _pageSize).ceil();

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => _buildV2(context);

  // ============================================================
  // V2 — flat / responsive layout. Reuses all v1 state, controllers,
  // and every action method (_loadPage, _softDelete, _showCloneDialog,
  // _exportCsv, bulk actions, _showApplyPaymentDialog, etc.) untouched.
  // New pieces:
  //  - the Invoice Number is now always rendered unconditionally next
  //    to the customer name in one primary block, instead of living in
  //    its own low-priority Flex column that could get squeezed to
  //    near-zero width once the fixed 360px actions column ate the
  //    remaining space on narrower screens (that's what was making it
  //    disappear).
  //  - the 8 per-row action icons collapse into a single overflow menu
  //    below the wide breakpoint (kept as 3 quick icons + menu above
  //    it), instead of a Table column that assumed 360px was always
  //    available.
  //  - Hide Paid / Due Date / the new Payment Status filter are now one
  //    "Filter" button opening a single dialog, instead of a permanent
  //    horizontal-scrolling strip of chips next to the search box.
  //  - a real LayoutBuilder breakpoint drives all of the above, plus
  //    which table columns show at all.
  // ============================================================

  static const List<Map<String, dynamic>> _paymentStatusFilterOptionsV2 = [
    {'value': 'all', 'label': 'All', 'color': Colors.grey},
    {'value': 'paid', 'label': 'Paid', 'color': Colors.green},
    {'value': 'partial', 'label': 'Partial', 'color': Colors.orange},
    {'value': 'unpaid', 'label': 'Unpaid', 'color': Colors.red},
  ];

  int get _activeFilterCountV2 =>
      (_hidePaid ? 1 : 0) +
      (_dueDateFilter != 'all' ? 1 : 0) +
      (_paymentStatusFilterV2 != 'all' ? 1 : 0);


  Future<void> _showFilterDialogV2() async {
    bool tempHidePaid = _hidePaid;
    String tempDue = _dueDateFilter;
    String tempStatus = _paymentStatusFilterV2;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Filter Invoices'),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hide fully paid invoices'),
                      value: tempHidePaid,
                      onChanged: (v) => setDialogState(() => tempHidePaid = v),
                      activeColor: Theme.of(dialogContext).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text('Payment status',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentStatusFilterOptionsV2.map((opt) {
                        final selected = tempStatus == opt['value'];
                        final color = opt['color'] as Color;
                        return ChoiceChip(
                          label: Text(opt['label'] as String),
                          selected: selected,
                          onSelected: (_) =>
                              setDialogState(() => tempStatus = opt['value'] as String),
                          selectedColor: color.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: selected ? color.withValues(alpha: 0.9) : null,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('Due date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dueDateFilterOptions.map((option) {
                        final selected = tempDue == option.$1;
                        return ChoiceChip(
                          label: Text(option.$2),
                          selected: selected,
                          onSelected: (_) => setDialogState(() => tempDue = option.$1),
                          selectedColor: option.$3.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: selected ? option.$3.withValues(alpha: 0.9) : null,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    tempHidePaid = false;
                    tempDue = 'all';
                    tempStatus = 'all';
                  });
                },
                child: const Text('Reset'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _hidePaid = tempHidePaid;
                    _dueDateFilter = tempDue;
                    _paymentStatusFilterV2 = tempStatus;
                    _currentPage = 0;
                  });
                  _loadPage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _searchFilterRowV2(bool isWide) {
    final searchField = TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search by Invoice ID or Customer Name…',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
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
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _currentPage = 0;
        });
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 400), _loadPage);
      },
    );

    final filterButton = widget.filterType != 'Invoice'
        ? const SizedBox.shrink()
        : Stack(
            clipBehavior: Clip.none,
            children: [
              OutlinedButton.icon(
                onPressed: _showFilterDialogV2,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Filter'),
              ),
              if (_activeFilterCountV2 > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$_activeFilterCountV2',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          );

    final statText = Text(
      'Total: $_totalCount   ·   Page ${_currentPage + 1}/${_totalPages > 0 ? _totalPages : 1}',
      style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: searchField)),
          const SizedBox(width: 12),
          filterButton,
          const Spacer(),
          statText,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        searchField,
        const SizedBox(height: 10),
        Row(
          children: [
            filterButton,
            const Spacer(),
            statText,
          ],
        ),
      ],
    );
  }

  Widget _bulkActionsBarV2() {
    final count = _selectedIds.length;
    return Container(
      key: const ValueKey('bulk_bar_v2'),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text('$count selected',
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          _buildBulkButton(
            icon: Icons.deselect,
            label: 'Deselect',
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
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
          _buildBulkButton(
            icon: Icons.payments_outlined,
            label: 'Mark Paid',
            color: Colors.green[300]!,
            onPressed: _isBulkLoading ? null : _bulkMarkAsPaid,
          ),
          _buildBulkButton(
            icon: Icons.table_chart_outlined,
            label: 'CSV',
            onPressed: _isBulkLoading ? null : _bulkExportCsv,
          ),
          _buildBulkButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDFs',
            onPressed: _isBulkLoading ? null : _bulkExportPdfs,
          ),
          if (widget.user.isAdmin())
            _buildBulkButton(
              icon: Icons.delete_outline,
              label: 'Trash',
              color: Colors.red[300]!,
              onPressed: _isBulkLoading ? null : _bulkSoftDelete,
            ),
        ],
      ),
    );
  }

  // ── Row action menu (used for every action beyond the wide-only quick
  // icons, and for ALL actions once collapsed on narrow screens) ──
  // isWide: on wide screens View/Edit/Apply Payment/PDF Preview/Download/
  // Print are all already visible as quick icons, so the overflow menu
  // only needs to carry Duplicate + Delete. On narrow screens, none of
  // those are visible, so the menu carries all of them.
  List<PopupMenuEntry<String>> _rowActionMenuItemsV2(Invoice invoice, bool isWide) {
    return [
      if (!isWide) ...[
        const PopupMenuItem(value: 'view', child: _MenuRow(Icons.visibility_outlined, 'View', Colors.green)),
        const PopupMenuItem(value: 'edit', child: _MenuRow(Icons.edit_outlined, 'Edit', Colors.blue)),
        if (widget.filterType == 'Invoice')
          PopupMenuItem(
            value: 'pay',
            child: _MenuRow(Icons.payments_outlined, 'Apply Payment',
                invoice.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.purple),
          ),
      ],
      const PopupMenuItem(value: 'duplicate', child: _MenuRow(Icons.copy_all_outlined, 'Duplicate', Colors.teal)),
      if (!isWide) ...[
        const PopupMenuItem(
            value: 'preview', child: _MenuRow(Icons.picture_as_pdf_outlined, 'PDF Preview', Colors.orange)),
        const PopupMenuItem(
            value: 'download', child: _MenuRow(Icons.download_outlined, 'Download PDF', Colors.deepPurple)),
        const PopupMenuItem(value: 'print', child: _MenuRow(Icons.print_outlined, 'Print', Colors.blueGrey)),
      ],
      if (widget.user.isAdmin())
        const PopupMenuItem(
            value: 'delete', child: _MenuRow(Icons.delete_outline, 'Move to Trash', Colors.red)),
    ];
  }

  void _handleRowActionV2(String action, Invoice invoice) {
    switch (action) {
      case 'view':
        InvoicePdfServices.showInvoiceDetails(context, invoice);
      case 'edit':
        widget.onEditInvoice(invoice);
      case 'pay':
        _showApplyPaymentDialog(invoice);
      case 'duplicate':
        _showCloneDialog(invoice);
      case 'preview':
        InvoicePdfServices.previewPDF(context, invoice);
      case 'download':
        PDFService.downloadPDF(context, invoice);
      case 'print':
        InvoicePdfServices.generatePDF(context, invoice);
      case 'delete':
        if (widget.user.isAdmin()) _softDelete(invoice);
    }
  }

  Widget _rowActionsV2(Invoice invoice, bool isWide) {
    final menu = PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'More actions',
      padding: EdgeInsets.zero,
      onSelected: (action) => _handleRowActionV2(action, invoice),
      itemBuilder: (ctx) => _rowActionMenuItemsV2(invoice, isWide),
    );
    if (!isWide) return menu;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildActionButton(Icons.visibility_outlined, Colors.green, 'View',
            () => InvoicePdfServices.showInvoiceDetails(context, invoice)),
        _buildActionButton(
            Icons.edit_outlined, Colors.blue, 'Edit', () => widget.onEditInvoice(invoice)),
        if (widget.filterType == 'Invoice')
          _buildActionButton(
            Icons.payments_outlined,
            invoice.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.purple,
            'Apply Payment',
            () => _showApplyPaymentDialog(invoice),
          ),
        _buildActionButton(Icons.picture_as_pdf_outlined, Colors.orange, 'PDF Preview',
            () => InvoicePdfServices.previewPDF(context, invoice)),
        _buildActionButton(Icons.download_outlined, Colors.deepPurple, 'Download PDF',
            () => PDFService.downloadPDF(context, invoice)),
        _buildActionButton(Icons.print_outlined, Colors.blueGrey, 'Print',
            () => InvoicePdfServices.generatePDF(context, invoice)),
        menu,
      ],
    );
  }

  Widget _tableHeaderRowV2(bool isWide) {
    TextStyle style = const TextStyle(
        color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.4);
    return Container(
      decoration: BoxDecoration(
        gradient: InvoiceManagementScreenColors.topBarBackgroundGradientColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Checkbox(
              value: _isAllPageSelected,
              tristate: _isSomePageSelected && !_isAllPageSelected,
              onChanged: (_) => _toggleSelectAll(),
              activeColor: Colors.white,
              checkColor: Theme.of(context).primaryColor,
              side: const BorderSide(color: Colors.white70, width: 2),
            ),
          ),
          SizedBox(width: 60, child: Text('Sl No', style: style)),
          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Invoice / Customer', style: style))),
          if (widget.filterType == 'Invoice' && isWide)
            Expanded(child: Text('Title', style: style)),
          SizedBox(width: 110, child: Text('Date', style: style)),
          if (isWide) SizedBox(width: 56, child: Text('Items', style: style)),
          Expanded(child: Text('Total', style: style)),
          if (widget.filterType == 'Invoice') ...[
            SizedBox(width: 76, child: Text('Status', style: style)),
            Expanded(child: Text('Outstanding', style: style)),
          ],
          SizedBox(width: isWide ? 300 : 48, child: Text('Actions', style: style)),
        ],
      ),
    );
  }

  Widget _invoiceRowV2(Invoice invoice, int index, bool isEven, bool isWide) {
    final isSelected = _selectedIds.contains(invoice.id);
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
            : (isEven
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surfaceContainer),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          left: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleOne(invoice.id),
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$index',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ),
            ),
          ),
          // Invoice number is ALWAYS rendered here, unconditionally —
          // this used to live in its own separate low-priority Flex
          // column that could be squeezed to near-zero width once the
          // fixed-width actions column ate the remaining space.
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('#${invoice.invoiceNumber ?? invoice.id}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(invoice.customer.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 2),
                      CustomerInfoButton(customer: invoice.customer),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.filterType == 'Invoice' && isWide)
            Expanded(
              child: Text(invoice.invoiceTitle ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          SizedBox(width: 110, child: _buildDateCell(invoice)),
          if (isWide)
            SizedBox(
              width: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${invoice.items.length}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                ),
              ),
            ),
          Expanded(
            child: Text(
              '${invoice.currencySymbol} ${invoice.total.toStringAsFixed(2)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          if (widget.filterType == 'Invoice') ...[
            SizedBox(
              width: 76,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildPaymentStatusChip(invoice.paymentStatus),
              ),
            ),
            Expanded(
              child: invoice.paymentStatus == PaymentStatus.paid
                  ? Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : Text(
                      '${invoice.currencySymbol} ${invoice.outstandingBalance.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: invoice.paymentStatus == PaymentStatus.partial
                            ? Colors.orange[700]
                            : Colors.red[700],
                      ),
                    ),
            ),
          ],
          SizedBox(width: isWide ? 300 : 48, child: _rowActionsV2(invoice, isWide)),
        ],
      ),
    );
  }

  Widget _paginationV2(bool isWide) {
    final left = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows per page:',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _pageSize,
          underline: const SizedBox(),
          items: [10, 25, 50, 100].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
          onChanged: (n) {
            if (n == null) return;
            setState(() {
              _pageSize = n;
              _currentPage = 0;
            });
            _loadPage();
          },
        ),
      ],
    );

    final right = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _currentPage > 0
              ? () {
                  setState(() => _currentPage--);
                  _loadPage();
                }
              : null,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const Text('Previous'),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          ),
          child: Text('Page ${_currentPage + 1} of ${_totalPages > 0 ? _totalPages : 1}',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: (_currentPage + 1 < _totalPages)
              ? () {
                  setState(() => _currentPage++);
                  _loadPage();
                }
              : null,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: const Text('Next'),
        ),
      ],
    );

    if (isWide) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [left, right]);
    }
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [left, right],
    );
  }

  Widget _emptyStateV2() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 72, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No ${widget.filterType.toLowerCase()}s found'
                : 'No results for "$_searchQuery"',
            style: TextStyle(
                fontSize: 17, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isEmpty
                ? 'Create your first ${widget.filterType.toLowerCase()} to see it here'
                : 'Try adjusting your search or filters',
            style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _headerBarV2(bool isWide) {
    if (isWide) {
      return [
        if (_isBulkLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          ),
        IconButton(
          icon: const Icon(Icons.download_for_offline_outlined),
          onPressed: _showFilteredDownloadDialog,
          tooltip: 'Download PDFs by date or invoice range',
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
      ];
    }

    // Narrow: collapse everything except a live-loading spinner into a
    // single overflow menu, same "move to 3-dot" treatment as the
    // per-row actions.
    return [
      if (_isBulkLoading)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          switch (value) {
            case 'download':
              _showFilteredDownloadDialog();
            case 'csv':
              _exportCsv();
            case 'trash':
              _showTrashDialog();
            case 'refresh':
              _currentPage = 0;
              _loadPage();
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
              value: 'download',
              child: _MenuRow(Icons.download_for_offline_outlined, 'Download PDFs by range', Colors.blueGrey)),
          const PopupMenuItem(
              value: 'csv', child: _MenuRow(Icons.file_download_outlined, 'Export all to CSV', Colors.blueGrey)),
          if (widget.user.isAdmin())
            const PopupMenuItem(value: 'trash', child: _MenuRow(Icons.delete_sweep_outlined, 'Trash', Colors.red)),
          const PopupMenuItem(value: 'refresh', child: _MenuRow(Icons.refresh, 'Refresh', Colors.blueGrey)),
        ],
      ),
    ];
  }

  Widget _buildV2(BuildContext context) {
    return LayoutBuilder(builder: (context, outerConstraints) {
      final isWide = outerConstraints.maxWidth >= 1000;

      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey[50],
        appBar: AppBar(
          title: Text('${widget.filterType} Management'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          actions: [..._headerBarV2(isWide), const SizedBox(width: 8)],
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              padding: const EdgeInsets.all(20),
              child: _searchFilterRowV2(isWide),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedIds.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('no_selection'))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _bulkActionsBarV2(),
                    ),
            ),
            const SizedBox(height: 16),
            _isLoadingPage
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: _pageInvoices.isEmpty
                        ? _emptyStateV2()
                        : Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthWide),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Card(
                                  elevation: 2,
                                  shadowColor: Colors.black.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      _tableHeaderRowV2(isWide),
                                      ..._pageInvoices.asMap().entries.map((entry) {
                                        final invoice = entry.value;
                                        final index = entry.key;
                                        final globalIndex = (_currentPage * _pageSize) + index + 1;
                                        return _invoiceRowV2(invoice, globalIndex, index.isEven, isWide);
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
            if (_pageInvoices.isNotEmpty)
              Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: _paginationV2(isWide),
              ),
          ],
        ),
      );
    });
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
              color: onPressed != null
                  ? c.withValues(alpha: 0.5)
                  : Colors.white24),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildDateCell(Invoice invoice) {
    final orderStr =
        AppFormatters.formatShortDate(invoice.date, pattern: _datePattern);
    if (invoice.dueDate == null) {
      return Text(orderStr, style: const TextStyle(fontSize: 13));
    }
    final today = InvoiceCalculator.dateOnly(DateTime.now());
    final due = InvoiceCalculator.dateOnly(invoice.dueDate!);
    final isOverdue = InvoiceCalculator.isOverdue(
      dueDate: invoice.dueDate,
      outstanding: invoice.outstandingBalance,
    );
    final isToday = due == today;
    final dueStr =
        AppFormatters.formatShortDate(invoice.dueDate, pattern: _datePattern);
    final dueColor = isOverdue
        ? Colors.red[700]!
        : isToday
            ? Colors.orange[700]!
            : Theme.of(context).colorScheme.onSurfaceVariant;
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
              child: Text(dueStr,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: dueColor,
                      fontWeight: (isOverdue || isToday)
                          ? FontWeight.w600
                          : FontWeight.normal)),
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
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: dueColor),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, String tooltip, VoidCallback? onPressed) {
    final effectiveColor = onPressed != null ? color : Theme.of(context).colorScheme.onSurfaceVariant;
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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

// V2: small icon+label row used inside PopupMenuItems for the row-actions
// and header-actions overflow menus, so every menu entry looks consistent.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Trash Dialog
class _TrashDialog extends ConsumerStatefulWidget {
  final List<Invoice> deletedInvoices;
  final VoidCallback onRestored;
  final String datePattern;

  const _TrashDialog(
      {required this.deletedInvoices,
      required this.onRestored,
      required this.datePattern});

  @override
  ConsumerState<_TrashDialog> createState() => _TrashDialogState();
}

class _TrashDialogState extends ConsumerState<_TrashDialog> {
  late List<Invoice> _invoices;

  @override
  void initState() {
    super.initState();
    _invoices = List.from(widget.deletedInvoices);
  }

  Future<void> _restore(Invoice invoice) async {
    await ref.read(invoiceRepositoryProvider).restoreInvoice(invoice.id);
    setState(() => _invoices.removeWhere((i) => i.id == invoice.id));
    widget.onRestored();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invoice restored.'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _permanentDelete(Invoice invoice) async {
    final confirmed = await AppError.confirm(
      context,
      title: 'Permanently Delete',
      message:
          'Permanently delete Invoice #${invoice.invoiceNumber ?? invoice.id}? This cannot be undone.',
    );
    if (!confirmed) return;
    await ref.read(invoiceRepositoryProvider).permanentDeleteInvoice(invoice.id);
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
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text('Trash',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_invoices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('Trash is empty',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
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
                      leading:
                          Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      title: Text('#${inv.invoiceNumber ?? inv.id} — ${inv.customer.name}'),
                      subtitle: Row(
                        children: [
                          Text(AppFormatters.formatShortDate(inv.date,
                              pattern: widget.datePattern)),
                          SizedBox(width: 10,),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4),
                            decoration: BoxDecoration(
                              color: inv.type == 'Invoice'
                                  ? Colors.indigo
                                  .withValues(alpha: 0.1)
                                  : Colors.orange
                                  .withValues(alpha: 0.1),
                              borderRadius:
                              BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                inv.type == 'Invoice'
                                    ? Colors.indigo
                                    .withValues(
                                    alpha: 0.35)
                                    : Colors.orange
                                    .withValues(
                                    alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              inv.type,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                inv.type == 'Invoice'
                                    ? Colors.indigo[700]
                                    : Colors.orange[800],
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        ],
                      ),
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
                            icon: const Icon(Icons.delete_forever, size: 16),
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
            color: value != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
