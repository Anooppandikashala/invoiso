import 'package:invoiso/common.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/repositories/installation_repository.dart';
import 'package:uuid/uuid.dart';

class SqliteInstallationRepository implements InstallationRepository
{
  /// Returns the unique identifier for this installation.
  ///
  /// If an identifier doesn't already exist, one is generated,
  /// persisted locally, and returned.
  @override
  Future<String> getOrCreateInstallationId() async {
    var id = await SettingsService.getSetting(
      SettingKey.installationId,
    );
    if (id != null) {
      return id;
    }
    id = const Uuid().v4();
    await SettingsService.setSetting(
      SettingKey.installationId,
      id,
    );
    return id;
  }
}