import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/repositories.dart';
import '../models/product.dart';

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return ref.read(productRepositoryProvider).getAllProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).getAllProducts());
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);
