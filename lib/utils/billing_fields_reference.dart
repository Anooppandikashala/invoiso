/// Names and descriptions of the billing fields that can be printed on an
/// invoice, quotation, receipt, credit note or debit note.
///
/// This is reference text only: copying it has no effect on the PDF output.
/// It exists so the field list can be pasted into a layout design (or a new
/// billing layout) without having to dig through the renderer.
class BillingFieldsReference {
  const BillingFieldsReference._();

  /// Human-readable field reference, in the same placeholder form that the
  /// block layout renderer understands (`{{invoice.number}}`, `{{total}}`,
  /// and so on). Item column keys are listed separately because they are
  /// written as plain column names inside an items/table block.
  static const String text = '''
INVOISO - BILLING FIELDS REFERENCE
Use these field names when designing a new billing layout.
Placeholders are written as {{field.name}}.

DOCUMENT
invoice.number       Invoice number as printed (custom number when the real number is hidden)
invoice.date         Invoice / order date
invoice.duedate      Due date (empty when no due date is set)
invoice.type         Document type: Invoice, Quotation, Receipt, Credit Note or Debit Note
invoice.title        Printed document title (Tax Invoice, Bill of Supply, etc.)
invoice.status       Document status (for example draft, sent, accepted, declined)
invoice.notes        Notes / terms printed on the document
invoice.paymentmethod  Payment method of the latest payment
invoice.salesperson  Salesperson custom field, when present
invoice.ponumber     Purchase order custom field, when present

CUSTOMER (BILL TO)
customer.name          Customer name
customer.businessname  Customer business / company name
customer.address       Customer billing address
customer.phone         Customer phone number
customer.email         Customer email address
customer.gstin         Customer GSTIN / tax ID

SELLER (YOUR COMPANY)
company.name      Company name
company.address   Company address
company.phone     Company phone number
company.email     Company email address
company.website   Company website
company.gstin     Company GSTIN
company.pan       Company PAN

LINE ITEMS (one row per item)
slno         Serial number (aliases: sl_no, #, no)
name         Item / product name (aliases: item, product)
description  Item description (alias: desc)
hsn          HSN / SAC code (aliases: hsncode, hsn_code)
qty          Quantity (alias: quantity)
unit         Unit of measure
price        Unit price (alias: rate)
discount     Line discount amount
tax          Line tax amount
amount       Line total (alias: total)

TOTALS
grossSubtotal   Sum of line totals before discounts (alias: gross_subtotal)
subtotal        Net subtotal
discount        Total of line discounts plus the invoice-level discount
tax             Total tax
cgst            Central GST share (not used on interstate supply)
sgst            State GST share (not used on interstate supply)
igst            Integrated GST (interstate supply only)
total           Grand total (alias: grandtotal)
amountPaid      Amount already received
balance         Outstanding balance (aliases: outstanding, amountdue)
previousBalance Previous balance carried into this invoice
amountInWords   Grand total written in words (alias: amount_in_words)

PAYMENT / BANK DETAILS
bank.name     Bank name
bank.account  Bank account number (alias: bank.accountnumber)
bank.ifsc     IFSC code
bank.iban     IBAN
bank.upi      UPI ID

CUSTOM FIELDS
Any custom field can be printed by its label; for example a field labelled
"Vehicle No" can be included in a layout as a custom-field block.

NOTE
This reference lists field names and descriptions only. It does not change
any saved template or PDF settings.
''';
}
