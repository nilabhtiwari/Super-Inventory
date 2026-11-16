import '../models/product_model.dart';
import '../local/database_helper.dart';

enum LookupSource { localDb, notFound }

class LookupResult {
  final ProductModel? product;
  final LookupSource source;
  final String barcode;
  final String? message;

  LookupResult({
    this.product,
    required this.source,
    required this.barcode,
    this.message,
  });

  bool get isFound => product != null;
}

class ProductLookupService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Store Inventory Database Lookup Engine:
  /// ONLY looks up products registered in the store's inventory database.
  /// No online retrieval or synthetic price guessing.
  Future<LookupResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return LookupResult(
        source: LookupSource.notFound,
        barcode: barcode,
        message: 'Empty barcode',
      );
    }

    try {
      final localProduct = await _db.getProductByBarcode(cleanBarcode);
      if (localProduct != null) {
        return LookupResult(
          product: localProduct,
          source: LookupSource.localDb,
          barcode: cleanBarcode,
          message: 'Found in store inventory',
        );
      }
    } catch (e) {
      // Local db error
    }

    return LookupResult(
      source: LookupSource.notFound,
      barcode: cleanBarcode,
      message: 'Product not registered in store inventory',
    );
  }
}
