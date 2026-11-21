/// Invoiso template engine: JSON layout document + invoice data → PDF page.
///
/// Pure Dart with no imports from the app, so the desktop app, the cloud
/// edition and the template tools all render templates the same way.
///
/// ```dart
/// pdf.addPage(buildBlockLayoutPage(
///   document: layoutJson,   // { page, theme, layout: [...] }
///   data: templateData,     // see data contract below
///   options: const TemplateOptions(currencySymbol: '₹'),
///   assets: TemplateAssets(logo: logoBytes, signature: signatureBytes),
/// ));
/// ```
///
/// Data contract — every key optional, missing = empty:
/// ```
/// company:    name, address, phone, email, website, gstin, pan, fssai,
///             country, stateCode, state
/// customer:   name, businessName, address, phone, email, gstin, stateCode,
///             state, custom{label: value}
/// shipTo:     name, phone, address
/// invoice:    number, title, type, status, notes, paymentMethod,
///             salesperson, poNumber, date / dueDate (ISO-8601),
///             isInterState, placeOfSupplyCode, placeOfSupply,
///             custom{label: value}
/// items[]:    slNo, name, alias, description, typeTag, hsn, qty, unit, rate,
///             discount, tax, amount, taxRate, taxable, cgst, sgst, igst
/// taxSummary[] (per HSN + rate): hsn, rate, taxable, cgstRate, cgst,
///             sgstRate, sgst, igstRate, igst, totalTax
/// charges[]:  label, amount
/// totals:     subtotal, grossSubtotal, discount, tax, total, amountPaid,
///             balance, previousBalance, amountInWords, taxable, cgst, sgst,
///             igst, totalQty, charges, previousBalanceDue, totalDue,
///             roundedTotal, roundOff, totalInWords, taxInWords
/// bank:       name, account, ifsc, iban, upi
/// ```
/// Amounts are numbers; the engine formats them with [TemplateOptions]
/// (currency, amount separator, date pattern, time format).
///
/// Placeholders: the named ones (`{{invoice.number}}`, `{{total}}`, …) plus
/// any path into the data, case-insensitive: `{{company.fssai}}`,
/// `{{totals.taxInWords}}`, `{{invoice.custom.Vehicle No}}`,
/// `{{invoice.datetime}}`. Numbers under `totals` print as money (quantities
/// stay plain). Lists (items, taxSummary, charges) are for tables.
library;

export 'src/block_layout_renderer.dart' show buildBlockLayoutPage;
export 'src/formatters.dart';
export 'src/template_options.dart';

/// Layout engine version. Layout documents and template packs record the
/// version they need; renderer changes must keep older versions' output.
const int kTemplateEngineVersion = 1;
