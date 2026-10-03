import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/customer_list_stats.dart';

abstract class CustomerRepository {
  Future<void> insertCustomer(Customer customer);
  Future<void> updateCustomer(Customer customer);
  Future<Customer?> getCustomerById(String id);
  Future<List<Customer>> getAllCustomers();
  Future<int> getTotalCustomerCount();
  Future<void> deleteCustomer(String id);
  Future<Customer?> findByPhone(String phone);
  Future<Customer?> findByEmail(String email);
  Future<Customer?> findDuplicate(String email, String phone);
  Future<void> deleteAllCustomers();
  Future<void> insertBatch(List<Customer> customers);
  Future<List<Customer>> getCustomersPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
  });
  /// Customer management list (Issues.md #43). [tab]: 'all' | 'business' |
  /// 'individual' | 'tax' | 'no_tax'. Search: name, email, phone, business
  /// name, address, tax number.
  Future<List<Customer>> getCustomerListPage({
    required int offset,
    required int limit,
    String query = '',
    String tab = 'all',
    String orderBy = 'name',
    bool ascending = true,
  });
  Future<int> getCustomerListCount({String query = '', String tab = 'all'});
  Future<List<String>> getCustomerListIds({
    String query = '',
    String tab = 'all',
    String orderBy = 'name',
    bool ascending = true,
  });
  Future<List<Customer>> getCustomersByIds(List<String> ids);
  Future<CustomerListStats> getCustomerListStats();
}
