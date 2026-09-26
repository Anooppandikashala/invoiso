import 'package:invoiso/database/cash_ledger_service.dart';
import 'package:invoiso/models/cash_ledger_entry.dart';
import 'package:invoiso/repositories/cash_ledger_repository.dart';

class SqliteCashLedgerRepository implements CashLedgerRepository {
  @override
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
  }) =>
      CashLedgerService.addExchange(
        upiToCash: upiToCash,
        amount: amount,
        fee: fee,
        feeMethod: feeMethod,
        dateTime: dateTime,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        createdBy: createdBy,
      );

  @override
  Future<CashLedgerEntry> addMovement({
    required String type,
    required double amount,
    String account = CashLedgerEntry.accountCash,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  }) =>
      CashLedgerService.addMovement(
        type: type,
        amount: amount,
        account: account,
        dateTime: dateTime,
        notes: notes,
        createdBy: createdBy,
      );

  @override
  Future<CashLedgerEntry> addAdjustment({
    double cashDelta = 0,
    double upiDelta = 0,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  }) =>
      CashLedgerService.addAdjustment(
        cashDelta: cashDelta,
        upiDelta: upiDelta,
        dateTime: dateTime,
        notes: notes,
        createdBy: createdBy,
      );

  @override
  Future<void> saveOpening({
    required double cash,
    required double upiBank,
    required DateTime date,
    String? createdBy,
  }) =>
      CashLedgerService.saveOpening(
          cash: cash, upiBank: upiBank, date: date, createdBy: createdBy);

  @override
  Future<void> deleteEntry(String id) => CashLedgerService.deleteEntry(id);

  @override
  Future<CashLedgerEntry?> getOpening() => CashLedgerService.getOpening();

  @override
  Future<List<CashLedgerEntry>> getEntries({
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
    int limit = 25,
    int offset = 0,
  }) =>
      CashLedgerService.getEntries(
          from: from,
          to: to,
          type: type,
          paymentsFrom: paymentsFrom,
          limit: limit,
          offset: offset);

  @override
  Future<int> countEntries({
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
  }) =>
      CashLedgerService.countEntries(
          from: from, to: to, type: type, paymentsFrom: paymentsFrom);

  @override
  Future<CashBalances> getBalances({DateTime? before}) =>
      CashLedgerService.getBalances(before: before);

  @override
  Future<CashPeriodTotals> getPeriodTotals(DateTime from, DateTime to) =>
      CashLedgerService.getPeriodTotals(from, to);
}
