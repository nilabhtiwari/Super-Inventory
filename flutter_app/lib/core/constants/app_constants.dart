class AppConstants {
  static const String appName = 'Super Inventory';
  static const String appVersion = '1.0.0';

  // API Default Fallback
  static const String defaultApiBaseUrl = 'http://10.0.2.2:5000/api'; // Android emulator localhost
  static const String openFoodFactsApi = 'https://world.openfoodfacts.org/api/v2/product';

  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'current_user';
  static const String keyShopSettings = 'shop_settings';
  static const String keyLastInvoiceNo = 'last_invoice_number';

  // Default GST Rates
  static const List<double> gstSlabs = [0.0, 5.0, 12.0, 18.0, 28.0];

  // Common Product Units
  static const List<String> units = [
    'pcs',
    'kg',
    'g',
    'L',
    'ml',
    'pack',
    'box',
    'meter',
    'dozen'
  ];

  // Common Categories
  static const List<String> defaultCategories = [
    'Groceries',
    'Beverages',
    'Dairy & Bakery',
    'Personal Care',
    'Snacks & Confectionery',
    'Household & Cleaning',
    'Electronics',
    'Stationery',
    'Pharmacy',
    'Others'
  ];
}
