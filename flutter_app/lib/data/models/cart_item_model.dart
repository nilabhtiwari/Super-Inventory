import 'product_model.dart';
import '../../core/utils/formatters.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double customSellingPrice;
  double discountPerUnit;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    double? customSellingPrice,
    this.discountPerUnit = 0.0,
  }) : customSellingPrice = customSellingPrice ?? product.sellingPrice;

  double get unitPrice => (customSellingPrice - discountPerUnit).clamp(0.0, double.infinity);

  double get cgstRate => product.cgstRate;
  double get sgstRate => product.sgstRate;
  double get igstRate => product.igstRate;
  double get totalGstRate => product.totalGstRate;

  Map<String, double> get taxBreakdown {
    return Formatters.calculateTaxBreakdown(
      sellingPrice: unitPrice,
      cgstRate: cgstRate,
      sgstRate: sgstRate,
      igstRate: igstRate,
      quantity: quantity,
    );
  }

  double get subtotal => taxBreakdown['subtotal'] ?? (unitPrice * quantity);
  double get cgstAmount => taxBreakdown['cgstAmount'] ?? 0.0;
  double get sgstAmount => taxBreakdown['sgstAmount'] ?? 0.0;
  double get igstAmount => taxBreakdown['igstAmount'] ?? 0.0;
  double get totalTax => taxBreakdown['totalTax'] ?? 0.0;
  double get lineTotal => taxBreakdown['grandTotal'] ?? (subtotal + totalTax);

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? customSellingPrice,
    double? discountPerUnit,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      customSellingPrice: customSellingPrice ?? this.customSellingPrice,
      discountPerUnit: discountPerUnit ?? this.discountPerUnit,
    );
  }

  Map<String, dynamic> toMap(int saleId) {
    return {
      'sale_id': saleId,
      'product_id': product.id,
      'product_name': product.name,
      'barcode': product.barcode,
      'hsn_code': product.hsnCode,
      'qty': quantity,
      'unit_price': unitPrice,
      'cgst_rate': cgstRate,
      'sgst_rate': sgstRate,
      'igst_rate': igstRate,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'line_total': lineTotal,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, ProductModel product) {
    return CartItemModel(
      product: product,
      quantity: map['qty'] as int? ?? 1,
      customSellingPrice: (map['unit_price'] as num?)?.toDouble() ?? product.sellingPrice,
    );
  }
}
