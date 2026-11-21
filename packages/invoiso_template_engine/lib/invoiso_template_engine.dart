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
/// Data contract (engine version 1) — every key optional, missing = empty:
/// ```
/// company:  name, address, phone, email, website, gstin, pan
/// customer: name, businessName, address, phone, email, gstin
/// invoice:  number, title, type, status, notes, paymentMethod, salesperson,
///           poNumber, date (ISO-8601), dueDate (ISO-8601 or null),
///           isInterState
/// items[]:  name, alias, description, hsn, qty, unit, rate, discount, tax,
///           amount
/// totals:   subtotal, grossSubtotal, discount, tax, total, amountPaid,
///           balance, previousBalance, amountInWords
/// bank:     name, account, ifsc, iban, upi
/// ```
/// Amounts are numbers; the engine formats them with [TemplateOptions].
library;

export 'src/block_layout_renderer.dart' show buildBlockLayoutPage;
export 'src/template_options.dart';

/// Layout engine version. Layout documents and template packs record the
/// version they need; renderer changes must keep older versions' output.
const int kTemplateEngineVersion = 1;
