import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/repositories.dart';
import '../models/invoice.dart';

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    return ref.read(invoiceRepositoryProvider).getAllInvoices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(invoiceRepositoryProvider).getAllInvoices());
  }

  Future<void> deleteInvoice(String id) async {
    await ref.read(invoiceRepositoryProvider).permanentDeleteInvoice(id);
    await refresh();
  }

  Future<void> softDeleteInvoice(String id) async {
    await ref.read(invoiceRepositoryProvider).softDeleteInvoice(id);
    await refresh();
  }
}

final invoicesProvider =
    AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(InvoiceNotifier.new);
