import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/hardware_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/services/thermal_printer_service.dart';

enum PrinterConnectionType { bluetooth, usbWired }

class BluetoothDeviceScreen extends ConsumerStatefulWidget {
  const BluetoothDeviceScreen({super.key});

  @override
  ConsumerState<BluetoothDeviceScreen> createState() => _BluetoothDeviceScreenState();
}

class _BluetoothDeviceScreenState extends ConsumerState<BluetoothDeviceScreen> {
  PrinterConnectionType _connectionType = PrinterConnectionType.bluetooth;
  bool _isSearching = false;
  List<Map<String, dynamic>> _discoveredDevices = [];

  void _searchPrinters() {
    setState(() {
      _isSearching = true;
      _discoveredDevices = [];
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        if (_connectionType == PrinterConnectionType.bluetooth) {
          _discoveredDevices = [
            {'name': 'MPT-II 58mm ESC/POS', 'address': 'DC:0D:30:4A:8B:11', 'type': 'Bluetooth', 'rssi': -54},
            {'name': 'BT-Printer-58', 'address': '66:22:90:1C:89:FE', 'type': 'Bluetooth', 'rssi': -68},
            {'name': 'Epson TM-T88V Wireless', 'address': '00:1A:7D:DA:71:04', 'type': 'Bluetooth', 'rssi': -72},
          ];
        } else {
          _discoveredDevices = [
            {'name': 'POS-58 USB Thermal Printer', 'address': 'USB Device (Port 1)', 'type': 'USB Wired', 'rssi': 0},
            {'name': 'TVS RP-3160 Gold USB', 'address': 'USB Device (Port 2)', 'type': 'USB Wired', 'rssi': 0},
          ];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final hardware = ref.watch(hardwareProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Thermal Printer & Devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // 1. LIVE CONNECTION STATUS BANNER
            // ============================================================
            Container(
              padding: const EdgeInsets.all(18),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (hardware.isConnected ? AppTheme.secondary : AppTheme.warning).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hardware.isConnected ? Icons.print_rounded : Icons.print_disabled_rounded,
                          color: hardware.isConnected ? AppTheme.secondary : AppTheme.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hardware.isConnected ? 'Thermal Printer Connected' : 'No Printer Connected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hardware.isConnected
                                  ? (hardware.connectedDevice?.name ?? 'ESC/POS 58mm Thermal Printer')
                                  : 'Select connection type & search below to pair',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (hardware.isConnected)
                        TextButton(
                          onPressed: () => ref.read(hardwareProvider.notifier).disconnect(),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                          child: const Text('Disconnect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  if (hardware.isConnected) ...[
                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.surfaceBorder, height: 1),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await ref.read(hardwareProvider.notifier).printTestSlip(settings);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? '✓ Test receipt slip printed!' : '⚠️ Printer communication failed'),
                              backgroundColor: ok ? AppTheme.secondary : AppTheme.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Print Test Slip (58mm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ============================================================
            // 2. CONNECTION TYPE SELECTOR (BLUETOOTH VS WIRED USB)
            // ============================================================
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'CONNECTION METHOD',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryContainer, letterSpacing: 1),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _connectionType = PrinterConnectionType.bluetooth;
                          _discoveredDevices = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _connectionType == PrinterConnectionType.bluetooth ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_rounded, size: 16, color: _connectionType == PrinterConnectionType.bluetooth ? Colors.white : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Bluetooth Wireless',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _connectionType == PrinterConnectionType.bluetooth ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _connectionType = PrinterConnectionType.usbWired;
                          _discoveredDevices = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _connectionType == PrinterConnectionType.usbWired ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.usb_rounded, size: 16, color: _connectionType == PrinterConnectionType.usbWired ? Colors.white : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'USB Cable / OTG',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _connectionType == PrinterConnectionType.usbWired ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Search Trigger Button
            OutlinedButton.icon(
              onPressed: _isSearching ? null : _searchPrinters,
              icon: _isSearching
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary))
                  : const Icon(Icons.search_rounded, size: 18, color: AppTheme.secondary),
              label: Text(
                _isSearching
                    ? 'Scanning for printers...'
                    : (_connectionType == PrinterConnectionType.bluetooth ? 'Search Nearby Bluetooth Printers' : 'Scan Connected USB Printers'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.secondary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppTheme.secondary.withOpacity(0.08),
              ),
            ),

            const SizedBox(height: 22),

            // ============================================================
            // 3. DISCOVERED PRINTERS LIST
            // ============================================================
            if (_discoveredDevices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'DISCOVERED PRINTERS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: _discoveredDevices.map((dev) {
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _connectionType == PrinterConnectionType.bluetooth ? Icons.bluetooth_rounded : Icons.usb_rounded,
                          color: AppTheme.primaryContainer,
                          size: 18,
                        ),
                      ),
                      title: Text(dev['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text("${dev['address']} • ${dev['type']}", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final printerDev = BluetoothPrinterDevice(name: dev['name'], address: dev['address']);
                          await ref.read(hardwareProvider.notifier).connect(printerDev);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("✓ Connected to ${dev['name']}"), backgroundColor: AppTheme.secondary),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Pair & Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (!_isSearching) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      _connectionType == PrinterConnectionType.bluetooth ? Icons.bluetooth_searching_rounded : Icons.usb_rounded,
                      size: 36,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _connectionType == PrinterConnectionType.bluetooth
                          ? 'No Bluetooth printers searched yet'
                          : 'No USB wired printers detected',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Turn on printer Bluetooth or connect USB OTG cable, then tap Search above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
