import React, { useRef, useState, useCallback } from 'react';
import {
  View, Text, TextInput, FlatList, TouchableOpacity,
  StyleSheet, Alert, Vibration,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useCartStore } from '../store/cartStore';
import { useAuthStore } from '../store/authStore';
import { useSettingsStore } from '../store/settingsStore';
import { getByBarcode } from '../api/products';
import { createSale } from '../api/sales';
import CartItemRow from '../components/CartItem';
import TotalPanel from '../components/TotalPanel';
import LoadingOverlay from '../components/LoadingOverlay';
import EmptyState from '../components/EmptyState';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { RootStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export default function POSScreen() {
  const navigation = useNavigation<Nav>();
  const barcodeRef = useRef<TextInput>(null);
  const [barcode, setBarcode] = useState('');
  const [scanning, setScanning] = useState(false);
  const [checkingOut, setCheckingOut] = useState(false);
  const [payMethod, setPayMethod] = useState<'cash' | 'upi' | 'card'>('cash');
  const lastScan = useRef({ code: '', time: 0 });

  const { items, subtotal, cgstTotal, sgstTotal, igstTotal, taxTotal,
          discountAmount, grandTotal, addItem, updateQty, removeItem, clearCart } = useCartStore();
  const { seller } = useAuthStore();
  const { settings } = useSettingsStore();

  const handleScan = useCallback(async (code: string) => {
    const trimmed = code.trim();
    if (!trimmed) return;
    const now = Date.now();
    if (trimmed === lastScan.current.code && now - lastScan.current.time < 500) return;
    lastScan.current = { code: trimmed, time: now };
    setBarcode('');
    setScanning(true);
    Vibration.vibrate(40);
    try {
      const { product } = await getByBarcode(trimmed);
      addItem(product);
    } catch (err: any) {
      Alert.alert('Not Found', `No product for barcode: ${trimmed}`);
      Vibration.vibrate([0, 60, 60, 60]);
    } finally {
      setScanning(false);
      setTimeout(() => barcodeRef.current?.focus(), 100);
    }
  }, [addItem]);

  const handleCheckout = async () => {
    if (items.length === 0) { Alert.alert('Empty Cart', 'Add items first.'); return; }
    Alert.alert('Confirm Sale', `Total: ₹${grandTotal.toFixed(2)} via ${payMethod.toUpperCase()}`, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Confirm', onPress: async () => {
        setCheckingOut(true);
        try {
          const { sale } = await createSale({
            items: items.map(i => ({ product_id: i.product_id, qty: i.qty })),
            payment_method: payMethod, discount_amount: discountAmount,
          });
          clearCart();
          navigation.navigate('Receipt', { saleId: sale.id });
        } catch (err: any) {
          Alert.alert('Checkout Failed', err.message);
        } finally { setCheckingOut(false); }
      }},
    ]);
  };

  const PAY = [
    { key: 'cash', icon: 'cash-outline',    label: 'Cash' },
    { key: 'upi',  icon: 'qr-code-outline', label: 'UPI' },
    { key: 'card', icon: 'card-outline',     label: 'Card' },
  ];

  return (
    <SafeAreaView style={s.safe} edges={['top']}>
      <LoadingOverlay visible={checkingOut} message="Processing…" />
      <View style={s.header}>
        <View>
          <Text style={s.shopName}>{settings?.shop_name || 'QEXmanage POS'}</Text>
          <Text style={s.sellerName}>👤 {seller?.name} · {seller?.role}</Text>
        </View>
        {items.length > 0 && (
          <TouchableOpacity onPress={() => Alert.alert('Clear Cart?', '', [{ text: 'Cancel', style: 'cancel' }, { text: 'Clear', style: 'destructive', onPress: clearCart }])} style={s.clearBtn}>
            <Ionicons name="trash-outline" size={18} color={Colors.error} />
          </TouchableOpacity>
        )}
      </View>

      <View style={[s.barcodeBox, scanning && s.barcodeBoxScanning]}>
        <Ionicons name={scanning ? 'hourglass-outline' : 'barcode-outline'} size={22} color={scanning ? Colors.warning : Colors.primary} />
        <TextInput
          ref={barcodeRef} style={s.barcodeInput} value={barcode}
          onChangeText={setBarcode} onSubmitEditing={() => handleScan(barcode)}
          placeholder={scanning ? 'Looking up…' : 'Scan barcode (BT HID) or type…'}
          placeholderTextColor={Colors.textMuted} autoFocus blurOnSubmit={false}
          returnKeyType="search" onBlur={() => setTimeout(() => barcodeRef.current?.focus(), 150)}
          editable={!scanning}
        />
        {barcode.length > 0 && !scanning && (
          <TouchableOpacity onPress={() => handleScan(barcode)} style={s.searchBtn}>
            <Ionicons name="search" size={18} color={Colors.white} />
          </TouchableOpacity>
        )}
      </View>

      <FlatList
        data={items} keyExtractor={i => String(i.product_id)} style={s.flex}
        contentContainerStyle={[s.cartList, items.length === 0 && s.flexGrow]}
        renderItem={({ item }) => (
          <CartItemRow item={item}
            onRemove={() => removeItem(item.product_id)}
            onQtyChange={(q) => updateQty(item.product_id, q)} />
        )}
        ListEmptyComponent={<EmptyState icon="scan-outline" title="Cart is empty" subtitle="Scan a barcode to add products" />}
      />

      {items.length > 0 && (
        <View style={s.footer}>
          <TotalPanel subtotal={subtotal} cgstTotal={cgstTotal} sgstTotal={sgstTotal}
            igstTotal={igstTotal} taxTotal={taxTotal} discountAmount={discountAmount}
            grandTotal={grandTotal} currencySymbol={settings?.currency_symbol || '₹'} />
          <View style={s.payRow}>
            {PAY.map(pm => (
              <TouchableOpacity key={pm.key} style={[s.payChip, payMethod === pm.key && s.payChipActive]}
                onPress={() => setPayMethod(pm.key as any)}>
                <Ionicons name={pm.icon as any} size={14} color={payMethod === pm.key ? Colors.white : Colors.textSecondary} />
                <Text style={[s.payLabel, payMethod === pm.key && s.payLabelActive]}>{pm.label}</Text>
              </TouchableOpacity>
            ))}
          </View>
          <TouchableOpacity style={s.checkoutBtn} onPress={handleCheckout} activeOpacity={0.85}>
            <Ionicons name="checkmark-circle-outline" size={22} color={Colors.white} />
            <Text style={s.checkoutText}>Checkout · ₹{grandTotal.toFixed(2)}</Text>
          </TouchableOpacity>
        </View>
      )}
    </SafeAreaView>
  );
}

