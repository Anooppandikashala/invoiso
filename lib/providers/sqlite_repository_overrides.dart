import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/repositories/sqlite/sqlite_auth_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_customer_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_item_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_product_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_report_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';

final sqliteRepositoryOverrides = <Override>[
  customerRepositoryProvider.overrideWith(
        (ref) => SqliteCustomerRepository(),
  ),
  invoiceRepositoryProvider.overrideWith(
        (ref) => SqliteInvoiceRepository(),
  ),
  productRepositoryProvider.overrideWith(
        (ref) => SqliteProductRepository(),
  ),
  paymentRepositoryProvider.overrideWith(
        (ref) => SqlitePaymentRepository(),
  ),
  companyInfoRepositoryProvider.overrideWith(
        (ref) => SqliteCompanyInfoRepository(),
  ),
  settingsRepositoryProvider.overrideWith(
        (ref) => SqliteSettingsRepository(),
  ),
  reportRepositoryProvider.overrideWith(
        (ref) => SqliteReportRepository(),
  ),
  invoiceItemRepositoryProvider.overrideWith(
        (ref) => SqliteInvoiceItemRepository(),
  ),
  authRepositoryProvider.overrideWith(
        (ref) => SqliteAuthRepository(),
  ),
];