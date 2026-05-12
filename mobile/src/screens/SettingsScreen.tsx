import React, { useEffect, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  TextInput, Alert, Switch, Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuthStore } from '../store/authStore';
import { useSettingsStore } from '../store/settingsStore';
import { updateSettings, createSeller } from '../api/settings';
import LoadingOverlay from '../components/LoadingOverlay';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';
import { RootStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<RootStackParamList>;

const Field = ({ label, value, onChangeText, placeholder, keyboardType, multiline }: any) => (
  <View style={st.field}>
    <Text style={st.label}>{label}</Text>
    <TextInput
      style={[st.input, multiline && { height: 80, textAlignVertical: 'top' }]}
      value={value} onChangeText={onChangeText}
      placeholder={placeholder || ''} placeholderTextColor={Colors.textMuted}
      keyboardType={keyboardType || 'default'} multiline={multiline}
    />
  </View>
);

export default function SettingsScreen() {
  const navigation = useNavigation<Nav>();
  const { seller, logout } = useAuthStore();
  const { settings, setSettings } = useSettingsStore();
  const isAdmin = seller?.role === 'admin';

  const [shopName, setShopName]       = useState(settings?.shop_name || '');
  const [address, setAddress]         = useState(settings?.shop_address || '');
  const [phone, setPhone]             = useState(settings?.shop_phone || '');
  const [email, setEmail]             = useState(settings?.shop_email || '');
  const [gstin, setGstin]             = useState(settings?.gstin || '');
  const [upiId, setUpiId]             = useState(settings?.upi_id || '');
  const [upiName, setUpiName]         = useState(settings?.upi_name || '');
  const [footer, setFooter]           = useState(settings?.receipt_footer || '');
  const [cgst, setCgst]               = useState(String(settings?.default_cgst ?? 9));
  const [sgst, setSgst]               = useState(String(settings?.default_sgst ?? 9));
  const [saving, setSaving]           = useState(false);

  // New seller form
  const [showNewSeller, setShowNewSeller] = useState(false);
  const [nsName, setNsName]           = useState('');
  const [nsEmail, setNsEmail]         = useState('');
  const [nsPhone, setNsPhone]         = useState('');
  const [nsPass, setNsPass]           = useState('');
  const [nsRole, setNsRole]           = useState<'seller' | 'manager'>('seller');
  const [creatingSeller, setCreatingSeller] = useState(false);

  const handleSaveSettings = async () => {
    if (!shopName.trim()) { Alert.alert('Error', 'Shop name is required'); return; }
    setSaving(true);
    try {
      const updated = await updateSettings({
        shop_name: shopName, shop_address: address, shop_phone: phone,
        shop_email: email, gstin, upi_id: upiId, upi_name: upiName,
        default_cgst: parseFloat(cgst) || 9, default_sgst: parseFloat(sgst) || 9,
        default_igst: 0, receipt_footer: footer,
      });
      setSettings(updated.settings);
      Alert.alert('Saved', 'Settings updated successfully!');
    } catch (e: any) { Alert.alert('Error', e.message); }
    finally { setSaving(false); }
  };

  const handleCreateSeller = async () => {
    if (!nsName || !nsEmail || !nsPass) { Alert.alert('Error', 'Name, email and password are required'); return; }
    setCreatingSeller(true);
    try {
      await createSeller({ name: nsName, email: nsEmail, phone: nsPhone, password: nsPass, role: nsRole });
      Alert.alert('Created', `${nsName} added as ${nsRole}`);
      setNsName(''); setNsEmail(''); setNsPhone(''); setNsPass('');
      setShowNewSeller(false);
    } catch (e: any) { Alert.alert('Error', e.message); }
    finally { setCreatingSeller(false); }
  };

  const Section = ({ title }: { title: string }) => (
    <View style={st.sectionHeader}>
      <Text style={st.sectionTitle}>{title}</Text>
    </View>
  );

  return (
    <SafeAreaView style={st.safe} edges={['top']}>
      <LoadingOverlay visible={saving} message="Saving…" />
      <View style={st.header}>
        <Text style={st.title}>Settings</Text>
        <View style={st.roleBadge}>
          <Text style={st.roleText}>{seller?.role?.toUpperCase()}</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={st.scroll} keyboardShouldPersistTaps="handled">
        {/* Profile */}
        <Section title="My Account" />
        <View style={st.profileCard}>
          <View style={st.avatar}>
            <Text style={st.avatarText}>{seller?.name?.charAt(0).toUpperCase()}</Text>
          </View>
          <View style={st.flex}>
            <Text style={st.profileName}>{seller?.name}</Text>
            <Text style={st.profileEmail}>{seller?.email}</Text>
            <Text style={st.profileRole}>{seller?.role}</Text>
          </View>
        </View>

        {/* Shop branding (admin only) */}
        {isAdmin && (
          <>
            <Section title="Shop Branding" />
            <View style={st.card}>
              <Field label="Shop Name *" value={shopName} onChangeText={setShopName} placeholder="My Store" />
              <Field label="Address" value={address} onChangeText={setAddress} placeholder="123 Main St, City" multiline />
              <Field label="Phone" value={phone} onChangeText={setPhone} placeholder="9876543210" keyboardType="phone-pad" />
              <Field label="Email" value={email} onChangeText={setEmail} placeholder="shop@email.com" keyboardType="email-address" />
              <Field label="GSTIN" value={gstin} onChangeText={setGstin} placeholder="22AAAAA0000A1Z5" />
              <Field label="Receipt Footer" value={footer} onChangeText={setFooter} placeholder="Thank you for shopping with us!" multiline />
            </View>

            <Section title="UPI Payment (Receipt QR)" />
            <View style={st.card}>
              <View style={st.upiInfo}>
                <Ionicons name="information-circle-outline" size={16} color={Colors.info} />
                <Text style={st.upiInfoText}>Customer can scan QR on receipt to pay directly via any UPI app</Text>
              </View>
              <Field label="UPI ID (VPA)" value={upiId} onChangeText={setUpiId} placeholder="yourshop@upi" keyboardType="email-address" />
              <Field label="Payee Name" value={upiName} onChangeText={setUpiName} placeholder="Your Shop Name" />
            </View>

            <Section title="Default GST Rates" />
            <View style={st.card}>
              <View style={st.gstRow}>
                <View style={st.gstField}>
                  <Text style={st.label}>CGST %</Text>
                  <TextInput style={st.input} value={cgst} onChangeText={setCgst} keyboardType="decimal-pad" />
                </View>
                <View style={st.gstField}>
                  <Text style={st.label}>SGST %</Text>
                  <TextInput style={st.input} value={sgst} onChangeText={setSgst} keyboardType="decimal-pad" />
                </View>
              </View>
              <Text style={st.gstNote}>Combined GST = CGST + SGST = {(parseFloat(cgst || '0') + parseFloat(sgst || '0')).toFixed(1)}%</Text>
            </View>

            <TouchableOpacity style={st.saveBtn} onPress={handleSaveSettings} activeOpacity={0.85}>
              <Ionicons name="save-outline" size={20} color={Colors.white} />
              <Text style={st.saveBtnText}>Save Settings</Text>
            </TouchableOpacity>

            {/* Staff Management */}
            <Section title="Staff Management" />
            <View style={st.card}>
              <TouchableOpacity style={st.manageSellersBtn} onPress={() => navigation.navigate('AuditLogs')}>
                <Ionicons name="list-outline" size={18} color={Colors.primary} />
                <Text style={st.manageText}>View Audit Logs</Text>
                <Ionicons name="chevron-forward" size={16} color={Colors.textMuted} />
              </TouchableOpacity>

              <TouchableOpacity style={[st.manageSellersBtn, { marginTop: Spacing.sm }]} onPress={() => setShowNewSeller(!showNewSeller)}>
                <Ionicons name="person-add-outline" size={18} color={Colors.secondary} />
                <Text style={[st.manageText, { color: Colors.secondary }]}>Add New Staff</Text>
                <Ionicons name={showNewSeller ? 'chevron-up' : 'chevron-down'} size={16} color={Colors.textMuted} />
              </TouchableOpacity>

              {showNewSeller && (
                <View style={st.newSellerForm}>
                  <Field label="Full Name" value={nsName} onChangeText={setNsName} placeholder="Staff Name" />
                  <Field label="Email" value={nsEmail} onChangeText={setNsEmail} placeholder="staff@shop.com" keyboardType="email-address" />
                  <Field label="Phone" value={nsPhone} onChangeText={setNsPhone} placeholder="9876543210" keyboardType="phone-pad" />
                  <Field label="Password" value={nsPass} onChangeText={setNsPass} placeholder="Min 8 chars" />
                  <Text style={st.label}>Role</Text>
                  <View style={st.roleRow}>
                    {(['seller', 'manager'] as const).map(r => (
                      <TouchableOpacity key={r} style={[st.roleChip, nsRole === r && st.roleChipActive]} onPress={() => setNsRole(r)}>
                        <Text style={[st.roleChipText, nsRole === r && st.roleChipTextActive]}>{r.charAt(0).toUpperCase() + r.slice(1)}</Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                  <TouchableOpacity style={st.createBtn} onPress={handleCreateSeller} disabled={creatingSeller}>
                    <Text style={st.createBtnText}>{creatingSeller ? 'Creating…' : 'Create Account'}</Text>
                  </TouchableOpacity>
                </View>
              )}
            </View>
          </>
        )}

        {/* Logout */}
        <Section title="Session" />
        <TouchableOpacity style={st.logoutBtn} onPress={() => Alert.alert('Logout', 'Are you sure?', [{ text: 'Cancel', style: 'cancel' }, { text: 'Logout', style: 'destructive', onPress: logout }])}>
          <Ionicons name="log-out-outline" size={20} color={Colors.error} />
          <Text style={st.logoutText}>Logout</Text>
        </TouchableOpacity>

        <Text style={st.version}>QEXmanage POS v1.0.0</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const st = StyleSheet.create({
  safe:         { flex: 1, backgroundColor: Colors.bg },
  header:       { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: Spacing.lg, paddingVertical: Spacing.md, borderBottomWidth: 1, borderBottomColor: Colors.border },
  title:        { color: Colors.textPrimary, fontSize: FontSizes.xl, fontWeight: '700' },
  roleBadge:    { backgroundColor: Colors.primary + '22', borderRadius: Radius.full, paddingHorizontal: 10, paddingVertical: 3, borderWidth: 1, borderColor: Colors.primary },
  roleText:     { color: Colors.primary, fontSize: FontSizes.xs, fontWeight: '700' },
  scroll:       { padding: Spacing.lg, paddingBottom: 40, gap: Spacing.sm },
  profileCard:  { flexDirection: 'row', alignItems: 'center', gap: Spacing.lg, backgroundColor: Colors.surface, borderRadius: Radius.xl, padding: Spacing.xl, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm },
  avatar:       { width: 56, height: 56, borderRadius: 28, backgroundColor: Colors.primary, justifyContent: 'center', alignItems: 'center', ...Shadows.glow },
  avatarText:   { color: Colors.white, fontSize: FontSizes.xxl, fontWeight: '800' },
  flex:         { flex: 1 },
  profileName:  { color: Colors.textPrimary, fontSize: FontSizes.lg, fontWeight: '700' },
  profileEmail: { color: Colors.textSecondary, fontSize: FontSizes.sm },
  profileRole:  { color: Colors.primary, fontSize: FontSizes.xs, fontWeight: '600', marginTop: 2 },
  sectionHeader:{ marginTop: Spacing.md },
  sectionTitle: { color: Colors.textMuted, fontSize: FontSizes.xs, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 1, marginBottom: Spacing.sm },
  card:         { backgroundColor: Colors.surface, borderRadius: Radius.xl, padding: Spacing.xl, borderWidth: 1, borderColor: Colors.border, ...Shadows.sm, gap: Spacing.sm },
  field:        { gap: 5 },
  label:        { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600' },
  input:        { backgroundColor: Colors.surface2, borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.border, color: Colors.textPrimary, paddingHorizontal: Spacing.md, paddingVertical: 11, fontSize: FontSizes.sm },
  upiInfo:      { flexDirection: 'row', alignItems: 'flex-start', gap: 8, backgroundColor: Colors.info + '11', borderRadius: Radius.md, padding: Spacing.md },
  upiInfoText:  { color: Colors.info, fontSize: FontSizes.xs, flex: 1 },
  gstRow:       { flexDirection: 'row', gap: Spacing.md },
  gstField:     { flex: 1, gap: 5 },
  gstNote:      { color: Colors.textMuted, fontSize: FontSizes.xs },
  saveBtn:      { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10, backgroundColor: Colors.primary, borderRadius: Radius.lg, paddingVertical: 15, ...Shadows.glow },
  saveBtnText:  { color: Colors.white, fontSize: FontSizes.md, fontWeight: '700' },
  manageSellersBtn: { flexDirection: 'row', alignItems: 'center', gap: Spacing.sm, paddingVertical: Spacing.sm },
  manageText:   { flex: 1, color: Colors.primary, fontSize: FontSizes.md, fontWeight: '600' },
  newSellerForm:{ marginTop: Spacing.md, gap: Spacing.sm, paddingTop: Spacing.md, borderTopWidth: 1, borderTopColor: Colors.border },
  roleRow:      { flexDirection: 'row', gap: Spacing.sm },
  roleChip:     { flex: 1, paddingVertical: 9, borderRadius: Radius.md, backgroundColor: Colors.surface2, borderWidth: 1, borderColor: Colors.border, alignItems: 'center' },
  roleChipActive:{ borderColor: Colors.primary, backgroundColor: Colors.primary + '22' },
  roleChipText: { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600' },
  roleChipTextActive: { color: Colors.primary },
  createBtn:    { backgroundColor: Colors.secondary, borderRadius: Radius.md, paddingVertical: 13, alignItems: 'center', marginTop: Spacing.sm },
  createBtnText:{ color: Colors.textInverse, fontSize: FontSizes.md, fontWeight: '700' },
  logoutBtn:    { flexDirection: 'row', alignItems: 'center', gap: Spacing.md, backgroundColor: Colors.error + '15', borderRadius: Radius.xl, padding: Spacing.xl, borderWidth: 1, borderColor: Colors.error + '40' },
  logoutText:   { color: Colors.error, fontSize: FontSizes.md, fontWeight: '700' },
  version:      { color: Colors.textMuted, fontSize: FontSizes.xs, textAlign: 'center', marginTop: Spacing.md },
});
