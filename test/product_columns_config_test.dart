import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';

void main() {
  test('stockEditAdminOnly defaults off, including in configs saved before it',
      () {
    expect(const ProductColumnsConfig().stockEditAdminOnly, isFalse);
    expect(ProductColumnsConfig.fromJson({'purchasePriceAdminOnly': true})
        .stockEditAdminOnly, isFalse);
  });

  test('stockEditAdminOnly survives JSON and copyWith', () {
    final on = const ProductColumnsConfig().copyWith(stockEditAdminOnly: true);
    expect(ProductColumnsConfig.fromJson(on.toJson()).stockEditAdminOnly, isTrue);
    expect(on.copyWith(stock: false).stockEditAdminOnly, isTrue);
  });
}
