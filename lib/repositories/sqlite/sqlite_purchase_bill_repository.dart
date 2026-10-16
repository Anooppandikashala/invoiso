import 'package:invoiso/database/purchase_bill_service.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/repositories/purchase_bill_repository.dart';

class SqlitePurchaseBillRepository implements PurchaseBillRepository {
  @override
  Future<void> insertPurchaseBill(PurchaseBill bill) => PurchaseBillService.insertPurchaseBill(bill);
  @override
  Future<void> updatePurchaseBill(PurchaseBill bill) => PurchaseBillService.updatePurchaseBill(bill);
  @override
  Future<PurchaseBill?> getPurchaseBillById(String id) => PurchaseBillService.getPurchaseBillById(id);
  @override
  Future<List<PurchaseBill>> getAllPurchaseBills() => PurchaseBillService.getAllPurchaseBills();
  @override
  Future<List<PurchaseBill>> getPurchaseBillsPaginated({
    int page = 0,
    int pageSize = 50,
    String searchQuery = '',
    String orderBy = 'bill_date',
    bool orderAscending = false,
  }) =>
      PurchaseBillService.getPurchaseBillsPaginated(
        page: page,
        pageSize: pageSize,
        searchQuery: searchQuery,
        orderBy: orderBy,
        orderAscending: orderAscending,
      );
  @override
  Future<int> getPurchaseBillCount({String searchQuery = ''}) =>
      PurchaseBillService.getPurchaseBillCount(searchQuery: searchQuery);
  @override
  Future<void> softDeletePurchaseBill(String id) => PurchaseBillService.softDeletePurchaseBill(id);
  @override
  Future<void> restorePurchaseBill(String id) => PurchaseBillService.restorePurchaseBill(id);
  @override
  Future<List<PurchaseBill>> getDeletedPurchaseBills() => PurchaseBillService.getDeletedPurchaseBills();
}
