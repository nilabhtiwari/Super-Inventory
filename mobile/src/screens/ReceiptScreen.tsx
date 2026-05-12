import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, Alert, Share } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useRoute, RouteProp } from '@react-navigation/native';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import QRCode from 'react-native-qrcode-svg';
import { getSale } from '../api/sales';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { formatCurrency, formatDate, buildUpiUrl } from '../utils/formatters';
import { RootStackParamList } from '../navigation/AppNavigator';

type RoutePropType = RouteProp<RootStackParamList, 'Receipt'>;

export default function ReceiptScreen() {
  const route = useRoute<RoutePropType>();
  const { saleId } = route.params;
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getSale(saleId).then(r => { setData(r); setLoading(false); }).catch(() => setLoading(false));
  }, [saleId]);

  if (loading || !data) return <LoadingOverlay visible message="Loading receipt…" />;

  const { sale, settings } = data;
  const items: any[] = sale.items || [];
  const upiUrl = settings?.upi_id
    ? buildUpiUrl({ pa: settings.upi_id, pn: settings.upi_name || settings.shop_name, am: sale.grand_total, tn: `INV ${sale.invoice_no}` })
    : null;

  // ── HTML receipt for printing ─────────────────────────────────────────────
  const buildHtml = () => `<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
  body{font-family:Arial,sans-serif;max-width:380px;margin:0 auto;padding:16px;font-size:13px}
  h1{text-align:center;font-size:18px;margin:0 0 4px}
  .center{text-align:center}.muted{color:#666}.divider{border-top:1px dashed #ccc;margin:8px 0}
  table{width:100%;border-collapse:collapse}td{padding:3px 0}
  .right{text-align:right}.bold{font-weight:700}.total{font-size:16px}
</style></head><body>
<h1>${settings?.shop_name || 'Receipt'}</h1>
<p class="center muted">${settings?.shop_address || ''}<br>${settings?.shop_phone || ''}</p>
${settings?.gstin ? `<p class="center muted">GSTIN: ${settings.gstin}</p>` : ''}
<div class="divider"></div>
<p><b>Invoice:</b> ${sale.invoice_no}<br><b>Date:</b> ${formatDate(sale.created_at)}<br><b>Seller:</b> ${sale.seller_name}</p>
<div class="divider"></div>
<table><tr class="muted"><td>Item</td><td class="right">Qty</td><td class="right">Rate</td><td class="right">Amount</td></tr>
${items.map(i => `<tr><td>${i.product_name}<br><span class="muted" style="font-size:11px">HSN: ${i.hsn_code || '-'} | GST: ${parseFloat(i.cgst_rate) + parseFloat(i.sgst_rate)}%</span></td><td class="right">${i.qty}</td><td class="right">₹${parseFloat(i.unit_price).toFixed(2)}</td><td class="right">₹${parseFloat(i.line_total).toFixed(2)}</td></tr>`).join('')}
</table>
<div class="divider"></div>
<table>
<tr><td>Subtotal</td><td class="right">₹${parseFloat(sale.subtotal).toFixed(2)}</td></tr>
${parseFloat(sale.cgst_total) > 0 ? `<tr><td class="muted">CGST</td><td class="right muted">₹${parseFloat(sale.cgst_total).toFixed(2)}</td></tr>` : ''}
${parseFloat(sale.sgst_total) > 0 ? `<tr><td class="muted">SGST</td><td class="right muted">₹${parseFloat(sale.sgst_total).toFixed(2)}</td></tr>` : ''}
${parseFloat(sale.igst_total) > 0 ? `<tr><td class="muted">IGST</td><td class="right muted">₹${parseFloat(sale.igst_total).toFixed(2)}</td></tr>` : ''}
${parseFloat(sale.discount_amount) > 0 ? `<tr><td class="muted">Discount</td><td class="right muted">-₹${parseFloat(sale.discount_amount).toFixed(2)}</td></tr>` : ''}
<tr class="bold total"><td>GRAND TOTAL</td><td class="right">₹${parseFloat(sale.grand_total).toFixed(2)}</td></tr>
<tr><td class="muted">Payment</td><td class="right muted">${sale.payment_method.toUpperCase()}</td></tr>
</table>
<div class="divider"></div>
<p class="center muted">${settings?.receipt_footer || 'Thank you for your purchase!'}</p>
</body></html>`;

  const handlePrint = async () => {
    try {
      const { uri } = await Print.printToFileAsync({ html: buildHtml() });
      if (await Sharing.isAvailableAsync()) { await Sharing.shareAsync(uri, { mimeType: 'application/pdf', dialogTitle: 'Share Receipt' }); }
      else { await Print.printAsync({ html: buildHtml() }); }
    } catch (e: any) { Alert.alert('Print Error', e.message); }
  };

  const Row = ({ label, value, bold }: { label: string; value: string; bold?: boolean }) => (
    <View style={rs.row}><Text style={[rs.rl, bold && rs.bold]}>{label}</Text><Text style={[rs.rv, bold && rs.bold]}>{value}</Text></View>
  );

  return (
    <SafeAreaView style={rs.safe} edges={['bottom']}>
      <ScrollView contentContainerStyle={rs.scroll}>
        {/* Shop header */}
        <View style={rs.shopHead}>
          <Text style={rs.shopName}>{settings?.shop_name}</Text>
          {settings?.shop_address ? <Text style={rs.shopSub}>{settings.shop_address}</Text> : null}
          {settings?.gstin ? <Text style={rs.shopSub}>GSTIN: {settings.gstin}</Text> : null}
        </View>

        <View style={rs.card}>
          <View style={rs.invoiceRow}>
            <View><Text style={rs.invLabel}>Invoice No.</Text><Text style={rs.invVal}>{sale.invoice_no}</Text></View>
            <View style={rs.right}><Text style={rs.invLabel}>Date</Text><Text style={rs.invVal}>{formatDate(sale.created_at)}</Text></View>
          </View>
          <Text style={rs.sectionTitle}>Items</Text>
          {items.map((item: any, idx: number) => (
            <View key={idx} style={rs.itemRow}>
              <View style={rs.flex}><Text style={rs.itemName}>{item.product_name}</Text><Text style={rs.itemSub}>GST {(parseFloat(item.cgst_rate) + parseFloat(item.sgst_rate)).toFixed(0)}% · Qty {item.qty} × {formatCurrency(item.unit_price)}</Text></View>
              <Text style={rs.itemTotal}>{formatCurrency(item.line_total)}</Text>
            </View>
          ))}
          <View style={rs.divider} />
          <Row label="Subtotal" value={formatCurrency(sale.subtotal)} />
          {parseFloat(sale.cgst_total) > 0 && <Row label="CGST" value={formatCurrency(sale.cgst_total)} />}
          {parseFloat(sale.sgst_total) > 0 && <Row label="SGST" value={formatCurrency(sale.sgst_total)} />}
          {parseFloat(sale.igst_total) > 0 && <Row label="IGST" value={formatCurrency(sale.igst_total)} />}
          {parseFloat(sale.discount_amount) > 0 && <Row label="Discount" value={`- ${formatCurrency(sale.discount_amount)}`} />}
          <View style={rs.divider} />
          <Row label="Grand Total" value={formatCurrency(sale.grand_total)} bold />
          <Row label="Payment" value={sale.payment_method.toUpperCase()} />
        </View>

        {/* UPI QR Code */}
        {upiUrl && (
          <View style={rs.qrCard}>
            <Text style={rs.qrTitle}>Pay via UPI</Text>
            <Text style={rs.qrSub}>Scan to pay ₹{parseFloat(sale.grand_total).toFixed(2)}</Text>
            <View style={rs.qrBox}>
              <QRCode value={upiUrl} size={160} backgroundColor="white" color="black" />
            </View>
            <Text style={rs.qrId}>UPI ID: {settings.upi_id}</Text>
          </View>
        )}

        {settings?.receipt_footer ? <Text style={rs.footer}>{settings.receipt_footer}</Text> : null}
      </ScrollView>

      {/* Action buttons */}
      <View style={rs.actions}>
        <TouchableOpacity style={rs.printBtn} onPress={handlePrint}>
          <Ionicons name="print-outline" size={20} color={Colors.white} />
          <Text style={rs.printText}>Print / Share PDF</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const rs = StyleSheet.create({
  safe:       { flex: 1, backgroundColor: Colors.bg },
  scroll:     { padding: Spacing.lg, paddingBottom: Spacing.xxxl },
  shopHead:   { alignItems: 'center', marginBottom: Spacing.lg },
  shopName:   { color: Colors.textPrimary, fontSize: FontSizes.xl, fontWeight: '800', textAlign: 'center' },
  shopSub:    { color: Colors.textMuted, fontSize: FontSizes.xs, textAlign: 'center', marginTop: 2 },
  card:       { backgroundColor: Colors.surface, borderRadius: Radius.xl, padding: Spacing.xl, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm, marginBottom: Spacing.lg },
  invoiceRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: Spacing.lg },
  right:      { alignItems: 'flex-end' },
  invLabel:   { color: Colors.textMuted, fontSize: FontSizes.xs },
  invVal:     { color: Colors.textPrimary, fontSize: FontSizes.md, fontWeight: '700' },
  sectionTitle:{ color: Colors.textSecondary, fontSize: FontSizes.xs, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1, marginBottom: Spacing.sm },
  itemRow:    { flexDirection: 'row', justifyContent: 'space-between', marginBottom: Spacing.sm },
  flex:       { flex: 1, marginRight: Spacing.sm },
  itemName:   { color: Colors.textPrimary, fontSize: FontSizes.sm, fontWeight: '600' },
  itemSub:    { color: Colors.textMuted, fontSize: FontSizes.xs },
  itemTotal:  { color: Colors.secondary, fontSize: FontSizes.sm, fontWeight: '700' },
  divider:    { height: 1, borderTopWidth: 1, borderStyle: 'dashed', borderColor: Colors.border, marginVertical: Spacing.md },
  row:        { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  rl:         { color: Colors.textSecondary, fontSize: FontSizes.sm },
  rv:         { color: Colors.textPrimary, fontSize: FontSizes.sm },
  bold:       { fontWeight: '800', fontSize: FontSizes.lg, color: Colors.secondary },
  qrCard:     { backgroundColor: Colors.surface, borderRadius: Radius.xl, padding: Spacing.xl, alignItems: 'center', borderWidth: 1, borderColor: Colors.border, marginBottom: Spacing.lg },
  qrTitle:    { color: Colors.textPrimary, fontSize: FontSizes.lg, fontWeight: '700', marginBottom: 4 },
  qrSub:      { color: Colors.textSecondary, fontSize: FontSizes.sm, marginBottom: Spacing.lg },
  qrBox:      { backgroundColor: Colors.white, padding: Spacing.md, borderRadius: Radius.md, marginBottom: Spacing.md },
  qrId:       { color: Colors.textMuted, fontSize: FontSizes.xs },
  footer:     { color: Colors.textMuted, fontSize: FontSizes.sm, textAlign: 'center', marginTop: Spacing.sm },
  actions:    { padding: Spacing.lg, borderTopWidth: 1, borderTopColor: Colors.border, backgroundColor: Colors.surface },
  printBtn:   { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10, backgroundColor: Colors.primary, borderRadius: Radius.lg, paddingVertical: 16, ...Shadows.glow },
  printText:  { color: Colors.white, fontSize: FontSizes.md, fontWeight: '700' },
});
