import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/local/database_helper.dart';

class CartState {
  final List<CartItemModel> items;
  final double discountAmount;
  final PaymentMethod paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final bool isProcessing;

  CartState({
    this.items = const [],
    this.discountAmount = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.isProcessing = false,
  });

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get uniqueItemCount => items.length;

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get cgstTotal => items.fold(0.0, (sum, i) => sum + i.cgstAmount);
  double get sgstTotal => items.fold(0.0, (sum, i) => sum + i.sgstAmount);
  double get igstTotal => items.fold(0.0, (sum, i) => sum + i.igstAmount);
  double get taxTotal => cgstTotal + sgstTotal + igstTotal;

  double get grandTotal {
    final total = (subtotal + taxTotal - discountAmount);
    return total > 0 ? double.parse(total.toStringAsFixed(2)) : 0.0;
  }

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
    double? discountAmount,
    PaymentMethod? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? notes,
    bool? isProcessing,
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  CartNotifier() : super(CartState());

  /// Adds or increments a product in cart
  void addProduct(ProductModel product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id || i.product.barcode == product.barcode);

    if (existingIndex != -1) {
      final updatedList = List<CartItemModel>.from(state.items);
      final current = updatedList[existingIndex];
      updatedList[existingIndex] = current.copyWith(quantity: current.quantity + quantity);
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItemModel(product: product, quantity: quantity);
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedList = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedList);
  }

  void removeItem(int productId) {
    final updatedList = state.items.where((item) => item.product.id != productId).toList();
    state = state.copyWith(items: updatedList);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discountAmount: discount.clamp(0.0, double.infinity));
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setCustomerInfo({String? name, String? phone}) {
    state = state.copyWith(customerName: name, customerPhone: phone);
  }

  void clearCart() {
    state = CartState();
  }

  /// Finalizes and commits the billing transaction to the database
  Future<SaleModel?> completeSale({
    int? sellerId,
    String? sellerName,
    String? paymentReference,
  }) async {
    if (state.isEmpty) return null;

    state = state.copyWith(isProcessing: true);

    try {
      final invoiceNumber = await _db.generateNextInvoiceNumber();

      final sale = SaleModel(
        invoiceNumber: invoiceNumber,
        sellerId: sellerId,
        sellerName: sellerName,
        customerName: state.customerName,
        customerPhone: state.customerPhone,
        subtotal: state.subtotal,
        cgstTotal: state.cgstTotal,
        sgstTotal: state.sgstTotal,
        igstTotal: state.igstTotal,
        taxTotal: state.taxTotal,
        discountAmount: state.discountAmount,
        grandTotal: state.grandTotal,
        paymentMethod: state.paymentMethod,
        paymentReference: paymentReference,
        notes: state.notes,
        status: SaleStatus.completed,
      );

      final completedSale = await _db.createSaleTransaction(
        sale: sale,
        items: state.items,
      );

      clearCart();
      return completedSale;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
