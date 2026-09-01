import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/hardware_provider.dart';
import '../../data/models/sale_model.dart';
import '../../data/local/database_helper.dart';
import '../../data/services/thermal_printer_service.dart';
import '../../data/services/pdf_receipt_service.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final int saleId;

  const ReceiptScreen({super.key, required this.saleId});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  SaleModel? _sale;
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    final sale = await DatabaseHelper.instance.getSaleById(widget.saleId);
    if (mounted) {
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleThermalPrint() async {
    if (_sale == null) return;
    final settings = ref.read(settingsProvider);
    final hardware = ref.read(hardwareProvider);

    if (!hardware.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bluetooth thermal printer not connected.'),
          action: SnackBarAction(
            label: 'Connect',
            onPressed: () => context.push('/hardware'),
          ),
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);
    final success = await ThermalPrinterService.instance.printInvoice(
      sale: _sale!,
      settings: settings,
    );
    setState(() => _isPrinting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Invoice sent to thermal printer!' : 'Printer error'),
          backgroundColor: success ? AppTheme.secondary : AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showWhatsAppDialog() async {
    if (_sale == null) return;
    final phoneController = TextEditingController(text: _sale?.customerPhone ?? '');

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Send Invoice to WhatsApp'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: const InputDecoration(
              prefixText: '+91 ',
              hintText: '10-digit mobile number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final phone = phoneController.text.trim();
                Navigator.pop(ctx);
                final settings = ref.read(settingsProvider);
                await PdfReceiptService.sendInvoiceToWhatsApp(
                  sale: _sale!,
                  settings: settings,
                  phoneNumber: phone,
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final hardware = ref.watch(hardwareProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const Center(child: Text('Invoice not found.')),
      );
    }

    final sale = _sale!;
    final upiPayload = (settings.upiId != null && settings.upiId!.isNotEmpty)
        ? Formatters.buildUpiQrPayload(
            upiId: settings.upiId!,
            payeeName: settings.upiName ?? settings.shopName,
            amount: sale.grandTotal,
            invoiceNumber: sale.invoiceNumber,
          )
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(sale.invoiceNumber),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============================================================
            // THERMAL RECEIPT VISUAL CARD
            // ============================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Store Branding Header
                  Text(
                    settings.shopName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (settings.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      settings.address!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (settings.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Phone: ${settings.phone}",
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (settings.gstin != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      "GSTIN: ${settings.gstin}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppTheme.surfaceBorder, thickness: 1),
                  ),

                  // Invoice Meta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Invoice: ${sale.invoiceNumber}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(Formatters.dateShort(sale.createdAt),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Cashier: ${sale.sellerName ?? 'Counter 1'}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(Formatters.time(sale.createdAt),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppTheme.surfaceBorder, thickness: 1),
                  ),

                  // Line Items List
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                              Text(
                                Formatters.currency(item.lineTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondary),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item.quantity} ${item.product.unit} x ${Formatters.currency(item.unitPrice)}",
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              Text(
                                "GST ${(item.cgstRate + item.sgstRate).toStringAsFixed(0)}% (₹${item.totalTax.toStringAsFixed(1)})",
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppTheme.surfaceBorder, thickness: 1),
                  ),

                  // Tax & Summary Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal:", style: TextStyle(color: AppTheme.textSecondary)),
                      Text(Formatters.currency(sale.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (sale.cgstTotal > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("CGST:", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(Formatters.currency(sale.cgstTotal),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (sale.sgstTotal > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SGST:", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(Formatters.currency(sale.sgstTotal),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                  if (sale.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Discount:", style: TextStyle(color: AppTheme.error)),
                        Text("-${Formatters.currency(sale.discountAmount)}",
                            style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "GRAND TOTAL:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        Formatters.currency(sale.grandTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Payment: ${sale.paymentMethod.name.toUpperCase()} (PAID)",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),

                  // ============================================================
                  // UPI QR CODE AT FOOTER
                  // ============================================================
                  if (upiPayload != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppTheme.surfaceBorder, thickness: 1),
                    ),
                    const Text(
                      'SCAN TO PAY VIA UPI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay exact ${Formatters.currency(sale.grandTotal)} with any UPI app',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: upiPayload,
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "UPI VPA: ${settings.upiId}",
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    settings.receiptFooter ?? 'Thank you for shopping with us!',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ============================================================
            // ACTION BUTTONS (PRINT, SHARE, WHATSAPP, NEW BILL)
            // ============================================================
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ).build(
                    context,
                    child: ElevatedButton(
                      onPressed: _isPrinting ? null : _handleThermalPrint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isPrinting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Print Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => PdfReceiptService.shareInvoicePdf(sale: sale, settings: settings),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, size: 18, color: AppTheme.textPrimary),
                        SizedBox(width: 8),
                        Text('Share PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showWhatsAppDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_rounded, size: 18, color: Color(0xFF25D366)),
                        SizedBox(width: 8),
                        Text('WhatsApp Invoice',
                            style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pushReplacement('/billing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
