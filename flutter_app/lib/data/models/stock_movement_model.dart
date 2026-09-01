enum StockReason { sale, purchase, adjustment, initial, returnOrder }

class StockMovementModel {
  final int? id;
  final int productId;
  final String productName;
  final String barcode;
  final int delta; // +ve for stock in, -ve for stock out
  final StockReason reason;
  final int? referenceId; // sale_id
  final int? sellerId;
  final String? sellerName;
  final String? note;
  final DateTime createdAt;

  StockMovementModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.delta,
    required this.reason,
    this.referenceId,
    this.sellerId,
    this.sellerName,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isStockIn => delta > 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_name': productName,
      'barcode': barcode,
      'delta': delta,
      'reason': reason.name,
      'reference_id': referenceId,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    StockReason r = StockReason.adjustment;
    try {
      r = StockReason.values.byName(map['reason']?.toString() ?? 'adjustment');
    } catch (_) {
      r = StockReason.adjustment;
    }

    return StockMovementModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productName: map['product_name']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      delta: map['delta'] as int? ?? 0,
      reason: r,
      referenceId: map['reference_id'] as int?,
      sellerId: map['seller_id'] as int?,
      sellerName: map['seller_name']?.toString(),
      note: map['note']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
