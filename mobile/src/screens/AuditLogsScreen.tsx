import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, StyleSheet, RefreshControl, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { getAuditLogs } from '../api/settings';
import EmptyState from '../components/EmptyState';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius } from '../theme';
import { formatDate } from '../utils/formatters';

const ACTION_COLORS: Record<string, string> = {
  LOGIN: Colors.success, LOGOUT: Colors.info, SALE_CREATE: Colors.secondary,
  PRODUCT_CREATE: Colors.primary, PRODUCT_UPDATE: Colors.warning,
  PRODUCT_DELETE: Colors.error, STOCK_ADJUST: Colors.accent,
  SETTINGS_UPDATE: Colors.info, SELLER_CREATE: Colors.primary, LOGIN_FAILED: Colors.error,
};

export default function AuditLogsScreen() {
  const [logs, setLogs]         = useState<any[]>([]);
  const [loading, setLoading]   = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [page, setPage]         = useState(1);
  const [hasMore, setHasMore]   = useState(true);

  const load = async (p = 1, refresh = false) => {
    if (refresh) setRefreshing(true); else if (p === 1) setLoading(true);
    try {
      const { logs: newLogs } = await getAuditLogs({ page: p, limit: 50 });
      setLogs(prev => p === 1 ? newLogs : [...prev, ...newLogs]);
      setHasMore(newLogs.length === 50);
      setPage(p);
    } finally { setLoading(false); setRefreshing(false); }
  };

  useEffect(() => { load(1); }, []);

  const LogCard = ({ item }: { item: any }) => {
    const color = ACTION_COLORS[item.action] || Colors.textMuted;
    return (
      <View style={al.card}>
        <View style={[al.dot, { backgroundColor: color }]} />
        <View style={al.flex}>
          <View style={al.row}>
            <View style={[al.badge, { backgroundColor: color + '22', borderColor: color }]}>
              <Text style={[al.badgeText, { color }]}>{item.action.replace(/_/g, ' ')}</Text>
            </View>
            <Text style={al.date}>{formatDate(item.created_at)}</Text>
          </View>
          {item.seller_name && <Text style={al.sub}>👤 {item.seller_name}</Text>}
          {item.entity && <Text style={al.sub}>{item.entity}{item.entity_id ? ` #${item.entity_id}` : ''}</Text>}
          {item.ip_address && <Text style={al.ip}>IP: {item.ip_address}</Text>}
        </View>
      </View>
    );
  };

  return (
    <SafeAreaView style={al.safe} edges={['bottom']}>
      <View style={al.toolbar}>
        <Text style={al.count}>{logs.length} entries</Text>
        <TouchableOpacity onPress={() => load(1, true)} style={{ padding: Spacing.sm }}>
          <Ionicons name="refresh-outline" size={18} color={Colors.primary} />
        </TouchableOpacity>
      </View>
      {loading ? <LoadingOverlay visible message="Loading logs…" /> : (
        <FlatList
          data={logs} keyExtractor={(item, idx) => String(item.id ?? idx)}
          renderItem={({ item }) => <LogCard item={item} />}
          contentContainerStyle={[al.list, logs.length === 0 && { flex: 1 }]}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => load(1, true)} tintColor={Colors.primary} />}
          onEndReached={() => { if (hasMore) load(page + 1); }}
          onEndReachedThreshold={0.3}
          ListEmptyComponent={<EmptyState icon="list-outline" title="No audit logs" subtitle="Actions will be recorded here" />}
        />
      )}
    </SafeAreaView>
  );
}

const al = StyleSheet.create({
  safe:      { flex: 1, backgroundColor: Colors.bg },
  toolbar:   { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: Spacing.lg, paddingVertical: Spacing.sm, borderBottomWidth: 1, borderBottomColor: Colors.border },
  count:     { color: Colors.textMuted, fontSize: FontSizes.sm },
  list:      { padding: Spacing.lg, gap: Spacing.sm },
  card:      { flexDirection: 'row', gap: Spacing.md, backgroundColor: Colors.surface, borderRadius: Radius.lg, padding: Spacing.md, borderWidth: 1, borderColor: Colors.border },
  dot:       { width: 8, height: 8, borderRadius: 4, marginTop: 6, flexShrink: 0 },
  flex:      { flex: 1, gap: 3 },
  row:       { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm, flexWrap: 'wrap' },
  badge:     { borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 2, borderWidth: 1 },
  badgeText: { fontSize: FontSizes.xs, fontWeight: '700' },
  date:      { color: Colors.textMuted, fontSize: FontSizes.xs },
  sub:       { color: Colors.textSecondary, fontSize: FontSizes.xs },
  ip:        { color: Colors.textMuted, fontSize: FontSizes.xs },
});
