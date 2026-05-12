import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { CartItem as CartItemType } from '../store/cartStore';
import { Colors, FontSizes, Spacing, Radius } from '../theme';
import { formatCurrency } from '../utils/formatters';

interface Props {
  item: CartItemType;
  onRemove: () => void;
  onQtyChange: (qty: number) => void;
}

export default function CartItem({ item, onRemove, onQtyChange }: Props) {
  return (
    <View style={styles.container}>
      <View style={styles.info}>
        <Text style={styles.name} numberOfLines={1}>{item.name}</Text>
        <Text style={styles.sub}>
          {formatCurrency(item.unit_price)} × {item.qty}
          {item.cgst_rate > 0 && (
            <Text style={styles.gst}> · GST {item.cgst_rate + item.sgst_rate}%</Text>
          )}
        </Text>
      </View>

      <View style={styles.right}>
        <View style={styles.qtyRow}>
          <TouchableOpacity style={styles.qtyBtn} onPress={() => onQtyChange(item.qty - 1)}>
            <Ionicons name="remove" size={16} color={Colors.primary} />
          </TouchableOpacity>
          <TextInput
            style={styles.qtyInput}
            value={String(item.qty)}
            keyboardType="numeric"
            onChangeText={(v) => {
              const n = parseInt(v);
              if (!isNaN(n) && n > 0) onQtyChange(n);
            }}
            selectTextOnFocus
          />
          <TouchableOpacity style={styles.qtyBtn} onPress={() => onQtyChange(item.qty + 1)}>
            <Ionicons name="add" size={16} color={Colors.primary} />
          </TouchableOpacity>
        </View>
        <Text style={styles.total}>{formatCurrency(item.line_total)}</Text>
        <TouchableOpacity onPress={onRemove} style={styles.removeBtn}>
          <Ionicons name="trash-outline" size={16} color={Colors.error} />
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface2,
    borderRadius: Radius.md,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
    gap: Spacing.sm,
  },
  info:    { flex: 1 },
  name:    { color: Colors.textPrimary, fontSize: FontSizes.md, fontWeight: '600', marginBottom: 2 },
  sub:     { color: Colors.textSecondary, fontSize: FontSizes.xs },
  gst:     { color: Colors.textMuted },
  right:   { alignItems: 'flex-end', gap: 6 },
  qtyRow:  { flexDirection: 'row', alignItems: 'center', gap: 4 },
  qtyBtn:  {
    width: 28, height: 28, borderRadius: 8,
    backgroundColor: Colors.surface,
    justifyContent: 'center', alignItems: 'center',
    borderWidth: 1, borderColor: Colors.border,
  },
  qtyInput: {
    width: 36, textAlign: 'center',
    color: Colors.textPrimary, fontSize: FontSizes.md, fontWeight: '700',
  },
  total:     { color: Colors.secondary, fontSize: FontSizes.md, fontWeight: '700' },
  removeBtn: { padding: 2 },
});
