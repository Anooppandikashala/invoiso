import 'package:invoiso/common/common.dart';
import 'package:invoiso/domain/purchase_bill_calculator.dart';
import 'package:invoiso/domain/purchase_bill_totals_calculator.dart';
import 'purchase_bill_item.dart';
import 'supplier_payment.dart';

class PurchaseBill {
  String id;
  String? supplierId; // nullable — walk-in/free-text supplier via supplierName only
  String supplierName;
  String? billNumber;
  DateTime billDate;
  String? notes;
  String? attachmentPath; // reserved for future OCR, no UI yet
  List<PurchaseBillItem> items;
  List<SupplierPayment> payments;
  DateTime? createdAt;

  PurchaseBill({
    required this.id,
    this.supplierId,
    this.supplierName = '',
    this.billNumber,
    required this.billDate,
    this.notes,
    this.attachmentPath,
    required this.items,
    this.payments = const [],
    this.createdAt,
  });

  PurchaseBillTotals get _totals => PurchaseBillTotalsCalculator.totals(
        lines: items.map((item) => PurchaseBillTotalsCalculator.line(
              costPerUnit: item.costPerUnit,
              quantity: item.quantity,
              taxRatePercent: item.taxRate,
            )),
      );

  double get subtotal => _totals.subtotal;

  double get tax => _totals.tax;

  double get total => _totals.total;

  double get amountPaid => payments.fold(0.0, (sum, p) => sum + p.amountPaid);

  double get outstandingBalance =>
      PurchaseBillCalculator.outstanding(total: total, paid: amountPaid);

  PaymentStatus get paymentStatus =>
      PurchaseBillCalculator.paymentStatus(total: total, paid: amountPaid);
}
