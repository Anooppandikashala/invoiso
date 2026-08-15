import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/supplier_payment.dart';

abstract class SupplierPaymentRepository {
  Future<SupplierPayment> addPayment({
    required PurchaseBill bill,
    required double amountPaid,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  });
  Future<List<SupplierPayment>> getPaymentsForBill(String billId);
  Future<double> getTotalPaidForBill(String billId);
  Future<Map<String, double>> getTotalPaidBatch(List<String> billIds);
  Future<void> deletePayment(String paymentId);
}
