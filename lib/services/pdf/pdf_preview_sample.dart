import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';

class PdfPreviewSample {
  static CompanyInfo fallbackCompany() {
    return CompanyInfo(
      name: 'YOUR COMPANY NAME',
      address: '123 Sample Street, Sample City - 000000',
      phone: '+91 00000 00000',
      email: 'company@example.com',
      website: 'https://example.com',
      gstin: '00AAAAA0000A0Z0',
      panNumber: 'AAAAA0000A',
      fssaiCode: '00000000000000',
      country: 'India',
    );
  }

  static Invoice createSampleInvoice({CompanyInfo? company}) {
    final effectiveCompany = company != null && company.name.isNotEmpty
        ? company
        : fallbackCompany();

    final sampleProducts = [
      Product(
        id: 'sample-p1',
        name: 'Sample Product A',
        description: 'Sample product description',
        price: 450.00,
        stock: 50,
        hsncode: '8481',
        tax_rate: 18,
        unit: 'pcs',
      ),
      Product(
        id: 'sample-p2',
        name: 'Sample Product B',
        description: 'Sample product description',
        price: 180.00,
        stock: 120,
        hsncode: '4016',
        tax_rate: 18,
        unit: 'box',
      ),
      Product(
        id: 'sample-p3',
        name: 'Sample Service',
        description: 'Sample service description',
        price: 750.00,
        stock: 999,
        hsncode: '9987',
        tax_rate: 18,
        unit: 'hrs',
        type: 'service',
      ),
    ];

    final sampleItems = [
      InvoiceItem(
        product: sampleProducts[0],
        quantity: 2,
        unitPrice: 450.00,
        unit: 'pcs',
        description: 'Sample item note',
      ),
      InvoiceItem(
        product: sampleProducts[1],
        quantity: 3,
        unitPrice: 180.00,
        unit: 'box',
        discount: 10.0,
        discountIsPercent: true,
      ),
      InvoiceItem(
        product: sampleProducts[2],
        quantity: 1,
        unitPrice: 750.00,
        unit: 'hrs',
      ),
    ];

    return Invoice(
      id: 'sample-inv-preview',
      invoiceNumber: 'INV-0001',
      customer: Customer(
        id: 'sample-c1',
        name: 'SAMPLE CUSTOMER',
        businessName: 'Sample Customer Business',
        email: 'customer@example.com',
        phone: '+91 00000 00000',
        address: '456 Sample Road, Sample Town - 000000',
        gstin: '00BBBBB0000B0Z0',
      ),
      items: sampleItems,
      date: DateTime.now(),
      type: 'Invoice',
      taxRate: 0.18,
      taxMode: TaxMode.perItem,
      currencyCode: 'INR',
      currencySymbol: '₹',
      notes:
          'Sample notes and terms appear here.',
      previousBalance: 0.0,
    );
  }
}

