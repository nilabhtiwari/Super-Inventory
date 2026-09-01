import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

enum FinancePeriod { monthly, yearly }

class FinanceInsightsScreen extends StatefulWidget {
  const FinanceInsightsScreen({super.key});

  @override
  State<FinanceInsightsScreen> createState() => _FinanceInsightsScreenState();
}

class _FinanceInsightsScreenState extends State<FinanceInsightsScreen> {
  FinancePeriod _selectedPeriod = FinancePeriod.monthly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Business Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // 1. HEADER & PERIOD FILTER
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Analytics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Performance overview for Main Branch',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = FinancePeriod.monthly),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == FinancePeriod.monthly ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedPeriod == FinancePeriod.monthly ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = FinancePeriod.yearly),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == FinancePeriod.yearly ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Yearly',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedPeriod == FinancePeriod.yearly ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ============================================================
            // 2. KPI BENTO GRID (TOTAL REVENUE, NET PROFIT, REACH)
            // ============================================================
            // Card 1: Total Revenue
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_up_rounded, size: 16, color: AppTheme.primaryContainer),
                          SizedBox(width: 6),
                          Text('Total Revenue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPeriod == FinancePeriod.monthly ? '₹1,24,500.00' : '₹14,94,000.00',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 13, color: AppTheme.secondary),
                          const SizedBox(width: 2),
                          Text(
                            _selectedPeriod == FinancePeriod.monthly ? '+14.5% vs last month' : '+18.2% vs last year',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.payments_rounded, color: AppTheme.primaryContainer, size: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Card 2: Net Profit
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monitoring_rounded, size: 14, color: AppTheme.secondary),
                            SizedBox(width: 4),
                            Text('Net Profit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedPeriod == FinancePeriod.monthly ? '₹32,840' : '₹3,94,080',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text('+8.2% margin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Card 3: Customer Reach
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.group_add_rounded, size: 14, color: AppTheme.tertiary),
                            SizedBox(width: 4),
                            Text('Customer Reach', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedPeriod == FinancePeriod.monthly ? '4,892' : '58,704',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text('+2.1% footfall', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ============================================================
            // 3. MAIN DUAL-BAR P&L CHART (REVENUE VS EXPENSES)
            // ============================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profit & Loss Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Icon(Icons.more_horiz_rounded, color: AppTheme.textMuted),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildDualBarChart(_selectedPeriod),

                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 12),

                  // Legend
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: AppTheme.primary, size: 10),
                          SizedBox(width: 4),
                          Text('Revenue', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                      SizedBox(width: 20),
                      Row(
                        children: [
                          Icon(Icons.circle, color: AppTheme.tertiary, size: 10),
                          SizedBox(width: 4),
                          Text('Expenses', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ============================================================
            // 4. PERFORMANCE AI INSIGHT CARD
            // ============================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1429),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Performance Insight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  const Text('AI-generated summary based on recent sales data.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 14),

                  // Tip 1
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: AppTheme.secondary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Revenue peaked in mid-month driven by the festive promotional campaign. Consider repeating similar targeted offers.',
                            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tip 2
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Operational expenses are trending 5% higher than projected. Review supply chain and supplier invoice margins.',
                            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Generating detailed P&L PDF report...'), backgroundColor: AppTheme.secondary),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Generate Detailed Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDualBarChart(FinancePeriod period) {
    final labels = period == FinancePeriod.monthly ? ['Jan', 'Feb', 'Mar', 'Apr'] : ['2023', '2024', '2025', '2026'];
    final revHeights = period == FinancePeriod.monthly ? [0.40, 0.55, 0.45, 0.70] : [0.45, 0.60, 0.75, 0.90];
    final expHeights = period == FinancePeriod.monthly ? [0.20, 0.25, 0.30, 0.40] : [0.25, 0.35, 0.45, 0.50];

    return SizedBox(
      height: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(labels.length, (i) {
          final isHighlighted = i == labels.length - 1;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Revenue Bar
                  Container(
                    width: 16,
                    height: 100 * revHeights[i],
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Expense Bar
                  Container(
                    width: 16,
                    height: 100 * expHeights[i],
                    decoration: BoxDecoration(
                      color: AppTheme.tertiary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? AppTheme.primaryContainer : AppTheme.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
