import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/hardware_provider.dart';

enum FinancialPeriod { monthly, yearly }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  FinancialPeriod _selectedPeriod = FinancialPeriod.monthly;

  // Form Controllers
  late TextEditingController _shopNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _helplineCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _upiIdCtrl;
  late TextEditingController _timingsCtrl;
  late TextEditingController _offerCtrl;
  late TextEditingController _productsSoldCtrl;
  late String _printerSize;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _shopNameCtrl = TextEditingController(text: s.shopName);
    _addressCtrl = TextEditingController(text: s.address);
    _phoneCtrl = TextEditingController(text: s.phone);
    _helplineCtrl = TextEditingController(text: s.grievanceHelpline);
    _emailCtrl = TextEditingController(text: s.email);
    _gstinCtrl = TextEditingController(text: s.gstin);
    _upiIdCtrl = TextEditingController(text: s.upiId);
    _timingsCtrl = TextEditingController(text: s.storeTimings);
    _offerCtrl = TextEditingController(text: s.promotionalOffer);
    _productsSoldCtrl = TextEditingController(text: s.productsSold);
    _printerSize = s.printerPaperSize;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _helplineCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _upiIdCtrl.dispose();
    _timingsCtrl.dispose();
    _offerCtrl.dispose();
    _productsSoldCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAllSettings() async {
    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      shopName: _shopNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      grievanceHelpline: _helplineCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      upiId: _upiIdCtrl.text.trim(),
      storeTimings: _timingsCtrl.text.trim(),
      promotionalOffer: _offerCtrl.text.trim(),
      productsSold: _productsSoldCtrl.text.trim(),
      printerPaperSize: _printerSize,
    );

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Store Profile & Printer Settings Updated!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _openEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF131520),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Color(0xFF2B2F48))),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Business Profile & Ads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Icon(Icons.storefront_rounded, color: AppTheme.primaryContainer),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'These details appear on customer bills to advertise your shop and handle customer grievances.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),

                // Store Logo / Photo Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 36, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Business Name
                const Text('Business Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                TextFormField(controller: _shopNameCtrl, decoration: const InputDecoration(hintText: 'e.g. Royal Supermarket')),
                const SizedBox(height: 12),

                // Phone & Grievance Helpline
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Store Phone *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(hintText: '9876543210')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Grievance Helpline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          TextFormField(controller: _helplineCtrl, decoration: const InputDecoration(hintText: 'Helpline Number')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location / Address
                const Text('Store Address / Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                TextFormField(controller: _addressCtrl, decoration: const InputDecoration(hintText: '123 Market Road, City Centre')),
                const SizedBox(height: 12),

                // Store Timings & Availability
                const Text('Store Timings (Printed on Bills)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                TextFormField(controller: _timingsCtrl, decoration: const InputDecoration(hintText: 'Mon - Sun: 8:00 AM - 10:30 PM')),
                const SizedBox(height: 12),

                // Festive Offers / Ad Message
                const Text('Promotional Offer / Festive Ad Banner', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _offerCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: '🎉 Flat 10% OFF on bills above ₹1,000! Call for free home delivery.'),
                ),
                const SizedBox(height: 12),

                // Products & Services Sold
                const Text('Products & Categories Sold', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                TextFormField(controller: _productsSoldCtrl, decoration: const InputDecoration(hintText: 'Groceries, Dairy, Beverages & Essentials')),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveAllSettings();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Save Business Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text('Are you sure you want to log out of Super Inventory?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hardware = ref.watch(hardwareProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Settings & Store Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // 1. CLICKABLE PROFILE CARD WITH EDIT ACTION
              // ============================================================
              InkWell(
                onTap: _openEditProfileModal,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
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
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.shopName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Timings: ${settings.storeTimings}",
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Helpline: ${settings.grievanceHelpline}",
                              style: const TextStyle(fontSize: 10, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ============================================================
              // 2. THERMAL PRINTER SETTING WITH CONNECTION STATUS
              // ============================================================
              const Text('HARDWARE DEVICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: hardware.isConnected ? AppTheme.secondary.withOpacity(0.15) : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.print_rounded, color: hardware.isConnected ? AppTheme.secondary : AppTheme.textMuted, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thermal Printer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text(
                                  hardware.isConnected ? '● Connected (${settings.printerPaperSize} ESC/POS)' : '○ Not Connected (Bluetooth)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: hardware.isConnected ? AppTheme.secondary : AppTheme.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => context.push('/hardware'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            side: const BorderSide(color: AppTheme.primaryContainer),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Manage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer)),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.surfaceBorder, height: 20),
                    // Paper Roll Width Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paper Width Size', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        DropdownButton<String>(
                          value: _printerSize,
                          underline: const SizedBox(),
                          dropdownColor: AppTheme.surfaceElevated,
                          items: const [
                            DropdownMenuItem(value: '58mm', child: Text('58mm (2-inch Roll)', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: '80mm', child: Text('80mm (3-inch Roll)', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _printerSize = val);
                              _saveAllSettings();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ============================================================
              // 3. BUSINESS FINANCIAL INSIGHTS (MONTHLY / YEARLY GRAPHS)
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FINANCIAL INSIGHTS & PROFIT/LOSS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
                  // Period Toggle
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = FinancialPeriod.monthly),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == FinancialPeriod.monthly ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Monthly', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = FinancialPeriod.yearly),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedPeriod == FinancialPeriod.yearly ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Yearly', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPeriod == FinancialPeriod.monthly ? 'This Month Gross' : 'This Year Gross',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            Text(
                              _selectedPeriod == FinancialPeriod.monthly ? '₹4,28,500.00' : '₹51,42,000.00',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Net Profit', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            Text(
                              _selectedPeriod == FinancialPeriod.monthly ? '+₹1,12,040 (26%)' : '+₹14,39,760 (28%)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.secondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Visual Graph Bar Simulation
                    _buildFinancialBarChart(_selectedPeriod),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // 4. LOG OUT ACTION BUTTON
              // ============================================================
              OutlinedButton.icon(
                onPressed: _confirmLogOut,
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                label: const Text('Log Out of Super Inventory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.error),
                  backgroundColor: AppTheme.error.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialBarChart(FinancialPeriod period) {
    final labels = period == FinancialPeriod.monthly
        ? ['Week 1', 'Week 2', 'Week 3', 'Week 4']
        : ['2023', '2024', '2025', '2026 (YTD)'];

    final heights = period == FinancialPeriod.monthly ? [0.55, 0.75, 0.85, 0.65] : [0.45, 0.65, 0.85, 0.95];

    return SizedBox(
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(labels.length, (i) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 28,
                height: 60 * heights[i],
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[i], style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
            ],
          );
        }),
      ),
    );
  }
}
