import 'custom_field_value.dart';

// Data Models
class Customer {
  String id;
  String name;
  String email;
  String phone;
  String address;
  String gstin;
  String businessName;
  bool shippingSameAsBilling;
  String shippingName;
  String shippingPhone;
  String shippingAddress;
  String dob; // ISO 'yyyy-MM-dd', '' = not set
  int? age; // manual age, only used when dob is empty
  String gender; // '' | 'male' | 'female' | 'other'
  List<CustomFieldValue> customFields;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.gstin,
    this.businessName = '',
    this.shippingSameAsBilling = true,
    this.shippingName = '',
    this.shippingPhone = '',
    this.shippingAddress = '',
    this.dob = '',
    this.age,
    this.gender = '',
    this.customFields = const [],
  });

  /// Age at [on]: computed from [dob] when set, else the manually entered [age].
  int? ageOn(DateTime on) => ageFromDob(dob, on) ?? age;

  /// Whole years between [dob] ('yyyy-MM-dd') and [on]; null when dob is unset/invalid.
  static int? ageFromDob(String dob, DateTime on) {
    final d = DateTime.tryParse(dob);
    if (d == null) return null;
    final hadBirthday =
        on.month > d.month || (on.month == d.month && on.day >= d.day);
    return on.year - d.year - (hadBirthday ? 0 : 1);
  }

  // Convert a Map into a Customer object
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      businessName: map['business_name'] ?? '',
      shippingSameAsBilling: (map['shipping_same_as_billing'] ?? 1) != 0,
      shippingName: map['shipping_name'] ?? '',
      shippingPhone: map['shipping_phone'] ?? '',
      shippingAddress: map['shipping_address'] ?? '',
      dob: map['dob'] ?? '',
      age: (map['age'] as num?)?.toInt(),
      gender: map['gender'] ?? '',
      customFields:
          CustomFieldValue.listFromJson(map['custom_fields'] as String?),
    );
  }

  // Convert a Customer object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'business_name': businessName,
      'shipping_same_as_billing': shippingSameAsBilling ? 1 : 0,
      'shipping_name': shippingName,
      'shipping_phone': shippingPhone,
      'shipping_address': shippingAddress,
      'dob': dob,
      'age': age,
      'gender': gender,
      'custom_fields': CustomFieldValue.listToJson(customFields),
    };
  }
}