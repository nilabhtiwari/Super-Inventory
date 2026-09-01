import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/billing/billing_screen.dart';
import '../../features/invoices/receipt_screen.dart';
import '../../features/invoices/bill_history_screen.dart';
import '../../features/products/product_listing_screen.dart';
import '../../features/products/add_edit_product_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/hardware/bluetooth_device_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const BillHistoryScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListingScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/premium',
            builder: (context, state) => const PremiumToolkitScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Standalone Fullscreen Flow Routes
      GoRoute(
        path: '/billing',
        builder: (context, state) => const BillingScreen(),
      ),
      GoRoute(
        path: '/receipt/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ReceiptScreen(saleId: id);
        },
      ),
      GoRoute(
        path: '/add-edit-product',
        builder: (context, state) {
          final productId = state.extra as int?;
          return AddEditProductScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/hardware',
        builder: (context, state) => const BluetoothDeviceScreen(),
      ),
    ],
  );
});
