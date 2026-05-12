import React, { useEffect, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  TextInput, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRoute, useNavigation, RouteProp } from '@react-navigation/native';
import { getProduct, createProduct, updateProduct, getCategories } from '../api/products';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { RootStackParamList } from '../navigation/AppNavigator';

type RouteP = RouteProp<RootStackParamList, 'AddEditProduct'>;

const Field = ({ label, value, onChangeText, placeholder, keyboardType, multiline, required }: any) => (
  <View style={ae.field}>
    <Text style={ae.label}>{label}{required ? <Text style={{ color: Colors.error }}> *</Text> : null}</Text>
    <TextInput
      style={[ae.input, multiline && { height: 72, textAlignVertical: 'top' }]}
      value={value} onChangeText={onChangeText}
      placeholder={placeholder || ''} placeholderTextColor={Colors.textMuted}
      keyboardType={keyboardType || 'default'} multiline={multiline}
    />
  </View>
);

export default function AddEditProductScreen() {
  const route      = useRoute<RouteP>();
  const navigation = useNavigation<any>();
  const isEdit     = !!route.params?.productId;

  const [loading, setSaving] = useState(false);
  const [fetching, setFetching] = useState(isEdit);
  const [categories, setCategories] = useState<any[]>([]);

  const [barcode, setBarcode]     = useState('');
  const [sku, setSku]             = useState('');
  const [name, setName]           = useState('');
  const [desc, setDesc]           = useState('');
  const [categoryId, setCategoryId] = useState<number | null>(null);
  const [hsn, setHsn]             = useState('');
  const [unit, setUnit]           = useState('pcs');
  const [purchasePrice, setPurchasePrice] = useState('');
  const [sellingPrice, setSellingPrice]   = useState('');
  const [mrp, setMrp]             = useState('');
  const [cgst, setCgst]           = useState('9');
  const [sgst, setSgst]           = useState('9');
  const [igst, setIgst]           = useState('0');
  const [stock, setStock]         = useState('0');
  const [lowStock, setLowStock]   = useState('10');

  useEffect(() => {
    getCategories().then(r => setCategories(r.categories || []));
    if (isEdit && route.params?.productId) {
      getProduct(route.params.productId).then(r => {
        const p = r.product;
        setBarcode(p.barcode); setSku(p.sku || ''); setName(p.name); setDesc(p.description || '');
        setCategoryId(p.category_id); setHsn(p.hsn_code || ''); setUnit(p.unit);
        setPurchasePrice(String(p.purchase_price)); setSellingPrice(String(p.selling_price));
        setMrp(p.mrp ? String(p.mrp) : ''); setCgst(String(p.cgst_rate)); setSgst(String(p.sgst_rate));
        setIgst(String(p.igst_rate)); setStock(String(p.stock_qty)); setLowStock(String(p.low_stock_threshold));
        setFetching(false);
      }).catch(() => setFetching(false));
    }
  }, []);

  const handleSave = async () => {
    if (!barcode.trim() || !name.trim() || !sellingPrice) {
      Alert.alert('Error', 'Barcode, name and selling price are required'); return;
    }
    setSaving(true);
    const payload = {
      barcode: barcode.trim(), sku: sku.trim() || undefined,
      name: name.trim(), description: desc.trim() || undefined,
      category_id: categoryId || undefined, hsn_code: hsn.trim() || undefined,
      unit: unit || 'pcs', purchase_price: parseFloat(purchasePrice) || 0,
      selling_price: parseFloat(sellingPrice),
      mrp: mrp ? parseFloat(mrp) : undefined,
      cgst_rate: parseFloat(cgst) || 0, sgst_rate: parseFloat(sgst) || 0,
      igst_rate: parseFloat(igst) || 0, stock_qty: parseInt(stock) || 0,
      low_stock_threshold: parseInt(lowStock) || 10,
    };
    try {
      if (isEdit && route.params?.productId) { await updateProduct(route.params.productId, payload); }
      else { await createProduct(payload); }
      Alert.alert('Saved', `Product ${isEdit ? 'updated' : 'created'} successfully`);
      navigation.goBack();
    } catch (e: any) { Alert.alert('Error', e.message); }
    finally { setSaving(false); }
  };

  if (fetching) return <LoadingOverlay visible message="Loading product…" />;

  const UNITS = ['pcs', 'kg', 'g', 'L', 'mL', 'pack', 'box', 'dozen'];

  return (
    <SafeAreaView style={ae.safe} edges={['bottom']}>
      <LoadingOverlay visible={loading} message={isEdit ? 'Updating…' : 'Creating…'} />
      <ScrollView contentContainerStyle={ae.scroll} keyboardShouldPersistTaps="handled">
        <Text style={ae.sectionTitle}>Basic Info</Text>
        <View style={ae.card}>
          <Field label="Barcode" value={barcode} onChangeText={setBarcode} placeholder="8901234567890" required />
          <Field label="SKU (optional)" value={sku} onChangeText={setSku} placeholder="SKU-001" />
          <Field label="Product Name" value={name} onChangeText={setName} placeholder="Product name" required />
          <Field label="Description" value={desc} onChangeText={setDesc} placeholder="Brief description" multiline />
          <Field label="HSN Code" value={hsn} onChangeText={setHsn} placeholder="1234" keyboardType="numeric" />
        </View>

        <Text style={ae.sectionTitle}>Pricing</Text>
        <View style={ae.card}>
          <View style={ae.row}>
            <View style={ae.flex}><Field label="Purchase Price" value={purchasePrice} onChangeText={setPurchasePrice} keyboardType="decimal-pad" /></View>
            <View style={ae.flex}><Field label="Selling Price" value={sellingPrice} onChangeText={setSellingPrice} keyboardType="decimal-pad" required /></View>
          </View>
          <Field label="MRP (optional)" value={mrp} onChangeText={setMrp} keyboardType="decimal-pad" />
        </View>

        <Text style={ae.sectionTitle}>GST</Text>
        <View style={ae.card}>
          <View style={ae.row}>
            <View style={ae.flex}><Field label="CGST %" value={cgst} onChangeText={setCgst} keyboardType="decimal-pad" /></View>
            <View style={ae.flex}><Field label="SGST %" value={sgst} onChangeText={setSgst} keyboardType="decimal-pad" /></View>
            <View style={ae.flex}><Field label="IGST %" value={igst} onChangeText={setIgst} keyboardType="decimal-pad" /></View>
          </View>
          <Text style={ae.hint}>Total GST = {((parseFloat(cgst) || 0) + (parseFloat(sgst) || 0)).toFixed(1)}%</Text>
        </View>

        <Text style={ae.sectionTitle}>Stock & Unit</Text>
        <View style={ae.card}>
          <View style={ae.row}>
            <View style={ae.flex}><Field label="Initial Stock" value={stock} onChangeText={setStock} keyboardType="numeric" /></View>
            <View style={ae.flex}><Field label="Low Stock Alert" value={lowStock} onChangeText={setLowStock} keyboardType="numeric" /></View>
          </View>
          <Text style={ae.label}>Unit</Text>
          <View style={ae.chipRow}>
            {UNITS.map(u => (
              <TouchableOpacity key={u} style={[ae.chip, unit === u && ae.chipActive]} onPress={() => setUnit(u)}>
                <Text style={[ae.chipText, unit === u && ae.chipTextActive]}>{u}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <Text style={ae.sectionTitle}>Category</Text>
        <View style={ae.card}>
          <View style={ae.chipRow}>
            <TouchableOpacity style={[ae.chip, categoryId === null && ae.chipActive]} onPress={() => setCategoryId(null)}>
              <Text style={[ae.chipText, categoryId === null && ae.chipTextActive]}>None</Text>
            </TouchableOpacity>
            {categories.map((c: any) => (
              <TouchableOpacity key={c.id} style={[ae.chip, categoryId === c.id && ae.chipActive]} onPress={() => setCategoryId(c.id)}>
                <Text style={[ae.chipText, categoryId === c.id && ae.chipTextActive]}>{c.name}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <TouchableOpacity style={ae.saveBtn} onPress={handleSave} activeOpacity={0.85}>
          <Text style={ae.saveBtnText}>{isEdit ? 'Update Product' : 'Create Product'}</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const ae = StyleSheet.create({
  safe:         { flex: 1, backgroundColor: Colors.bg },
  scroll:       { padding: Spacing.lg, paddingBottom: 40, gap: Spacing.sm },
  sectionTitle: { color: Colors.textMuted, fontSize: FontSizes.xs, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1, marginTop: Spacing.md, marginBottom: Spacing.sm },
  card:         { backgroundColor: Colors.surface, borderRadius: Radius.xl, padding: Spacing.xl, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm, gap: Spacing.md },
  row:          { flexDirection: 'row', gap: Spacing.md },
  flex:         { flex: 1 },
  field:        { gap: 5 },
  label:        { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600', marginBottom: 4 },
  input:        { backgroundColor: Colors.surface2, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border, color: Colors.textPrimary, paddingHorizontal: Spacing.md, paddingVertical: 11, fontSize: FontSizes.sm },
  hint:         { color: Colors.textMuted, fontSize: FontSizes.xs },
  chipRow:      { flexDirection: 'row', flexWrap: 'wrap', gap: Spacing.sm },
  chip:         { paddingVertical: 6, paddingHorizontal: 12, borderRadius: Radius.full, backgroundColor: Colors.surface2, borderWidth: 1, borderColor: Colors.border },
  chipActive:   { borderColor: Colors.primary, backgroundColor: Colors.primary + '22' },
  chipText:     { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600' },
  chipTextActive:{ color: Colors.primary },
  saveBtn:      { backgroundColor: Colors.primary, borderRadius: Radius.lg, paddingVertical: 16, alignItems: 'center', marginTop: Spacing.md, ...Shadows.glow },
  saveBtnText:  { color: Colors.white, fontSize: FontSizes.lg, fontWeight: '700' },
});
