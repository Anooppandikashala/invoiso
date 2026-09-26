/// One row of the Cash / UPI-Bank ledger: a UPI↔Cash exchange, the opening
/// balance, or a cash movement (expense, withdrawal, bank deposit,
/// adjustment). UPI and bank are one account ("UPI/Bank").
///
/// [cashDelta] / [upiDelta] are the signed effect on each account, fixed when
/// the entry is written. Balances are sums of these, never stored.
class CashLedgerEntry {
  // entry_type values
  static const upiToCash = 'upi_to_cash';
  static const cashToUpi = 'cash_to_upi';
  static const opening = 'opening';
  static const expense = 'expense';
  static const withdrawal = 'withdrawal';
  static const bankDeposit = 'bank_deposit';
  static const adjustment = 'adjustment';
  // Read-only rows merged in from invoice_payments by getEntries; never
  // stored in cash_ledger. notes = invoice number, fee_method = payment method.
  static const invoicePayment = 'invoice_payment';

  // Accounts (fee_method, and the "from" account of expenses/withdrawals)
  static const accountCash = 'cash';
  static const accountUpiBank = 'upi_bank';

  final String id;
  final String entryType;
  final String? receiptNumber; // exchanges only
  final double exchangeAmount;
  final double serviceFee; // the only income; exchangeAmount never is
  final String? feeMethod;
  final double cashDelta;
  final double upiDelta;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime dateTime;
  final String? notes;
  final String? createdBy;

  const CashLedgerEntry({
    required this.id,
    required this.entryType,
    this.receiptNumber,
    this.exchangeAmount = 0,
    this.serviceFee = 0,
    this.feeMethod,
    this.cashDelta = 0,
    this.upiDelta = 0,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.dateTime,
    this.notes,
    this.createdBy,
  });

  bool get isExchange => entryType == upiToCash || entryType == cashToUpi;

  Map<String, dynamic> toMap() => {
        'id': id,
        'entry_type': entryType,
        'receipt_number': receiptNumber,
        'exchange_amount': exchangeAmount,
        'service_fee': serviceFee,
        'fee_method': feeMethod,
        'cash_delta': cashDelta,
        'upi_delta': upiDelta,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'date_time': dateTime.toIso8601String(),
        'notes': notes,
        'created_by': createdBy,
      };

  factory CashLedgerEntry.fromMap(Map<String, dynamic> map) => CashLedgerEntry(
        id: map['id'] as String,
        entryType: map['entry_type'] as String,
        receiptNumber: map['receipt_number'] as String?,
        exchangeAmount: (map['exchange_amount'] as num?)?.toDouble() ?? 0,
        serviceFee: (map['service_fee'] as num?)?.toDouble() ?? 0,
        feeMethod: map['fee_method'] as String?,
        cashDelta: (map['cash_delta'] as num?)?.toDouble() ?? 0,
        upiDelta: (map['upi_delta'] as num?)?.toDouble() ?? 0,
        customerId: map['customer_id'] as String?,
        customerName: map['customer_name'] as String?,
        customerPhone: map['customer_phone'] as String?,
        dateTime: DateTime.parse(map['date_time'] as String),
        notes: map['notes'] as String?,
        createdBy: map['created_by'] as String?,
      );
}

/// Current account balances. Total = [cash] + [upiBank].
typedef CashBalances = ({
  double cash,
  double upiBank,
  DateTime? trackingStart, // opening-balance date; null = not set up yet
});

/// Income / spend over a period (display only).
typedef CashPeriodTotals = ({double serviceIncome, double expenses});
