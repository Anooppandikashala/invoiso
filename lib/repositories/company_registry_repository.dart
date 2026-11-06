import 'package:invoiso/models/company_profile.dart';

/// The companies this app can switch between. Local edition: one SQLite file
/// per company, registry in shared_prefs (`CompanyRegistryService`). Cloud
/// edition: the organizations the signed-in user belongs to.
abstract class CompanyRegistryRepository {
  /// Every company, oldest first. Empty when nothing is available yet (cloud
  /// before sign-in).
  Future<List<CompanyProfile>> listCompanies();
  Future<String?> getActiveCompanyId();

  /// Makes [id] the active company. Callers reload anything they hold.
  Future<void> switchToCompany(String id);

  /// Registers a new company without switching to it.
  Future<CompanyProfile> createCompany(String name);

  /// The registry label shown in company pickers (not company_info).
  Future<void> renameCompany(String id, String name);
  Future<void> deleteCompany(String id);
}
