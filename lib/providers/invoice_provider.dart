import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/invoice_service.dart';
import '../models/invoice.dart';

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    return InvoiceService.getAllInvoices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => InvoiceService.getAllInvoices());
  }

  Future<void> deleteInvoice(String id) async {
    await InvoiceService.permanentDeleteInvoice(id);
    await refresh();
  }

  Future<void> softDeleteInvoice(String id) async {
    await InvoiceService.softDeleteInvoice(id);
    await refresh();
  }
}

final invoicesProvider =
    AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(InvoiceNotifier.new);
