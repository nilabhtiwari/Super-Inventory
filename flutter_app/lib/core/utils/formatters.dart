import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static String currency(num? amount) {
    if (amount == null) return '₹0.00';
    return _currencyFormat.format(amount);
  }

  static String compactCurrency(num? amount) {
    if (amount == null) return '₹0';
    return _compactCurrency.format(amount);
  }

  static String date(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String dateShort(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String time(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Builds a standard UPI payment deep link URL for QR Code & UPI intents
  /// Example: upi://pay?pa=shop@upi&pn=My+Shop&am=250.00&tn=INV-20260901-0001&cu=INR
  static String buildUpiQrPayload({
    required String upiId,
    required String payeeName,
    required double amount,
    required String invoiceNumber,
    String? note,
  }) {
    final cleanUpi = upiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(note ?? 'Payment for $invoiceNumber');
    final formattedAmount = amount.toStringAsFixed(2);

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&tn=$cleanNote&cu=INR';
  }

  /// Calculates GST breakdown for selling price (Tax-Inclusive vs Tax-Exclusive)
  static Map<String, double> calculateTaxBreakdown({
    required double sellingPrice,
    required double cgstRate,
    required double sgstRate,
    required double igstRate,
    required int quantity,
  }) {
    final totalGstRate = (igstRate > 0) ? igstRate : (cgstRate + sgstRate);
    final isTaxInclusive = false; // By default POS pricing is base price + GST

    double subtotal = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;
    double totalTax = 0.0;
    double grandTotal = 0.0;

    if (isTaxInclusive) {
      final basePricePerUnit = sellingPrice / (1 + (totalGstRate / 100));
      subtotal = basePricePerUnit * quantity;
      totalTax = (sellingPrice * quantity) - subtotal;
      if (igstRate > 0) {
        igstAmount = totalTax;
      } else {
        cgstAmount = totalTax / 2;
        sgstAmount = totalTax / 2;
      }
      grandTotal = sellingPrice * quantity;
    } else {
      subtotal = sellingPrice * quantity;
      if (igstRate > 0) {
        igstAmount = (subtotal * igstRate) / 100;
        totalTax = igstAmount;
      } else {
        cgstAmount = (subtotal * cgstRate) / 100;
        sgstAmount = (subtotal * sgstRate) / 100;
        totalTax = cgstAmount + sgstAmount;
      }
      grandTotal = subtotal + totalTax;
    }

    return {
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'cgstAmount': double.parse(cgstAmount.toStringAsFixed(2)),
      'sgstAmount': double.parse(sgstAmount.toStringAsFixed(2)),
      'igstAmount': double.parse(igstAmount.toStringAsFixed(2)),
      'totalTax': double.parse(totalTax.toStringAsFixed(2)),
      'grandTotal': double.parse(grandTotal.toStringAsFixed(2)),
    };
  }
}
