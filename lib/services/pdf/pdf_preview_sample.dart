import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';

class PdfPreviewSample {
  static CompanyInfo fallbackCompany() {
    return CompanyInfo(
      name: 'ACME ENTERPRISES LTD',
      address: '102 Industrial Tech Park, Central Avenue, Sector 5',
      phone: '+91 9876543210',
      email: 'billing@acme-enterprises.com',
      website: 'https://acme-enterprises.com',
      gstin: '27AABCA1234A1Z5',
      panNumber: 'AABCA1234A',
      fssaiCode: '10012011000123',
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
        name: 'Precision Valve Assembly A-100',
        description: 'Industrial grade stainless steel 316, pressure rated',
        price: 450.00,
        stock: 50,
        hsncode: '8481',
        tax_rate: 18,
        unit: 'pcs',
      ),
      Product(
        id: 'sample-p2',
        name: 'Hydraulic Seal Kit (Pack of 5)',
        description: 'High-temperature resistant synthetic polymer',
        price: 180.00,
        stock: 120,
        hsncode: '4016',
        tax_rate: 18,
        unit: 'box',
      ),
      Product(
        id: 'sample-p3',
        name: 'Annual System Maintenance & Inspection',
        description: 'Comprehensive calibration and preventative servicing',
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
        description: 'Batch #2026-B, Certified ISO 9001',
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
      invoiceNumber: 'INV-2026-0042',
      customer: Customer(
        id: 'sample-c1',
        name: 'BHARAT ENGINEERING WORKS',
        businessName: 'Bharat Engineering Works Pvt Ltd',
        email: 'procurement@bharateng.com',
        phone: '+91 9123456789',
        address: 'Plot 45, MIDC Industrial Area, Pune, Maharashtra - 411018',
        gstin: '27AABCB9876B1Z2',
      ),
      items: sampleItems,
      date: DateTime.now(),
      type: 'Invoice',
      taxRate: 0.18,
      taxMode: TaxMode.perItem,
      currencyCode: 'INR',
      currencySymbol: '₹',
      notes:
          '1. Goods once sold will not be taken back without authorization.\n2. Payment due within 15 days of invoice date.\n3. Subject to local jurisdiction.',
      previousBalance: 0.0,
    );
  }
}

