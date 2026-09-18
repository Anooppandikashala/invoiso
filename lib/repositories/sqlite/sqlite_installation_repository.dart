import 'package:invoiso/database/company_registry_service.dart';
import 'package:invoiso/repositories/installation_repository.dart';

class SqliteInstallationRepository implements InstallationRepository
{
  /// Returns the unique identifier for this installation.
  ///
  /// Device-level (not per-company) so it stays stable across company
  /// switches — see `CompanyRegistryService.getOrCreateInstallationId`.
  @override
  Future<String> getOrCreateInstallationId() =>
      CompanyRegistryService.getOrCreateInstallationId();
}