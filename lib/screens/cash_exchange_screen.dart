import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/database/cash_ledger_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/cash_ledger_entry.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/exchange_receipt_service.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';

/// Cash / UPI-Bank exchange ledger: balances, entry actions and history.
class CashExchangeScreen extends ConsumerStatefulWidget {
  final User user;
  const CashExchangeScreen({super.key, required this.user});

  @override
  ConsumerState<CashExchangeScreen> createState() => _CashExchangeScreenState();
}

enum _Period { today, month, all, custom }

class _CashExchangeScreenState extends ConsumerState<CashExchangeScreen> {
  bool _loading = true;
  String _sym = '₹';
  CashBalances _balances = (cash: 0, upiBank: 0, trackingStart: null);
  CashPeriodTotals _today = (serviceIncome: 0, expenses: 0);
  CashPeriodTotals _month = (serviceIncome: 0, expenses: 0);
  CashLedgerEntry? _opening;
  List<CashLedgerEntry> _entries = [];
  int _page = 0;
  int _pageSize = 25;
  int _total = 0;
  _Period _period = _Period.today;
  DateTimeRange? _customRange; // set before _period becomes custom
  CashBalances? _periodOpening;
  CashBalances? _periodClosing;
  String? _typeFilter;
  bool _balancesOpen = true; // period opening / closing cards

  bool get _isAdmin => widget.user.isAdmin();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Opening-balance (setup) date; nothing is tracked before it.
  DateTime? get _setupDate => _balances.trackingStart;

  /// Periods never start before the setup date (e.g. "This month" after a
  /// 25 Sep setup is 25–26 Sep, not 1–30).
  DateTime _fromSetup(DateTime d) {
    final s = _setupDate;
    return s != null && d.isBefore(s) ? DateTime(s.year, s.month, s.day) : d;
  }

