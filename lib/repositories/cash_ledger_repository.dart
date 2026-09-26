import 'package:invoiso/models/cash_ledger_entry.dart';

abstract class CashLedgerRepository {
  Future<CashLedgerEntry> addExchange({
    required bool upiToCash,
    required double amount,
    required double fee,
    required String feeMethod,
    required DateTime dateTime,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? createdBy,
  });
  Future<CashLedgerEntry> addMovement({
    required String type,
    required double amount,
    String account,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  });
  Future<CashLedgerEntry> addAdjustment({
    double cashDelta,
    double upiDelta,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  });
  Future<void> saveOpening({
    required double cash,
    required double upiBank,
    required DateTime date,
    String? createdBy,
  });
  Future<void> deleteEntry(String id);
  Future<CashLedgerEntry?> getOpening();
  Future<List<CashLedgerEntry>> getEntries({
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
    int limit,
    int offset,
  });
  Future<int> countEntries({
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
  });
  Future<CashBalances> getBalances({DateTime? before});
  Future<CashPeriodTotals> getPeriodTotals(DateTime from, DateTime to);
}
