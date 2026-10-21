import 'package:invoiso/common/setting_key.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/repositories/settings_repository.dart';

/// Which optional customer fields are switched on in Settings → Customer.
class CustomerFieldSettings {
  final bool age;
  final bool dob;
  final bool gender;
  final bool shipping;
  final bool customFields;
  final List<CustomFieldDef> customFieldDefs; // sorted by sortOrder
  // Print on PDF (only matters when the field itself is on). Custom fields
  // use CustomFieldDef.showInPdf per definition.
  final bool ageInPdf;
  final bool dobInPdf;
  final bool genderInPdf;
  final bool shipToInPdf;

  const CustomerFieldSettings({
    this.age = false,
    this.dob = false,
    this.gender = false,
    this.shipping = false,
    this.customFields = false,
    this.customFieldDefs = const [],
    this.ageInPdf = true,
    this.dobInPdf = true,
    this.genderInPdf = true,
    this.shipToInPdf = true,
  });

  bool get any =>
      age || dob || gender || shipping || (customFields && customFieldDefs.isNotEmpty);

  static Future<CustomerFieldSettings> load(SettingsRepository repo) async {
    final flags = await Future.wait([
      repo.getSetting(SettingKey.customerAgeEnabled),
      repo.getSetting(SettingKey.customerDobEnabled),
      repo.getSetting(SettingKey.customerGenderEnabled),
      repo.getSetting(SettingKey.shippingAddressEnabled),
      repo.getSetting(SettingKey.customerCustomFieldsEnabled),
      repo.getSetting(SettingKey.showCustomerAgeInPdf),
      repo.getSetting(SettingKey.showCustomerDobInPdf),
      repo.getSetting(SettingKey.showCustomerGenderInPdf),
      repo.getSetting(SettingKey.showShipToInPdf),
    ]);
    final defs = [...await repo.getCustomerCustomFieldDefs()]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return CustomerFieldSettings(
      age: flags[0] == 'true',
      dob: flags[1] == 'true',
      gender: flags[2] == 'true',
      shipping: flags[3] == 'true',
      customFields: flags[4] == 'true',
      customFieldDefs: defs,
      ageInPdf: flags[5] != 'false',
      dobInPdf: flags[6] != 'false',
      genderInPdf: flags[7] != 'false',
      shipToInPdf: flags[8] != 'false',
    );
  }
}
