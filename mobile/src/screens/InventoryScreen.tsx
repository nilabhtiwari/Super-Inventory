import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, RefreshControl, Modal, TextInput, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { getLowStock, adjustStock, getMovements } from '../api/inventory';
import EmptyState from '../components/EmptyState';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { formatCurrency, stockStatus } from '../utils/formatters';

const stockColor = { ok: Colors.success, low: Colors.warning, out: Colors.error };

export default function InventoryScreen() {
  const [products, setProducts]   = useState<any[]>([]);
  const [movements, setMovements] = useState<any[]>([]);
  const [loading, setLoading]     = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [tab, setTab]             = useState<'low' | 'movements'>('low');
  const [adjustModal, setAdjustModal] = useState(false);
  const [selected, setSelected]   = useState<any>(null);
  const [delta, setDelta]         = useState('');
  const [reason, setReason]       = useState<'purchase' | 'adjustment' | 'return'>('purchase');
  const [note, setNote]           = useState('');
  const [adjusting, setAdjusting] = useState(false);

  const load = useCallback(async (refresh = false) => {
    if (refresh) setRefreshing(true); else setLoading(true);
    try {
      const [low, mov] = await Promise.all([getLowStock(), getMovements({ limit: 50 })]);
      setProducts(low.products);
      setMovements(mov.movements);
    } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { load(); }, []);

  const openAdjust = (product: any) => { setSelected(product); setDelta(''); setNote(''); setAdjustModal(true); };

  const handleAdjust = async () => {
    const d = parseInt(delta);
    if (isNaN(d) || d === 0) { Alert.alert('Error', 'Enter a valid non-zero quantity'); return; }
    setAdjusting(true);
    try {
      await adjustStock({ product_id: selected.id, delta: d, reason, note });
      Alert.alert('Success', `Stock updated for ${selected.name}`);
      setAdjustModal(false);
      load(true);
    } catch (e: any) { Alert.alert('Error', e.message); }
    finally { setAdjusting(false); }
  };

  const REASONS = [
    { key: 'purchase', label: 'Purchase' },
    { key: 'adjustment', label: 'Adjustment' },
    { key: 'return', label: 'Return' },
  ];

  const LowStockCard = ({ item }: { item: any }) => {
    const status = stockStatus(item.stock_qty, item.low_stock_threshold);
    return (
      <View style={inv.card}>
        <View style={inv.row}>
          <View style={inv.flex}>
            <Text style={inv.name} numberOfLines={1}>{item.name}</Text>
            <Text style={inv.barcode}>{item.barcode}</Text>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 4 }}>
              <View style={[inv.badge, { borderColor: stockColor[status], backgroundColor: stockColor[status] + '22' }]}>
                <Text style={[inv.badgeText, { color: stockColor[status] }]}>
                  {status === 'out' ? '⚠ Out of Stock' : `${item.stock_qty} left`}
                </Text>
              </View>
              <Text style={inv.threshold}>Min: {item.low_stock_threshold}</Text>
            </View>
          </View>
          <View style={inv.right}>
            <Text style={inv.price}>{formatCurrency(item.selling_price)}</Text>
            <TouchableOpacity style={inv.adjustBtn} onPress={() => openAdjust(item)}>
              <Ionicons name="add-circle-outline" size={14} color={Colors.white} />
              <Text style={inv.adjustText}>Adjust</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  };

  const MovCard = ({ item }: { item: any }) => {
    const isIn = item.delta > 0;
    return (
      <View style={inv.movCard}>
        <View style={[inv.movIcon, { backgroundColor: isIn ? Colors.success + '22' : Colors.error + '22' }]}>
          <Ionicons name={isIn ? 'arrow-up-outline' : 'arrow-down-outline'} size={18} color={isIn ? Colors.success : Colors.error} />
        </View>
        <View style={inv.flex}>
          <Text style={inv.name} numberOfLines={1}>{item.product_name}</Text>
          <Text style={inv.barcode}>{item.reason} · {item.seller_name || 'System'}</Text>
        </View>
        <View style={inv.right}>
          <Text style={[inv.delta, { color: isIn ? Colors.success : Colors.error }]}>{isIn ? '+' : ''}{item.delta}</Text>
          <Text style={inv.threshold}>{new Date(item.created_at).toLocaleDateString('en-IN')}</Text>
        </View>
      </View>
    );
  };

  return (
    <SafeAreaView style={inv.safe} edges={['top']}>
      <View style={inv.header}>
        <Text style={inv.title}>Inventory</Text>
        {products.length > 0 && <View style={inv.alertBadge}><Text style={inv.alertText}>{products.length} low</Text></View>}
      </View>

      <View style={inv.tabs}>
        {[{ key: 'low', label: '⚠ Low Stock' }, { key: 'movements', label: '📋 Movements' }].map(t => (
          <TouchableOpacity key={t.key} style={[inv.tab, tab === t.key && inv.tabActive]} onPress={() => setTab(t.key as any)}>
            <Text style={[inv.tabText, tab === t.key && inv.tabTextActive]}>{t.label}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {loading ? <LoadingOverlay visible message="Loading…" /> : (
        <FlatList
          data={tab === 'low' ? products : movements}
          keyExtractor={(i, idx) => String(i.id || idx)}
          renderItem={tab === 'low' ? ({ item }) => <LowStockCard item={item} /> : ({ item }) => <MovCard item={item} />}
          contentContainerStyle={[inv.list, (tab === 'low' ? products : movements).length === 0 && { flex: 1 }]}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => load(true)} tintColor={Colors.primary} />}
          ListEmptyComponent={tab === 'low'
            ? <EmptyState icon="checkmark-circle-outline" title="All stocked up!" subtitle="No products below threshold" />
            : <EmptyState icon="list-outline" title="No movements" subtitle="Stock changes will appear here" />}
        />
      )}

      {/* Adjust Modal */}
      <Modal visible={adjustModal} transparent animationType="slide">
        <View style={inv.modalBg}>
          <View style={inv.modalBox}>
            <Text style={inv.modalTitle}>Adjust Stock</Text>
            <Text style={inv.modalSub}>{selected?.name}</Text>
            <Text style={inv.modalCurrent}>Current stock: {selected?.stock_qty}</Text>

            <Text style={inv.label}>Change (+add / -remove)</Text>
            <TextInput style={inv.input} value={delta} onChangeText={setDelta} keyboardType="numbers-and-punctuation" placeholder="+10 or -5" placeholderTextColor={Colors.textMuted} />

            <Text style={inv.label}>Reason</Text>
            <View style={inv.reasonRow}>
              {REASONS.map(r => (
                <TouchableOpacity key={r.key} style={[inv.reasonChip, reason === r.key && inv.reasonActive]} onPress={() => setReason(r.key as any)}>
                  <Text style={[inv.reasonText, reason === r.key && inv.reasonTextActive]}>{r.label}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={inv.label}>Note (optional)</Text>
            <TextInput style={inv.input} value={note} onChangeText={setNote} placeholder="Supplier name, ref no…" placeholderTextColor={Colors.textMuted} />

            <View style={inv.modalBtns}>
              <TouchableOpacity style={inv.cancelBtn} onPress={() => setAdjustModal(false)}><Text style={inv.cancelText}>Cancel</Text></TouchableOpacity>
              <TouchableOpacity style={inv.confirmBtn} onPress={handleAdjust} disabled={adjusting}>
                {adjusting ? <Text style={inv.confirmText}>Saving…</Text> : <Text style={inv.confirmText}>Confirm</Text>}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const inv = StyleSheet.create({
  safe:        { flex: 1, backgroundColor: Colors.bg },
  header:      { flexDirection: 'row', alignItems: 'center', gap: Spacing.md, paddingHorizontal: Spacing.lg, paddingVertical: Spacing.md, borderBottomWidth: 1, borderBottomColor: Colors.border },
  title:       { color: Colors.textPrimary, fontSize: FontSizes.xl, fontWeight: '700', flex: 1 },
  alertBadge:  { backgroundColor: Colors.error, borderRadius: Radius.full, paddingHorizontal: 10, paddingVertical: 3 },
  alertText:   { color: Colors.white, fontSize: FontSizes.xs, fontWeight: '700' },
  tabs:        { flexDirection: 'row', margin: Spacing.lg, marginBottom: 0, backgroundColor: Colors.surface2, borderRadius: Radius.md, padding: 4 },
  tab:         { flex: 1, paddingVertical: 9, alignItems: 'center', borderRadius: Radius.sm },
  tabActive:   { backgroundColor: Colors.primary },
  tabText:     { color: Colors.textMuted, fontSize: FontSizes.sm, fontWeight: '600' },
  tabTextActive:{ color: Colors.white },
  list:        { padding: Spacing.lg, gap: Spacing.sm },
  card:        { backgroundColor: Colors.surface, borderRadius: Radius.lg, padding: Spacing.lg, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm },
  row:         { flexDirection: 'row' },
  flex:        { flex: 1, marginRight: Spacing.sm },
  right:       { alignItems: 'flex-end', gap: 8 },
  name:        { color: Colors.textPrimary, fontSize: FontSizes.md, fontWeight: '700' },
  barcode:     { color: Colors.textMuted, fontSize: FontSizes.xs, marginTop: 2 },
  badge:       { borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 2, borderWidth: 1 },
  badgeText:   { fontSize: FontSizes.xs, fontWeight: '700' },
  threshold:   { color: Colors.textMuted, fontSize: FontSizes.xs },
  price:       { color: Colors.secondary, fontSize: FontSizes.lg, fontWeight: '800' },
  adjustBtn:   { flexDirection: 'row', alignItems: 'center', gap: 4, backgroundColor: Colors.primary, borderRadius: Radius.sm, paddingHorizontal: 10, paddingVertical: 6 },
  adjustText:  { color: Colors.white, fontSize: FontSizes.xs, fontWeight: '700' },
  movCard:     { flexDirection: 'row', alignItems: 'center', gap: Spacing.md, backgroundColor: Colors.surface, borderRadius: Radius.md, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border },
  movIcon:     { width: 36, height: 36, borderRadius: 18, justifyContent: 'center', alignItems: 'center' },
  delta:       { fontSize: FontSizes.lg, fontWeight: '800' },
  modalBg:     { flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'flex-end' },
  modalBox:    { backgroundColor: Colors.surface, borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: Spacing.xxl, gap: Spacing.md },
  modalTitle:  { color: Colors.textPrimary, fontSize: FontSizes.xl, fontWeight: '700' },
  modalSub:    { color: Colors.textSecondary, fontSize: FontSizes.sm },
  modalCurrent:{ color: Colors.primary, fontSize: FontSizes.md, fontWeight: '600' },
  label:       { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600' },
  input:       { backgroundColor: Colors.surface2, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border, color: Colors.textPrimary, paddingHorizontal: Spacing.md, paddingVertical: 12, fontSize: FontSizes.md },
  reasonRow:   { flexDirection: 'row', gap: Spacing.sm },
  reasonChip:  { flex: 1, paddingVertical: 8, borderRadius: Radius.md, backgroundColor: Colors.surface2, borderWidth: 1, borderColor: Colors.border, alignItems: 'center' },
  reasonActive:{ borderColor: Colors.primary, backgroundColor: Colors.primary + '22' },
  reasonText:  { color: Colors.textSecondary, fontSize: FontSizes.xs, fontWeight: '600' },
  reasonTextActive: { color: Colors.primary },
  modalBtns:   { flexDirection: 'row', gap: Spacing.md },
  cancelBtn:   { flex: 1, paddingVertical: 14, borderRadius: Radius.md, backgroundColor: Colors.surface2, alignItems: 'center' },
  cancelText:  { color: Colors.textSecondary, fontSize: FontSizes.md, fontWeight: '600' },
  confirmBtn:  { flex: 1, paddingVertical: 14, borderRadius: Radius.md, backgroundColor: Colors.primary, alignItems: 'center' },
  confirmText: { color: Colors.white, fontSize: FontSizes.md, fontWeight: '700' },
});
