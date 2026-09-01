import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../data/services/thermal_printer_service.dart';
import '../../data/models/shop_settings_model.dart';

class HardwareState {
  final List<BluetoothDevice> pairedDevices;
  final BluetoothDevice? connectedDevice;
  final BluetoothPrinterStatus printerStatus;
  final bool isScanning;
  final String? message;

  HardwareState({
    this.pairedDevices = const [],
    this.connectedDevice,
    this.printerStatus = BluetoothPrinterStatus.disconnected,
    this.isScanning = false,
    this.message,
  });

  bool get isConnected => printerStatus == BluetoothPrinterStatus.connected;

  HardwareState copyWith({
    List<BluetoothDevice>? pairedDevices,
    BluetoothDevice? connectedDevice,
    BluetoothPrinterStatus? printerStatus,
    bool? isScanning,
    String? message,
  }) {
    return HardwareState(
      pairedDevices: pairedDevices ?? this.pairedDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      printerStatus: printerStatus ?? this.printerStatus,
      isScanning: isScanning ?? this.isScanning,
      message: message ?? this.message,
    );
  }
}

class HardwareNotifier extends StateNotifier<HardwareState> {
  final ThermalPrinterService _service = ThermalPrinterService.instance;

  HardwareNotifier() : super(HardwareState()) {
    scanDevices();
  }

  Future<void> scanDevices() async {
    state = state.copyWith(isScanning: true, message: null);
    try {
      final devices = await _service.getPairedDevices();
      state = state.copyWith(
        pairedDevices: devices,
        isScanning: false,
        connectedDevice: _service.connectedDevice,
        printerStatus: _service.status,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        message: 'Bluetooth scan error: $e',
      );
    }
  }

  Future<bool> connectPrinter(BluetoothDevice device) async {
    state = state.copyWith(printerStatus: BluetoothPrinterStatus.connecting);
    final success = await _service.connect(device);
    state = state.copyWith(
      connectedDevice: _service.connectedDevice,
      printerStatus: _service.status,
      message: success ? 'Connected to ${device.name}' : 'Connection failed',
    );
    return success;
  }

  Future<void> disconnectPrinter() async {
    await _service.disconnect();
    state = state.copyWith(
      connectedDevice: null,
      printerStatus: BluetoothPrinterStatus.disconnected,
      message: 'Disconnected',
    );
  }

  Future<bool> printTestSlip(ShopSettingsModel settings) async {
    return await _service.printTestSlip(settings);
  }
}

final hardwareProvider = StateNotifierProvider<HardwareNotifier, HardwareState>((ref) {
  return HardwareNotifier();
});
