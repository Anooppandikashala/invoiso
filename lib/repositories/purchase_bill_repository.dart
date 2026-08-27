import 'package:invoiso/models/purchase_bill.dart';

abstract class PurchaseBillRepository {
  Future<void> insertPurchaseBill(PurchaseBill bill);
  Future<void> updatePurchaseBill(PurchaseBill bill);
  Future<PurchaseBill?> getPurchaseBillById(String id);
  Future<List<PurchaseBill>> getAllPurchaseBills();
  Future<List<PurchaseBill>> getPurchaseBillsPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
    String orderBy = 'bill_date',
    bool orderAscending = false,
  });
  Future<int> getPurchaseBillCount({String searchQuery = ''});
  Future<void> softDeletePurchaseBill(String id);
  Future<void> restorePurchaseBill(String id);
  Future<List<PurchaseBill>> getDeletedPurchaseBills();
}
