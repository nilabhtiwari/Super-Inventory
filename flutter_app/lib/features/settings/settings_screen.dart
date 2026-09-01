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
  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text('Are you sure you want to sign out of Super Inventory?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hardware = ref.watch(hardwareProvider);
    final authState = ref.watch(authProvider);

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
            // 1. PROFILE SECTION (CLICKABLE)
            // ============================================================
            InkWell(
              onTap: () => context.push('/edit-profile'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, size: 28, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.shopName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authState.user?.email ?? 'merchant@superinventory.com',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // 2. HARDWARE SECTION
            // ============================================================
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 8),
              child: Text(
                'HARDWARE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryContainer, letterSpacing: 1),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  // Thermal Printer Item
                  InkWell(
                    onTap: () => context.push('/hardware'),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: hardware.isConnected ? AppTheme.secondary.withOpacity(0.15) : AppTheme.surfaceElevated,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.print_rounded, color: hardware.isConnected ? AppTheme.secondary : AppTheme.textMuted, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thermal Printer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                Text('Epson TM-T88V (${settings.printerPaperSize})', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hardware.isConnected ? AppTheme.secondary : AppTheme.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hardware.isConnected ? 'Connected' : 'Not Connected',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hardware.isConnected ? AppTheme.secondary : AppTheme.warning,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // Barcode Scanner Item
                  Opacity(
                    opacity: 0.7,
                    child: InkWell(
                      onTap: () => context.push('/hardware'),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, color: AppTheme.textMuted, size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Barcode Scanner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text('Bluetooth Wireless Scanner', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.circle, color: AppTheme.error, size: 8),
                                SizedBox(width: 6),
                                Text('Not Connected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error)),
                                SizedBox(width: 6),
                                Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // 3. PREFERENCES SECTION
            // ============================================================
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 8),
              child: Text(
                'PREFERENCES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryContainer, letterSpacing: 1),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  // Notifications
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.textSecondary, size: 22),
                    title: const Text('Notifications', style: TextStyle(fontSize: 14, color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    onTap: () {},
                  ),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // Language
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppTheme.textSecondary, size: 22),
                    title: const Text('Language', style: TextStyle(fontSize: 14, color: Colors.white)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('English (US)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                      ],
                    ),
                    onTap: () {},
                  ),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // Security
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppTheme.textSecondary, size: 22),
                    title: const Text('Security & Biometrics', style: TextStyle(fontSize: 14, color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    onTap: () {},
                  ),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // About
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 22),
                    title: const Text('About Super Inventory', style: TextStyle(fontSize: 14, color: Colors.white)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('v2.1.0-STABLE', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                      ],
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // 4. SIGN OUT BUTTON (CENTERED PILL BUTTON)
            // ============================================================
            Center(
              child: OutlinedButton.icon(
                onPressed: _confirmSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.error),
                label: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: AppTheme.error.withOpacity(0.08),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
