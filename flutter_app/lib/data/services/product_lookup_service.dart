import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../local/database_helper.dart';
import '../../core/constants/app_constants.dart';

enum LookupSource { localDb, openFoodFacts, notFound }

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

  /// The 3-Tier Product Lookup Engine:
  /// 1. Local Database (Instant)
  /// 2. OpenFoodFacts Global Barcode API (Online Fallback)
  /// 3. Returns notFound to trigger Instant Quick Add form
  Future<LookupResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return LookupResult(
        source: LookupSource.notFound,
        barcode: barcode,
        message: 'Empty barcode',
      );
    }

    // ----------------------------------------------------
    // Method 1: Local Database Search
    // ----------------------------------------------------
    try {
      final localProduct = await _db.getProductByBarcode(cleanBarcode);
      if (localProduct != null) {
        return LookupResult(
          product: localProduct,
          source: LookupSource.localDb,
          barcode: cleanBarcode,
          message: 'Found in store catalog',
        );
      }
    } catch (e) {
      // Fall through to online lookup
    }

    // ----------------------------------------------------
    // Method 2: OpenFoodFacts Global Online Barcode Database
    // ----------------------------------------------------
    try {
      final url = Uri.parse('${AppConstants.openFoodFactsApi}/$cleanBarcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final p = data['product'];
          final String name = p['product_name'] ??
              p['product_name_en'] ??
              p['generic_name'] ??
              'Item $cleanBarcode';
          final String? category = (p['categories'] as String?)?.split(',').first.trim();
          final String? imageUrl = p['image_front_small_url'] ?? p['image_url'];

          // Default smart estimation
          final product = ProductModel(
            barcode: cleanBarcode,
            name: name,
            category: category ?? 'General',
            unit: 'pcs',
            purchasePrice: 0.0,
            sellingPrice: 50.0, // Default prompt value for quick confirmation
            cgstRate: 9.0,
            sgstRate: 9.0,
            quantity: 10,
            minStock: 5,
            imageUrl: imageUrl,
          );

          return LookupResult(
            product: product,
            source: LookupSource.openFoodFacts,
            barcode: cleanBarcode,
            message: 'Found online via OpenFoodFacts',
          );
        }
      }
    } catch (_) {
      // Network timeout or offline - proceed to Method 3
    }

    // ----------------------------------------------------
    // Method 3: Not Found -> Caller opens Quick Add Modal
    // ----------------------------------------------------
    return LookupResult(
      source: LookupSource.notFound,
      barcode: cleanBarcode,
      message: 'Product not registered in store catalog',
    );
  }
}
