import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { View, ActivityIndicator, StyleSheet } from 'react-native';

import { useAuthStore } from '../store/authStore';
import { useSettingsStore } from '../store/settingsStore';
import { Colors } from '../theme';

import LoginScreen from '../screens/LoginScreen';
import POSScreen from '../screens/POSScreen';
import SaleHistoryScreen from '../screens/SaleHistoryScreen';
import ProductsScreen from '../screens/ProductsScreen';
import InventoryScreen from '../screens/InventoryScreen';
import SettingsScreen from '../screens/SettingsScreen';
import ReceiptScreen from '../screens/ReceiptScreen';
import AddEditProductScreen from '../screens/AddEditProductScreen';
import AuditLogsScreen from '../screens/AuditLogsScreen';

export type RootStackParamList = {
  Login: undefined;
  Main: undefined;
  Receipt: { saleId: number };
  AddEditProduct: { productId?: number };
  AuditLogs: undefined;
};

export type TabParamList = {
  POS: undefined;
  History: undefined;
  Products: undefined;
  Inventory: undefined;
  Settings: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<TabParamList>();

function MainTabs() {
  const { seller } = useAuthStore();
  const isManager = seller?.role === 'admin' || seller?.role === 'manager';

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarStyle: {
          backgroundColor: Colors.surface,
          borderTopColor: Colors.border,
          borderTopWidth: 1,
          height: 70,
          paddingBottom: 10,
          paddingTop: 8,
        },
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textMuted,
        tabBarLabelStyle: { fontSize: 11, fontWeight: '500' },
        tabBarIcon: ({ focused, color, size }) => {
          const icons: Record<string, [string, string]> = {
            POS:       ['scan-outline', 'scan'],
            History:   ['receipt-outline', 'receipt'],
            Products:  ['cube-outline', 'cube'],
            Inventory: ['layers-outline', 'layers'],
            Settings:  ['settings-outline', 'settings'],
          };
          const [outline, filled] = icons[route.name] || ['ellipse-outline', 'ellipse'];
          return <Ionicons name={(focused ? filled : outline) as any} size={22} color={color} />;
        },
      })}
    >
      <Tab.Screen name="POS" component={POSScreen} options={{ title: 'POS' }} />
      <Tab.Screen name="History" component={SaleHistoryScreen} options={{ title: 'Sales' }} />
      {isManager && <Tab.Screen name="Products" component={ProductsScreen} options={{ title: 'Products' }} />}
      {isManager && <Tab.Screen name="Inventory" component={InventoryScreen} options={{ title: 'Inventory' }} />}
      <Tab.Screen name="Settings" component={SettingsScreen} options={{ title: 'Settings' }} />
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  const { seller, isInitialized, initialize } = useAuthStore();
  const fetchSettings = useSettingsStore(s => s.fetch);

  useEffect(() => { initialize(); }, []);
  useEffect(() => { if (seller) fetchSettings(); }, [seller]);

  if (!isInitialized) {
    return (
      <View style={styles.splash}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {!seller ? (
          <Stack.Screen name="Login" component={LoginScreen} />
        ) : (
          <>
            <Stack.Screen name="Main" component={MainTabs} />
            <Stack.Screen name="Receipt" component={ReceiptScreen}
              options={{ headerShown: true, title: 'Receipt', headerStyle: { backgroundColor: Colors.surface }, headerTintColor: Colors.textPrimary }} />
            <Stack.Screen name="AddEditProduct" component={AddEditProductScreen}
              options={{ headerShown: true, title: 'Product', headerStyle: { backgroundColor: Colors.surface }, headerTintColor: Colors.textPrimary }} />
            <Stack.Screen name="AuditLogs" component={AuditLogsScreen}
              options={{ headerShown: true, title: 'Audit Logs', headerStyle: { backgroundColor: Colors.surface }, headerTintColor: Colors.textPrimary }} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  splash: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Colors.bg },
});
