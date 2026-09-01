import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ============================================================
      // STITCH CENTER PROMINENT SCAN & BILL FLOATING ACTION BUTTON
      // ============================================================
      floatingActionButton: Container(
        height: 68,
        width: 68,
        margin: const EdgeInsets.only(top: 14),
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () => context.push('/billing'),
            backgroundColor: AppTheme.primary,
            elevation: 10,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 3),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Group: Home & Products
            Row(
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/'),
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go('/products'),
                ),
              ],
            ),

            // Spacer for center floating action button
            const SizedBox(width: 48),

            // Right Group: Bills/History & Reports/Settings
            Row(
              children: [
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/history'),
                ),
                _buildNavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/reports'),
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: currentIndex == 4,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.primaryContainer : AppTheme.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryContainer : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
