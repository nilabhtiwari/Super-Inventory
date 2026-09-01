import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/cart_item_model.dart';
import '../models/shop_settings_model.dart';
import '../models/stock_movement_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('qexmanage_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        sku TEXT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        hsn_code TEXT,
        unit TEXT NOT NULL DEFAULT 'pcs',
        purchase_price REAL NOT NULL DEFAULT 0.0,
        selling_price REAL NOT NULL,
        mrp REAL,
        cgst_rate REAL NOT NULL DEFAULT 9.0,
        sgst_rate REAL NOT NULL DEFAULT 9.0,
        igst_rate REAL NOT NULL DEFAULT 0.0,
        quantity INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 10,
        image_url TEXT,
        supplier_name TEXT,
        mfg_date TEXT,
        expiry_date TEXT,
        best_before_months INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_products_barcode ON products (barcode)');
    await db.execute('CREATE INDEX idx_products_name ON products (name)');

    // 2. Sales Table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        seller_id INTEGER,
        seller_name TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        subtotal REAL NOT NULL,
        cgst_total REAL NOT NULL DEFAULT 0.0,
        sgst_total REAL NOT NULL DEFAULT 0.0,
        igst_total REAL NOT NULL DEFAULT 0.0,
        tax_total REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        payment_ref TEXT,
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_sales_created_at ON sales (created_at)');
    await db.execute('CREATE INDEX idx_sales_invoice_no ON sales (invoice_no)');

    // 3. Sale Items Table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        barcode TEXT NOT NULL,
        hsn_code TEXT,
        qty INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        cgst_rate REAL NOT NULL DEFAULT 0.0,
        sgst_rate REAL NOT NULL DEFAULT 0.0,
        igst_rate REAL NOT NULL DEFAULT 0.0,
        cgst_amount REAL NOT NULL DEFAULT 0.0,
        sgst_amount REAL NOT NULL DEFAULT 0.0,
        igst_amount REAL NOT NULL DEFAULT 0.0,
        line_total REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // 4. Stock Movements Table
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        barcode TEXT NOT NULL,
        delta INTEGER NOT NULL,
        reason TEXT NOT NULL,
        reference_id INTEGER,
        seller_id INTEGER,
        seller_name TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Shop Settings Table
    await db.execute('''
      CREATE TABLE shop_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL DEFAULT 'SmartScan Retail Store',
        shop_address TEXT DEFAULT '123 Market Road, City Centre',
        shop_phone TEXT DEFAULT '+91 9876543210',
        shop_email TEXT DEFAULT 'store@smartscan.local',
        gstin TEXT DEFAULT '27AAAAA0000A1Z5',
        logo_url TEXT,
        upi_id TEXT DEFAULT 'smartscan@upi',
        upi_name TEXT DEFAULT 'SmartScan Store',
        default_cgst REAL NOT NULL DEFAULT 9.0,
        default_sgst REAL NOT NULL DEFAULT 9.0,
        default_igst REAL NOT NULL DEFAULT 0.0,
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        receipt_footer TEXT DEFAULT 'Thank you for shopping with us! Visit again.',
        paper_width_mm INTEGER NOT NULL DEFAULT 58
      )
    ''');

    // Insert Default Shop Settings
    await db.insert('shop_settings', ShopSettingsModel().toMap());

    // Seed Sample Products for Immediate Scanning & Billing
    await _seedInitialProducts(db);
  }

  Future<void> _seedInitialProducts(Database db) async {
    final sampleProducts = [
      ProductModel(
        barcode: '8901030762512',
        name: 'Parle-G Gold Biscuits 800g',
        category: 'Snacks & Confectionery',
        hsnCode: '1905',
        unit: 'pack',
        purchasePrice: 65.0,
        sellingPrice: 80.0,
        mrp: 85.0,
        cgstRate: 2.5,
        sgstRate: 2.5,
        quantity: 120,
        minStock: 25,
      ),
      ProductModel(
        barcode: '8901058000491',
        name: 'Amul Butter 500g',
        category: 'Dairy & Bakery',
        hsnCode: '0405',
        unit: 'pack',
        purchasePrice: 240.0,
        sellingPrice: 275.0,
        mrp: 275.0,
        cgstRate: 6.0,
        sgstRate: 6.0,
        quantity: 45,
        minStock: 15,
      ),
      ProductModel(
        barcode: '8901030010025',
        name: 'Britannia Good Day Butter 200g',
        category: 'Snacks & Confectionery',
        hsnCode: '1905',
        unit: 'pack',
        purchasePrice: 28.0,
        sellingPrice: 35.0,
        mrp: 35.0,
        cgstRate: 9.0,
        sgstRate: 9.0,
        quantity: 90,
        minStock: 20,
      ),
      ProductModel(
        barcode: '8906003200014',
        name: 'Kurkure Masala Munch 90g',
        category: 'Snacks & Confectionery',
        hsnCode: '1905',
        unit: 'pack',
        purchasePrice: 15.0,
        sellingPrice: 20.0,
        mrp: 20.0,
        cgstRate: 9.0,
        sgstRate: 9.0,
        quantity: 150,
        minStock: 30,
      ),
      ProductModel(
        barcode: '8901719106361',
        name: 'Tata Tea Gold 250g',
        category: 'Beverages',
        hsnCode: '0902',
        unit: 'pack',
        purchasePrice: 120.0,
        sellingPrice: 155.0,
        mrp: 160.0,
        cgstRate: 2.5,
        sgstRate: 2.5,
        quantity: 60,
        minStock: 12,
      ),
      ProductModel(
        barcode: '8901058852236',
        name: 'Maggi 2-Minute Masala Noodles 280g',
        category: 'Groceries',
        hsnCode: '1902',
        unit: 'pack',
        purchasePrice: 48.0,
        sellingPrice: 60.0,
        mrp: 60.0,
        cgstRate: 9.0,
        sgstRate: 9.0,
        quantity: 80,
        minStock: 20,
      ),
      ProductModel(
        barcode: '8901030383847',
        name: 'Dettol Original Liquid Handwash 200ml',
        category: 'Personal Care',
        hsnCode: '3401',
        unit: 'pcs',
        purchasePrice: 75.0,
        sellingPrice: 99.0,
        mrp: 99.0,
        cgstRate: 9.0,
        sgstRate: 9.0,
        quantity: 8, // Triggers Low Stock Alert
        minStock: 10,
      ),
    ];

    for (final p in sampleProducts) {
      await db.insert('products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ----------------------------------------------------
  // PRODUCT OPERATIONS
  // ----------------------------------------------------

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode.trim()],
    );

    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  Future<ProductModel?> getProductById(int id) async {
    final db = await instance.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ProductModel>> getAllProducts({
    String? searchQuery,
    String? category,
    bool onlyActive = true,
  }) async {
    final db = await instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (onlyActive) {
      whereClauses.add('is_active = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR barcode LIKE ? OR sku LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (category != null && category != 'All' && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return maps.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<List<ProductModel>> getLowStockProducts() async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'quantity <= min_stock AND is_active = 1',
      orderBy: 'quantity ASC',
    );
    return maps.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await instance.database;
    final id = await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (product.quantity > 0) {
      await insertStockMovement(StockMovementModel(
        productId: id,
        productName: product.name,
        barcode: product.barcode,
        delta: product.quantity,
        reason: StockReason.initial,
        note: 'Initial inventory entry',
      ));
    }

    return id;
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    // Soft delete
    return await db.update(
      'products',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ----------------------------------------------------
  // INVENTORY & STOCK ADJUSTMENTS
  // ----------------------------------------------------

  Future<bool> adjustStock({
    required int productId,
    required int delta,
    required StockReason reason,
    String? note,
    int? sellerId,
    String? sellerName,
  }) async {
    final db = await instance.database;
    final product = await getProductById(productId);
    if (product == null) return false;

    final newQty = product.quantity + delta;
    if (newQty < 0) return false;

    return await db.transaction((txn) async {
      await txn.update(
        'products',
        {'quantity': newQty, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [productId],
      );

      await txn.insert(
        'stock_movements',
        StockMovementModel(
          productId: productId,
          productName: product.name,
          barcode: product.barcode,
          delta: delta,
          reason: reason,
          note: note,
          sellerId: sellerId,
          sellerName: sellerName,
        ).toMap(),
      );

      return true;
    });
  }

  Future<int> insertStockMovement(StockMovementModel movement) async {
    final db = await instance.database;
    return await db.insert('stock_movements', movement.toMap());
  }

  Future<List<StockMovementModel>> getStockMovements({int? productId, int limit = 100}) async {
    final db = await instance.database;
    final maps = await db.query(
      'stock_movements',
      where: productId != null ? 'product_id = ?' : null,
      whereArgs: productId != null ? [productId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((e) => StockMovementModel.fromMap(e)).toList();
  }

  // ----------------------------------------------------
  // BILLING & TRANSACTION MANAGEMENT
  // ----------------------------------------------------

  Future<String> generateNextInvoiceNumber() async {
    final db = await instance.database;
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final prefix = "INV-$dateStr";

    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sales WHERE invoice_no LIKE '$prefix%'"
    );

    final count = Sqflite.firstIntValue(result) ?? 0;
    final seq = (count + 1).toString().padLeft(4, '0');
    return "$prefix-$seq";
  }

  Future<SaleModel> createSaleTransaction({
    required SaleModel sale,
    required List<CartItemModel> items,
  }) async {
    final db = await instance.database;

    return await db.transaction((txn) async {
      // 1. Insert Sales Header
      final saleId = await txn.insert('sales', sale.toMap());

      // 2. Insert Sale Items & Deduct Inventory
      for (final item in items) {
        final itemMap = item.toMap(saleId);
        await txn.insert('sale_items', itemMap);

        // Atomic Stock Deduction
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );

        // Stock Movement Audit Log
        await txn.insert(
          'stock_movements',
          StockMovementModel(
            productId: item.product.id ?? 0,
            productName: item.product.name,
            barcode: item.product.barcode,
            delta: -item.quantity,
            reason: StockReason.sale,
            referenceId: saleId,
            sellerId: sale.sellerId,
            sellerName: sale.sellerName,
            note: 'Sold in Invoice ${sale.invoiceNumber}',
          ).toMap(),
        );
      }

      return SaleModel(
        id: saleId,
        invoiceNumber: sale.invoiceNumber,
        sellerId: sale.sellerId,
        sellerName: sale.sellerName,
        customerName: sale.customerName,
        customerPhone: sale.customerPhone,
        subtotal: sale.subtotal,
        cgstTotal: sale.cgstTotal,
        sgstTotal: sale.sgstTotal,
        igstTotal: sale.igstTotal,
        taxTotal: sale.taxTotal,
        discountAmount: sale.discountAmount,
        grandTotal: sale.grandTotal,
        paymentMethod: sale.paymentMethod,
        paymentReference: sale.paymentReference,
        status: sale.status,
        notes: sale.notes,
        isSynced: sale.isSynced,
        createdAt: sale.createdAt,
        items: items,
      );
    });
  }

  Future<List<SaleModel>> getAllSales({int limit = 50, int offset = 0}) async {
    final db = await instance.database;
    final maps = await db.query(
      'sales',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    List<SaleModel> sales = [];
    for (final map in maps) {
      final saleId = map['id'] as int;
      final itemMaps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      
      List<CartItemModel> items = [];
      for (final im in itemMaps) {
        final p = await getProductById(im['product_id'] as int) ??
            ProductModel(
              id: im['product_id'] as int,
              barcode: im['barcode']?.toString() ?? '',
              name: im['product_name']?.toString() ?? '',
              sellingPrice: (im['unit_price'] as num?)?.toDouble() ?? 0.0,
            );
        items.add(CartItemModel.fromMap(im, p));
      }

      sales.add(SaleModel.fromMap(map, items: items));
    }
    return sales;
  }

  Future<SaleModel?> getSaleById(int id) async {
    final db = await instance.database;
    final maps = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final itemMaps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [id]);
    List<CartItemModel> items = [];
    for (final im in itemMaps) {
      final p = await getProductById(im['product_id'] as int) ??
          ProductModel(
            id: im['product_id'] as int,
            barcode: im['barcode']?.toString() ?? '',
            name: im['product_name']?.toString() ?? '',
            sellingPrice: (im['unit_price'] as num?)?.toDouble() ?? 0.0,
          );
      items.add(CartItemModel.fromMap(im, p));
    }

    return SaleModel.fromMap(maps.first, items: items);
  }

  // ----------------------------------------------------
  // DASHBOARD & ANALYTICS METRICS
  // ----------------------------------------------------

  Future<Map<String, dynamic>> getTodayDashboardMetrics() async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Today Sales & Invoices
    final salesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_bills,
        COALESCE(SUM(grand_total), 0) as total_sales,
        COALESCE(SUM(tax_total), 0) as total_tax
      FROM sales
      WHERE created_at LIKE '$todayStr%' AND status = 'completed'
    ''');

    // Today Profit (Selling Price - Purchase Price)
    final profitResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM((si.unit_price - p.purchase_price) * si.qty), 0) as total_profit
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      LEFT JOIN products p ON p.id = si.product_id
      WHERE s.created_at LIKE '$todayStr%' AND s.status = 'completed'
    ''');

    final lowStockCountResult = await db.rawQuery('''
      SELECT COUNT(*) as low_stock_count FROM products WHERE quantity <= min_stock AND is_active = 1
    ''');

    final totalBills = Sqflite.firstIntValue(salesResult) ?? 0;
    final totalSales = (salesResult.first['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalTax = (salesResult.first['total_tax'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = (profitResult.first['total_profit'] as num?)?.toDouble() ?? 0.0;
    final lowStockCount = Sqflite.firstIntValue(lowStockCountResult) ?? 0;

    return {
      'totalBills': totalBills,
      'totalSales': totalSales,
      'totalTax': totalTax,
      'totalProfit': totalProfit,
      'lowStockCount': lowStockCount,
    };
  }

  // ----------------------------------------------------
  // SHOP SETTINGS
  // ----------------------------------------------------

  Future<ShopSettingsModel> getShopSettings() async {
    final db = await instance.database;
    final maps = await db.query('shop_settings', limit: 1);
    if (maps.isNotEmpty) {
      return ShopSettingsModel.fromMap(maps.first);
    }
    return ShopSettingsModel();
  }

  Future<int> updateShopSettings(ShopSettingsModel settings) async {
    final db = await instance.database;
    return await db.update(
      'shop_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id ?? 1],
    );
  }
}
