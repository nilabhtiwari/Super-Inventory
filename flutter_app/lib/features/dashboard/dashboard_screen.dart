import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/hardware_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/sale_model.dart';
import '../../data/local/database_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic> _metrics = {
    'totalBills': 0,
    'totalSales': 0.0,
    'totalTax': 0.0,
    'totalProfit': 0.0,
    'lowStockCount': 0,
  };
  List<SaleModel> _recentSales = [];
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final metrics = await DatabaseHelper.instance.getTodayDashboardMetrics();
    final recent = await DatabaseHelper.instance.getAllSales(limit: 5);
    if (mounted) {
      setState(() {
        _metrics = metrics;
        _recentSales = recent;
        _isLoadingMetrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final hardware = ref.watch(hardwareProvider);
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      // ============================================================
      // STITCH STANDARDIZED PURPLE TOP APP BAR
      // ============================================================
      drawer: _buildStoreDrawer(settings, authState),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 4,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
              ),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.shopName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded, color: AppTheme.secondary, size: 18),
                  ],
                ),
                Text(
                  "OPEN • ${settings.storeTimings}",
                  style: const TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Notifications Bell with Unread Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () => context.push('/inventory'),
              ),
              if (productsState.lowStockProducts.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await ref.read(productsProvider.notifier).loadProducts();
        },
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Low stock alert banner
              if (productsState.lowStockProducts.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => context.push('/inventory'),
                  child: Container(
                    margin: const EdgeInsets.bottom: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "${productsState.lowStockProducts.length} items low on stock",
                            style: const TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.warning, size: 20),
                      ],
                    ),
                  ),
                ),
              ],

              // ============================================================
              // CORE HERO BUTTON: CREATE BILL
              // ============================================================
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Hero(
                  tag: 'create_bill_hero',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        context.push('/billing').then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Ink(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: AppTheme.createBillGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: AppTheme.tertiary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -15,
                              bottom: -15,
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 160,
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              '1-TAP EXPRESS BILLING',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white24,
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CREATE BILL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Instant camera scan • Speed checkout < 30s',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // STITCH TODAY'S QUICK STATS
              // ============================================================
              const Text(
                "TODAY'S QUICK STATS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Total Sales Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Sales',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                Formatters.compactCurrency(_metrics['totalSales']),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryContainer,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '+12%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Invoices / Units Sold Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bills Generated',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${_metrics['totalBills']}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'invoices',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // STITCH QUICK ACTIONS GRID
              // ============================================================
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.barcode_reader,
                      label: 'Hardware Scanner',
                      color: AppTheme.primary,
                      onTap: () => context.push('/billing'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.print_rounded,
                      label: hardware.isConnected ? 'Printer Ready' : 'Bluetooth Printer',
                      color: hardware.isConnected ? AppTheme.secondary : AppTheme.tertiary,
                      onTap: () => context.push('/hardware'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.category_rounded,
                      label: 'Catalog Items',
                      color: AppTheme.primaryContainer,
                      onTap: () => context.push('/products'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // STITCH RECENT TRANSACTIONS
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/history'),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_recentSales.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'No transactions yet today. Tap CREATE BILL to start.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentSales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final sale = _recentSales[index];

                    return InkWell(
                      onTap: () => context.push('/receipt/${sale.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: AppTheme.primaryContainer, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale.invoiceNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "${Formatters.time(sale.createdAt)} • ${sale.items.length} Items",
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.currency(sale.grandTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppTheme.primaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Paid',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDrawer(dynamic settings, dynamic authState) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.shopName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Active: ${authState.user?.name ?? 'Merchant'}",
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Store Quick Info Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Timings: ${settings.storeTimings}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.call_rounded, size: 16, color: AppTheme.primaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Helpline: ${settings.grievanceHelpline}",
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.tertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            settings.address,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Active Promotional Ad
            if (settings.promotionalOffer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACTIVE RECEIPT AD:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.secondary)),
                      const SizedBox(height: 4),
                      Text(settings.promotionalOffer, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(color: AppTheme.surfaceBorder, height: 1),

            // Drawer Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryContainer),
                    title: const Text('Edit Business Profile & Ads', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/edit-profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_rounded, color: Color(0xFF00D4AA)),
                    title: const Text('Financial Insights & P&L', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/finance');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.print_rounded, color: AppTheme.secondary),
                    title: const Text('Thermal Printer Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.tertiary),
                    title: const Text('Smart GST Tax Optimizer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/premium');
                    },
                  ),
                ],
              ),
            ),

            // Log Out Button in Drawer
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
                label: const Text('Log Out', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  backgroundColor: AppTheme.error.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
