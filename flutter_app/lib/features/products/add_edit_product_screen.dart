import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/product_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/local/database_helper.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final int? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _hsnController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  final _minStockController = TextEditingController(text: '5');
  final _descController = TextEditingController();

  String _selectedCategory = 'Groceries';
  String _selectedUnit = 'pcs';
  double _selectedGstSlab = 18.0;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit && widget.productId != null) {
      _loadProductDetails(widget.productId!);
      _isInit = false;
    }
  }

  Future<void> _loadProductDetails(int id) async {
    setState(() => _isLoading = true);
    final p = await DatabaseHelper.instance.getProductById(id);
    if (p != null && mounted) {
      setState(() {
        _barcodeController.text = p.barcode;
        _nameController.text = p.name;
        _skuController.text = p.sku ?? '';
        _hsnController.text = p.hsnCode ?? '';
        _sellingPriceController.text = p.sellingPrice.toStringAsFixed(2);
        _purchasePriceController.text = p.purchasePrice.toStringAsFixed(2);
        _mrpController.text = p.mrp != null ? p.mrp!.toStringAsFixed(2) : '';
        _stockController.text = p.quantity.toString();
        _minStockController.text = p.minStock.toString();
        _descController.text = p.description ?? '';
        _selectedCategory = p.category ?? 'Groceries';
        _selectedUnit = p.unit;
        _selectedGstSlab = (p.cgstRate + p.sgstRate);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _hsnController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final mrp = double.tryParse(_mrpController.text.trim());
    final qty = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 5;
    final halfGst = _selectedGstSlab / 2;

    final product = ProductModel(
      id: widget.productId,
      barcode: barcode,
      name: name,
      sku: _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null,
      hsnCode: _hsnController.text.trim().isNotEmpty ? _hsnController.text.trim() : null,
      category: _selectedCategory,
      unit: _selectedUnit,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: mrp,
      cgstRate: halfGst,
      sgstRate: halfGst,
      quantity: qty,
      minStock: minStock,
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
    );

    setState(() => _isLoading = true);

    if (widget.productId != null) {
      await ref.read(productsProvider.notifier).updateProduct(product);
    } else {
      await ref.read(productsProvider.notifier).addProduct(product);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.productId != null ? 'Product updated successfully' : 'Product added to catalog'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Basic Info Section
              _buildSectionHeader('Basic Product Details'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (EAN / UPC / Code 128) *',
                        prefixIcon: Icon(Icons.qr_code_rounded, color: AppTheme.primary),
                        hintText: '8901030762512',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Barcode is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.textMuted),
                        hintText: 'e.g. Parle-G Biscuits 800g',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(labelText: 'Category'),
                            dropdownColor: AppTheme.surfaceElevated,
                            items: AppConstants.defaultCategories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v ?? 'Groceries'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            dropdownColor: AppTheme.surfaceElevated,
                            items: AppConstants.units
                                .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedUnit = v ?? 'pcs'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hsnController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'HSN / SAC Code (for GST)',
                        hintText: 'e.g. 1905',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Pricing & GST Section
              _buildSectionHeader('Pricing & GST Slabs'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Selling Price (₹) *',
                              prefixText: '₹ ',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Cost Price (₹)',
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mrpController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'MRP (₹)',
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: _selectedGstSlab,
                            decoration: const InputDecoration(labelText: 'GST Slab'),
                            dropdownColor: AppTheme.surfaceElevated,
                            items: AppConstants.gstSlabs
                                .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text("${g.toStringAsFixed(0)}% GST",
                                        style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedGstSlab = v ?? 18.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Stock & Inventory Limits
              _buildSectionHeader('Stock & Inventory Levels'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Available Stock',
                          hintText: '10',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Low Stock Alert Limit',
                          hintText: '5',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isEdit ? 'Update Product Details' : 'Save Product to Catalog',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
