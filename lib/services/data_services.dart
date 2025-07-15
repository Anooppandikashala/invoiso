import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product.dart';

// Data Service
class DataService {
  static List<Customer> customers = [
    Customer(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '123-456-7890',
        address: '123 Main St'),
    Customer(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        phone: '098-765-4321',
        address: '456 Oak Ave'),
  ];

  static List<Product> products = [
    Product(
        id: '1',
        name: 'Laptop',
        description: 'High-performance laptop',
        price: 999.99,
        stock: 10),
    Product(
        id: '2',
        name: 'Mouse',
        description: 'Wireless mouse',
        price: 25.99,
        stock: 50),
    Product(
        id: '3',
        name: 'Keyboard',
        description: 'Mechanical keyboard',
        price: 79.99,
        stock: 25),
  ];

  static List<Invoice> invoices = [];

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}