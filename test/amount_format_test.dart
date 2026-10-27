// AmountFormat.money: each Number format style, negatives, small values,
// lakh / crore grouping and rounding.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/utils/formatters.dart';

void main() {
  tearDown(() => AmountFormat.style = AmountSeparator.none);

  test('none keeps the plain 2-decimal format', () {
    AmountFormat.style = AmountSeparator.none;
    expect(AmountFormat.money(1234567.891), '1234567.89');
    expect(AmountFormat.money(0), '0.00');
  });

  test('international groups by thousands', () {
    AmountFormat.style = AmountSeparator.international;
    expect(AmountFormat.money(1234567.89), '1,234,567.89');
    expect(AmountFormat.money(999.5), '999.50');
    expect(AmountFormat.money(-1234.5), '-1,234.50');
  });

  test('indian groups lakh / crore', () {
    AmountFormat.style = AmountSeparator.indian;
    expect(AmountFormat.money(1234567.89), '12,34,567.89');
    expect(AmountFormat.money(12345678.9), '1,23,45,678.90');
    expect(AmountFormat.money(1000), '1,000.00');
    expect(AmountFormat.money(-100000), '-1,00,000.00');
  });

  test('setting keys round-trip; unknown falls back to none', () {
    for (final s in AmountSeparator.values) {
      expect(AmountSeparatorExtension.fromKey(s.key), s);
    }
    expect(AmountSeparatorExtension.fromKey(null), AmountSeparator.none);
    expect(AmountSeparatorExtension.defaultFor('INR'), AmountSeparator.indian);
    expect(AmountSeparatorExtension.defaultFor('USD'),
        AmountSeparator.international);
  });
}
