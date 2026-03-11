import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/product_service.dart';
import '../models/product.dart';

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return ProductService.getAllProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ProductService.getAllProducts());
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);
