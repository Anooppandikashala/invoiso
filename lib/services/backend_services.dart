import '../repositories/company_info_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/settings_repository.dart';

/// Non-widget service classes (PDF generation, thermal printing, exports, update
/// checks) can't use `ref.read(...)` — they're plain static classes, not part of
/// the widget tree. This is the seam that lets them reach the correct backend
/// (SQLite vs Supabase) anyway: each app's main() calls [configure] once, with
/// the same repository instances it passes to ProviderScope, before runApp.
class BackendServices {
  static SettingsRepository? _settings;
  static CompanyInfoRepository? _companyInfo;
  static InvoiceRepository? _invoices;
  static PaymentRepository? _payments;

  static void configure({
    required SettingsRepository settings,
    required CompanyInfoRepository companyInfo,
    required InvoiceRepository invoices,
    required PaymentRepository payments,
  }) {
    _settings = settings;
    _companyInfo = companyInfo;
    _invoices = invoices;
    _payments = payments;
  }

  static SettingsRepository get settings => _settings ??
      (throw StateError('BackendServices.configure() was never called.'));
  static CompanyInfoRepository get companyInfo => _companyInfo ??
      (throw StateError('BackendServices.configure() was never called.'));
  static InvoiceRepository get invoices => _invoices ??
      (throw StateError('BackendServices.configure() was never called.'));
  static PaymentRepository get payments => _payments ??
      (throw StateError('BackendServices.configure() was never called.'));
}
