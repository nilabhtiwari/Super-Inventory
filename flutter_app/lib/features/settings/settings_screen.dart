import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/hardware_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _printerSize;

  @override
  void initState() {
    super.initState();
    _printerSize = ref.read(settingsProvider).printerPaperSize;
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
        elevation: 2,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // 1. STORE PROFILE BANNER (NAVIGATES TO FULL EDIT PROFILE)
            // ============================================================
            InkWell(
              onTap: () => context.push('/edit-profile'),
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
                          const SizedBox(height: 2),
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
            // 2. THERMAL PRINTER HARDWARE SETTING
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: hardware.isConnected ? AppTheme.secondary.withOpacity(0.15) : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.print_rounded, color: hardware.isConnected ? AppTheme.secondary : AppTheme.textMuted, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thermal Printer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: hardware.isConnected ? AppTheme.secondary : AppTheme.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    hardware.isConnected ? 'Connected (${settings.printerPaperSize} ESC/POS)' : 'Not Connected (Bluetooth)',
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
                  const Divider(color: AppTheme.surfaceBorder, height: 22),
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
                            ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(printerPaperSize: val));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ============================================================
            // 3. MERCHANT UPI VPA & DIGITAL PAYMENTS
            // ============================================================
            const Text('PAYMENT CONFIGURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Merchant UPI VPA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(settings.upiId, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.verified_rounded, color: AppTheme.secondary, size: 18),
                ],
              ),
            ),

            const SizedBox(height: 28),

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
    );
  }
}
