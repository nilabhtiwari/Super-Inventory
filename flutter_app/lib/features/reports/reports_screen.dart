import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database_helper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'Today';
  bool _isLoading = true;
  Map<String, dynamic> _summary = {
    'totalSales': 0.0,
    'totalTax': 0.0,
    'cgst': 0.0,
    'sgst': 0.0,
    'totalProfit': 0.0,
    'invoiceCount': 0,
    'itemsSold': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final db = await DatabaseHelper.instance.database;

    String dateFilter = "";
    final now = DateTime.now();

    if (_selectedPeriod == 'Today') {
      final todayStr = now.toIso8601String().substring(0, 10);
      dateFilter = "WHERE s.created_at LIKE '$todayStr%'";
    } else if (_selectedPeriod == 'This Month') {
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      dateFilter = "WHERE s.created_at LIKE '$monthStr%'";
    }

    final salesQuery = '''
      SELECT 
        COUNT(*) as invoice_count,
        COALESCE(SUM(grand_total), 0) as total_sales,
        COALESCE(SUM(tax_total), 0) as total_tax,
        COALESCE(SUM(cgst_total), 0) as cgst,
        COALESCE(SUM(sgst_total), 0) as sgst
      FROM sales s
      $dateFilter AND s.status = 'completed'
    ''';

    final profitQuery = '''
      SELECT 
        COALESCE(SUM((si.unit_price - p.purchase_price) * si.qty), 0) as total_profit,
        COALESCE(SUM(si.qty), 0) as items_sold
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      LEFT JOIN products p ON p.id = si.product_id
      $dateFilter AND s.status = 'completed'
    ''';

    try {
      final sResult = await db.rawQuery(salesQuery);
      final pResult = await db.rawQuery(profitQuery);

      if (mounted) {
        setState(() {
          _summary = {
            'invoiceCount': sResult.first['invoice_count'] as int? ?? 0,
            'totalSales': (sResult.first['total_sales'] as num?)?.toDouble() ?? 0.0,
            'totalTax': (sResult.first['total_tax'] as num?)?.toDouble() ?? 0.0,
            'cgst': (sResult.first['cgst'] as num?)?.toDouble() ?? 0.0,
            'sgst': (sResult.first['sgst'] as num?)?.toDouble() ?? 0.0,
            'totalProfit': (pResult.first['total_profit'] as num?)?.toDouble() ?? 0.0,
            'itemsSold': (pResult.first['items_sold'] as int?) ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('GST & Profit Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector Chips
            Row(
              children: ['Today', 'This Month', 'All Time'].map((period) {
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedPeriod = period);
                      _loadReportData();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        period,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else ...[
              // Revenue & Profit Hero Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.currency_rupee_rounded, color: Colors.white, size: 20),
                              Spacer(),
                              Text('Total Sales', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            Formatters.currency(_summary['totalSales']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${_summary['invoiceCount']} completed bills",
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.secondary, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up_rounded, color: AppTheme.secondary, size: 20),
                              Spacer(),
                              Text('Gross Profit', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            Formatters.currency(_summary['totalProfit']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${_summary['itemsSold']} items sold",
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // GST BREAKDOWN CARD
              // ============================================================
              const Text(
                'GST TAX BREAKDOWN REPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    _buildGstRow(
                      label: 'Total Tax Collected (GST)',
                      amount: _summary['totalTax'],
                      isBold: true,
                      color: AppTheme.textPrimary,
                    ),
                    const Divider(color: AppTheme.surfaceBorder, height: 24),
                    _buildGstRow(
                      label: 'Central GST (CGST)',
                      amount: _summary['cgst'],
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildGstRow(
                      label: 'State GST (SGST)',
                      amount: _summary['sgst'],
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildGstRow(
                      label: 'Integrated GST (IGST)',
                      amount: 0.0,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Operational Metrics
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Average Bill Value',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          _summary['invoiceCount'] > 0
                              ? Formatters.currency(
                                  _summary['totalSales'] / _summary['invoiceCount'])
                              : '₹0.00',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: AppTheme.surfaceBorder),
                    Column(
                      children: [
                        const Text('Profit Margin %',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          _summary['totalSales'] > 0
                              ? "${((_summary['totalProfit'] / _summary['totalSales']) * 100).toStringAsFixed(1)}%"
                              : '0.0%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGstRow({
    required String label,
    required double amount,
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? AppTheme.textSecondary,
          ),
        ),
        Text(
          Formatters.currency(amount),
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? AppTheme.secondary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
