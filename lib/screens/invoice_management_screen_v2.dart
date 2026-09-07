import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/common/invoiso_colors.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/customer.dart';
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
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  bool _isLoadingPage = false;
  bool _isBulkLoading = false;
  bool _hidePaid = false;
  String _dueDateFilter =
      'all'; // 'all' | 'overdue' | 'due_today' | 'due_week' | 'due_month'
  String _paymentStatusFilterV2 = 'all'; // 'all' | 'paid' | 'partial' | 'unpaid'
  DateTime? _invoiceDateFrom;
  DateTime? _invoiceDateTo;
  int? _idRangeFrom;
  int? _idRangeTo;
  String _sortField = 'id'; // 'id' | 'date' | 'customer_name'
  bool _sortAscending = false;
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
  static const List<(String, Color)> _dueDateFilterOptions = [
    ('all', Colors.grey),
    ('overdue', Colors.red),
    ('due_today', Colors.orange),
    ('due_week', Colors.blue),
    ('due_month', Colors.teal),
  ];

  static String _dueDateFilterLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'overdue' => l10n.invoiceMgmtOverdueBadge,
      'due_today' => l10n.invoiceMgmtDueTodayLabel,
      'due_week' => l10n.invoiceMgmtDueWeekLabel,
      'due_month' => l10n.invoiceMgmtDueMonthLabel,
      _ => l10n.invoiceMgmtDueAllLabel,
    };
  }

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
          orderBy: _sortField,
          orderAscending: _sortAscending,
          customerId: _selectedCustomerId,
        ),
        ref.read(invoiceRepositoryProvider).getInvoiceCount(
          searchQuery: _searchQuery,
          filterType: widget.filterType,
          customerId: _selectedCustomerId,
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
        if (_invoiceDateFrom != null || _invoiceDateTo != null) {
          pageInvoices = pageInvoices.where((inv) {
            final d = InvoiceCalculator.dateOnly(inv.date);
            if (_invoiceDateFrom != null &&
                d.isBefore(InvoiceCalculator.dateOnly(_invoiceDateFrom!))) {
              return false;
            }
            if (_invoiceDateTo != null &&
                d.isAfter(InvoiceCalculator.dateOnly(_invoiceDateTo!))) {
              return false;
            }
            return true;
          }).toList();
        }
        if (_idRangeFrom != null || _idRangeTo != null) {
          pageInvoices = pageInvoices.where((inv) {
            final n = int.tryParse(
                (inv.invoiceNumber ?? inv.id).replaceAll(RegExp(r'\D'), ''));
            if (n == null) return false;
            if (_idRangeFrom != null && n < _idRangeFrom!) return false;
            if (_idRangeTo != null && n > _idRangeTo!) return false;
            return true;
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
        AppError.show(
            context, AppLocalizations.of(context)!.invoiceMgmtFailedToLoadMessage(e.toString()),
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
        title: Row(
          children: [
            const Icon(Icons.copy_all, color: Colors.teal),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.dashboardDuplicateInvoiceTitle),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.dashboardDuplicateInvoiceBody(
              invoice.invoiceNumber ?? invoice.id, invoice.customer.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Quotation'),
            icon: const Icon(Icons.request_quote_outlined),
            label: Text(AppLocalizations.of(context)!.labelQuotation),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.receipt),
            label: Text(AppLocalizations.of(context)!.labelInvoice),
          ),
        ],
      ),
    );
    if (type != null) {
      widget.onCloneInvoice(invoice, type);
    }
  }

  Future<void> _softDelete(Invoice invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppError.confirm(
      context,
      title: l10n.invoiceMgmtMoveToTrashTitle,
      message: l10n.invoiceMgmtMoveToTrashBody(invoice.invoiceNumber ?? invoice.id),
      confirmLabel: l10n.invoiceMgmtMoveToTrashTitle,
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    await ref.read(invoiceRepositoryProvider).softDeleteInvoice(invoice.id);
    ref.read(invoicesProvider.notifier).refresh();
    await _loadPage();
    if (mounted) {
      AppError.showSuccess(context, AppLocalizations.of(context)!.invoiceMgmtMovedToTrashMessage);
    }
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
              Text(AppLocalizations.of(context)!
                  .invoiceMgmtExportToCsvTitle('${widget.filterType}s')),
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
                        Text(AppLocalizations.of(context)!.invoiceMgmtExportAllRecordsLabel,
                            style: const TextStyle(
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
                          AppLocalizations.of(context)!.invoiceMgmtFilterByDateRangeLabel,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                label: AppLocalizations.of(context)!.invoiceMgmtFromDateLabel,
                                value: fromDate,
                                formatter: fmt,
                                onPicked: (d) => setS(() => fromDate = d),
                                onCleared: () => setS(() => fromDate = null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DatePickerField(
                                label: AppLocalizations.of(context)!.invoiceMgmtToDateLabel,
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
                          Text(
                            AppLocalizations.of(context)!.invoiceMgmtDateRangeInvalidMessage,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
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
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton.icon(
              onPressed: (!exportAll &&
                      fromDate != null &&
                      toDate != null &&
                      toDate!.isBefore(fromDate!))
                  ? null
                  : () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.download, size: 18),
              label: Text(AppLocalizations.of(context)!.actionExport),
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
      if (path == null) return; // user cancelled the save dialog
      if (mounted) {
        AppError.showSuccess(context,
            AppLocalizations.of(context)!.invoiceMgmtExportedRecordsMessage(invoices.length, path));
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        AppError.show(context, AppLocalizations.of(context)!.invoiceMgmtExportFailedMessage(e.toString()));
      }
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
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedIds.length;
    final confirmed = await AppError.confirm(
      context,
      title: l10n.invoiceMgmtMoveToTrashTitle,
      message: l10n.invoiceMgmtBulkMoveToTrashBody(count),
      confirmLabel: l10n.invoiceMgmtMoveToTrashTitle,
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
            context, AppLocalizations.of(context)!.invoiceMgmtBulkMovedToTrashMessage(count));
      }
    } catch (e) {
      if (mounted) {
        AppError.show(context, AppLocalizations.of(context)!.invoiceMgmtBulkDeleteFailedMessage(e.toString()));
      }
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
      if (path == null) return; // user cancelled the save dialog
      if (mounted) {
        AppError.showSuccess(context,
            AppLocalizations.of(context)!.invoiceMgmtBulkExportedCsvMessage(selected.length));
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        AppError.show(context, AppLocalizations.of(context)!.invoiceMgmtCsvExportFailedMessage(e.toString()));
      }
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
            Text(AppLocalizations.of(context)!.invoiceMgmtDownloadPdfsTitle),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.invoiceMgmtSavePdfsPromptMessage(selected.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_outlined),
            label: Text(AppLocalizations.of(context)!.invoiceMgmtSaveToFolderLabel),
            onPressed: () => Navigator.pop(ctx, 'folder'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.folder_zip_outlined),
            label: Text(AppLocalizations.of(context)!.invoiceMgmtSaveAsZipLabel),
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
        dialogTitle: AppLocalizations.of(context)!.invoiceMgmtChooseFolderDialogTitle,
      );
      if (outputDir == null || !mounted) return;
    } else {
      zipSavePath = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.invoiceMgmtSaveZipDialogTitle,
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
            Text(saveMode == 'zip'
                ? AppLocalizations.of(context)!.invoiceMgmtCreatingZipLabel
                : AppLocalizations.of(context)!.invoiceMgmtGeneratingPdfsLabel),
          ],
        ),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, done, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.invoiceMgmtProcessingPdfsMessage(selected.length),
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
        AppError.showSuccess(context, AppLocalizations.of(context)!.invoiceMgmtSavedToMessage(path));
        await OpenFile.open(path);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppError.show(context, AppLocalizations.of(context)!.invoiceMgmtPdfExportFailedMessage(e.toString()));
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
          title: Row(
            children: [
              const Icon(Icons.filter_alt_outlined),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.invoiceMgmtDownloadByFilterTitle),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                        value: 0,
                        label: Text(AppLocalizations.of(context)!.invoiceMgmtByDateLabel),
                        icon: const Icon(Icons.calendar_today_outlined, size: 16)),
                    ButtonSegment(
                        value: 1,
                        label: Text(AppLocalizations.of(context)!.invoiceMgmtByInvoiceNumberLabel),
                        icon: const Icon(Icons.tag_outlined, size: 16)),
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
                      label: AppLocalizations.of(context)!.invoiceMgmtFromDateLabel,
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
                      label: AppLocalizations.of(context)!.invoiceMgmtToDateLabel,
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
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.invoiceMgmtFromInvoiceNumberLabel,
                          border: const OutlineInputBorder()),
                      onChanged: (_) => setS(() => matchCount = 0),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextField(
                      controller: toIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.invoiceMgmtToInvoiceNumberLabel,
                          border: const OutlineInputBorder()),
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
                        : Text(AppLocalizations.of(context)!.invoiceMgmtCheckCountLabel),
                  ),
                  const SizedBox(width: 12),
                  if (matchCount > 0)
                    Text(
                      matchCount > _maxBulkPdfExport
                          ? AppLocalizations.of(context)!.invoiceMgmtInvoicesExceedLimitMessage(
                              matchCount, _maxBulkPdfExport)
                          : AppLocalizations.of(context)!.invoiceMgmtInvoicesMatchMessage(matchCount),
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
                      AppLocalizations.of(context)!
                          .invoiceMgmtMaxPdfsPerDownloadMessage(_maxBulkPdfExport),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.actionCancel)),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_outlined),
              label: Text(AppLocalizations.of(context)!.invoiceMgmtSaveToFolderLabel),
              onPressed: matchCount > 0 && matchCount <= _maxBulkPdfExport
                  ? () => Navigator.pop(ctx, 'folder')
                  : null,
            ),
            FilledButton.icon(
              icon: const Icon(Icons.folder_zip_outlined),
              label: Text(AppLocalizations.of(context)!.invoiceMgmtSaveAsZipLabel),
              onPressed: matchCount > 0 && matchCount <= _maxBulkPdfExport
                  ? () => Navigator.pop(ctx, 'zip')
                  : null,
            ),
          ],
        ),
      ),
    ).then((saveMode) async {
      if (saveMode == null || !mounted) return;
      final l10n = AppLocalizations.of(context)!;

      final invoices = await ref.read(invoiceRepositoryProvider).getInvoicesForExport(
        fromDate: filterMode == 0 ? fromDate : null,
        toDate: filterMode == 0 ? toDate : null,
        fromId: filterMode == 1 ? int.tryParse(fromIdCtrl.text) : null,
        toId: filterMode == 1 ? int.tryParse(toIdCtrl.text) : null,
        filterType: widget.filterType,
      );

      if (invoices.isEmpty) {
        if (mounted) {
          AppError.show(context, l10n.invoiceMgmtNoInvoicesForFilterMessage);
        }
        return;
      }
      if (invoices.length > _maxBulkPdfExport) {
        if (mounted) {
          AppError.show(
              context, l10n.invoiceMgmtFilterExceedsLimitMessage(invoices.length, _maxBulkPdfExport));
        }
        return;
      }

      String? outputDir;
      String? zipSavePath;
      if (saveMode == 'folder') {
        outputDir = await FilePicker.platform.getDirectoryPath(
            dialogTitle: l10n.invoiceMgmtChooseFolderDialogTitle);
        if (outputDir == null || !mounted) return;
      } else {
        zipSavePath = await FilePicker.platform.saveFile(
          dialogTitle: l10n.invoiceMgmtSaveZipDialogTitle,
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
            Text(saveMode == 'zip'
                ? l10n.invoiceMgmtCreatingZipLabel
                : l10n.invoiceMgmtGeneratingPdfsLabel),
          ]),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, done, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.invoiceMgmtProcessingPdfsMessage(invoices.length)),
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
          AppError.showSuccess(context, l10n.invoiceMgmtSavedToMessage(path));
          await OpenFile.open(path);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          AppError.show(context, l10n.invoiceMgmtExportFailedMessage(e.toString()));
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
    final l10n = AppLocalizations.of(context)!;

    if (unpaid.isEmpty) {
      AppError.show(context, l10n.invoiceMgmtAllAlreadyPaidMessage);
      return;
    }

    final confirmed = await AppError.confirm(
      context,
      title: l10n.invoiceMgmtMarkAsPaidTitle,
      message: l10n.invoiceMgmtMarkAsPaidBody(unpaid.length) +
          (alreadyPaid > 0 ? l10n.invoiceMgmtAlreadyPaidNoteMessage(alreadyPaid) : ''),
      confirmLabel: l10n.invoiceMgmtMarkAsPaidTitle,
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
            context, AppLocalizations.of(context)!.invoiceMgmtMarkedAsPaidMessage(count));
      }
    } catch (e) {
      if (mounted) {
        AppError.show(context, AppLocalizations.of(context)!.invoiceMgmtMarkAsPaidFailedMessage(e.toString()));
      }
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
    {'value': 'all', 'color': Colors.grey},
    {'value': 'paid', 'color': Colors.green},
    {'value': 'partial', 'color': Colors.orange},
    {'value': 'unpaid', 'color': Colors.red},
  ];

  static String _paymentStatusFilterLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'paid' => l10n.paymentStatusPaid,
      'partial' => l10n.paymentStatusPartial,
      'unpaid' => l10n.paymentStatusUnpaid,
      _ => l10n.invoiceMgmtStatusAllLabel,
    };
  }

  // Deliberately separate from _showFilterDialogV2 — picking a customer is
  // its own control, not one more field inside the Filter dialog.
  Future<void> _pickCustomerFilterV2() async {
    final results = await Future.wait([
      ref.read(customerRepositoryProvider).getAllCustomers(),
      ref.read(invoiceRepositoryProvider).getCustomersWithInvoices(filterType: widget.filterType),
    ]);
    final allCustomers = results[0] as List<Customer>;
    final invoiceCustomers = results[1] as List<({String id, String name})>;
    final byId = {for (final c in allCustomers) c.id: c};
    // Customers typed directly on an invoice without being saved to the
    // Customers list still get a real (random) customer_id on the invoice —
    // show them too, using the invoice's snapshotted name, instead of
    // silently dropping anything that isn't a saved Customer record.
    final savedIds = byId.keys.toSet();
    final customers = invoiceCustomers.map((ic) {
      return byId[ic.id] ??
          Customer(
            id: ic.id,
            name: ic.name.isEmpty ? 'Unknown' : ic.name,
            email: '',
            phone: '',
            address: '',
            gstin: '',
          );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (!mounted) return;
    final selected = await showDialog<Customer?>(
      context: context,
      builder: (dialogContext) {
        String query = '';
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          final filtered = query.isEmpty
              ? customers
              : customers
                  .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Filter by Customer'),
            content: SizedBox(
              width: 380,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search customers…',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setDialogState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No customers found'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final c = filtered[i];
                              final isSaved = savedIds.contains(c.id);
                              return ListTile(
                                title: Text(c.name),
                                subtitle: !isSaved
                                    ? const Text('Not saved as a customer')
                                    : c.businessName.isNotEmpty
                                        ? Text(c.businessName)
                                        : null,
                                onTap: () => Navigator.pop(dialogContext, c),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        });
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedCustomerId = selected.id;
      _selectedCustomerName = selected.name;
      _currentPage = 0;
    });
    _loadPage();
  }

  void _clearCustomerFilterV2() {
    setState(() {
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _currentPage = 0;
    });
    _loadPage();
  }

  int get _activeFilterCountV2 =>
      (_hidePaid ? 1 : 0) +
      (_dueDateFilter != 'all' ? 1 : 0) +
      (_paymentStatusFilterV2 != 'all' ? 1 : 0) +
      (_invoiceDateFrom != null || _invoiceDateTo != null ? 1 : 0) +
      (_idRangeFrom != null || _idRangeTo != null ? 1 : 0);


  Future<void> _showFilterDialogV2() async {
    bool tempHidePaid = _hidePaid;
    String tempDue = _dueDateFilter;
    String tempStatus = _paymentStatusFilterV2;
    DateTime? tempDateFrom = _invoiceDateFrom;
    DateTime? tempDateTo = _invoiceDateTo;
    final idFromCtrl =
        TextEditingController(text: _idRangeFrom?.toString() ?? '');
    final idToCtrl =
        TextEditingController(text: _idRangeTo?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)!.invoiceMgmtFilterInvoicesTitle),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.invoiceMgmtHideFullyPaidLabel),
                      value: tempHidePaid,
                      onChanged: (v) => setDialogState(() => tempHidePaid = v),
                      activeColor: Theme.of(dialogContext).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.invoiceMgmtPaymentStatusLabel,
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
                          label: Text(_paymentStatusFilterLabel(
                              AppLocalizations.of(context)!, opt['value'] as String)),
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
                    Text(AppLocalizations.of(context)!.invoiceMgmtDueDateLabel,
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
                          label: Text(_dueDateFilterLabel(AppLocalizations.of(context)!, option.$1)),
                          selected: selected,
                          onSelected: (_) => setDialogState(() => tempDue = option.$1),
                          selectedColor: option.$2.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: selected ? option.$2.withValues(alpha: 0.9) : null,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.invoiceMgmtInvoiceDateRangeLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _DatePickerField(
                        label: AppLocalizations.of(context)!.invoiceMgmtFromDateLabel,
                        value: tempDateFrom,
                        formatter: DateFormat(_datePattern),
                        onPicked: (d) => setDialogState(() => tempDateFrom = d),
                        onCleared: () => setDialogState(() => tempDateFrom = null),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _DatePickerField(
                        label: AppLocalizations.of(context)!.invoiceMgmtToDateLabel,
                        value: tempDateTo,
                        formatter: DateFormat(_datePattern),
                        onPicked: (d) => setDialogState(() => tempDateTo = d),
                        onCleared: () => setDialogState(() => tempDateTo = null),
                      )),
                    ]),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.invoiceMgmtInvoiceNumberRangeLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: TextField(
                        controller: idFromCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.invoiceMgmtFromHashLabel,
                            border: const OutlineInputBorder()),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                        controller: idToCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.invoiceMgmtToHashLabel,
                            border: const OutlineInputBorder()),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    tempHidePaid = false;
                    tempDue = 'all';
                    tempStatus = 'all';
                    tempDateFrom = null;
                    tempDateTo = null;
                    idFromCtrl.clear();
                    idToCtrl.clear();
                  });
                },
                child: Text(AppLocalizations.of(context)!.actionReset),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(AppLocalizations.of(context)!.actionCancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      setState(() {
                        _hidePaid = tempHidePaid;
                        _dueDateFilter = tempDue;
                        _paymentStatusFilterV2 = tempStatus;
                        _invoiceDateFrom = tempDateFrom;
                        _invoiceDateTo = tempDateTo;
                        _idRangeFrom = int.tryParse(idFromCtrl.text);
                        _idRangeTo = int.tryParse(idToCtrl.text);
                        _currentPage = 0;
                      });
                      _loadPage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.actionApply),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }

  // Sort is a separate button/dialog from Filter — different concern
  // (ordering vs narrowing the result set), and applies to both Invoices
  // and Quotations alike (unlike Filter, which is Invoice-only).
  static const List<(String, bool, IconData)> _sortOptionsV2 = [
    ('id', false, Icons.fiber_new_outlined),
    ('id', true, Icons.history_outlined),
    ('date', false, Icons.calendar_today_outlined),
    ('date', true, Icons.calendar_today_outlined),
    ('customer_name', true, Icons.sort_by_alpha_outlined),
    ('customer_name', false, Icons.sort_by_alpha_outlined),
  ];

  static String _sortOptionLabel(AppLocalizations l10n, String field, bool asc) {
    return switch ((field, asc)) {
      ('id', false) => l10n.invoiceMgmtSortRecentlyAdded,
      ('id', true) => l10n.invoiceMgmtSortOldestAdded,
      ('date', false) => l10n.invoiceMgmtSortDateNewest,
      ('date', true) => l10n.invoiceMgmtSortDateOldest,
      ('customer_name', true) => l10n.invoiceMgmtSortCustomerAZ,
      _ => l10n.invoiceMgmtSortCustomerZA,
    };
  }

  Future<void> _showSortDialogV2() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context)!.invoiceMgmtSortByTitle),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _sortOptionsV2.map((opt) {
                final (field, asc, icon) = opt;
                final selected = _sortField == field && _sortAscending == asc;
                final primaryColor = Theme.of(context).primaryColor;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, size: 20, color: selected ? primaryColor : null),
                  title: Text(_sortOptionLabel(AppLocalizations.of(context)!, field, asc),
                      style: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? primaryColor : null)),
                  trailing:
                      selected ? Icon(Icons.check_circle, color: primaryColor, size: 20) : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    if (_sortField == field && _sortAscending == asc) return;
                    setState(() {
                      _sortField = field;
                      _sortAscending = asc;
                      _currentPage = 0;
                    });
                    _loadPage();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context)!.actionClose),
            ),
          ],
        );
      },
    );
  }

  Widget _searchFilterRowV2(bool isWide) {
    final searchField = TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.invoiceMgmtSearchHintMessage,
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

    final customerButton = _selectedCustomerId == null
        ? OutlinedButton.icon(
            onPressed: _pickCustomerFilterV2,
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('Customer'),
          )
        : InputChip(
            avatar: const Icon(Icons.person, size: 16),
            label: Text(_selectedCustomerName ?? '',
                overflow: TextOverflow.ellipsis, maxLines: 1),
            onPressed: _pickCustomerFilterV2,
            onDeleted: _clearCustomerFilterV2,
          );

    final filterButton = widget.filterType != 'Invoice'
        ? const SizedBox.shrink()
        : Stack(
            clipBehavior: Clip.none,
            children: [
              OutlinedButton.icon(
                onPressed: _showFilterDialogV2,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(AppLocalizations.of(context)!.invoiceMgmtFilterLabel),
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

    final sortButton = OutlinedButton.icon(
      onPressed: _showSortDialogV2,
      icon: const Icon(Icons.sort, size: 18),
      label: Text(AppLocalizations.of(context)!.invoiceMgmtSortLabel),
    );

    final statText = Text(
      AppLocalizations.of(context)!.invoiceMgmtTotalPageStatusLabel(
          _totalCount, _currentPage + 1, _totalPages > 0 ? _totalPages : 1),
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
          customerButton,
          const SizedBox(width: 8),
          filterButton,
          if (widget.filterType == 'Invoice') const SizedBox(width: 8),
          sortButton,
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
            customerButton,
            const SizedBox(width: 8),
            filterButton,
            if (widget.filterType == 'Invoice') const SizedBox(width: 8),
            sortButton,
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
            child: Text(AppLocalizations.of(context)!.invoiceMgmtSelectedCountLabel(count),
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          _buildBulkButton(
            icon: Icons.deselect,
            label: AppLocalizations.of(context)!.invoiceMgmtDeselectLabel,
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
          _buildBulkButton(
            icon: Icons.select_all,
            label: AppLocalizations.of(context)!.invoiceMgmtSelectPageLabel,
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
            label: AppLocalizations.of(context)!.invoiceMgmtMarkPaidLabel,
            color: Colors.green[300]!,
            onPressed: _isBulkLoading ? null : _bulkMarkAsPaid,
          ),
          _buildBulkButton(
            icon: Icons.table_chart_outlined,
            label: AppLocalizations.of(context)!.invoiceMgmtCsvLabel,
            onPressed: _isBulkLoading ? null : _bulkExportCsv,
          ),
          _buildBulkButton(
            icon: Icons.picture_as_pdf_outlined,
            label: AppLocalizations.of(context)!.invoiceMgmtPdfsLabel,
            onPressed: _isBulkLoading ? null : _bulkExportPdfs,
          ),
          if (widget.user.isAdmin())
            _buildBulkButton(
              icon: Icons.delete_outline,
              label: AppLocalizations.of(context)!.invoiceMgmtTrashLabel,
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
    final l10n = AppLocalizations.of(context)!;
    return [
      if (!isWide) ...[
        PopupMenuItem(value: 'view', child: _MenuRow(Icons.visibility_outlined, l10n.actionView, Colors.green)),
        PopupMenuItem(value: 'edit', child: _MenuRow(Icons.edit_outlined, l10n.actionEdit, Colors.blue)),
        if (widget.filterType == 'Invoice')
          PopupMenuItem(
            value: 'pay',
            child: _MenuRow(Icons.payments_outlined, l10n.actionApplyPayment,
                invoice.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.purple),
          ),
      ],
      PopupMenuItem(value: 'duplicate', child: _MenuRow(Icons.copy_all_outlined, l10n.actionDuplicate, Colors.teal)),
      if (!isWide) ...[
        PopupMenuItem(
            value: 'preview', child: _MenuRow(Icons.picture_as_pdf_outlined, l10n.actionPdfPreview, Colors.orange)),
        PopupMenuItem(
            value: 'download', child: _MenuRow(Icons.download_outlined, l10n.actionDownloadPdf, Colors.deepPurple)),
        PopupMenuItem(value: 'print', child: _MenuRow(Icons.print_outlined, l10n.actionPrint, Colors.blueGrey)),
      ],
      if (widget.user.isAdmin())
        PopupMenuItem(
            value: 'delete', child: _MenuRow(Icons.delete_outline, l10n.invoiceMgmtMoveToTrashTitle, Colors.red)),
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
    final l10n = AppLocalizations.of(context)!;
    final menu = PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: l10n.invoiceMgmtMoreActionsTooltip,
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
        _buildActionButton(Icons.visibility_outlined, Colors.green, l10n.actionView,
            () => InvoicePdfServices.showInvoiceDetails(context, invoice)),
        _buildActionButton(
            Icons.edit_outlined, Colors.blue, l10n.actionEdit, () => widget.onEditInvoice(invoice)),
        if (widget.filterType == 'Invoice')
          _buildActionButton(
            Icons.payments_outlined,
            invoice.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.purple,
            l10n.actionApplyPayment,
            () => _showApplyPaymentDialog(invoice),
          ),
        _buildActionButton(Icons.picture_as_pdf_outlined, Colors.orange, l10n.actionPdfPreview,
            () => InvoicePdfServices.previewPDF(context, invoice)),
        _buildActionButton(Icons.download_outlined, Colors.deepPurple, l10n.actionDownloadPdf,
            () => PDFService.downloadPDF(context, invoice)),
        _buildActionButton(Icons.print_outlined, Colors.blueGrey, l10n.actionPrint,
            () => InvoicePdfServices.generatePDF(context, invoice)),
        menu,
      ],
    );
  }

  Widget _tableHeaderRowV2(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
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
          SizedBox(width: 60, child: Text(l10n.invoiceMgmtColSlNo, style: style)),
          Expanded(flex: 3, child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(l10n.invoiceMgmtColInvoiceCustomer, style: style))),
          if (widget.filterType == 'Invoice' && isWide)
            Expanded(child: Text(l10n.invoiceMgmtColTitle, style: style)),
          SizedBox(width: 110, child: Text(l10n.invoiceMgmtColDate, style: style)),
          if (isWide) SizedBox(width: 56, child: Text(l10n.invoiceMgmtColItems, style: style)),
          Expanded(child: Text(l10n.fieldTotalLabel, style: style)),
          if (widget.filterType == 'Invoice') ...[
            SizedBox(width: 76, child: Text(l10n.invoiceMgmtColStatus, style: style)),
            Expanded(child: Text(l10n.invoiceMgmtColOutstanding, style: style)),
          ],
          SizedBox(width: isWide ? 300 : 48, child: Text(l10n.invoiceMgmtColActions, style: style)),
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
    final l10n = AppLocalizations.of(context)!;
    final left = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.invoiceMgmtRowsPerPageLabel,
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
          label: Text(l10n.actionPrevious),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          ),
          child: Text(l10n.invoiceMgmtPageOfLabel(_currentPage + 1, _totalPages > 0 ? _totalPages : 1),
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
          label: Text(l10n.actionNext),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 72, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? l10n.invoiceMgmtNoFilteredTypeFoundMessage('${widget.filterType.toLowerCase()}s')
                : l10n.invoiceMgmtNoResultsForQueryMessage(_searchQuery),
            style: TextStyle(
                fontSize: 17, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isEmpty
                ? l10n.invoiceMgmtCreateFirstTypeMessage(widget.filterType.toLowerCase())
                : l10n.invoiceMgmtTryAdjustingFiltersMessage,
            style: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _headerBarV2(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
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
          tooltip: l10n.invoiceMgmtDownloadByRangeTooltip,
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          onPressed: _exportCsv,
          tooltip: l10n.invoiceMgmtExportAllCsvTooltip,
        ),
        if (widget.user.isAdmin())
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _showTrashDialog,
            tooltip: l10n.invoiceMgmtTrashLabel,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _currentPage = 0;
            _loadPage();
          },
          tooltip: l10n.actionRefresh,
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
          PopupMenuItem(
              value: 'download',
              child: _MenuRow(Icons.download_for_offline_outlined, l10n.invoiceMgmtDownloadByRangeMenuLabel,
                  Colors.blueGrey)),
          PopupMenuItem(
              value: 'csv',
              child: _MenuRow(Icons.file_download_outlined, l10n.invoiceMgmtExportAllCsvTooltip, Colors.blueGrey)),
          if (widget.user.isAdmin())
            PopupMenuItem(
                value: 'trash', child: _MenuRow(Icons.delete_sweep_outlined, l10n.invoiceMgmtTrashLabel, Colors.red)),
          PopupMenuItem(value: 'refresh', child: _MenuRow(Icons.refresh, l10n.actionRefresh, Colors.blueGrey)),
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
          title: Text(AppLocalizations.of(context)!.invoiceMgmtManagementTitle(widget.filterType)),
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
                  isOverdue
                      ? AppLocalizations.of(context)!.invoiceMgmtOverdueBadge
                      : AppLocalizations.of(context)!.invoiceMgmtTodayBadge,
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
    final l10n = AppLocalizations.of(context)!;
    final Color color;
    final String label;
    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        label = l10n.paymentStatusPaid;
      case PaymentStatus.partial:
        color = Colors.orange;
        label = l10n.paymentStatusPartial;
      case PaymentStatus.unpaid:
        color = Colors.red;
        label = l10n.paymentStatusUnpaid;
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
        SnackBar(
            content: Text(AppLocalizations.of(context)!.invoiceMgmtInvoiceRestoredMessage),
            backgroundColor: Colors.green,
            showCloseIcon: true,
            closeIconColor: Colors.white),
      );
    }
  }

  Future<void> _permanentDelete(Invoice invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppError.confirm(
      context,
      title: l10n.invoiceMgmtPermanentlyDeleteTitle,
      message: l10n.invoiceMgmtPermanentlyDeleteBody(invoice.invoiceNumber ?? invoice.id),
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
                Text(AppLocalizations.of(context)!.invoiceMgmtTrashLabel,
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  child: Text(AppLocalizations.of(context)!.invoiceMgmtTrashIsEmptyLabel,
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
                              inv.type == 'Invoice'
                                  ? AppLocalizations.of(context)!.labelInvoice
                                  : AppLocalizations.of(context)!.labelQuotation,
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
                            label: Text(AppLocalizations.of(context)!.actionRestore),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.green),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () => _permanentDelete(inv),
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: Text(AppLocalizations.of(context)!.actionDelete),
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
                child: Text(AppLocalizations.of(context)!.actionClose),
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
          value != null ? formatter.format(value!) : AppLocalizations.of(context)!.invoiceMgmtAnyDateLabel,
          style: TextStyle(
            fontSize: 13,
            color: value != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
