import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _openTimeCtrl;
  late TextEditingController _closeTimeCtrl;
  late TextEditingController _offerCtrl;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _businessNameCtrl = TextEditingController(text: s.shopName);
    _phoneCtrl = TextEditingController(text: s.grievanceHelpline.isNotEmpty ? s.grievanceHelpline : s.phone);
    _addressCtrl = TextEditingController(text: s.address);
    _openTimeCtrl = TextEditingController(text: '08:00 AM');
    _closeTimeCtrl = TextEditingController(text: '10:30 PM');
    _offerCtrl = TextEditingController(text: s.promotionalOffer);
    _categories = ['Groceries', 'Dairy & Bakery', 'Beverages', 'Household Essentials'];
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    _offerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final current = ref.read(settingsProvider);
    final timings = "${_openTimeCtrl.text.trim()} - ${_closeTimeCtrl.text.trim()}";
    
    final updated = current.copyWith(
      shopName: _businessNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      grievanceHelpline: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      storeTimings: timings,
      promotionalOffer: _offerCtrl.text.trim(),
      productsSold: _categories.join(', '),
    );

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Business Profile & Receipt Ads Updated Successfully!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      context.pop();
    }
  }

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
        title: const Text('Edit Profile & Business Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // 1. PHOTO UPLOAD SECTION
              // ============================================================
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.storefront_rounded, size: 48, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Business or Store Photo', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // 2. BASIC DETAILS
              // ============================================================
              Container(
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
                        Icon(Icons.storefront_rounded, color: AppTheme.primaryContainer, size: 18),
                        SizedBox(width: 8),
                        Text('Basic Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('Business Name *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _businessNameCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Super Inventory Store'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Business Name is required' : null,
                    ),

                    const SizedBox(height: 12),

                    const Text('Phone Number (Customer Support & Grievance) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.call_rounded, size: 18, color: AppTheme.textMuted),
                        hintText: '+91 9876543210',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                    ),

                    const SizedBox(height: 12),

                    const Text('Location / Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_rounded, size: 18, color: AppTheme.textMuted),
                        hintText: '123 Market Street, City Centre',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ============================================================
              // 3. OPERATING HOURS
              // ============================================================
              Container(
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
                        Icon(Icons.schedule_rounded, color: AppTheme.secondary, size: 18),
                        SizedBox(width: 8),
                        Text('Operating Hours', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Opening Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              TextFormField(controller: _openTimeCtrl, decoration: const InputDecoration(hintText: '08:00 AM')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Closing Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              TextFormField(controller: _closeTimeCtrl, decoration: const InputDecoration(hintText: '10:30 PM')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ============================================================
              // 4. OFFERS & ANNOUNCEMENTS (PRINTED ON BILLS)
              // ============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1429),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.tertiary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.celebration_rounded, color: AppTheme.tertiary, size: 18),
                        SizedBox(width: 8),
                        Text('Offers & Announcements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.tertiary)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('Current Promotion (Prints on customer bills)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _offerCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: '🎉 Festive Special: Flat 10% OFF on purchases above ₹1,000! Call for free delivery.'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ============================================================
              // 5. TOP CATEGORIES SOLD
              // ============================================================
              Container(
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
                        Icon(Icons.category_rounded, color: AppTheme.primaryContainer, size: 18),
                        SizedBox(width: 8),
                        Text('Top Categories Sold', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._categories.map((c) => Chip(
                              backgroundColor: AppTheme.surfaceElevated,
                              label: Text(c, style: const TextStyle(fontSize: 11, color: Colors.white)),
                              side: const BorderSide(color: AppTheme.surfaceBorder),
                            )),
                        ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 14, color: AppTheme.primaryContainer),
                          label: const Text('Add more', style: TextStyle(fontSize: 11, color: AppTheme.primaryContainer)),
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: AppTheme.primaryContainer, style: BorderStyle.solid),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // 6. RECEIPT SYNC NOTICE & SAVE BUTTON
              // ============================================================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.primaryContainer, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The details provided above will be automatically printed on customer bills and digital receipts for grievance support and promotional reach.',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Profile Updates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
