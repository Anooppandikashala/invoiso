class Product {
  String id;
  String name;
  String description;
  double price;
  int stock;
  String hsncode;
  // ignore: non_constant_identifier_names
  int tax_rate;
  String type; // 'product' or 'service'
  double defaultDiscount;
  double purchasePrice;
  String? aliasName; // local-language display name for PDFs

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.hsncode,
    // ignore: non_constant_identifier_names
    required this.tax_rate,
    this.type = 'product',
    this.defaultDiscount = 0.0,
    this.purchasePrice = 0.0,
    this.aliasName,
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
      type: map['type'] as String? ?? 'product',
      defaultDiscount: (map['default_discount'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      aliasName: map['alias_name'] as String?,
    );
  }

  factory Product.fromInvoiceItemsMap(Map<String, dynamic> map) {
    return Product(
      id: map['product_id'] ?? '',
      name: map['product_name'] ?? '',
      description: map['product_description'] ?? '',
      price: (map['product_price'] is int)
          ? (map['product_price'] as int).toDouble()
          : (map['product_price'] ?? 0.0).toDouble(),
      stock: map['product_stock'] ?? 0,
      hsncode: map['product_hsn_code'] ?? '',
      tax_rate: map['product_tax_rate'] ?? 0,
      type: map['product_type'] as String? ?? 'product',
      defaultDiscount: (map['product_default_discount'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['product_purchase_price'] as num?)?.toDouble() ?? 0.0,
      aliasName: map['product_alias_name'] as String?,
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
      'type': type,
      'default_discount': defaultDiscount,
      'purchase_price': purchasePrice,
      'alias_name': aliasName,
    };
  }

  /// Name to print on PDFs — [aliasName] when [useAlias] is on and set, else [name].
  String displayName(bool useAlias) =>
      (useAlias && (aliasName?.trim().isNotEmpty ?? false)) ? aliasName! : name;
}
