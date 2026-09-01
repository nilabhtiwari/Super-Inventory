import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

enum FinancePeriod { monthly, yearly, quarterly }

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
        title: const Text('Financial Insights & P&L', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Filter Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = FinancePeriod.monthly),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == FinancePeriod.monthly ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Monthly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedPeriod == FinancePeriod.monthly ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = FinancePeriod.quarterly),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == FinancePeriod.quarterly ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Quarterly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedPeriod == FinancePeriod.quarterly ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = FinancePeriod.yearly),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == FinancePeriod.yearly ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Yearly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedPeriod == FinancePeriod.yearly ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Top Revenue & Profit Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedPeriod == FinancePeriod.monthly
                            ? 'THIS MONTH GROSS'
                            : (_selectedPeriod == FinancePeriod.quarterly ? 'THIS QUARTER GROSS' : 'ANNUAL GROSS (YTD)'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.secondary.withOpacity(0.5)),
                        ),
                        child: const Text(
                          '+18.4% vs Prev',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedPeriod == FinancePeriod.monthly
                        ? '₹4,28,500.00'
                        : (_selectedPeriod == FinancePeriod.quarterly ? '₹12,85,500.00' : '₹51,42,000.00'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Net Profit', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          Text(
                            _selectedPeriod == FinancePeriod.monthly
                                ? '₹1,12,040.00'
                                : (_selectedPeriod == FinancePeriod.quarterly ? '₹3,47,080.00' : '₹14,39,760.00'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.secondary),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Profit Margin', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          Text(
                            _selectedPeriod == FinancePeriod.monthly ? '26.1%' : (_selectedPeriod == FinancePeriod.quarterly ? '27.0%' : '28.0%'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Performance Visual Bar Chart
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profit / Loss Trajectory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      Icon(Icons.bar_chart_rounded, color: AppTheme.secondary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildVisualChart(_selectedPeriod),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Financial Breakdown Grid
            const Text('FINANCIAL BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cost of Goods (COGS)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedPeriod == FinancePeriod.monthly ? '₹2,78,500' : '₹33,42,000',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GST Collected', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedPeriod == FinancePeriod.monthly ? '₹37,960' : '₹3,60,240',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualChart(FinancePeriod period) {
    final labels = period == FinancePeriod.monthly
        ? ['Week 1', 'Week 2', 'Week 3', 'Week 4']
        : (period == FinancePeriod.quarterly ? ['Month 1', 'Month 2', 'Month 3'] : ['2023', '2024', '2025', '2026']);

    final heights = period == FinancePeriod.monthly
        ? [0.55, 0.75, 0.85, 0.65]
        : (period == FinancePeriod.quarterly ? [0.65, 0.80, 0.95] : [0.45, 0.65, 0.85, 0.95]);

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(labels.length, (i) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: 85 * heights[i],
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(labels[i], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
            ],
          );
        }),
      ),
    );
  }
}
