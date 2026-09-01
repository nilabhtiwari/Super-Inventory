import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models/sale_model.dart';
import '../models/shop_settings_model.dart';
import '../../core/utils/formatters.dart';

enum BluetoothPrinterStatus { disconnected, connecting, connected }

class ThermalPrinterService {
  static final ThermalPrinterService instance = ThermalPrinterService._init();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  BluetoothDevice? _connectedDevice;
  BluetoothPrinterStatus _status = BluetoothPrinterStatus.disconnected;

  ThermalPrinterService._init();

  BluetoothPrinterStatus get status => _status;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _status == BluetoothPrinterStatus.connected;

  Future<bool> isBluetoothAvailable() async {
    return (await _bluetooth.isAvailable) ?? false;
  }

  Future<bool> isBluetoothOn() async {
    return (await _bluetooth.isOn) ?? false;
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (_) {
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    _status = BluetoothPrinterStatus.connecting;
    try {
      final connected = await _bluetooth.connect(device);
      if (connected == true) {
        _connectedDevice = device;
        _status = BluetoothPrinterStatus.connected;
        return true;
      }
    } catch (_) {
      // Connect failed
    }
    _status = BluetoothPrinterStatus.disconnected;
    _connectedDevice = null;
    return false;
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
    _status = BluetoothPrinterStatus.disconnected;
    _connectedDevice = null;
  }

  /// Prints a full commercial ESC/POS thermal invoice
  Future<bool> printInvoice({
    required SaleModel sale,
    required ShopSettingsModel settings,
  }) async {
    if (!isConnected) return false;

    try {
      // Check printer online state
      final isOnline = await _bluetooth.isConnected ?? false;
      if (!isOnline) {
        _status = BluetoothPrinterStatus.disconnected;
        return false;
      }

      // 1. Header (Centered, Bold Store Name)
      _bluetooth.printCustom(settings.shopName, 3, 1); // Size 3 (Large), Align 1 (Center)
      if (settings.address != null && settings.address!.isNotEmpty) {
        _bluetooth.printCustom(settings.address!, 0, 1);
      }
      if (settings.phone != null && settings.phone!.isNotEmpty) {
        _bluetooth.printCustom("Phone: ${settings.phone}", 0, 1);
      }
      if (settings.gstin != null && settings.gstin!.isNotEmpty) {
        _bluetooth.printCustom("GSTIN: ${settings.gstin}", 1, 1);
      }

      _bluetooth.printCustom("--------------------------------", 0, 1);
      _bluetooth.printLeftRight("Invoice: ${sale.invoiceNumber}", Formatters.dateShort(sale.createdAt), 0);
      _bluetooth.printCustom("Cashier: ${sale.sellerName ?? 'Counter 1'}", 0, 0);
      _bluetooth.printCustom("--------------------------------", 0, 1);

      // 2. Line Items Table
      _bluetooth.printLeftRight("ITEM [QTY x RATE]", "AMOUNT", 1);
      _bluetooth.printCustom("- - - - - - - - - - - - - - - - ", 0, 1);

      for (final item in sale.items) {
        final itemHeader = item.product.name;
        final details = "${item.quantity} ${item.product.unit} x ${item.unitPrice.toStringAsFixed(2)}";
        final totalStr = "Rs.${item.lineTotal.toStringAsFixed(2)}";

        _bluetooth.printCustom(itemHeader, 1, 0);
        _bluetooth.printLeftRight("  $details", totalStr, 0);
      }

      _bluetooth.printCustom("--------------------------------", 0, 1);

      // 3. Tax & Totals Breakdown
      _bluetooth.printLeftRight("Subtotal:", "Rs.${sale.subtotal.toStringAsFixed(2)}", 0);
      if (sale.cgstTotal > 0) {
        _bluetooth.printLeftRight("CGST Total:", "Rs.${sale.cgstTotal.toStringAsFixed(2)}", 0);
      }
      if (sale.sgstTotal > 0) {
        _bluetooth.printLeftRight("SGST Total:", "Rs.${sale.sgstTotal.toStringAsFixed(2)}", 0);
      }
      if (sale.igstTotal > 0) {
        _bluetooth.printLeftRight("IGST Total:", "Rs.${sale.igstTotal.toStringAsFixed(2)}", 0);
      }
      if (sale.discountAmount > 0) {
        _bluetooth.printLeftRight("Discount:", "-Rs.${sale.discountAmount.toStringAsFixed(2)}", 0);
      }

      _bluetooth.printCustom("================================", 0, 1);
      _bluetooth.printLeftRight("GRAND TOTAL:", "Rs.${sale.grandTotal.toStringAsFixed(2)}", 2); // Bold Large
      _bluetooth.printCustom("================================", 0, 1);
      _bluetooth.printLeftRight("Payment Mode:", sale.paymentMethod.name.toUpperCase(), 1);

      // 4. UPI Payment QR Code on Receipt Footer
      if (settings.upiId != null && settings.upiId!.isNotEmpty) {
        _bluetooth.printCustom("--- SCAN & PAY VIA UPI ---", 0, 1);
        final upiPayload = Formatters.buildUpiQrPayload(
          upiId: settings.upiId!,
          payeeName: settings.upiName ?? settings.shopName,
          amount: sale.grandTotal,
          invoiceNumber: sale.invoiceNumber,
        );
        _bluetooth.printQRcode(upiPayload, 200, 200, 1); // 200x200 centered
        _bluetooth.printCustom("UPI ID: ${settings.upiId}", 0, 1);
      }

      // 5. Footer & Paper Cut Feed
      _bluetooth.printCustom(settings.receiptFooter ?? "Thank you for shopping with us!", 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Print Test Receipt
  Future<bool> printTestSlip(ShopSettingsModel settings) async {
    if (!isConnected) return false;

    try {
      _bluetooth.printCustom(settings.shopName, 2, 1);
      _bluetooth.printCustom("*** TEST PRINT OK ***", 1, 1);
      _bluetooth.printCustom("Thermal Printer Connected", 0, 1);
      _bluetooth.printLeftRight("Status:", "READY", 0);
      _bluetooth.printLeftRight("Paper:", "${settings.paperWidthMm}mm", 0);
      _bluetooth.printCustom("--------------------------------", 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.paperCut();
      return true;
    } catch (_) {
      return false;
    }
  }
}
