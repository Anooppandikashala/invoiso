// Invoice.pdfNumberText: drafts preview with "DRAFT" in place of a number.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';

void main() {
  Invoice doc({bool isDraft = false, bool hideNumber = false}) => Invoice(
        id: 'id-1',
        invoiceNumber: isDraft ? null : '007',
        customer: Customer(
            id: 'c1', name: 'C', email: '', phone: '', address: '', gstin: ''),
        items: [],
        date: DateTime(2026, 1, 1),
        dueDate: DateTime(2026, 1, 15),
        type: 'Invoice',
        isDraft: isDraft,
        hideInvoiceNumber: hideNumber,
        customInvoiceNumber: hideNumber ? 'X-9' : null,
      );

  test('draft shows DRAFT, without prefix, even with a custom number', () {
    expect(doc(isDraft: true).pdfNumberText('INV-'), 'DRAFT');
    expect(doc(isDraft: true, hideNumber: true).pdfNumberText('INV-'), 'DRAFT');
  });

  test('final invoice number unchanged', () {
    expect(doc().pdfNumberText('INV-'), 'INV-007');
    expect(doc().pdfNumberText('INV-', showLeadingZeros: false), 'INV-7');
    expect(doc(hideNumber: true).pdfNumberText('INV-'), 'X-9');
  });
}
