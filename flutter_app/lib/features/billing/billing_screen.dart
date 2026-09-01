import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/services/product_lookup_service.dart';
import '../../data/local/database_helper.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final ProductLookupService _lookupService = ProductLookupService();
  final FocusNode _keyboardFocusNode = FocusNode();
  final StringBuffer _keyboardBuffer = StringBuffer();

  bool _isCameraVisible = true;
  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    // Auto-focus hardware barcode listener for external BT / USB HID scanners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// Processes camera or hardware barcode string
  Future<void> _handleBarcodeDetected(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return;

    // Debounce duplicate scans within 800ms
    final now = DateTime.now();
    if (_lastScannedBarcode == barcode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 800) {
      return;
    }

    _lastScannedBarcode = barcode;
    _lastScanTime = now;

    if (_isProcessingScan) return;
    setState(() => _isProcessingScan = true);

    HapticFeedback.mediumImpact();

    try {
      final result = await _lookupService.lookupBarcode(barcode);

      if (!mounted) return;

      if (result.isFound) {
        // Method 1 & Method 2: Found in local catalog or online
        ref.read(cartProvider.notifier).addProduct(result.product!);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Added: ${result.product!.name}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  Formatters.currency(result.product!.sellingPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 1200),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Method 3: Not Found -> Open Quick Add Modal
        HapticFeedback.heavyImpact();
        await _showQuickAddProductDialog(barcode);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingScan = false);
        _keyboardFocusNode.requestFocus();
      }
    }
  }

  /// Quick Add Product Bottom Sheet (Method 3)
  Future<void> _showQuickAddProductDialog(String barcode) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final purchasePriceController = TextEditingController(text: '0');
    final stockController = TextEditingController(text: '10');
    double selectedGst = 18.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded,
                              color: AppTheme.warning, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Add New Product',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Barcode: $barcode',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        hintText: 'e.g. Dairy Milk Chocolate 50g',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Selling Price (₹) *',
                              hintText: '40.00',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: purchasePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Cost Price (₹)',
                              hintText: '30.00',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Initial Quantity',
                              hintText: '10',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<double>(
                            value: selectedGst,
                            decoration: const InputDecoration(labelText: 'GST Slab'),
                            dropdownColor: AppTheme.surfaceElevated,
                            items: const [
                              DropdownMenuItem(value: 0.0, child: Text('0% GST')),
                              DropdownMenuItem(value: 5.0, child: Text('5% GST')),
                              DropdownMenuItem(value: 12.0, child: Text('12% GST')),
                              DropdownMenuItem(value: 18.0, child: Text('18% GST')),
                              DropdownMenuItem(value: 28.0, child: Text('28% GST')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedGst = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                        if (name.isEmpty || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid product name & price')),
                          );
                          return;
                        }

                        final cost = double.tryParse(purchasePriceController.text.trim()) ?? 0.0;
                        final qty = int.tryParse(stockController.text.trim()) ?? 10;
                        final halfGst = selectedGst / 2;

                        final newProduct = ProductModel(
                          barcode: barcode,
                          name: name,
                          sellingPrice: price,
                          purchasePrice: cost,
                          cgstRate: halfGst,
                          sgstRate: halfGst,
                          quantity: qty,
                          minStock: 5,
                          unit: 'pcs',
                          category: 'General',
                        );

                        // Save permanently to SQLite database
                        await DatabaseHelper.instance.insertProduct(newProduct);

                        // Add to current cart
                        ref.read(cartProvider.notifier).addProduct(newProduct);

                        if (mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save to Store & Add to Bill',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Discount Dialog
  Future<void> _showDiscountDialog() async {
    final cart = ref.read(cartProvider);
    final controller = TextEditingController(
      text: cart.discountAmount > 0 ? cart.discountAmount.toStringAsFixed(2) : '',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Apply Bill Discount'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              prefixText: '₹ ',
              hintText: 'Enter discount amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final discount = double.tryParse(controller.text.trim()) ?? 0.0;
                ref.read(cartProvider.notifier).setDiscount(discount);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  /// Complete Sale & Open Receipt
  Future<void> _handleCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Scan items first.')),
      );
      return;
    }

    final auth = ref.read(authProvider);

    try {
      final sale = await ref.read(cartProvider.notifier).completeSale(
            sellerId: auth.user?.id,
            sellerName: auth.user?.name ?? 'Cashier',
          );

      if (sale != null && mounted) {
        HapticFeedback.heavyImpact();
        // Replace with Receipt Screen
        context.pushReplacement('/receipt/${sale.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final settings = ref.watch(settingsProvider);

    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      onKey: (event) {
        // Catch hardware barcode scanner keyboard stream + ENTER
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            final barcode = _keyboardBuffer.toString().trim();
            _keyboardBuffer.clear();
            if (barcode.isNotEmpty) {
              _handleBarcodeDetected(barcode);
            }
          } else if (event.character != null && event.character!.isNotEmpty) {
            _keyboardBuffer.write(event.character);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Express POS Billing'),
          actions: [
            // Flashlight Toggle
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? AppTheme.accent : AppTheme.textMuted,
              ),
              onPressed: () {
                _scannerController.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
            // Toggle Camera Preview
            IconButton(
              icon: Icon(
                _isCameraVisible ? Icons.camera_alt_rounded : Icons.camera_alt_outlined,
                color: _isCameraVisible ? AppTheme.primary : AppTheme.textMuted,
              ),
              onPressed: () {
                setState(() => _isCameraVisible = !_isCameraVisible);
              },
            ),
            // Clear Cart Button
            if (cart.items.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.error),
                onPressed: () {
                  ref.read(cartProvider.notifier).clearCart();
                },
              ),
          ],
        ),
        body: Column(
          children: [
            // ============================================================
            // TOP SECTION: LIVE CAMERA BARCODE SCANNER VIEWFINDER
            // ============================================================
            if (_isCameraVisible)
              Container(
                height: 160,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isProcessingScan ? AppTheme.warning : AppTheme.primary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _handleBarcodeDetected(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      // Targeting reticle overlay
                      Container(
                        width: 220,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isProcessingScan ? AppTheme.warning : AppTheme.secondary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isProcessingScan ? 'Processing scan...' : 'Align barcode in box',
                            style: TextStyle(
                              color: _isProcessingScan ? AppTheme.warning : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ============================================================
            // MIDDLE SECTION: LIVE CART ITEM LIST
            // ============================================================
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 64,
                            color: AppTheme.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Scanner Ready',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Point camera at product barcode or use BT scanner',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];

                        return Dismissible(
                          key: Key('item_${item.product.id}_${item.product.barcode}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            ref.read(cartProvider.notifier).removeItem(item.product.id ?? 0);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${Formatters.currency(item.unitPrice)} • GST ${(item.cgstRate + item.sgstRate).toStringAsFixed(0)}% (₹${item.totalTax.toStringAsFixed(1)})",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded,
                                          size: 22, color: AppTheme.textSecondary),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(item.product.id ?? 0, item.quantity - 1);
                                      },
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "${item.quantity}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded,
                                          size: 22, color: AppTheme.primary),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(item.product.id ?? 0, item.quantity + 1);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Line Total
                                Text(
                                  Formatters.currency(item.lineTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ============================================================
            // BOTTOM STICKY SECTION: TOTALS, PAYMENT MODE & CHECKOUT
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: const Border(
                  top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Payment Method Chips
                    Row(
                      children: PaymentMethod.values.map((method) {
                        final isSelected = cart.paymentMethod == method;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref.read(cartProvider.notifier).setPaymentMethod(method);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.surfaceBorder,
                                ),
                              ),
                              child: Text(
                                method.name.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Subtotal & GST Summary Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Subtotal: ${Formatters.currency(cart.subtotal)} • GST: ${Formatters.currency(cart.taxTotal)}",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        GestureDetector(
                          onTap: _showDiscountDialog,
                          child: Text(
                            cart.discountAmount > 0
                                ? "Discount: -${Formatters.currency(cart.discountAmount)}"
                                : "+ Add Discount",
                            style: TextStyle(
                              fontSize: 12,
                              color: cart.discountAmount > 0 ? AppTheme.error : AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Grand Total & Checkout Button
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL PAYABLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                Formatters.currency(cart.grandTotal),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: cart.isEmpty || cart.isProcessing ? null : _handleCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: cart.isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'PAY & INVOICE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
