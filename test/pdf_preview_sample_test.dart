import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'test_pdf_font_service.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';
import 'package:invoiso/services/pdf/pdf_preview_sample.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfPreviewSample & All Templates Generation Test', () {
    late pw.ThemeData pdfTheme;
    late Uint8List logoBytes;
    late Uint8List watermarkBytes;
    late Uint8List signatureBytes;

    setUpAll(() async {
      pdfTheme = await TestPdfFontService.loadTheme();
      logoBytes = await File('assets/images/demo_logo.png').readAsBytes();
      watermarkBytes = await File('assets/images/watermark.png').readAsBytes();
      signatureBytes = await File('assets/images/sig.jpeg').readAsBytes();
    });

    for (final template in InvoiceTemplate.values) {
      test('Generates preview PDF successfully for ${template.name}', () async {
        final pageSize = switch (template) {
          InvoiceTemplate.thermal => PageSize.thermal80,
          InvoiceTemplate.compact => PageSize.a6,
          _ => PageSize.a4,
        };

        final settings = PdfGenerationSettings(
          company: PdfPreviewSample.fallbackCompany(),
          template: template,
          invoicePrefix: 'INV-',
          showGst: true,
          showQuantity: true,
          showDiscount: true,
          showTypeTag: true,
          businessType: BusinessType.both,
          upiEntries: const [
            UpiEntry(label: 'UPI', id: 'sample@upi', isDefault: true),
          ],
          showQrStr: 'true',
          showBankDetails: true,
          bankAccounts: const [
            BankAccount(
              label: 'Default Bank',
              bankName: 'Sample Bank',
              accountNumber: '1234567890',
              ifscCode: 'SMPL0001234',
              isDefault: true,
            ),
          ],
          logoPosition: LogoPosition.left,
          logoSizePx: 80,
          logoBytes: logoBytes,
          thankYouNote: 'Thank you for your business!',
          datePattern: 'dd/MM/yyyy',
          showFooterBranding: true,
          themeColor: null,
          showPreviousBalance: true,
          pageFormat: PDFService.pageSizeToFormat(pageSize),
          pageSize: pageSize,
          showTotalQuantity: true,
          pdfTheme: pdfTheme,
          watermarkBytes: watermarkBytes,
          signatureBytes: signatureBytes,
          showCgstSgst: true,
          letterheadEnabled: false,
        );

        final invoice = PdfPreviewSample.createSampleInvoice(
          company: settings.company,
        );
        final doc = PDFService.generateInvoicePDFWithSettings(
          invoice,
          settings,
        );
        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(500));
      });
    }
  });
}

