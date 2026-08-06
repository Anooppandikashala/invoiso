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
  String unit;
  bool unlimitedStock;
  bool priceIncludesTax;

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
    this.unit = '',
    this.unlimitedStock = false,
    this.priceIncludesTax = false,
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
      unit: map['unit'] as String? ?? '',
      unlimitedStock: (map['unlimited_stock'] ?? 0) == 1,
      priceIncludesTax: (map['price_includes_tax'] ?? 0) == 1,
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
      unit: map['product_unit'] as String? ?? '',
      priceIncludesTax: (map['product_price_includes_tax'] ?? 0) == 1,
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
      'unit': unit,
      'unlimited_stock': unlimitedStock ? 1 : 0,
      'price_includes_tax': priceIncludesTax ? 1 : 0,
    };
  }

  /// Name to print on PDFs — [aliasName] when [useAlias] is on and set, else [name].
  String displayName(bool useAlias) =>
      (useAlias && (aliasName?.trim().isNotEmpty ?? false)) ? aliasName! : name;
}

class ProductMetadata {
  String productId;
  String? storageLocation;
  String? containerNumber;
  String? batchNumber;
  String? expiryDate;
  String? manufactureDate;
  String? supplierName;
  String? skuCode;
  String? notes;

  ProductMetadata({
    required this.productId,
    this.storageLocation,
    this.containerNumber,
    this.batchNumber,
    this.expiryDate,
    this.manufactureDate,
    this.supplierName,
    this.skuCode,
    this.notes,
  });

  bool get isEmpty =>
      (storageLocation?.isEmpty ?? true) &&
      (containerNumber?.isEmpty ?? true) &&
      (batchNumber?.isEmpty ?? true) &&
      (expiryDate?.isEmpty ?? true) &&
      (manufactureDate?.isEmpty ?? true) &&
      (supplierName?.isEmpty ?? true) &&
      (skuCode?.isEmpty ?? true) &&
      (notes?.isEmpty ?? true);

  factory ProductMetadata.fromMap(Map<String, dynamic> map) {
    return ProductMetadata(
      productId: map['product_id'] ?? '',
      storageLocation: map['storage_location'] as String?,
      containerNumber: map['container_number'] as String?,
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] as String?,
      manufactureDate: map['manufacture_date'] as String?,
      supplierName: map['supplier_name'] as String?,
      skuCode: map['sku_code'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'storage_location': storageLocation,
      'container_number': containerNumber,
      'batch_number': batchNumber,
      'expiry_date': expiryDate,
      'manufacture_date': manufactureDate,
      'supplier_name': supplierName,
      'sku_code': skuCode,
      'notes': notes,
    };
  }
}
