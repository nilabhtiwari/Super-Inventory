import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/sale_model.dart';
import '../../data/local/database_helper.dart';
import '../../data/services/pdf_receipt_service.dart';

enum ChartType { column, line, donut }

class BillHistoryScreen extends ConsumerStatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  ConsumerState<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends ConsumerState<BillHistoryScreen> {
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ChartType _selectedChart = ChartType.column;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final sales = await DatabaseHelper.instance.getAllSales(limit: 100);
    if (mounted) {
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    }
  }

  List<SaleModel> get _filteredSales {
    if (_searchQuery.trim().isEmpty) return _sales;
    final term = _searchQuery.trim().toLowerCase();
    return _sales.where((s) {
      return s.invoiceNumber.toLowerCase().contains(term) ||
          (s.customerName?.toLowerCase().contains(term) ?? false) ||
          (s.customerPhone?.contains(term) ?? false);
    }).toList();
  }

  double get _totalRevenue =>
      _filteredSales.fold(0.0, (sum, s) => sum + s.grandTotal);

  double get _estimatedProfit => _totalRevenue * 0.28; // Estimated 28% gross margin

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Bill History & Profit Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // STITCH MONTHLY TRENDS & KPI CARDS
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryContainer),
                      SizedBox(width: 6),
                      Text('Last 30 Days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Total Revenue Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL REVENUE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.currency(_totalRevenue),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 4),
                            Text('+12.5%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Net Profit Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.tertiary.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NET PROFIT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.currency(_estimatedProfit),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.tertiary),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.trending_up_rounded, color: AppTheme.tertiary, size: 14),
                            SizedBox(width: 4),
                            Text('+8.2%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ============================================================
            // STITCH CHART CANVAS (COLUMN / LINE / DONUT TOGGLE)
            // ============================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profit Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Monthly Revenue vs Profit', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                      // Dropdown Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: DropdownButton<ChartType>(
                          value: _selectedChart,
                          underline: const SizedBox(),
                          dropdownColor: AppTheme.surfaceElevated,
                          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppTheme.primaryContainer),
                          items: const [
                            DropdownMenuItem(value: ChartType.column, child: Text('Column Chart', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: ChartType.line, child: Text('Line Chart', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: ChartType.donut, child: Text('Donut Chart', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedChart = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart Visualization
                  _buildChartPreview(_selectedChart),

                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: AppTheme.primaryContainer),
                          SizedBox(width: 6),
                          Text('Revenue (75%)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                      SizedBox(width: 16),
                      Row(
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: AppTheme.tertiary),
                          SizedBox(width: 6),
                          Text('Profit (25%)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // STITCH RECENT BILLS LIST WITH 1-TAP WHATSAPP SHARING
            // ============================================================
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search by Invoice # or Customer Phone...',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Bills',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                Text(
                  "${_filteredSales.length} Transactions",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
            else if (_filteredSales.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('No matching bills found.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sale = _filteredSales[index];
                  final estimatedLineProfit = sale.grandTotal * 0.25;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        // Customer / Invoice Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person_rounded, color: AppTheme.primaryContainer, size: 22),
                        ),
                        const SizedBox(width: 12),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sale.customerName?.isNotEmpty == true ? sale.customerName! : sale.invoiceNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                "${Formatters.dateShort(sale.createdAt)} • ${Formatters.time(sale.createdAt)}",
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              Text(
                                "Profit: +${Formatters.currency(estimatedLineProfit)}",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.tertiary),
                              ),
                            ],
                          ),
                        ),

                        // Amount & WhatsApp Action
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.currency(sale.grandTotal),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.receipt_rounded, size: 20, color: AppTheme.primaryContainer),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => context.push('/receipt/${sale.id}'),
                                ),
                                const SizedBox(width: 10),
                                // Stitch 1-Click WhatsApp Button
                                GestureDetector(
                                  onTap: () {
                                    PdfReceiptService.sendInvoiceToWhatsApp(
                                      sale: sale,
                                      settings: settings,
                                      phoneNumber: sale.customerPhone,
                                    );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF25D366)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPreview(ChartType type) {
    if (type == ChartType.column) {
      final months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
      final revHeights = [0.6, 0.75, 0.65, 0.85, 0.95, 0.8];
      final profitHeights = [0.25, 0.3, 0.28, 0.35, 0.4, 0.38];

      return SizedBox(
        height: 140,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(months.length, (i) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 10,
                      height: 90 * revHeights[i],
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 10,
                      height: 90 * profitHeights[i],
                      decoration: const BoxDecoration(
                        color: AppTheme.tertiary,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(months[i], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            );
          }),
        ),
      );
    } else if (type == ChartType.line) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Icon(Icons.show_chart_rounded, size: 80, color: AppTheme.primaryContainer),
      );
    } else {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Icon(Icons.donut_large_rounded, size: 80, color: AppTheme.tertiary),
      );
    }
  }
}
