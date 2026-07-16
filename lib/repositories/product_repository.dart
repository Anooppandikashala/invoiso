import 'package:invoiso/models/product.dart';

abstract class ProductRepository {
  Future<void> insertProduct(Product product);
  Future<List<Product>> getAllProducts();
  Future<int> getTotalProductCount();
  Future<Product?> getProductById(String id);
  Future<void> updateProduct(Product product);
  Future<List<Product>> searchProducts(String query, {String? type});
  Future<List<Product>> getProductsPaginated({
    required int offset,
    required int limit,
    String query = '',
    String orderBy = 'name',
    bool orderASC = true,
    String? type,
  });
  Future<int> getProductCount([String query = '', String? type]);
  Future<void> deleteProduct(String id);
  Future<void> updateProductStock(String id, int newStock);
  Future<bool> hasSufficientStock(String productId, int quantity);
  Future<Product?> findDuplicateByName(String name);
  Future<void> deleteAllProducts();
  Future<void> insertBatch(List<Product> products, {int batchSize = 50});
  Future<List<Product>> getOutOfStockProducts();
}
