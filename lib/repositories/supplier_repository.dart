import 'package:invoiso/models/supplier.dart';

abstract class SupplierRepository {
  Future<void> insertSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<Supplier?> getSupplierById(String id);
  Future<List<Supplier>> getAllSuppliers();
  Future<int> getTotalSupplierCount();
  Future<List<Supplier>> getSuppliersPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
  });
  Future<int> getSupplierCount([String query = '']);
  Future<void> softDeleteSupplier(String id);
  Future<void> restoreSupplier(String id);
  Future<List<Supplier>> getDeletedSuppliers();
  Future<double> getOutstandingBalance(String supplierId);
}
