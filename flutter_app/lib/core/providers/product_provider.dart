import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/local/database_helper.dart';

class ProductsState {
  final List<ProductModel> products;
  final List<ProductModel> lowStockProducts;
  final String searchQuery;
  final String selectedCategory;
  final bool isLoading;

  ProductsState({
    this.products = const [],
    this.lowStockProducts = const [],
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.isLoading = false,
  });

  ProductsState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? lowStockProducts,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
  }) {
    return ProductsState(
      products: products ?? this.products,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  ProductsNotifier() : super(ProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await _db.getAllProducts(
        searchQuery: state.searchQuery,
        category: state.selectedCategory,
      );
      final lowStock = await _db.getLowStockProducts();
      state = state.copyWith(
        products: products,
        lowStockProducts: lowStock,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadProducts();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    loadProducts();
  }

  Future<int> addProduct(ProductModel product) async {
    final id = await _db.insertProduct(product);
    await loadProducts();
    return id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  Future<bool> adjustStock({
    required int productId,
    required int delta,
    required StockReason reason,
    String? note,
  }) async {
    final success = await _db.adjustStock(
      productId: productId,
      delta: delta,
      reason: reason,
      note: note,
    );
    if (success) {
      await loadProducts();
    }
    return success;
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});
