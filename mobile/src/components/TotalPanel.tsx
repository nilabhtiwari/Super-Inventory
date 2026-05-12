import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, FontSizes, Spacing, Radius } from '../theme';
import { formatCurrency } from '../utils/formatters';

interface Props {
  subtotal: number;
  cgstTotal: number;
  sgstTotal: number;
  igstTotal: number;
  taxTotal: number;
  discountAmount: number;
  grandTotal: number;
  currencySymbol?: string;
}

const Row = ({ label, value, highlight = false, muted = false }: { label: string; value: string; highlight?: boolean; muted?: boolean }) => (
  <View style={styles.row}>
    <Text style={[styles.label, muted && styles.muted]}>{label}</Text>
    <Text style={[styles.value, highlight && styles.highlight, muted && styles.muted]}>{value}</Text>
  </View>
);

export default function TotalPanel({ subtotal, cgstTotal, sgstTotal, igstTotal, taxTotal, discountAmount, grandTotal, currencySymbol = '₹' }: Props) {
  const fmt = (n: number) => formatCurrency(n, currencySymbol);
  return (
    <View style={styles.container}>
      <Row label="Subtotal" value={fmt(subtotal)} />
      {cgstTotal > 0 && <Row label={`CGST`} value={fmt(cgstTotal)} muted />}
      {sgstTotal > 0 && <Row label={`SGST`} value={fmt(sgstTotal)} muted />}
      {igstTotal > 0 && <Row label={`IGST`} value={fmt(igstTotal)} muted />}
      {taxTotal > 0   && <Row label="Total Tax" value={fmt(taxTotal)} />}
      {discountAmount > 0 && <Row label="Discount" value={`- ${fmt(discountAmount)}`} muted />}
      <View style={styles.divider} />
      <Row label="Grand Total" value={fmt(grandTotal)} highlight />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.surface2,
    borderRadius: Radius.lg,
    padding: Spacing.lg,
    gap: Spacing.sm,
  },
  row:       { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  label:     { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '500' },
  value:     { color: Colors.textPrimary, fontSize: FontSizes.sm, fontWeight: '600' },
  highlight: { color: Colors.secondary, fontSize: FontSizes.xl, fontWeight: '800' },
  muted:     { color: Colors.textMuted, fontSize: FontSizes.xs },
  divider:   { height: 1, backgroundColor: Colors.border, marginVertical: Spacing.xs },
});
