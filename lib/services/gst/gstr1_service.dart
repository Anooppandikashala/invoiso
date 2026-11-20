import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/repositories/company_info_repository.dart';
import 'package:invoiso/repositories/invoice_repository.dart';
import 'package:invoiso/repositories/purchase_bill_repository.dart';
import 'package:invoiso/models/gstr3b_summary.dart';
import 'package:invoiso/services/gst/gstr3b_builder.dart';
import 'package:invoiso/services/gst/purchase_gst_builder.dart';
import 'package:invoiso/repositories/report_repository.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';

/// GSTR-1 return period: a month, or a calendar quarter (QRMP filers).
class Gstr1Period {
  final DateTime from;
  final DateTime to;

  Gstr1Period.month(int year, int month)
      : from = DateTime(year, month),
        to = DateTime(year, month + 1, 0);

  /// [quarter] 1–4: Jan–Mar, Apr–Jun, Jul–Sep, Oct–Dec.
  Gstr1Period.quarter(int year, int quarter)
      : from = DateTime(year, quarter * 3 - 2),
        to = DateTime(year, quarter * 3 + 1, 0);
}

/// Loads a period through the repositories (SQLite or cloud) and builds the
/// GSTR-1 data with [Gstr1Builder].
class Gstr1Service {
  const Gstr1Service._();

  static Future<Gstr1Report> load(
    Gstr1Period period, {
    required InvoiceRepository invoices,
    required ReportRepository reports,
    required CompanyInfoRepository companyInfo,
  }) async {
    final docs = await invoices.getInvoicesForExport(
        fromDate: period.from, toDate: period.to);
    // Originals of the period's notes, including ones from earlier periods.
    final originals = {for (final d in docs) d.id: d};
    for (final id in {
      for (final d in docs)
        if (d.originalInvoiceId != null) d.originalInvoiceId!,
    }) {
      if (originals.containsKey(id)) continue;
      final o = await invoices.getInvoiceById(id);
      if (o != null) originals[id] = o;
    }
    final (:prefixes, :leadingZeros) = await ReportService.documentNumbering();
    String numberOf(Invoice inv) {
      final prefix = prefixes[inv.type] ?? '';
      return inv.pdfNumberText(prefix, showLeadingZeros: leadingZeros) ??
          '$prefix${inv.invoiceNumber ?? inv.id}';
    }

    return Gstr1Builder.build(Gstr1Input(
      companyGstin: (await companyInfo.getCompanyInfo())?.gstin ?? '',
      documents: docs,
      numberOf: numberOf,
      originals: originals,
      documentsIssued: await reports.getDocumentsIssued(period.from, period.to),
    ));
  }
}

/// GSTR-3B summary for a period: sales via [Gstr1Service] (same numbers as
/// the GSTR-1 export) + the period's purchase bills (PurchaseGstReportsPlan.md P5).
class Gstr3bService {
  const Gstr3bService._();

  static Future<Gstr3bSummary> load(
    Gstr1Period period, {
    required InvoiceRepository invoices,
    required ReportRepository reports,
    required CompanyInfoRepository companyInfo,
    PurchaseBillRepository? purchaseBills, // null: purchases off → no ITC
  }) async {
    final sales = await Gstr1Service.load(period,
        invoices: invoices, reports: reports, companyInfo: companyInfo);
    final gstin = (await companyInfo.getCompanyInfo())?.gstin ?? '';
    final purchases = PurchaseGstBuilder.build(
        companyGstin: gstin,
        bills: purchaseBills == null
            ? const []
            : await purchaseBills.getPurchaseBillsInRange(period.from, period.to));
    return Gstr3bBuilder.build(
        companyGstin: gstin, sales: sales, purchases: purchases);
  }
}
