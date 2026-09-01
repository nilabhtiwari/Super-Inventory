import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class PremiumToolkitScreen extends ConsumerStatefulWidget {
  const PremiumToolkitScreen({super.key});

  @override
  ConsumerState<PremiumToolkitScreen> createState() => _PremiumToolkitScreenState();
}

class _PremiumToolkitScreenState extends ConsumerState<PremiumToolkitScreen> {
  bool _isSubscribed = false; // Locked mode by default for non-subscribers

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Super Inventory • Insights & Tax Optimizer'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.surfaceBorder)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isSubscribed = !_isSubscribed);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isSubscribed
                        ? '🎉 Premium Active! All AI Insights, Expiry Trackers & Tax Optimizers Unlocked.'
                        : '🔒 Locked preview mode for non-subscribers.'),
                    backgroundColor: _isSubscribed ? AppTheme.secondary : AppTheme.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSubscribed ? AppTheme.secondary : AppTheme.primary,
                foregroundColor: _isSubscribed ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isSubscribed ? Icons.check_circle_rounded : Icons.workspace_premium_rounded),
                  const SizedBox(width: 8),
                  Text(
                    _isSubscribed ? 'Subscribed: Full Analytics & Tax Optimizer Active' : 'Subscribe to Premium (₹499/mo)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Super Inventory Insights',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Smart GST tax savings, profit maximization, and predictive inventory protection.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // ============================================================
            // 1. GENERIC EXPIRY ALERT HINT (NO SECTORS / CATEGORIES DISCLOSED)
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.error.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '12 Stock Batches Near Expiry',
                          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('CRITICAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Risk of stock loss & profit leakage detected. Subscribe to Premium to identify affected products, batch numbers, and trigger automated flash clearances.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // 2. DETAILED EXPIRY LIST (BLURRED FOR NON-SUBSCRIBERS)
            // ============================================================
            _buildLockedSection(
              isLocked: !_isSubscribed,
              lockedTitle: 'Exact Batch Expiry Breakdown & Auto-Clearance',
              lockedSubtitle: 'Unlock batch numbers, days remaining, and 1-tap automated discounting to recover revenue.',
              child: Column(
                children: [
                  _buildExpiryRow('Paracetamol 500mg Strip', 'Batch #A902 • Expires in 4 days', '40 units', AppTheme.error),
                  const SizedBox(height: 8),
                  _buildExpiryRow('Organic Almond Milk 1L', 'Batch #E441 • Expires in 12 days', '18 units', AppTheme.warning),
                  const SizedBox(height: 8),
                  _buildExpiryRow('Amul Fresh Paneer 200g', 'Batch #P108 • Expires in 3 days', '25 units', AppTheme.error),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // 3. NEW PREMIUM FEATURE: SMART GST TAX OPTIMIZER & PROFIT MAXIMIZER
            // ============================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1035), Color(0xFF12131C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryContainer.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.savings_rounded, color: AppTheme.secondary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart GST Tax Optimizer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            Text(
                              'Save GST & maximize net profit margins',
                              style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildTaxSavingsPill(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Input Tax Credit (ITC) Recovery',
                    description: 'Identifies uncollected purchase tax credits to directly reduce payable GST by up to 18%.',
                  ),
                  const SizedBox(height: 10),
                  _buildTaxSavingsPill(
                    icon: Icons.price_change_rounded,
                    title: 'Tax Slabs Margin Optimizer',
                    description: 'AI pricing model adjusts margins across 0%, 5%, 12%, 18%, 28% slabs to maximize gross profit.',
                  ),
                  const SizedBox(height: 10),
                  _buildTaxSavingsPill(
                    icon: Icons.bolt_rounded,
                    title: '1-Click CA-Ready Tax Filing Assistant',
                    description: 'Automates GSTR-1 and GSTR-3B filings, eliminating penalties and saving CA auditing costs.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // 4. GST TAX BREAKDOWN & SAVINGS (BLURRED FOR NON-SUBSCRIBERS)
            // ============================================================
            _buildLockedSection(
              isLocked: !_isSubscribed,
              lockedTitle: 'Live Tax Savings & Input Credit (ITC) Report',
              lockedSubtitle: 'Unlock itemized GST savings, tax liability offset calculations, and 1-click CA filing summaries.',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    _buildGstRow('Taxable Turnover (Q3)', '₹14,52,000.00'),
                    const Divider(color: AppTheme.surfaceBorder, height: 16),
                    _buildGstRow('CGST Collected (9%)', '₹1,30,680.00'),
                    const Divider(color: AppTheme.surfaceBorder, height: 16),
                    _buildGstRow('SGST Collected (9%)', '₹1,30,680.00'),
                    const Divider(color: AppTheme.surfaceBorder, height: 16),
                    _buildGstRow('Direct ITC Tax Saved by App', '₹48,200.00', isHighlight: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSavingsPill({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSection({
    required bool isLocked,
    required String lockedTitle,
    required String lockedSubtitle,
    required Widget child,
  }) {
    if (!isLocked) return child;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryContainer, width: 1.5),
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppTheme.primaryContainer, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lockedTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lockedSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

  Widget _buildExpiryRow(String name, String detail, String qty, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(detail, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGstRow(String label, String amount, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isHighlight ? AppTheme.secondary : Colors.white,
          ),
        ),
      ],
    );
  }
}
