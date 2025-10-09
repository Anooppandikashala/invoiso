class Product {
  String id;
  String name;
  String description;
  double price;
  int stock;
  String hsncode;
  int tax_rate;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.hsncode,
    required this.tax_rate
  });

  // Convert a Map into a Product object
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      hsncode: map['hsncode'] ?? '',
      tax_rate: map['tax_rate'] ?? 0,
    );
  }

  // Convert a Product object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'hsncode': hsncode,
      'tax_rate': tax_rate,
    };
  }
}