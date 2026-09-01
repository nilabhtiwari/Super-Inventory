import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _upiIdCtrl;
  late String _printerSize;
  late bool _enableGst;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _shopNameCtrl = TextEditingController(text: settings.shopName);
    _addressCtrl = TextEditingController(text: settings.address);
    _phoneCtrl = TextEditingController(text: settings.phone);
    _emailCtrl = TextEditingController(text: settings.email);
    _gstinCtrl = TextEditingController(text: settings.gstin);
    _upiIdCtrl = TextEditingController(text: settings.upiId);
    _printerSize = settings.printerPaperSize;
    _enableGst = settings.enableGst;
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      shopName: _shopNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      upiId: _upiIdCtrl.text.trim(),
      printerPaperSize: _printerSize,
      enableGst: _enableGst,
    );

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _confirmLogOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out of Super Inventory?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('Store & App Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Header Card
              Container(
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
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Super Inventory',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            "Logged in as ${authState.user?.name ?? 'Merchant'}",
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Store Profile Section
              const Text('STORE PROFILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
              const SizedBox(height: 10),

              TextFormField(
                controller: _shopNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  prefixIcon: Icon(Icons.store_rounded, color: AppTheme.primaryContainer),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Store name required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Store Address (Printed on Receipts)',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryContainer),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryContainer),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _gstinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN Number',
                        prefixIcon: Icon(Icons.receipt_outlined, color: AppTheme.primaryContainer),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Payments & UPI QR
              const Text('PAYMENTS & UPI QR SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
              const SizedBox(height: 10),

              TextFormField(
                controller: _upiIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merchant UPI ID / VPA (For Dynamic Payment QR)',
                  prefixIcon: Icon(Icons.qr_code_rounded, color: AppTheme.secondary),
                  helperText: 'Used to dynamically generate QR on invoices (e.g. store@okaxis)',
                ),
              ),

              const SizedBox(height: 24),

              // Hardware & Printer Roll
              const Text('THERMAL PRINTER ROLL SIZE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('58mm (2-inch)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      value: '58mm',
                      groupValue: _printerSize,
                      activeColor: AppTheme.primaryContainer,
                      onChanged: (val) => setState(() => _printerSize = val!),
                      tileColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.surfaceBorder)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('80mm (3-inch)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      value: '80mm',
                      groupValue: _printerSize,
                      activeColor: AppTheme.primaryContainer,
                      onChanged: (val) => setState(() => _printerSize = val!),
                      tileColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.surfaceBorder)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 16),

              // LOG OUT BUTTON
              OutlinedButton.icon(
                onPressed: _confirmLogOut,
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                label: const Text('Log Out of Super Inventory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.error),
                  backgroundColor: AppTheme.error.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
