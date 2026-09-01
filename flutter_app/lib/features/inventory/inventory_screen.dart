import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/product_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';
import '../../data/local/database_helper.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StockMovementModel> _movements = [];
  bool _isLoadingMovements = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMovements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoadingMovements = true);
    final list = await DatabaseHelper.instance.getStockMovements();
    if (mounted) {
      setState(() {
        _movements = list;
        _isLoadingMovements = false;
      });
    }
  }

  Future<void> _showAdjustStockDialog(ProductModel product) async {
    final qtyController = TextEditingController(text: '10');
    final noteController = TextEditingController();
    StockReason selectedReason = StockReason.purchase;
    bool isStockIn = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('Adjust Stock: ${product.name}', style: const TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Stock: ${product.quantity} ${product.unit}",
                      style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Stock In vs Stock Out Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('+ Add Stock (In)'),
                          selected: isStockIn,
                          selectedColor: AppTheme.secondary.withOpacity(0.2),
                          onSelected: (val) => setModalState(() => isStockIn = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('- Reduce (Out)'),
                          selected: !isStockIn,
                          selectedColor: AppTheme.error.withOpacity(0.2),
                          onSelected: (val) => setModalState(() => isStockIn = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity to change'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<StockReason>(
                    value: selectedReason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    dropdownColor: AppTheme.surfaceElevated,
                    items: const [
                      DropdownMenuItem(value: StockReason.purchase, child: Text('Supplier Purchase')),
                      DropdownMenuItem(value: StockReason.adjustment, child: Text('Manual Adjustment')),
                      DropdownMenuItem(value: StockReason.returnOrder, child: Text('Customer Return')),
                    ],
                    onChanged: (v) => setModalState(() => selectedReason = v ?? StockReason.purchase),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Audit Note / Invoice Ref'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                    if (qty <= 0) return;

                    final delta = isStockIn ? qty : -qty;

                    await ref.read(productsProvider.notifier).adjustStock(
                          productId: product.id!,
                          delta: delta,
                          reason: selectedReason,
                          note: noteController.text.trim(),
                        );

                    Navigator.pop(ctx);
                    _loadMovements();
                  },
                  child: const Text('Apply Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final lowStock = productsState.lowStockProducts;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inventory & Stock Alerts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text("Low Stock (${lowStock.length})"),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 18),
                  SizedBox(width: 6),
                  Text("Movement Logs"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Low Stock Alerts Tab
          lowStock.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 64, color: AppTheme.secondary.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      const Text(
                        'All Stock Levels Healthy!',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No products currently below their threshold.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lowStock.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = lowStock[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.warning, size: 24),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Barcode: ${p.barcode} • Min Alert: ${p.minStock} ${p.unit}",
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Available: ${p.quantity} ${p.unit}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () => _showAdjustStockDialog(p),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Restock', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          // 2. Stock Movements Log Tab
          _isLoadingMovements
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _movements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 56, color: AppTheme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text('No stock movements logged yet',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _movements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final m = _movements[index];
                        final isPositive = m.delta > 0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isPositive ? AppTheme.secondary : AppTheme.error)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  color: isPositive ? AppTheme.secondary : AppTheme.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.productName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Reason: ${m.reason.name.toUpperCase()}${m.note != null ? ' • ${m.note}' : ''}",
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    Text(
                                      Formatters.date(m.createdAt),
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                "${isPositive ? '+' : ''}${m.delta}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isPositive ? AppTheme.secondary : AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
