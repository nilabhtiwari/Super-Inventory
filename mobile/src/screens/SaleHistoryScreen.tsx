import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, RefreshControl } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { getSales } from '../api/sales';
import EmptyState from '../components/EmptyState';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { formatCurrency, formatDate, paymentLabel } from '../utils/formatters';
import { RootStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export default function SaleHistoryScreen() {
  const navigation = useNavigation<Nav>();
  const [sales, setSales]       = useState<any[]>([]);
  const [summary, setSummary]   = useState<any>(null);
  const [loading, setLoading]   = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [page, setPage]         = useState(1);
  const [total, setTotal]       = useState(0);
  const LIMIT = 20;

  const load = useCallback(async (p = 1, refresh = false) => {
    if (refresh) setRefreshing(true); else if (p === 1) setLoading(true);
    try {
      const data = await getSales({ page: p, limit: LIMIT });
      setSales(prev => p === 1 ? data.sales : [...prev, ...data.sales]);
      setTotal(data.total);
      setSummary(data.today_summary);
      setPage(p);
    } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { load(1); }, []);

  const loadMore = () => { if (sales.length < total) load(page + 1); };

  const payColor: Record<string, string> = {
    cash: Colors.success, upi: Colors.primary, card: Colors.info, mixed: Colors.warning,
  };

  const SaleCard = ({ item }: { item: any }) => (
    <TouchableOpacity style={sh.card} onPress={() => navigation.navigate('Receipt', { saleId: item.id })} activeOpacity={0.8}>
      <View style={sh.row}>
        <View style={sh.flex}>
          <Text style={sh.invoice}>{item.invoice_no}</Text>
          <Text style={sh.date}>{formatDate(item.created_at)}</Text>
          {item.seller_name && <Text style={sh.seller}>by {item.seller_name}</Text>}
        </View>
        <View style={sh.right}>
          <Text style={sh.amount}>{formatCurrency(item.grand_total)}</Text>
          <View style={[sh.payBadge, { backgroundColor: payColor[item.payment_method] + '22', borderColor: payColor[item.payment_method] }]}>
            <Text style={[sh.payText, { color: payColor[item.payment_method] }]}>{paymentLabel[item.payment_method]}</Text>
          </View>
        </View>
      </View>
      <Ionicons name="chevron-forward" size={14} color={Colors.textMuted} style={sh.chevron} />
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={sh.safe} edges={['top']}>
      <View style={sh.header}>
        <Text style={sh.title}>Sale History</Text>
        <Text style={sh.count}>{total} total</Text>
      </View>

      {summary && (
        <View style={sh.summaryRow}>
          <View style={sh.summaryCard}>
            <Text style={sh.summaryLabel}>Today's Sales</Text>
            <Text style={sh.summaryVal}>{summary.total_sales}</Text>
          </View>
          <View style={sh.summaryCard}>
            <Text style={sh.summaryLabel}>Today's Revenue</Text>
            <Text style={sh.summaryVal}>{formatCurrency(summary.total_revenue)}</Text>
          </View>
          <View style={sh.summaryCard}>
            <Text style={sh.summaryLabel}>Today's Tax</Text>
            <Text style={sh.summaryVal}>{formatCurrency(summary.total_tax)}</Text>
          </View>
        </View>
      )}

      {loading ? <LoadingOverlay visible message="Loading…" /> : (
        <FlatList
          data={sales} keyExtractor={i => String(i.id)}
          renderItem={({ item }) => <SaleCard item={item} />}
          contentContainerStyle={sh.list}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => load(1, true)} tintColor={Colors.primary} />}
          onEndReached={loadMore} onEndReachedThreshold={0.3}
          ListEmptyComponent={<EmptyState icon="receipt-outline" title="No sales yet" subtitle="Complete your first sale to see history" />}
        />
      )}
    </SafeAreaView>
  );
}

const sh = StyleSheet.create({
  safe:        { flex: 1, backgroundColor: Colors.bg },
  header:      { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: Spacing.lg, paddingVertical: Spacing.md, borderBottomWidth: 1, borderBottomColor: Colors.border },
  title:       { color: Colors.textPrimary, fontSize: FontSizes.xl, fontWeight: '700' },
  count:       { color: Colors.textMuted, fontSize: FontSizes.sm },
  summaryRow:  { flexDirection: 'row', gap: Spacing.sm, padding: Spacing.lg, paddingBottom: 0 },
  summaryCard: { flex: 1, backgroundColor: Colors.surface2, borderRadius: Radius.md, padding: Spacing.md, alignItems: 'center' },
  summaryLabel:{ color: Colors.textMuted, fontSize: FontSizes.xs, marginBottom: 4 },
  summaryVal:  { color: Colors.secondary, fontSize: FontSizes.md, fontWeight: '700' },
  list:        { padding: Spacing.lg, gap: Spacing.sm, flexGrow: 1 },
  card:        { backgroundColor: Colors.surface, borderRadius: Radius.lg, padding: Spacing.lg, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm },
  row:         { flexDirection: 'row', alignItems: 'flex-start' },
  flex:        { flex: 1 },
  right:       { alignItems: 'flex-end', gap: 6 },
  invoice:     { color: Colors.textPrimary, fontSize: FontSizes.md, fontWeight: '700' },
  date:        { color: Colors.textMuted, fontSize: FontSizes.xs, marginTop: 2 },
  seller:      { color: Colors.textMuted, fontSize: FontSizes.xs },
  amount:      { color: Colors.secondary, fontSize: FontSizes.lg, fontWeight: '800' },
  payBadge:    { borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 2, borderWidth: 1 },
  payText:     { fontSize: FontSizes.xs, fontWeight: '700' },
  chevron:     { position: 'absolute', right: 0, top: '50%' },
});
