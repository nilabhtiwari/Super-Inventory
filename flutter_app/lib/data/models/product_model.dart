class ProductModel {
  final int? id;
  final String barcode;
  final String? sku;
  final String name;
  final String? description;
  final String? category;
  final String? hsnCode;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double? mrp;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final int quantity;
  final int minStock;
  final String? imageUrl;
  final String? supplierName;
  final String? mfgDate;
  final String? expiryDate;
  final int? bestBeforeMonths;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    this.id,
    required this.barcode,
    this.sku,
    required this.name,
    this.description,
    this.category,
    this.hsnCode,
    this.unit = 'pcs',
    this.purchasePrice = 0.0,
    required this.sellingPrice,
    this.mrp,
    this.cgstRate = 9.0,
    this.sgstRate = 9.0,
    this.igstRate = 0.0,
    this.quantity = 0,
    this.minStock = 10,
    this.imageUrl,
    this.supplierName,
    this.mfgDate,
    this.expiryDate,
    this.bestBeforeMonths,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalGstRate => igstRate > 0 ? igstRate : (cgstRate + sgstRate);

  bool get isLowStock => quantity <= minStock && quantity > 0;
  bool get isOutOfStock => quantity <= 0;

  ProductModel copyWith({
    int? id,
    String? barcode,
    String? sku,
    String? name,
    String? description,
    String? category,
    String? hsnCode,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? cgstRate,
    double? sgstRate,
    double? igstRate,
    int? quantity,
    int? minStock,
    String? imageUrl,
    String? supplierName,
    String? mfgDate,
    String? expiryDate,
    int? bestBeforeMonths,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      hsnCode: hsnCode ?? this.hsnCode,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      cgstRate: cgstRate ?? this.cgstRate,
      sgstRate: sgstRate ?? this.sgstRate,
      igstRate: igstRate ?? this.igstRate,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      imageUrl: imageUrl ?? this.imageUrl,
      supplierName: supplierName ?? this.supplierName,
      mfgDate: mfgDate ?? this.mfgDate,
      expiryDate: expiryDate ?? this.expiryDate,
      bestBeforeMonths: bestBeforeMonths ?? this.bestBeforeMonths,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barcode': barcode,
      'sku': sku,
      'name': name,
      'description': description,
      'category': category,
      'hsn_code': hsnCode,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'mrp': mrp,
      'cgst_rate': cgstRate,
      'sgst_rate': sgstRate,
      'igst_rate': igstRate,
      'quantity': quantity,
      'min_stock': minStock,
      'image_url': imageUrl,
      'supplier_name': supplierName,
      'mfg_date': mfgDate,
      'expiry_date': expiryDate,
      'best_before_months': bestBeforeMonths,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      barcode: map['barcode']?.toString() ?? '',
      sku: map['sku']?.toString(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      category: map['category']?.toString() ?? map['category_name']?.toString(),
      hsnCode: map['hsn_code']?.toString(),
      unit: map['unit']?.toString() ?? 'pcs',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble(),
      cgstRate: (map['cgst_rate'] as num?)?.toDouble() ?? 9.0,
      sgstRate: (map['sgst_rate'] as num?)?.toDouble() ?? 9.0,
      igstRate: (map['igst_rate'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? (map['stock_qty'] as int?) ?? 0,
      minStock: (map['min_stock'] as int?) ?? (map['low_stock_threshold'] as int?) ?? 10,
      imageUrl: map['image_url']?.toString(),
      supplierName: map['supplier_name']?.toString(),
      mfgDate: map['mfg_date']?.toString(),
      expiryDate: map['expiry_date']?.toString(),
      bestBeforeMonths: map['best_before_months'] as int?,
      isActive: (map['is_active'] == 1 || map['is_active'] == true || map['is_active'] == null),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
