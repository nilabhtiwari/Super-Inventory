import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale_model.dart';
import '../models/shop_settings_model.dart';
import '../../core/utils/formatters.dart';

class PdfReceiptService {
  static Future<Uint8List> generateInvoicePdfBytes({
    required SaleModel sale,
    required ShopSettingsModel settings,
  }) async {
    final pdf = pw.Document();

    final upiPayload = (settings.upiId != null && settings.upiId!.isNotEmpty)
        ? Formatters.buildUpiQrPayload(
            upiId: settings.upiId!,
            payeeName: settings.upiName ?? settings.shopName,
            amount: sale.grandTotal,
            invoiceNumber: sale.invoiceNumber,
          )
        : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Store Header
              pw.Text(
                settings.shopName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              if (settings.address != null)
                pw.Text(
                  settings.address!,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              if (settings.phone != null)
                pw.Text('Ph: ${settings.phone!}', style: const pw.TextStyle(fontSize: 9)),
              if (settings.gstin != null)
                pw.Text('GSTIN: ${settings.gstin!}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice: ${sale.invoiceNumber}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text(Formatters.dateShort(sale.createdAt), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier: ${sale.sellerName ?? "Counter 1"}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(Formatters.time(sale.createdAt), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (sale.customerName != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Customer: ${sale.customerName!}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text('Item',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Rate',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Total',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Items List
              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(item.product.name,
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text('${item.quantity}',
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(item.unitPrice.toStringAsFixed(2),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(item.lineTotal.toStringAsFixed(2),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          ),
                        ],
                      ),
                      pw.Text(
                        'HSN: ${item.product.hsnCode ?? "-"} | GST: ${(item.cgstRate + item.sgstRate).toStringAsFixed(0)}%',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(Formatters.currency(sale.subtotal), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (sale.cgstTotal > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CGST', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(Formatters.currency(sale.cgstTotal),
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              if (sale.sgstTotal > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SGST', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(Formatters.currency(sale.sgstTotal),
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              if (sale.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red)),
                    pw.Text('-${Formatters.currency(sale.discountAmount)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.red)),
                  ],
                ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text(Formatters.currency(sale.grandTotal),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // QR Code at Footer
              if (upiPayload != null) ...[
                pw.Text('Scan to Pay via UPI',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: upiPayload,
                  width: 90,
                  height: 90,
                ),
                pw.SizedBox(height: 2),
                pw.Text('UPI: ${settings.upiId!}', style: const pw.TextStyle(fontSize: 7)),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              ],

              // Footer Note
              pw.Text(
                settings.receiptFooter ?? 'Thank you for shopping with us!',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Share PDF via standard system dialog
  static Future<void> shareInvoicePdf({
    required SaleModel sale,
    required ShopSettingsModel settings,
  }) async {
    final bytes = await generateInvoicePdfBytes(sale: sale, settings: settings);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Invoice_${sale.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Tax Invoice ${sale.invoiceNumber} from ${settings.shopName}',
      subject: 'Invoice ${sale.invoiceNumber}',
    );
  }

  /// 1-Click WhatsApp Invoice Sharing
  static Future<bool> sendInvoiceToWhatsApp({
    required SaleModel sale,
    required ShopSettingsModel settings,
    String? phoneNumber,
  }) async {
    final cleanPhone = phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final itemLines = sale.items
        .map((i) => "• ${i.product.name} (Qty: ${i.quantity}) - Rs. ${i.lineTotal.toStringAsFixed(2)}")
        .join("\n");

    final message = """
🧾 *${settings.shopName}*
*Tax Invoice:* ${sale.invoiceNumber}
*Date:* ${Formatters.date(sale.createdAt)}
------------------------------------
${itemLines}
------------------------------------
*Subtotal:* ${Formatters.currency(sale.subtotal)}
*Tax (GST):* ${Formatters.currency(sale.taxTotal)}
*Grand Total:* *${Formatters.currency(sale.grandTotal)}*
*Payment Mode:* ${sale.paymentMethod.name.toUpperCase()}

${settings.receiptFooter ?? "Thank you for shopping with us!"}
""";

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = formattedPhone.isNotEmpty
        ? 'https://wa.me/$formattedPhone?text=$encodedMessage'
        : 'https://api.whatsapp.com/send?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
