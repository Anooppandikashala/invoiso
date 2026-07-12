import 'package:invoiso/models/customer.dart';

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
}