const s = StyleSheet.create({
  safe:              { flex: 1, backgroundColor: Colors.bg },
  flex:              { flex: 1 },
  flexGrow:          { flexGrow: 1 },
  header:            { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: Spacing.lg, paddingVertical: Spacing.md, borderBottomWidth: 1, borderBottomColor: Colors.border },
  shopName:          { color: Colors.textPrimary, fontSize: FontSizes.lg, fontWeight: '700' },
  sellerName:        { color: Colors.textMuted, fontSize: FontSizes.xs, marginTop: 2 },
  clearBtn:          { padding: Spacing.sm },
  barcodeBox:        { flexDirection: 'row', alignItems: 'center', margin: Spacing.lg, backgroundColor: Colors.surface2, borderRadius: Radius.lg, borderWidth: 2, borderColor: Colors.primary, paddingHorizontal: Spacing.md, gap: Spacing.sm, ...Shadows.glow },
  barcodeBoxScanning:{ borderColor: Colors.warning },
  barcodeInput:      { flex: 1, color: Colors.textPrimary, fontSize: FontSizes.md, paddingVertical: 14 },
  searchBtn:         { backgroundColor: Colors.primary, padding: 8, borderRadius: Radius.sm },
  cartList:          { paddingHorizontal: Spacing.lg, paddingBottom: Spacing.md },
  footer:            { backgroundColor: Colors.surface, borderTopWidth: 1, borderTopColor: Colors.border, padding: Spacing.lg, gap: Spacing.md },
  payRow:            { flexDirection: 'row', gap: Spacing.sm },
  payChip:           { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5, paddingVertical: 9, borderRadius: Radius.md, backgroundColor: Colors.surface2, borderWidth: 1, borderColor: Colors.border },
  payChipActive:     { backgroundColor: Colors.primary, borderColor: Colors.primary },
  payLabel:          { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600' },
  payLabelActive:    { color: Colors.white },
  checkoutBtn:       { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10, backgroundColor: Colors.secondary, borderRadius: Radius.lg, paddingVertical: 16, ...Shadows.md },
  checkoutText:      { color: Colors.textInverse, fontSize: FontSizes.lg, fontWeight: '800' },
});
