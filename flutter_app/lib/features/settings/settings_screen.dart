import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/shop_settings_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstinController;
  late TextEditingController _upiIdController;
  late TextEditingController _upiNameController;
  late TextEditingController _footerController;
  int _paperWidth = 58;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.shopName);
    _addressController = TextEditingController(text: settings.address ?? '');
    _phoneController = TextEditingController(text: settings.phone ?? '');
    _emailController = TextEditingController(text: settings.email ?? '');
    _gstinController = TextEditingController(text: settings.gstin ?? '');
    _upiIdController = TextEditingController(text: settings.upiId ?? '');
    _upiNameController = TextEditingController(text: settings.upiName ?? '');
    _footerController = TextEditingController(text: settings.receiptFooter ?? '');
    _paperWidth = settings.paperWidthMm;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _upiIdController.dispose();
    _upiNameController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = ref.read(settingsProvider).copyWith(
          shopName: _nameController.text.trim(),
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          gstin: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim() : null,
          upiId: _upiIdController.text.trim().isNotEmpty ? _upiIdController.text.trim() : null,
          upiName: _upiNameController.text.trim().isNotEmpty ? _upiNameController.text.trim() : null,
          receiptFooter: _footerController.text.trim().isNotEmpty ? _footerController.text.trim() : null,
          paperWidthMm: _paperWidth,
        );

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store settings and UPI configuration updated!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Store & Hardware Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active User Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        authState.user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user?.name ?? 'Seller',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            "${authState.user?.email ?? ''} • Role: ${authState.user?.role.name.toUpperCase() ?? 'SELLER'}",
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. Store Branding & Contact
              _buildSectionHeader('Shop Profile & Invoice Header'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Store / Business Name *',
                        prefixIcon: Icon(Icons.store_rounded, color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Shop Address',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _gstinController,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN Number',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. UPI QR Payments Configuration
              _buildSectionHeader('UPI Payment QR (Receipt Footer)'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer scans QR code on receipt footer to pay exact bill via Google Pay, PhonePe, Paytm, BHIM, or any UPI app.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'Shop UPI VPA ID *',
                        prefixIcon: Icon(Icons.qr_code_rounded, color: AppTheme.secondary),
                        hintText: 'e.g. merchant@icici or 9876543210@paytm',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _upiNameController,
                      decoration: const InputDecoration(
                        labelText: 'Payee Name (displayed in UPI apps)',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                        hintText: 'e.g. SmartScan Retail Store',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Thermal Printer Paper Settings
              _buildSectionHeader('Thermal Receipt Printing'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paper Width Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('58mm (Standard Roll)'),
                            selected: _paperWidth == 58,
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                            onSelected: (val) => setState(() => _paperWidth = 58),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('80mm (Wide Roll)'),
                            selected: _paperWidth == 80,
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                            onSelected: (val) => setState(() => _paperWidth = 80),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _footerController,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Footer Message',
                        hintText: 'Thank you for shopping with us! Visit again.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/hardware'),
                      icon: const Icon(Icons.bluetooth_rounded, size: 18),
                      label: const Text('Manage Bluetooth Printers & Scanners'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Save Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
