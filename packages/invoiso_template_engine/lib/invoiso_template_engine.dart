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
///             country, stateCode, state, taxLabel, panLabel
/// customer:   name, businessName, address, phone, email, gstin, stateCode,
///             state, fields[] {label, value} (age / DOB / gender + custom
///             fields, as cells), extraLines[] (same, as the built-ins'
///             text lines)
/// shipTo:     name, phone, address, lines[] (empty unless Ship To prints)
/// invoice:    number, title, type, status, notes, paymentMethod,
///             salesperson, poNumber, date / dueDate (ISO-8601),
///             isInterState, placeOfSupplyCode, placeOfSupply,
///             custom{label: value}, customFields[] {label, value},
///             gstLines[] {label, value}, returnLines[],
///             numberLabel ("<document type> No."), keyFields[] {label,
///             value} (number, Dated, Due Date), headerFields[] {label,
///             value} (number labelled by type, Dated, Due Date, then
///             filled custom fields — the GST voucher cells)
/// items[]:    slNo, name, alias, description, typeTag, hsn, qty, unit, rate,
///             discount, tax, amount, taxRate, cgstRate, sgstRate, igstRate,
///             taxable, cgst, sgst, igst,
///             meta{key: value} (enabled product-metadata columns)
/// settings:   showGst, showQuantity, showDiscount, showTypeTag, showSlNo,
///             showTaxColumn, showCgstSgst, showIgst, showTotalQuantity,
///             showRoundOff, showDescription, descriptionNewLine,
///             showBankDetails, showUpiQr, thankYouNote, logoPosition
///             (left|right), metadataColumns[]
///             {key, label,
///             width}
/// Values hidden by the app's show/hide settings arrive empty, so lines
/// showing only them disappear; `settings.*` drive column / row `if`s.
/// taxSummary[] (per HSN + rate): hsn, rate, taxable, cgstRate, cgst,
///             sgstRate, sgst, igstRate, igst, totalTax
/// charges[]:  label, amount
/// totals:     subtotal, grossSubtotal, discount, tax, total, amountPaid,
///             balance, previousBalance, amountInWords, taxable, cgst, sgst,
///             igst, totalQty, charges, previousBalanceDue, totalDue,
///             roundedTotal, roundOff, totalInWords, taxInWords
/// bank:       name, account, ifsc, iban, upi
/// payment:    upiPayload (empty when UPI QR is off), upiAmount, qrLabel,
///             qrTitle (uploaded QR label or "Pay via UPI"; empty when off)
/// ```
/// Amounts are numbers; the engine formats them with [TemplateOptions]
/// (currency, amount separator, date pattern, time format).
///
/// Placeholders: the named ones (`{{invoice.number}}`, `{{total}}`, …) plus
/// any path into the data, case-insensitive: `{{company.fssai}}`,
/// `{{totals.taxInWords}}`, `{{invoice.custom.Vehicle No}}`,
/// `{{invoice.datetime}}`. Numbers under `totals` print as money (quantities
/// stay plain). Lists (items, taxSummary, charges) are for tables.
///
/// Engine 2 (`"engine": 2` in the document) adds building blocks:
/// `box` (border, background, padding, margin, radius, width/height, child),
/// `row` (children side by side; child `width` "30%"/points or `flex`;
/// `border` → equal-height bordered cells), `column` (stacked, `gap`),
/// `text` (`style` + size/bold/italic/color/align/uppercase/letterSpacing/
/// maxLines), `divider` (thickness/color), `pageNumber`. Document-level:
/// `page.frame` (border on every page), `pageHeader` / `pageFooter` (blocks
/// repeated per page; `{{page}}` / `{{pages}}`), `styles` (named text
/// styles), `gap` (space between top-level blocks, default 12). Documents
/// without `engine` (or `engine: 1`) render exactly as before.
///
/// Also in engine 2: `table` over any data list (`source`: items /
/// taxSummary / charges) with columns (`value` template, multi-line `cell`,
/// `width`, `align`, `if`), `border` grid|horizontal|outer|none, `header`
/// style, `zebra`, `footerRows` (cells by column `id`, `if`); header row
/// repeats on every page when the user's setting is on, or per table with
/// `repeatHeader: true / false`. `if` block (`when` / `then` / `else`) and an `if`
/// property on any block; `repeat` (one child per list item); `qr` (UPI
/// link from `payment.upiPayload` or the uploaded payment QR asset);
/// `grid` (a list as bordered cells, `columns` per row, `cell` template,
/// `spanLast` to let a short last row span the width). Text may contain
/// `**bold**` parts, e.g. "**{{row.label}}:** {{row.value}}".
/// Inside tables / repeat, `{{row.*}}` is the current item
/// (`row.displayName` honours the alias setting). Filters:
/// `{{path|money|number|qty|percent|upper|lower|capitalize}}`.
/// Conditions: "path" (set / non-zero / true), "!path",
/// {"path": .., "equals": ..}, or a list of these (all must hold).
library;

export 'src/block_layout_renderer.dart'
    show buildBlockLayoutPage, templatePageFormat;
export 'src/formatters.dart';
export 'src/template_options.dart';

/// Layout engine version. Layout documents and template packs record the
/// version they need; renderer changes must keep older versions' output.
const int kTemplateEngineVersion = 2;
