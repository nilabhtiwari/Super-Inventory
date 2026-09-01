import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/hardware_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/services/thermal_printer_service.dart';

class BluetoothDeviceScreen extends ConsumerWidget {
  const BluetoothDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hardware = ref.watch(hardwareProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hardware & Devices'),
        actions: [
          IconButton(
            icon: hardware.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: hardware.isScanning
                ? null
                : () => ref.read(hardwareProvider.notifier).scanDevices(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hardware.isConnected ? AppTheme.secondary : AppTheme.surfaceBorder,
                  width: hardware.isConnected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (hardware.isConnected ? AppTheme.secondary : AppTheme.textMuted)
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hardware.isConnected ? Icons.print_rounded : Icons.print_disabled_rounded,
                          color: hardware.isConnected ? AppTheme.secondary : AppTheme.textMuted,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hardware.isConnected ? 'Thermal Printer Connected' : 'No Printer Connected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hardware.connectedDevice?.name ??
                                  (hardware.printerStatus == BluetoothPrinterStatus.connecting
                                      ? 'Connecting to printer...'
                                      : 'Pair printer in phone Bluetooth settings first'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hardware.isConnected) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await ref
                                  .read(hardwareProvider.notifier)
                                  .printTestSlip(settings);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Test slip printed!' : 'Test print error'),
                                    backgroundColor: success ? AppTheme.secondary : AppTheme.error,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.receipt_rounded, size: 18),
                            label: const Text('Print Test Slip'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => ref.read(hardwareProvider.notifier).disconnectPrinter(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.error),
                            foregroundColor: AppTheme.error,
                          ),
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Supported Devices Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Supports standard 58mm & 80mm ESC/POS Bluetooth thermal printers & Bluetooth HID barcode scanners.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Paired Devices List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PAIRED BLUETOOTH DEVICES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(hardwareProvider.notifier).scanDevices(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Scan Again', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (hardware.pairedDevices.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_searching_rounded,
                        size: 44, color: AppTheme.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Paired Bluetooth Devices Found',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Turn on Bluetooth and pair your printer in Android Settings > Bluetooth first.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hardware.pairedDevices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final device = hardware.pairedDevices[index];
                  final isCurrent = hardware.connectedDevice?.address == device.address &&
                      hardware.isConnected;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent ? AppTheme.secondary : AppTheme.surfaceBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.print_rounded,
                          color: isCurrent ? AppTheme.secondary : AppTheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name ?? 'Bluetooth Device',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                device.address ?? '',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'CONNECTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(hardwareProvider.notifier).connectPrinter(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Connect', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
