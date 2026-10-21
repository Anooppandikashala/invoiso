import 'package:invoiso/database/supplier_service.dart';
import 'package:invoiso/models/supplier.dart';
import 'package:invoiso/repositories/supplier_repository.dart';

class SqliteSupplierRepository implements SupplierRepository {
  @override
  Future<void> insertSupplier(Supplier supplier) => SupplierService.insertSupplier(supplier);
  @override
  Future<void> updateSupplier(Supplier supplier) => SupplierService.updateSupplier(supplier);
  @override
  Future<Supplier?> getSupplierById(String id) => SupplierService.getSupplierById(id);
  @override
  Future<List<Supplier>> getAllSuppliers() => SupplierService.getAllSuppliers();
  @override
  Future<int> getTotalSupplierCount() => SupplierService.getTotalSupplierCount();
  @override
  Future<List<Supplier>> getSuppliersPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
  }) =>
      SupplierService.getSuppliersPaginated(
        offset: offset,
        limit: limit,
        query: query,
        orderBy: orderBy,
        orderASC: orderASC,
      );
  @override
  Future<int> getSupplierCount([String query = '']) => SupplierService.getSupplierCount(query);
  @override
  Future<void> softDeleteSupplier(String id) => SupplierService.softDeleteSupplier(id);
  @override
  Future<void> restoreSupplier(String id) => SupplierService.restoreSupplier(id);
  @override
  Future<List<Supplier>> getDeletedSuppliers() => SupplierService.getDeletedSuppliers();
  @override
  Future<double> getOutstandingBalance(String supplierId) => SupplierService.getOutstandingBalance(supplierId);
}
