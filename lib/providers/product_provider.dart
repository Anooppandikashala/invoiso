import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/models/product.dart';

class ProductNotifier extends AutoDisposeAsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return ref.read(productRepositoryProvider).getAllProducts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).getAllProducts());
  }
}

// autoDispose: re-read on every open of the purchase bill form (its only
// reader), so products added/edited/restored since then show up.
final productsProvider =
    AsyncNotifierProvider.autoDispose<ProductNotifier, List<Product>>(ProductNotifier.new);
