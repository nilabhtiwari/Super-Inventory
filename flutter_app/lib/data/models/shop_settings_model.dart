class ShopSettingsModel {
  final String shopName;
  final String address;
  final String phone;
  final String email;
  final String gstin;
  final String upiId;
  final String printerPaperSize;
  final bool enableGst;
  final String currencySymbol;
  // NEW BUSINESS PROFILE & MARKETING FIELDS
  final String storeTimings;
  final String promotionalOffer;
  final String productsSold;
  final String grievanceHelpline;
  final String? businessPhotoUrl;

  ShopSettingsModel({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.upiId,
    this.printerPaperSize = '58mm',
    this.enableGst = true,
    this.currencySymbol = '₹',
    this.storeTimings = 'Mon - Sun: 8:00 AM - 10:30 PM',
    this.promotionalOffer = '🎉 Special Festive Discount: Flat 10% OFF on orders above ₹1,000!',
    this.productsSold = 'Groceries, Dairy, Beverages, Snacks & Daily Essentials',
    this.grievanceHelpline = '9876543210',
    this.businessPhotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'address': address,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'upiId': upiId,
      'printerPaperSize': printerPaperSize,
      'enableGst': enableGst ? 1 : 0,
      'currencySymbol': currencySymbol,
      'storeTimings': storeTimings,
      'promotionalOffer': promotionalOffer,
      'productsSold': productsSold,
      'grievanceHelpline': grievanceHelpline,
      'businessPhotoUrl': businessPhotoUrl,
    };
  }

  factory ShopSettingsModel.fromMap(Map<String, dynamic> map) {
    return ShopSettingsModel(
      shopName: map['shopName'] ?? 'Super Inventory Store',
      address: map['address'] ?? 'Main Branch, City Centre',
      phone: map['phone'] ?? '9876543210',
      email: map['email'] ?? 'merchant@superinventory.com',
      gstin: map['gstin'] ?? '27AAAAA0000A1Z5',
      upiId: map['upiId'] ?? 'superinventory@upi',
      printerPaperSize: map['printerPaperSize'] ?? '58mm',
      enableGst: (map['enableGst'] ?? 1) == 1,
      currencySymbol: map['currencySymbol'] ?? '₹',
      storeTimings: map['storeTimings'] ?? 'Mon - Sun: 8:00 AM - 10:30 PM',
      promotionalOffer: map['promotionalOffer'] ?? '🎉 Special Festive Discount: Flat 10% OFF on orders above ₹1,000!',
      productsSold: map['productsSold'] ?? 'Groceries, Dairy, Beverages & Daily Essentials',
      grievanceHelpline: map['grievanceHelpline'] ?? '9876543210',
      businessPhotoUrl: map['businessPhotoUrl'],
    );
  }

  ShopSettingsModel copyWith({
    String? shopName,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? upiId,
    String? printerPaperSize,
    bool? enableGst,
    String? currencySymbol,
    String? storeTimings,
    String? promotionalOffer,
    String? productsSold,
    String? grievanceHelpline,
    String? businessPhotoUrl,
  }) {
    return ShopSettingsModel(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      upiId: upiId ?? this.upiId,
      printerPaperSize: printerPaperSize ?? this.printerPaperSize,
      enableGst: enableGst ?? this.enableGst,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      storeTimings: storeTimings ?? this.storeTimings,
      promotionalOffer: promotionalOffer ?? this.promotionalOffer,
      productsSold: productsSold ?? this.productsSold,
      grievanceHelpline: grievanceHelpline ?? this.grievanceHelpline,
      businessPhotoUrl: businessPhotoUrl ?? this.businessPhotoUrl,
    );
  }
}
