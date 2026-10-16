// Data Models
class Supplier {
  String id;
  String name;
  String businessName;
  String phone;
  String email;
  String address;
  String gstin;
  String notes;
  DateTime? deletedAt;

  Supplier({
    required this.id,
    required this.name,
    this.businessName = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.gstin = '',
    this.notes = '',
    this.deletedAt,
  });

  // Convert a Map into a Supplier object
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      businessName: map['business_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      notes: map['notes'] ?? '',
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'] as String)
          : null,
    );
  }

  // Convert a Supplier object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'business_name': businessName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'notes': notes,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
