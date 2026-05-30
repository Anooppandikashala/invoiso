class PaymentReceiptNumbers {
  const PaymentReceiptNumbers._();

  static int maxReceiptSuffix(Iterable<String?> receiptNumbers) {
    var maxSuffix = 0;
    for (final receiptNumber in receiptNumbers) {
      if (receiptNumber == null) continue;
      final dashR = receiptNumber.lastIndexOf('-R');
      if (dashR == -1) continue;
      final suffix = int.tryParse(receiptNumber.substring(dashR + 2)) ?? 0;
      if (suffix > maxSuffix) maxSuffix = suffix;
    }
    return maxSuffix;
  }

  static String nextReceiptNumber({
    required String invoiceId,
    required Iterable<String?> existingReceiptNumbers,
  }) {
    return '$invoiceId-R${maxReceiptSuffix(existingReceiptNumbers) + 1}';
  }
}
