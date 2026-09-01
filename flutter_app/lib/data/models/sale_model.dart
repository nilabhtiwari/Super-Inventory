import 'cart_item_model.dart';

enum PaymentMethod { cash, upi, card, mixed }

enum SaleStatus { completed, refunded, voided }

class SaleModel {
  final int? id;
  final String invoiceNumber;
  final int? sellerId;
  final String? sellerName;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double taxTotal;
  final double discountAmount;
  final double grandTotal;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final SaleStatus status;
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;
  final List<CartItemModel> items;

  SaleModel({
    this.id,
    required this.invoiceNumber,
    this.sellerId,
    this.sellerName,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    this.cgstTotal = 0.0,
    this.sgstTotal = 0.0,
    this.igstTotal = 0.0,
    required this.taxTotal,
    this.discountAmount = 0.0,
    required this.grandTotal,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentReference,
    this.status = SaleStatus.completed,
    this.notes,
    this.isSynced = false,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_no': invoiceNumber,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'cgst_total': cgstTotal,
      'sgst_total': sgstTotal,
      'igst_total': igstTotal,
      'tax_total': taxTotal,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod.name,
      'payment_ref': paymentReference,
      'status': status.name,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, {List<CartItemModel> items = const []}) {
    PaymentMethod method = PaymentMethod.cash;
    try {
      method = PaymentMethod.values.byName(map['payment_method']?.toString().toLowerCase() ?? 'cash');
    } catch (_) {
      method = PaymentMethod.cash;
    }

    SaleStatus saleStatus = SaleStatus.completed;
    try {
      saleStatus = SaleStatus.values.byName(map['status']?.toString().toLowerCase() ?? 'completed');
    } catch (_) {
      saleStatus = SaleStatus.completed;
    }

    return SaleModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_no']?.toString() ?? map['invoice_number']?.toString() ?? '',
      sellerId: map['seller_id'] as int?,
      sellerName: map['seller_name']?.toString(),
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      cgstTotal: (map['cgst_total'] as num?)?.toDouble() ?? 0.0,
      sgstTotal: (map['sgst_total'] as num?)?.toDouble() ?? 0.0,
      igstTotal: (map['igst_total'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (map['tax_total'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: method,
      paymentReference: map['payment_ref']?.toString(),
      status: saleStatus,
      notes: map['notes']?.toString(),
      isSynced: (map['is_synced'] == 1 || map['is_synced'] == true),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      items: items,
    );
  }
}
