import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/repositories/product_repository.dart';

class SqliteProductRepository implements ProductRepository {
  @override
  Future<void> insertProduct(Product product) => ProductService.insertProduct(product);
  @override
  Future<List<Product>> getAllProducts() => ProductService.getAllProducts();
  @override
  Future<int> getTotalProductCount() => ProductService.getTotalProductCount();
  @override
  Future<Product?> getProductById(String id) => ProductService.getProductById(id);
  @override
  Future<void> updateProduct(Product product) => ProductService.updateProduct(product);
  @override
  Future<List<Product>> searchProducts(String query, {String? type}) =>
      ProductService.searchProducts(query, type: type);
  @override
  Future<List<Product>> getProductsPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
    String? type,
  }) =>
      ProductService.getProductsPaginated(
        offset: offset,
        limit: limit,
        query: query,
        orderBy: orderBy,
        orderASC: orderASC,
        type: type,
      );
  @override
  Future<int> getProductCount([String query = '', String? type]) =>
      ProductService.getProductCount(query, type);
  @override
  Future<void> deleteProduct(String id) => ProductService.deleteProduct(id);
  @override
  Future<void> updateProductStock(String id, int newStock) =>
      ProductService.updateProductStock(id, newStock);
  @override
  Future<bool> hasSufficientStock(String productId, int quantity) =>
      ProductService.hasSufficientStock(productId, quantity);
  @override
  Future<Product?> findDuplicateByName(String name) => ProductService.findDuplicateByName(name);
  @override
  Future<void> deleteAllProducts() => ProductService.deleteAllProducts();
  @override
  Future<void> insertBatch(List<Product> products, {int batchSize = 50}) =>
      ProductService.insertBatch(products, batchSize: batchSize);
  @override
  Future<List<Product>> getOutOfStockProducts() => ProductService.getOutOfStockProducts();
}
