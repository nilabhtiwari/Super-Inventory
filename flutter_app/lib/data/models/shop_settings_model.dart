class ShopSettingsModel {
  final int? id;
  final String shopName;
  final String? address;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? logoUrl;
  final String? upiId; // UPI VPA e.g. shop@upi
  final String? upiName; // Payee Name displayed in UPI Apps
  final double defaultCgst;
  final double defaultSgst;
  final double defaultIgst;
  final String currencySymbol;
  final String? receiptFooter;
  final int paperWidthMm; // 58 or 80

  ShopSettingsModel({
    this.id,
    this.shopName = 'Super Inventory Store',
    this.address = '123 Market Road, City Centre',
    this.phone = '+91 9876543210',
    this.email = 'store@superinventory.local',
    this.gstin = '27AAAAA0000A1Z5',
    this.logoUrl,
    this.upiId = 'superinventory@upi',
    this.upiName = 'Super Inventory Retail Store',
    this.defaultCgst = 9.0,
    this.defaultSgst = 9.0,
    this.defaultIgst = 0.0,
    this.currencySymbol = '₹',
    this.receiptFooter = 'Thank you for shopping with us! Visit again.',
    this.paperWidthMm = 58,
  });

  ShopSettingsModel copyWith({
    int? id,
    String? shopName,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? logoUrl,
    String? upiId,
    String? upiName,
    double? defaultCgst,
    double? defaultSgst,
    double? defaultIgst,
    String? currencySymbol,
    String? receiptFooter,
    int? paperWidthMm,
  }) {
    return ShopSettingsModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      logoUrl: logoUrl ?? this.logoUrl,
      upiId: upiId ?? this.upiId,
      upiName: upiName ?? this.upiName,
      defaultCgst: defaultCgst ?? this.defaultCgst,
      defaultSgst: defaultSgst ?? this.defaultSgst,
      defaultIgst: defaultIgst ?? this.defaultIgst,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'shop_name': shopName,
      'shop_address': address,
      'shop_phone': phone,
      'shop_email': email,
      'gstin': gstin,
      'logo_url': logoUrl,
      'upi_id': upiId,
      'upi_name': upiName,
      'default_cgst': defaultCgst,
      'default_sgst': defaultSgst,
      'default_igst': defaultIgst,
      'currency_symbol': currencySymbol,
      'receipt_footer': receiptFooter,
      'paper_width_mm': paperWidthMm,
    };
  }

  factory ShopSettingsModel.fromMap(Map<String, dynamic> map) {
    return ShopSettingsModel(
      id: map['id'] as int?,
      shopName: map['shop_name']?.toString() ?? 'SmartScan Store',
      address: map['shop_address']?.toString() ?? map['address']?.toString(),
      phone: map['shop_phone']?.toString() ?? map['phone']?.toString(),
      email: map['shop_email']?.toString() ?? map['email']?.toString(),
      gstin: map['gstin']?.toString(),
      logoUrl: map['logo_url']?.toString(),
      upiId: map['upi_id']?.toString() ?? 'smartscan@upi',
      upiName: map['upi_name']?.toString() ?? 'SmartScan Retail Store',
      defaultCgst: (map['default_cgst'] as num?)?.toDouble() ?? 9.0,
      defaultSgst: (map['default_sgst'] as num?)?.toDouble() ?? 9.0,
      defaultIgst: (map['default_igst'] as num?)?.toDouble() ?? 0.0,
      currencySymbol: map['currency_symbol']?.toString() ?? '₹',
      receiptFooter: map['receipt_footer']?.toString() ?? 'Thank you for shopping with us! Visit again.',
      paperWidthMm: (map['paper_width_mm'] as int?) ?? 58,
    );
  }
}
