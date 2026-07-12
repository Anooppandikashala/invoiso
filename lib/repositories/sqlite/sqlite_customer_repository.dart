import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/repositories/customer_repository.dart';

class SqliteCustomerRepository implements CustomerRepository {
  @override
  Future<void> insertCustomer(Customer customer) => CustomerService.insertCustomer(customer);
  @override
  Future<void> updateCustomer(Customer customer) => CustomerService.updateCustomer(customer);
  @override
  Future<Customer?> getCustomerById(String id) => CustomerService.getCustomerById(id);
  @override
  Future<List<Customer>> getAllCustomers() => CustomerService.getAllCustomers();
  @override
  Future<int> getTotalCustomerCount() => CustomerService.getTotalCustomerCount();
  @override
  Future<void> deleteCustomer(String id) => CustomerService.deleteCustomer(id);
  @override
  Future<Customer?> findByPhone(String phone) => CustomerService.findByPhone(phone);
  @override
  Future<Customer?> findByEmail(String email) => CustomerService.findByEmail(email);
  @override
  Future<Customer?> findDuplicate(String email, String phone) => CustomerService.findDuplicate(email, phone);
  @override
  Future<void> deleteAllCustomers() => CustomerService.deleteAllCustomers();
  @override
  Future<void> insertBatch(List<Customer> customers) => CustomerService.insertBatch(customers);
  @override
  Future<List<Customer>> getCustomersPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
  }) =>
      CustomerService.getCustomersPaginated(
        offset: offset,
        limit: limit,
        query: query,
        orderBy: orderBy,
        orderASC: orderASC,
      );
}
