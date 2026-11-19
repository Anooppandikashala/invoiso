import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/gst_utils.dart';

void main() {
  test('HSN: empty or 4/6/8 digits is valid', () {
    for (final h in ['', '8471', '847130', '84713010', ' 8471 ']) {
      expect(GstUtils.isValidHsn(h), isTrue, reason: h);
    }
    for (final h in ['84', '84713', '8471A', '847130101', '84-71']) {
      expect(GstUtils.isValidHsn(h), isFalse, reason: h);
    }
  });

  test('state code from a valid GSTIN only', () {
    expect(GstUtils.stateCodeFromGstin('33ABCDE1234F1Z5'), '33');
    expect(GstUtils.stateCodeFromGstin(' 29abcde1234f1z5 '), '29');
    expect(GstUtils.stateCodeFromGstin(''), isNull);
    expect(GstUtils.stateCodeFromGstin(null), isNull);
    expect(GstUtils.stateCodeFromGstin('33ABCDE1234F1X5'), isNull); // 14th char must be Z
  });
}
