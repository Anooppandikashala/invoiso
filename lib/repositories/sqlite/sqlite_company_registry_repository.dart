import 'package:invoiso/database/company_registry_service.dart';
import 'package:invoiso/models/company_profile.dart';
import 'package:invoiso/repositories/company_registry_repository.dart';

class SqliteCompanyRegistryRepository implements CompanyRegistryRepository {
  @override
  Future<List<CompanyProfile>> listCompanies() =>
      CompanyRegistryService.listCompanies();

  @override
  Future<String?> getActiveCompanyId() =>
      CompanyRegistryService.getActiveCompanyId();

  @override
  Future<void> switchToCompany(String id) =>
      CompanyRegistryService.switchToCompany(id);

  @override
  Future<CompanyProfile> createCompany(String name) =>
      CompanyRegistryService.createCompany(name);

  @override
  Future<void> renameCompany(String id, String name) =>
      CompanyRegistryService.renameCompany(id, name);

  @override
  Future<void> deleteCompany(String id) =>
      CompanyRegistryService.deleteCompany(id);
}