  (DateTime?, DateTime?) get _range {
    final now = DateTime.now();
    return switch (_period) {
      _Period.today =>
        (_fromSetup(DateTime(now.year, now.month, now.day)), _endOfDay(now)),
      _Period.month => (_fromSetup(DateTime(now.year, now.month)), _endOfDay(now)),
      _Period.all => (null, null),
      _Period.custom =>
        (_fromSetup(_customRange!.start), _endOfDay(_customRange!.end)),
    };
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// Balances + totals, then the current history page. Only needed on open
  /// and after a write; filter/page changes call [_loadEntries] alone.
  Future<void> _load() async {
    final repo = ref.read(cashLedgerRepositoryProvider);
    final now = DateTime.now();
    final r = await Future.wait([
      ref.read(settingsRepositoryProvider).getCurrency(),
      repo.getBalances(),
      repo.getOpening(),
      repo.getPeriodTotals(DateTime(now.year, now.month, now.day), _endOfDay(now)),
      repo.getPeriodTotals(DateTime(now.year, now.month), _endOfDay(now)),
    ]);
    if (!mounted) return;
    setState(() {
      _sym = (r[0] as CurrencyOption).symbol;
      _balances = r[1] as CashBalances;
      _opening = r[2] as CashLedgerEntry?;
      _today = r[3] as CashPeriodTotals;
      _month = r[4] as CashPeriodTotals;
    });
    await Future.wait([_loadPeriodBalances(), _loadEntries()]);
  }

  /// Opening / closing balances of the selected period. Only depends on the
  /// period, so it runs on open, after a write, and on a period change.
  Future<void> _loadPeriodBalances() async {
    final (from, to) = _range;
    final setup = _setupDate;
    final repo = ref.read(cashLedgerRepositoryProvider);
    // A period starting on/before the setup day opens with the setup
    // balance (the opening entry is dated that day, so "before" would be 0).
    final startsAtSetup =
        from == null || (setup != null && !from.isAfter(setup));
    final CashBalances opening = startsAtSetup
        ? (
            cash: _opening?.cashDelta ?? 0,
            upiBank: _opening?.upiDelta ?? 0,
            trackingStart: null
          )
        : await repo.getBalances(before: from);
    final CashBalances closing = to == null
        ? _balances
        : await repo.getBalances(
            before: DateTime(to.year, to.month, to.day + 1));
    if (!mounted) return;
    setState(() {
      _periodOpening = opening;
      _periodClosing = closing;
    });
  }

  Future<void> _setPeriod(_Period p) async {
    if (p == _Period.custom) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final first = _fromSetup(DateTime(2000));
      final initial = _customRange ??
          DateTimeRange(
              start: _fromSetup(DateTime(now.year, now.month)), end: today);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: first,
        lastDate: today,
        initialDateRange: initial.start.isBefore(first)
            ? DateTimeRange(start: first, end: initial.end)
            : initial,
        // Same centred, size-capped dialog as Reports (not full window).
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: Theme.of(context).primaryColor),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
              child: child!,
            ),
          ),
        ),
      );
      if (picked == null || !mounted) return; // keep the current period
      _customRange = picked;
    }
    _setFilter(() => _period = p);
    _loadPeriodBalances();
  }

  /// One page of history plus its total count (2 indexed queries).
  Future<void> _loadEntries() async {
    final repo = ref.read(cashLedgerRepositoryProvider);
    final (from, to) = _range;
    final paymentsFrom = _balances.trackingStart;
    final r = await Future.wait([
      repo.getEntries(
          from: from,
          to: to,
          type: _typeFilter,
          paymentsFrom: paymentsFrom,
          limit: _pageSize,
          offset: _page * _pageSize),
      repo.countEntries(
          from: from, to: to, type: _typeFilter, paymentsFrom: paymentsFrom),
    ]);
    if (!mounted) return;
    final total = r[1] as int;
    // A delete can empty the last page; step back to the new last page.
    if (_page > 0 && _page * _pageSize >= total) {
      _page = ((total - 1) / _pageSize).floor().clamp(0, _page);
      return _loadEntries();
    }
    setState(() {
      _entries = r[0] as List<CashLedgerEntry>;
      _total = total;
      _loading = false;
    });
  }

  void _setFilter(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
    });
    _loadEntries();
  }

  String _money(double v) =>
      '$_sym${NumberFormat('#,##0.00').format(v.abs())}';
  String _signed(double v) => '${v < 0 ? '−' : '+'}${_money(v)}';

  String _accountLabel(AppLocalizations l10n, String? account) =>
      account == CashLedgerEntry.accountCash
          ? l10n.cashExchangeCashLabel
          : l10n.cashExchangeUpiBankLabel;

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
        CashLedgerEntry.upiToCash => l10n.cashExchangeUpiToCash,
        CashLedgerEntry.cashToUpi => l10n.cashExchangeCashToUpi,
        CashLedgerEntry.opening => l10n.cashExchangeOpeningBalance,
        CashLedgerEntry.expense => l10n.cashExchangeExpense,
        CashLedgerEntry.withdrawal => l10n.cashExchangeWithdrawal,
        CashLedgerEntry.bankDeposit => l10n.cashExchangeBankDeposit,
        CashLedgerEntry.invoicePayment => l10n.cashExchangeInvoicePayment,
        _ => l10n.cashExchangeAdjustment,
      };

  IconData _typeIcon(String type) => switch (type) {
        CashLedgerEntry.upiToCash || CashLedgerEntry.cashToUpi =>
          Icons.currency_exchange,
        CashLedgerEntry.opening => Icons.flag_outlined,
        CashLedgerEntry.expense => Icons.shopping_bag_outlined,
        CashLedgerEntry.withdrawal => Icons.north_east,
        CashLedgerEntry.bankDeposit => Icons.account_balance_outlined,
        CashLedgerEntry.invoicePayment => Icons.receipt_long_outlined,
        _ => Icons.tune,
      };

  // ── Dialog helpers ──────────────────────────────────────────────────────

  static final _amountFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'));
  static final _signedFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$'));

  Widget _numField(TextEditingController c, String label,
          {bool signed = false, ValueChanged<String>? onChanged}) =>
      TextField(
        controller: c,
        keyboardType:
            TextInputType.numberWithOptions(decimal: true, signed: signed),
        inputFormatters: [signed ? _signedFormatter : _amountFormatter],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '$_sym ',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _textField(TextEditingController c, String label,
          {TextInputType? keyboardType, int maxLines = 1}) =>
      TextField(
        controller: c,
        keyboardType: keyboardType,
        minLines: 1,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _accountPicker(AppLocalizations l10n, String value,
          ValueChanged<String> onChanged) =>
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
              value: CashLedgerEntry.accountCash,
              label: Text(l10n.cashExchangeCashLabel)),
          ButtonSegment(
              value: CashLedgerEntry.accountUpiBank,
              label: Text(l10n.cashExchangeUpiBankLabel)),
        ],
        selected: {value},
        onSelectionChanged: (v) => onChanged(v.first),
      );

  /// [floor]: earliest pickable date (the setup date for ledger entries, so
  /// nothing lands where it's counted but never shown). Ignored when
  /// [value] is already earlier.
  Widget _dateTimeTile(
      AppLocalizations l10n, DateTime value, ValueChanged<DateTime> onPicked,
      {bool withTime = true, DateTime? floor}) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: floor == null || value.isBefore(floor)
                ? DateTime(2000)
                : floor,
            lastDate: DateTime.now().add(const Duration(days: 1)));
        if (d == null || !mounted) return;
        var t = TimeOfDay.fromDateTime(value);
        if (withTime) {
          final picked = await showTimePicker(context: context, initialTime: t);
          if (picked != null) t = picked;
        }
        onPicked(DateTime(d.year, d.month, d.day, t.hour, t.minute));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText:
              withTime ? l10n.cashExchangeDateTimeLabel : l10n.cashExchangeDateLabel,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(DateFormat(withTime ? 'dd MMM yyyy, hh:mm a' : 'dd MMM yyyy')
            .format(value)),
      ),
    );
  }

  /// Shared dialog shell. [save] returns false to keep the dialog open.
  Future<void> _formDialog({
    required String title,
    required List<Widget> Function(StateSetter setDialog) fields,
    required Future<bool> Function() save,
    double width = 420,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final w in fields(setDialog)) ...[
                    w,
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.actionCancel)),
            FilledButton(
                onPressed: () async {
                  if (await save() && ctx.mounted) Navigator.pop(ctx, true);
                },
                child: Text(l10n.actionSave)),
          ],
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Widget _pair(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
      );

  /// Name field that searches existing customers as you type. Picking one
  /// calls [onPicked]; free text still works for walk-in customers.
  Widget _customerField(AppLocalizations l10n, TextEditingController name,
      FocusNode focus, ValueChanged<Customer> onPicked) {
    return RawAutocomplete<Customer>(
      textEditingController: name,
      focusNode: focus,
      displayStringForOption: (c) => c.name,
      optionsBuilder: (v) async {
        final q = v.text.trim();
        if (q.isEmpty) return const <Customer>[];
        return ref
            .read(customerRepositoryProvider)
            .getCustomerListPage(offset: 0, limit: 8, query: q);
      },
      onSelected: onPicked,
      fieldViewBuilder: (context, controller, focusNode, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: l10n.cashExchangeCustomerNameLabel,
          hintText: l10n.cashExchangeCustomerSearchHint,
          prefixIcon: const Icon(Icons.person_search_outlined),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 300),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final c in options)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline, size: 20),
                    title: Text(c.name),
                    subtitle: Text([c.phone, c.businessName]
                        .where((t) => t.isNotEmpty)
                        .join(' • ')),
                    onTap: () => onSelected(c),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _error(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  // ── Dialogs ───────────────────────────────────────────────────────────────

  String _init(double v) => v == 0 ? '' : v.toStringAsFixed(2);

  /// [editing]: prefill from that entry and save over it; the direction can
  /// then be switched too.
  Future<void> _exchangeDialog(bool upiToCash,
      {CashLedgerEntry? editing}) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = TextEditingController(text: _init(editing?.exchangeAmount ?? 0));
    final fee = TextEditingController(text: _init(editing?.serviceFee ?? 0));
    final name = TextEditingController(text: editing?.customerName);
    final nameFocus = FocusNode();
    final phone = TextEditingController(text: editing?.customerPhone);
    final notes = TextEditingController(text: editing?.notes);
    // Default: the fee comes with what the customer hands over.
    var feeMethod = editing?.feeMethod ??
        (upiToCash
            ? CashLedgerEntry.accountUpiBank
            : CashLedgerEntry.accountCash);
    var when = editing?.dateTime ?? DateTime.now();
    Customer? picked; // linked only while the name still matches
    await _formDialog(
      title: editing != null
          ? l10n.cashExchangeEditTitle
          : upiToCash
              ? l10n.cashExchangeUpiToCash
              : l10n.cashExchangeCashToUpi,
      width: 640,
      fields: (setDialog) {
        final a = _parse(amount);
        final f = _parse(fee);
        // Outgoing side: cash for UPI→Cash, UPI/Bank for Cash→UPI. When
        // editing, without the entry's own (old) effect.
        final available = upiToCash
            ? _balances.cash - (editing?.cashDelta ?? 0)
            : _balances.upiBank - (editing?.upiDelta ?? 0);
        final method = _accountLabel(l10n, feeMethod);
        return [
          if (editing != null)
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: true, label: Text(l10n.cashExchangeUpiToCash)),
                ButtonSegment(
                    value: false, label: Text(l10n.cashExchangeCashToUpi)),
              ],
              selected: {upiToCash},
              onSelectionChanged: (v) => setDialog(() => upiToCash = v.first),
            ),
          _pair(
            _numField(amount, l10n.cashExchangeAmountLabel,
                onChanged: (_) => setDialog(() {})),
            _numField(fee, l10n.cashExchangeFeeLabel,
                onChanged: (_) => setDialog(() {})),
          ),
          Row(
            children: [
              Expanded(child: Text(l10n.cashExchangeFeePaidByLabel)),
              _accountPicker(
                  l10n, feeMethod, (v) => setDialog(() => feeMethod = v)),
            ],
          ),
          _pair(
            _customerField(l10n, name, nameFocus, (c) {
              setDialog(() {
                picked = c;
                if (c.phone.isNotEmpty) phone.text = c.phone;
              });
            }),
            _textField(phone, l10n.cashExchangeCustomerPhoneLabel,
                keyboardType: TextInputType.phone),
          ),
          _dateTimeTile(l10n, when, (v) => setDialog(() => when = v),
              floor: _setupDate),
          _textField(notes, l10n.cashExchangeNotesLabel, maxLines: 3),
          if (a > 0)
            Text(
              upiToCash
                  ? l10n.cashExchangeSummaryUpiToCash(
                      _money(a), _money(f), method)
                  : l10n.cashExchangeSummaryCashToUpi(
                      _money(a), _money(f), method),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          // The warning shows the balance, which regular users don't see.
          if (_isAdmin && a > available)
            Text(
              l10n.cashExchangeLowBalanceWarning(
                  _money(available),
                  upiToCash
                      ? l10n.cashExchangeCashLabel
                      : l10n.cashExchangeUpiBankLabel),
              style: TextStyle(color: Colors.orange[800]),
            ),
        ];
      },
      save: () async {
        if (_parse(amount) <= 0) {
          _error(l10n.paymentDialogInvalidAmountError);
          return false;
        }
        final linked = picked != null && picked!.name == name.text.trim();
        if (editing != null) {
          // Keep the saved customer link while the name is unchanged.
          final keep = !linked && name.text.trim() == editing.customerName;
          return _update(
              editing,
              CashLedgerService.buildExchange(
                upiToCash: upiToCash,
                amount: _parse(amount),
                fee: _parse(fee),
                feeMethod: feeMethod,
                dateTime: when,
                customerId:
                    linked ? picked!.id : (keep ? editing.customerId : null),
                customerName: _opt(name),
                customerPhone: _opt(phone),
                notes: _opt(notes),
              ));
        }
        await ref.read(cashLedgerRepositoryProvider).addExchange(
              upiToCash: upiToCash,
              amount: _parse(amount),
              fee: _parse(fee),
              feeMethod: feeMethod,
              dateTime: when,
              customerId: linked ? picked!.id : null,
              customerName: _opt(name),
              customerPhone: _opt(phone),
              notes: _opt(notes),
              createdBy: widget.user.id,
            );
        return true;
      },
    );
    nameFocus.dispose();
  }

  Future<void> _movementDialog(String type, {CashLedgerEntry? editing}) async {
    final l10n = AppLocalizations.of(context)!;
    final isDeposit = type == CashLedgerEntry.bankDeposit;
    // No stored account: a deposit adds to UPI/Bank; an expense or
    // withdrawal takes from the one account it changed.
    final amount = TextEditingController(
        text: editing == null
            ? ''
            : _init(isDeposit
                ? editing.upiDelta
                : -(editing.cashDelta + editing.upiDelta)));
    final notes = TextEditingController(text: editing?.notes);
    var account = editing != null && !isDeposit && editing.upiDelta != 0
        ? CashLedgerEntry.accountUpiBank
        : CashLedgerEntry.accountCash;
    var when = editing?.dateTime ?? DateTime.now();
    await _formDialog(
      title: editing != null ? l10n.cashExchangeEditTitle : _typeLabel(l10n, type),
      fields: (setDialog) => [
        _numField(amount, l10n.cashExchangeAmountLabel),
        if (!isDeposit) ...[
          Text(l10n.cashExchangeFromAccountLabel),
          _accountPicker(l10n, account, (v) => setDialog(() => account = v)),
        ],
        _textField(notes, l10n.cashExchangeNotesLabel),
        _dateTimeTile(l10n, when, (v) => setDialog(() => when = v),
            floor: _setupDate),
      ],
      save: () async {
        if (_parse(amount) <= 0) {
          _error(l10n.paymentDialogInvalidAmountError);
          return false;
        }
        if (editing != null) {
          return _update(
              editing,
              CashLedgerService.buildMovement(
                type: type,
                amount: _parse(amount),
                account: account,
                dateTime: when,
                notes: _opt(notes),
              ));
        }
        await ref.read(cashLedgerRepositoryProvider).addMovement(
              type: type,
              amount: _parse(amount),
              account: account,
              dateTime: when,
              notes: _opt(notes),
              createdBy: widget.user.id,
            );
        return true;
      },
    );
  }

  Future<void> _openingDialog() async {
    final l10n = AppLocalizations.of(context)!;
    String init(double? v) => v == null ? '' : v.toStringAsFixed(2);
    final cash = TextEditingController(text: init(_opening?.cashDelta));
    final upi = TextEditingController(text: init(_opening?.upiDelta));
    var date = _opening?.dateTime ?? DateTime.now();
    await _formDialog(
      title: l10n.cashExchangeOpeningBalance,
      fields: (setDialog) => [
        Text(l10n.cashExchangeSetupMessage),
        _numField(cash, l10n.cashExchangeCashLabel),
        _numField(upi, l10n.cashExchangeUpiBankLabel),
        _dateTimeTile(l10n, date, (v) => setDialog(() => date = v),
            withTime: false),
      ],
      save: () async {
        await ref.read(cashLedgerRepositoryProvider).saveOpening(
              cash: _parse(cash),
              upiBank: _parse(upi),
              date: DateTime(date.year, date.month, date.day),
              createdBy: widget.user.id,
            );
        return true;
      },
    );
  }

  Future<void> _adjustmentDialog({CashLedgerEntry? editing}) async {
    final l10n = AppLocalizations.of(context)!;
    final cash = TextEditingController(text: _init(editing?.cashDelta ?? 0));
    final upi = TextEditingController(text: _init(editing?.upiDelta ?? 0));
    final notes = TextEditingController(text: editing?.notes);
    var when = editing?.dateTime ?? DateTime.now();
    await _formDialog(
      title: editing != null
          ? l10n.cashExchangeEditTitle
          : l10n.cashExchangeAdjustment,
      fields: (setDialog) => [
        _numField(cash, l10n.cashExchangeCashDeltaLabel, signed: true),
        _numField(upi, l10n.cashExchangeUpiDeltaLabel, signed: true),
        _textField(notes, l10n.cashExchangeNotesLabel),
        _dateTimeTile(l10n, when, (v) => setDialog(() => when = v),
            floor: _setupDate),
      ],
      save: () async {
        if (_parse(cash) == 0 && _parse(upi) == 0) {
          _error(l10n.paymentDialogInvalidAmountError);
          return false;
        }
        if (editing != null) {
          return _update(
              editing,
              CashLedgerEntry(
                id: editing.id,
                entryType: CashLedgerEntry.adjustment,
                cashDelta: _parse(cash),
                upiDelta: _parse(upi),
                dateTime: when,
                notes: _opt(notes),
              ));
        }
        await ref.read(cashLedgerRepositoryProvider).addAdjustment(
              cashDelta: _parse(cash),
              upiDelta: _parse(upi),
              dateTime: when,
              notes: _opt(notes),
              createdBy: widget.user.id,
            );
        return true;
      },
    );
  }

  Future<void> _confirmDelete(CashLedgerEntry e) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashExchangeDeleteTitle),
        content: Text(l10n.cashExchangeDeleteMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(cashLedgerRepositoryProvider).deleteEntry(e.id,
          userId: widget.user.id,
          userName: widget.user.username,
          isAdmin: _isAdmin);
    } on StateError {
      if (mounted) _error(l10n.cashExchangeChangeFailed);
    }
    await _load();
  }

  /// Saves an edit. A refusal (row gone, edit window over) still closes the
  /// dialog, and the reload shows the current state.
  Future<bool> _update(CashLedgerEntry old, CashLedgerEntry updated) async {
    try {
      await ref.read(cashLedgerRepositoryProvider).updateEntry(old.id, updated,
          userId: widget.user.id,
          userName: widget.user.username,
          isAdmin: _isAdmin);
    } on StateError {
      if (mounted) _error(AppLocalizations.of(context)!.cashExchangeChangeFailed);
    }
    return true;
  }

  Future<void> _edit(CashLedgerEntry e) => switch (e.entryType) {
        CashLedgerEntry.upiToCash ||
        CashLedgerEntry.cashToUpi =>
          _exchangeDialog(e.entryType == CashLedgerEntry.upiToCash, editing: e),
        CashLedgerEntry.adjustment => _adjustmentDialog(editing: e),
        _ => _movementDialog(e.entryType, editing: e),
      };

  /// One line with everything an entry holds (edit log views).
  String _summary(AppLocalizations l10n, CashLedgerEntry e) => [
        _typeLabel(l10n, e.entryType),
        if (e.isExchange) _money(e.exchangeAmount),
        if (e.isExchange)
          '${l10n.cashExchangeFeeLabel} ${_money(e.serviceFee)} · ${_accountLabel(l10n, e.feeMethod)}',
        if (e.cashDelta != 0) '${l10n.cashExchangeCashLabel} ${_signed(e.cashDelta)}',
        if (e.upiDelta != 0)
          '${l10n.cashExchangeUpiBankLabel} ${_signed(e.upiDelta)}',
        DateFormat('dd MMM yyyy, hh:mm a').format(e.dateTime),
        if (e.receiptNumber != null) e.receiptNumber!,
        if (e.customerName != null) e.customerName!,
        if (e.customerPhone != null) e.customerPhone!,
        if (e.notes != null) e.notes!,
      ].join(' • ');

  Widget _changeTile(String title, String summary, {VoidCallback? onTap}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(summary),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  String _changeTitle(AppLocalizations l10n, CashLedgerChange c) {
    final user = c.changedByName ?? '—';
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(c.changedAt);
    return c.action == 'delete'
        ? l10n.cashExchangeHistoryDeleted(user, date)
        : l10n.cashExchangeHistoryEdited(user, date);
  }

  /// [children] / [pager] get the dialog's context and setState, so a pager
  /// can swap the page in place.
  Future<void> _showChanges(
      String title,
      List<Widget> Function(BuildContext ctx, StateSetter setDialog) children,
      {List<Widget> Function(BuildContext ctx, StateSetter setDialog)? pager}) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children(ctx, setDialog),
              ),
            ),
          ),
          actions: [
            if (pager != null) ...pager(ctx, setDialog),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionClose)),
          ],
        ),
      ),
    );
  }

  /// Current version first (unless deleted since), then each old version
  /// (newest first).
  Future<void> _historyDialog(String entryId, CashLedgerEntry? current) async {
    final l10n = AppLocalizations.of(context)!;
    final changes =
        await ref.read(cashLedgerRepositoryProvider).getHistory(entryId);
    if (!mounted) return;
    await _showChanges(l10n.cashExchangeHistoryTitle, (_, __) => [
      if (current != null)
        _changeTile(l10n.cashExchangeHistoryCurrent, _summary(l10n, current)),
      for (final c in changes) ...[
        if (current != null || c != changes.first) const Divider(),
        _changeTile(_changeTitle(l10n, c), _summary(l10n, c.entry)),
      ],
    ]);
  }

  /// Edits and deletes, 10 per page, newest first; only the page shown is
  /// loaded. Tapping an edit opens that entry's full history.
  Future<void> _changeLogDialog() async {
    const pageSize = 10;
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(cashLedgerRepositoryProvider);
    String? action; // null = all, 'edit', 'delete'
    var total = await repo.countChanges();
    var changes = await repo.getChanges(limit: pageSize);
    var page = 0;
    if (!mounted) return;
    int pages() => (total / pageSize).ceil().clamp(1, 1 << 30);
    Future<void> load(BuildContext ctx, StateSetter setDialog, int p,
        {bool recount = false}) async {
      final n = recount ? await repo.countChanges(action: action) : total;
      final rows = await repo.getChanges(
          action: action, limit: pageSize, offset: p * pageSize);
      if (!ctx.mounted) return;
      setDialog(() {
        total = n;
        page = p;
        changes = rows;
      });
    }

    Future<void> openHistory(String entryId) async {
      final current = await repo.getEntry(entryId);
      if (mounted) await _historyDialog(entryId, current);
    }

    await _showChanges(
      l10n.cashExchangeChangeLog,
      (ctx, setDialog) => [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: 'all', label: Text(l10n.invoiceMgmtStatusAllLabel)),
            ButtonSegment(value: 'edit', label: Text(l10n.cashExchangeEdited)),
            ButtonSegment(
                value: 'delete', label: Text(l10n.cashExchangeDeleted)),
          ],
          selected: {action ?? 'all'},
          onSelectionChanged: (v) {
            action = v.first == 'all' ? null : v.first;
            load(ctx, setDialog, 0, recount: true);
          },
        ),
        const SizedBox(height: 8),
        if (changes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.cashExchangeNoChanges),
          ),
        for (var i = 0; i < changes.length; i++) ...[
          if (i > 0) const Divider(),
          _changeTile(_changeTitle(l10n, changes[i]),
              _summary(l10n, changes[i].entry),
              onTap: changes[i].action == 'edit'
                  ? () => openHistory(changes[i].entry.id)
                  : null),
        ],
      ],
      // Always shown (like the main history), arrows off on a single page.
      pager: (ctx, setDialog) => [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.actionPrevious,
          onPressed: page > 0 ? () => load(ctx, setDialog, page - 1) : null,
        ),
        Text(l10n.invoiceMgmtPageOfLabel(page + 1, pages())),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.actionNext,
          onPressed: page < pages() - 1
              ? () => load(ctx, setDialog, page + 1)
              : null,
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _stat(
      String label, double value, Color color, IconData icon, double width) {
    // Min height (not fixed) so larger text scales grow the card instead of
    // overflowing; the icon drops out when the card gets narrow.
    final showIcon = width >= 170;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value < 0 ? '−${_money(value)}' : _money(value),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: value < 0 ? Colors.red[700] : null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
        CashLedgerEntry.upiToCash || CashLedgerEntry.cashToUpi => Colors.blue,
        CashLedgerEntry.expense => Colors.orange,
        CashLedgerEntry.withdrawal => Colors.purple,
        CashLedgerEntry.bankDeposit => Colors.teal,
        CashLedgerEntry.invoicePayment => Colors.green,
        _ => Colors.blueGrey,
      };

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );

  // Scales down instead of overflowing when a large amount doesn't fit.
  Widget _deltaLine(String label, double delta) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Text(_signed(delta),
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: delta < 0 ? Colors.red[400] : Colors.green[500])),
        ],
      ));

  Widget _entryTile(AppLocalizations l10n, CashLedgerEntry e) {
    final color = _typeColor(e.entryType);
    final isPayment = e.entryType == CashLedgerEntry.invoicePayment;
    final details = <String>[
      // Invoice payments are stored by date only.
      DateFormat(isPayment ? 'dd MMM yyyy' : 'dd MMM yyyy, hh:mm a')
          .format(e.dateTime),
      if (isPayment && e.notes != null) '${l10n.labelInvoice} ${e.notes}',
      if (e.receiptNumber != null) e.receiptNumber!,
      if (isPayment && e.feeMethod != null) paymentMethodLabel(l10n, e.feeMethod!),
      if (e.customerPhone != null) e.customerPhone!,
      if (!isPayment && e.notes != null) e.notes!,
    ].join(' • ');
    final fee = e.isExchange
        ? _chip(
            '+${_money(e.serviceFee)} ${l10n.cashExchangeFeeLabel} · ${_accountLabel(l10n, e.feeMethod)}',
            Colors.green)
        : null;
    // Admins: any entry; users: their own, for 24 hours. Never the opening
    // (own dialog) or invoice payments (managed from the Invoices screen).
    final canModify = CashLedgerService.canModify(e,
        userId: widget.user.id, isAdmin: _isAdmin);
    final showHistory = _isAdmin && e.edited;
    // Download (exchanges) + a "more" menu with Print (exchanges), History,
    // Edit and Delete.
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (e.isExchange)
          IconButton(
            tooltip: l10n.paymentDialogDownloadReceiptTooltip,
            icon: const Icon(Icons.download_outlined, size: 20),
            onPressed: () => ExchangeReceiptService.download(context, e, _sym),
          ),
        if (e.isExchange || canModify || showHistory)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) => switch (v) {
              'print' => ExchangeReceiptService.printReceipt(context, e, _sym),
              'history' => _historyDialog(e.id, e),
              'edit' => _edit(e),
              _ => _confirmDelete(e),
            },
            itemBuilder: (_) => [
              if (e.isExchange)
                PopupMenuItem(
                  value: 'print',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.print_outlined),
                    title: Text(l10n.actionPrint),
                  ),
                ),
              if (showHistory)
                PopupMenuItem(
                  value: 'history',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(l10n.cashExchangeHistoryTitle),
                  ),
                ),
              if (canModify)
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.actionEdit),
                  ),
                ),
              if (canModify)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                    title: Text(l10n.actionDelete,
                        style: TextStyle(color: Colors.red[400])),
                  ),
                ),
            ],
          ),
      ],
    );

    // Wide vs narrow from this row's own width, so fixed parts can't exceed
    // it. Narrow: amounts and actions wrap under the details; only the
    // 36px avatar + 12px gap stay fixed.
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 600;
      final deltas = Column(
        crossAxisAlignment:
            narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (e.cashDelta != 0)
            _deltaLine(l10n.cashExchangeCashLabel, e.cashDelta),
          if (e.upiDelta != 0)
            _deltaLine(l10n.cashExchangeUpiBankLabel, e.upiDelta),
        ],
      );
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(_typeLabel(l10n, e.entryType), color),
              if (e.isExchange || isPayment)
                Text(_money(e.exchangeAmount),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              if (e.customerName != null)
                Text(e.customerName!, style: const TextStyle(fontSize: 14)),
              if (fee != null) fee,
              if (e.edited) _chip(l10n.cashExchangeEdited, Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 4),
          Text(details,
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (narrow) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [deltas, actions],
            ),
          ],
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_typeIcon(e.entryType), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: info),
            if (!narrow) ...[
              const SizedBox(width: 16),
              SizedBox(width: 230, child: deltas),
              // Fixed slot keeps rows aligned (two 48px buttons).
              SizedBox(
                width: 96,
                child: Align(alignment: Alignment.centerRight, child: actions),
              ),
            ],
          ],
        ),
      );
    });
  }


  String _amount(double v) => v < 0 ? '−${_money(v)}' : _money(v);

  /// Active filters + the period's opening and closing balances.
  Widget _periodSummary(AppLocalizations l10n) {
    final (from, to) = _range;
    final fmt = DateFormat('dd MMM yyyy');
    final start = from ?? _setupDate;
    final range = start == null
        ? l10n.cashExchangePeriodAll
        : '${fmt.format(start)} – ${fmt.format(to ?? DateTime.now())}';
    final type = _typeFilter == null
        ? l10n.cashExchangeAllTypes
        : _typeLabel(l10n, _typeFilter!);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget block(String title, IconData icon, CashBalances? b,
        {Color? tint}) {
      Widget value(String label, double v, {bool bold = false}) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: muted)),
              Text(_amount(v),
                  style: TextStyle(
                      fontSize: bold ? 16 : 14.5,
                      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                      color: v < 0 ? Colors.red[400] : null)),
            ],
          );
      final accent = tint ?? muted;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tint?.withValues(alpha: 0.08) ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
          border: Border.all(
              color: tint?.withValues(alpha: 0.35) ?? Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                value(l10n.cashExchangeCashLabel, b?.cash ?? 0),
                value(l10n.cashExchangeUpiBankLabel, b?.upiBank ?? 0),
                value(l10n.cashExchangeTotalLabel,
                    (b?.cash ?? 0) + (b?.upiBank ?? 0),
                    bold: true),
              ],
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final opening = block(
        start == null
            ? l10n.cashExchangeOpeningBalance
            : '${l10n.cashExchangeOpeningBalance} · ${fmt.format(start)}',
        Icons.flag_outlined,
        _periodOpening);
    final closing = block(
        '${l10n.cashExchangeClosingBalance} · ${fmt.format(to ?? now)}',
        Icons.event_available_outlined,
        _periodClosing,
        tint: Theme.of(context).colorScheme.primary);
    final closingTotal =
        (_periodClosing?.cash ?? 0) + (_periodClosing?.upiBank ?? 0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters left; balances toggle right (wraps under when narrow).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.filter_alt_outlined, size: 18, color: muted),
                  Text('${l10n.cashExchangeShowingLabel}: $range • $type',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_period == _Period.custom)
                    TextButton(
                        onPressed: () => _setPeriod(_Period.custom),
                        child: Text(l10n.cashExchangeChangeDates)),
                ],
              ),
              if (_isAdmin)
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Collapsed: the closing total stays in view.
                    if (!_balancesOpen)
                      Text(
                          '${l10n.cashExchangeClosingBalance}: ${_amount(closingTotal)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: closingTotal < 0 ? Colors.red[400] : null)),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _balancesOpen = !_balancesOpen),
                      icon: Icon(_balancesOpen
                          ? Icons.expand_less
                          : Icons.expand_more),
                      label: Text(_balancesOpen
                          ? l10n.cashExchangeHideBalances
                          : l10n.cashExchangeShowBalances),
                    ),
                  ],
                ),
            ],
          ),
          if (_isAdmin)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: !_balancesOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      // Side by side, equal width, when both fit; else
                      // stacked.
                      child: LayoutBuilder(
                        builder: (context, c) => c.maxWidth >= 640
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: opening),
                                  const SizedBox(width: 16),
                                  Expanded(child: closing),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  opening,
                                  const SizedBox(height: 12),
                                  closing,
                                ],
                              ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _pagination(AppLocalizations l10n) {
    final totalPages = (_total / _pageSize).ceil().clamp(1, 1 << 30);
    final start = _page * _pageSize + 1;
    final end = ((_page + 1) * _pageSize).clamp(0, _total);
    final text = TextStyle(
        fontSize: 13, color: Theme.of(context).colorScheme.onSurface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child: Text(l10n.invoiceMgmtRowsPerPageLabel, style: text)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox(),
                items: [10, 25, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (n) {
                  if (n != null) _setFilter(() => _pageSize = n);
                },
              ),
            ],
          ),
          // Separate Wrap item so it moves to the next line when narrow.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.reportsShowingRangeLabel(start, end, _total),
                style: text),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: l10n.actionPrevious,
                onPressed: _page > 0
                    ? () {
                        setState(() => _page--);
                        _loadEntries();
                      }
                    : null,
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.invoiceMgmtPageOfLabel(_page + 1, totalPages),
                      style: text.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: l10n.actionNext,
                onPressed: _page < totalPages - 1
                    ? () {
                        setState(() => _page++);
                        _loadEntries();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navServices),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _body(l10n),
    );
  }

  Widget _body(AppLocalizations l10n) {
    final b = _balances;
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(builder: (context, constraints) {
                const gap = 12.0;
                final cols = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 480
                        ? 2
                        : 1;
                // floor: fractional widths could otherwise push the last card
                // of a row onto its own line.
                final w =
                    ((constraints.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balances and income are business finance: admins only.
                    if (_isAdmin)
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _stat(l10n.cashExchangeCashLabel, b.cash, Colors.green,
                            Icons.payments_outlined, w),
                        _stat(l10n.cashExchangeUpiBankLabel, b.upiBank,
                            Colors.blue, Icons.account_balance_wallet_outlined, w),
                        _stat(l10n.cashExchangeTotalLabel, b.cash + b.upiBank,
                            Colors.indigo, Icons.summarize_outlined, w),
                        _stat(l10n.cashExchangeIncomeTodayLabel,
                            _today.serviceIncome, Colors.teal, Icons.trending_up, w),
                        _stat(l10n.cashExchangeIncomeMonthLabel,
                            _month.serviceIncome, Colors.teal,
                            Icons.calendar_month_outlined, w),
                        _stat(l10n.cashExchangeExpensesMonthLabel, _month.expenses,
                            Colors.orange, Icons.shopping_bag_outlined, w),
                      ],
                    ),
                    if (_opening == null) ...[
                      if (_isAdmin) const SizedBox(height: 16),
                      // Not a ListTile: its trailing button can't wrap and
                      // asserts on narrow widths.
                      Card(
                        color: Colors.amber.withValues(alpha: 0.12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 700),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.flag_outlined),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(l10n.cashExchangeSetupTitle,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(_isAdmin
                                              ? l10n.cashExchangeSetupMessage
                                              : l10n
                                                  .cashExchangeSetupAdminOnlyMessage),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isAdmin)
                                FilledButton(
                                    onPressed: _openingDialog,
                                    child:
                                        Text(l10n.cashExchangeOpeningBalance)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_isAdmin || _opening == null) const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Coloured by what the customer receives, as the
                        // balance cards: Cash green, UPI/Bank blue.
                        FilledButton.icon(
                            onPressed: () => _exchangeDialog(true),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.payments_outlined, size: 18),
                            label: Text(l10n.cashExchangeUpiToCash)),
                        FilledButton.icon(
                            onPressed: () => _exchangeDialog(false),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white),
                            icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18),
                            label: Text(l10n.cashExchangeCashToUpi)),
                        OutlinedButton.icon(
                            onPressed: () =>
                                _movementDialog(CashLedgerEntry.expense),
                            icon: const Icon(Icons.shopping_bag_outlined,
                                size: 18),
                            label: Text(l10n.cashExchangeExpense)),
                        OutlinedButton.icon(
                            onPressed: () =>
                                _movementDialog(CashLedgerEntry.withdrawal),
                            icon: const Icon(Icons.north_east, size: 18),
                            label: Text(l10n.cashExchangeWithdrawal)),
                        OutlinedButton.icon(
                            onPressed: () =>
                                _movementDialog(CashLedgerEntry.bankDeposit),
                            icon: const Icon(Icons.account_balance_outlined,
                                size: 18),
                            label: Text(l10n.cashExchangeBankDeposit)),
                        if (_isAdmin && _opening != null)
                          OutlinedButton.icon(
                              onPressed: _openingDialog,
                              icon: const Icon(Icons.flag_outlined, size: 18),
                              label: Text(l10n.cashExchangeOpeningBalance)),
                        if (_isAdmin)
                          OutlinedButton.icon(
                              onPressed: _adjustmentDialog,
                              icon: const Icon(Icons.tune, size: 18),
                              label: Text(l10n.cashExchangeAdjustment)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Scales down instead of overflowing when the four
                        // periods don't fit the width (real fonts, narrow
                        // windows / phones).
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SegmentedButton<_Period>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor:
                                  primary.withValues(alpha: 0.18),
                              selectedForegroundColor: primary,
                            ),
                            segments: [
                              ButtonSegment(
                                  value: _Period.today,
                                  label: Text(l10n.cashExchangePeriodToday)),
                              ButtonSegment(
                                  value: _Period.month,
                                  label: Text(l10n.cashExchangePeriodMonth)),
                              ButtonSegment(
                                  value: _Period.all,
                                  label: Text(l10n.cashExchangePeriodAll)),
                              ButtonSegment(
                                  value: _Period.custom,
                                  icon: const Icon(Icons.date_range, size: 16),
                                  label: Text(l10n.cashExchangePeriodCustom)),
                            ],
                            selected: {_period},
                            onSelectionChanged: (v) => _setPeriod(v.first),
                          ),
                        ),
                        // Clip so the hover highlight follows the pill shape;
                        // transparent focus colour so it doesn't stay filled
                        // after a pick.
                        Container(
                          height: 40,
                          // Fixed width + isExpanded: long type names are
                          // trimmed instead of overflowing.
                          width: 200,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.outline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _typeFilter,
                              isExpanded: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              focusColor: Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.small),
                              items: [
                                DropdownMenuItem(
                                    value: null,
                                    child: Text(l10n.cashExchangeAllTypes,
                                        overflow: TextOverflow.ellipsis)),
                                for (final t in const [
                                  CashLedgerEntry.upiToCash,
                                  CashLedgerEntry.cashToUpi,
                                  CashLedgerEntry.expense,
                                  CashLedgerEntry.withdrawal,
                                  CashLedgerEntry.bankDeposit,
                                  CashLedgerEntry.invoicePayment,
                                  CashLedgerEntry.adjustment,
                                  CashLedgerEntry.opening,
                                ])
                                  DropdownMenuItem(
                                      value: t,
                                      child: Text(_typeLabel(l10n, t),
                                          overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (v) =>
                                  _setFilter(() => _typeFilter = v),
                            ),
                          ),
                        ),
                        if (_isAdmin)
                          TextButton.icon(
                              onPressed: _changeLogDialog,
                              icon: const Icon(Icons.history, size: 18),
                              label: Text(l10n.cashExchangeChangeLog)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _periodSummary(l10n),
                    const SizedBox(height: 12),
                    if (_entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text(l10n.cashExchangeEmpty)),
                      )
                    else
                      Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final e in _entries) ...[
                              _entryTile(l10n, e),
                              if (e != _entries.last) const Divider(height: 1),
                            ],
                            _pagination(l10n),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
