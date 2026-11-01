# Contributions

My contributions to Invoiso by [@Dgman77](https://github.com/Dgman77).

## Latest updates

- Added a **copy button** to the **Invoice Details** header on the create-invoice screen. It copies the billing field names and descriptions (document, customer, seller, line items, totals, payment/bank and custom fields) for future billing-layout design.
- Added `lib/utils/billing_fields_reference.dart` with the shared billing-field reference text.
- Updated `test/pdf_settings_custom_layout_test.dart`, removed `test/custom_layout_import_test.dart`, and added `test/billing_fields_reference_test.dart`.

## PDF settings and custom invoice layouts (v4.4.9)

- Built the block-based custom invoice layout engine (`lib/services/pdf/pdf_template_block_layout.dart`) that renders user-imported layout documents with `header`, `divider`, `twoColumn`, `table`, `summary`, `box`, `signature` and `footer` blocks.
- Added the `CustomInvoiceLayout` model with lenient JSON parsing, validation, normalization and round-trip export, so hand-written and older imported layouts still load correctly.
- Rebuilt the PDF settings screen as `pdf_settings_screen_v2.dart` with saved-layout management: preview, edit JSON, and delete existing inserted layouts.
- Added a block-layout JSON editor with validation feedback for existing inserted layouts.
- Added `BlockLayoutSketch`, a live sketch of the actual imported layout (blocks, placeholders and accent colour) used in the layout gallery and preview instead of the built-in template thumbnail.
- Added letterhead and software-branding controls, page margin presets and validation, and a real print preview.
- Added sample invoice data for PDF previews so layouts can be previewed without using real customer data.
- Reworked the Classic, Modern, Minimal, Compact, Executive and Grid Classic PDF templates to support the new layout settings.
- Updated the template list tile to show the selected layout's own preview and accent colour.
- Updated analyzer options and the Windows installer scripts (`installer/bill_v2.iss`, `installer/bill_v3.iss`).

## Tests

- `test/custom_invoice_layout_test.dart` — model parsing, validation and export
- `test/billing_fields_reference_test.dart` — billing field reference contents
- `test/pdf_custom_layout_render_test.dart` — block layout rendering
- `test/pdf_settings_custom_layout_test.dart` — inserted-layout listing, JSON editing and Add Layout removal
- `test/pdf_letterhead_print_test.dart` — letterhead and print rendering
- `test/pdf_preview_sample_test.dart` — preview sample data
- `test/template_list_tile_test.dart` — template preview tile
