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
  bool _isSubscribed = false; // By default locked / non-subscriber mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Super Inventory • Insights'),
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
                        ? '🎉 Premium Active! All AI Insights & Expiry Trackers Unlocked.'
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
                    _isSubscribed ? 'Subscribed: Full Analytics Active' : 'Subscribe to Premium (₹499/mo)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
              'Automated GST analytics, predictive expiry protection, and AI profit suggestions.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // ============================================================
            // 1. EXPIRATION ALERT HINT (ALWAYS VISIBLE TO NON-SUBSCRIBERS)
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
                    '⚠️ Risk of stock wastage detected across Dairy, Beverages & Pharma categories.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ============================================================
            // 2. DETAILED EXPIRY LIST (BLURRED / LOCKED FOR NON-SUBSCRIBERS)
            // ============================================================
            _buildLockedSection(
              isLocked: !_isSubscribed,
              lockedTitle: 'Batch Expiry Breakdown & Auto-Discounting',
              lockedSubtitle: 'Unlock exact batch numbers, expiry dates, and 1-tap clearance flash sales.',
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
            // 3. GST FILING & TAX BREAKDOWN (BLURRED FOR NON-SUBSCRIBERS)
            // ============================================================
            _buildLockedSection(
              isLocked: !_isSubscribed,
              lockedTitle: 'Automated GST Filings & ITC Input Credit',
              lockedSubtitle: 'Unlock GSTR-1, GSTR-3B tax calculations, and 1-click CA export report.',
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
                    _buildGstRow('Eligible Input Tax Credit (ITC)', '₹48,200.00', isHighlight: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // 4. AI PROFIT PLANS & DEAD STOCK SUGGESTIONS
            // ============================================================
            _buildLockedSection(
              isLocked: !_isSubscribed,
              lockedTitle: 'AI Profit & Fast-Moving Stock Optimization',
              lockedSubtitle: 'Get predictive restock alerts and bundle strategies to increase margins by up to 30%.',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Plan: Bundle Parle-G with Tata Tea Gold (+18% margin boost)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 6),
                    Text('💡 Dead stock liquidation: Apply 10% discount on slow-moving noodles to free ₹14,000 cash.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
            // Blurred Background Child
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),

            // Overlay with Lock Icon and Hint
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
