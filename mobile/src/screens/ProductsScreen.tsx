import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, TextInput, RefreshControl, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { getProducts, deleteProduct } from '../api/products';
import { useAuthStore } from '../store/authStore';
import EmptyState from '../components/EmptyState';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { formatCurrency, stockStatus } from '../utils/formatters';
import { RootStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<RootStackParamList>;

const stockColor = { ok: Colors.success, low: Colors.warning, out: Colors.error };

export default function ProductsScreen() {
  const navigation = useNavigation<Nav>();
  const { seller } = useAuthStore();
  const isManager = seller?.role === 'admin' || seller?.role === 'manager';
  const [products, setProducts] = useState<any[]>([]);
  const [search, setSearch]     = useState('');
  const [loading, setLoading]   = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async (s = search, refresh = false) => {
    if (refresh) setRefreshing(true); else setLoading(true);
    try {
      const { products: p } = await getProducts({ search: s, limit: 100 });
      setProducts(p);
    } finally { setLoading(false); setRefreshing(false); }
  }, [search]);

  useEffect(() => { load(); }, []);

  const handleSearch = (text: string) => { setSearch(text); load(text); };

  const handleDelete = (product: any) => {
    Alert.alert('Delete Product', `Delete "${product.name}"?`, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete', style: 'destructive', onPress: async () => {
        try {
          await deleteProduct(product.id);
          setProducts(prev => prev.filter(p => p.id !== product.id));
        } catch (e: any) { Alert.alert('Error', e.message); }
      }},
    ]);
  };

  const ProductCard = ({ item }: { item: any }) => {
    const status = stockStatus(item.stock_qty, item.low_stock_threshold);
    return (
      <View style={ps.card}>
        <View style={ps.row}>
          <View style={ps.flex}>
            <Text style={ps.name} numberOfLines={1}>{item.name}</Text>
            <Text style={ps.barcode}>📦 {item.barcode}</Text>
            <Text style={ps.sub}>{item.category_name || 'Uncategorized'}</Text>
          </View>
          <View style={ps.right}>
            <Text style={ps.price}>{formatCurrency(item.selling_price)}</Text>
            <View style={[ps.stockBadge, { borderColor: stockColor[status], backgroundColor: stockColor[status] + '22' }]}>
              <Text style={[ps.stockText, { color: stockColor[status] }]}>
                {status === 'out' ? 'Out of Stock' : `${item.stock_qty} ${item.unit}`}
              </Text>
            </View>
          </View>
        </View>
        {isManager && (
          <View style={ps.actions}>
            <TouchableOpacity style={ps.editBtn} onPress={() => navigation.navigate('AddEditProduct', { productId: item.id })}>
              <Ionicons name="create-outline" size={15} color={Colors.primary} /><Text style={ps.editText}>Edit</Text>
            </TouchableOpacity>
            <TouchableOpacity style={ps.deleteBtn} onPress={() => handleDelete(item)}>
              <Ionicons name="trash-outline" size={15} color={Colors.error} /><Text style={ps.deleteText}>Delete</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>
    );
  };

  return (
    <SafeAreaView style={ps.safe} edges={['top']}>
      <View style={ps.header}>
        <Text style={ps.title}>Products</Text>
        {isManager && (
          <TouchableOpacity style={ps.addBtn} onPress={() => navigation.navigate('AddEditProduct', {})}>
            <Ionicons name="add" size={22} color={Colors.white} />
          </TouchableOpacity>
        )}
      </View>

      <View style={ps.searchBox}>
        <Ionicons name="search-outline" size={18} color={Colors.textMuted} />
        <TextInput
          style={ps.searchInput} value={search} onChangeText={handleSearch}
          placeholder="Search by name or barcode…" placeholderTextColor={Colors.textMuted}
          returnKeyType="search"
        />
        {search.length > 0 && <TouchableOpacity onPress={() => handleSearch('')}><Ionicons name="close-circle" size={18} color={Colors.textMuted} /></TouchableOpacity>}
      </View>

      {loading ? <LoadingOverlay visible message="Loading products…" /> : (
        <FlatList
          data={products} keyExtractor={i => String(i.id)}
          renderItem={({ item }) => <ProductCard item={item} />}
          contentContainerStyle={ps.list}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => load(search, true)} tintColor={Colors.primary} />}
          ListEmptyComponent={<EmptyState icon="cube-outline" title="No products found" subtitle={search ? 'Try a different search term' : 'Add your first product'} />}
        />
      )}
    </SafeAreaView>
  );
}

const ps = StyleSheet.create({
  safe:        { flex: 1, backgroundColor: Colors.bg },
  header:      { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: Spacing.lg, paddingVertical: Spacing.md, borderBottomWidth: 1, borderBottomColor: Colors.border },
  title:       { color: Colors.textPrimary, fontSize: FontSizes.xl, fontWeight: '700' },
  addBtn:      { width: 38, height: 38, borderRadius: 19, backgroundColor: Colors.primary, justifyContent: 'center', alignItems: 'center', ...Shadows.glow },
  searchBox:   { flexDirection: 'row', alignItems: 'center', margin: Spacing.lg, marginBottom: 0, backgroundColor: Colors.surface2, borderRadius: Radius.md, paddingHorizontal: Spacing.md, gap: Spacing.sm, borderWidth: 1, borderColor: Colors.border },
  searchInput: { flex: 1, color: Colors.textPrimary, fontSize: FontSizes.sm, paddingVertical: 12 },
  list:        { padding: Spacing.lg, gap: Spacing.sm, flexGrow: 1 },
  card:        { backgroundColor: Colors.surface, borderRadius: Radius.lg, padding: Spacing.lg, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm },
  row:         { flexDirection: 'row' },
  flex:        { flex: 1, marginRight: Spacing.sm },
  right:       { alignItems: 'flex-end', gap: 6 },
  name:        { color: Colors.textPrimary, fontSize: FontSizes.md, fontWeight: '700' },
  barcode:     { color: Colors.textMuted, fontSize: FontSizes.xs, marginTop: 2 },
  sub:         { color: Colors.textSecondary, fontSize: FontSizes.xs, marginTop: 2 },
  price:       { color: Colors.secondary, fontSize: FontSizes.lg, fontWeight: '800' },
  stockBadge:  { borderRadius: Radius.full, paddingHorizontal: 8, paddingVertical: 2, borderWidth: 1 },
  stockText:   { fontSize: FontSizes.xs, fontWeight: '700' },
  actions:     { flexDirection: 'row', gap: Spacing.sm, marginTop: Spacing.md, paddingTop: Spacing.sm, borderTopWidth: 1, borderTopColor: Colors.border },
  editBtn:     { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5, paddingVertical: 7, borderRadius: Radius.sm, backgroundColor: Colors.primary + '22', borderWidth: 1, borderColor: Colors.primary },
  editText:    { color: Colors.primary, fontSize: FontSizes.sm, fontWeight: '600' },
  deleteBtn:   { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5, paddingVertical: 7, borderRadius: Radius.sm, backgroundColor: Colors.error + '22', borderWidth: 1, borderColor: Colors.error },
  deleteText:  { color: Colors.error, fontSize: FontSizes.sm, fontWeight: '600' },
});
