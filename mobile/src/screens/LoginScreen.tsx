import React, { useState, useRef } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  KeyboardAvoidingView, Platform, ScrollView, Animated, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuthStore } from '../store/authStore';
import { Colors, FontSizes, Spacing, Radius, Shadows } from '../theme';

export default function LoginScreen() {
  const [email, setEmail]         = useState('');
  const [password, setPassword]   = useState('');
  const [showPass, setShowPass]   = useState(false);
  const [error, setError]         = useState('');
  const { login, isLoading }      = useAuthStore();
  const shake                     = useRef(new Animated.Value(0)).current;

  const triggerShake = () => {
    Animated.sequence([
      Animated.timing(shake, { toValue: 10, duration: 60, useNativeDriver: true }),
      Animated.timing(shake, { toValue: -10, duration: 60, useNativeDriver: true }),
      Animated.timing(shake, { toValue: 6, duration: 60, useNativeDriver: true }),
      Animated.timing(shake, { toValue: 0, duration: 60, useNativeDriver: true }),
    ]).start();
  };

  const handleLogin = async () => {
    if (!email.trim() || !password.trim()) {
      setError('Please enter email and password');
      triggerShake();
      return;
    }
    setError('');
    try {
      await login(email.trim().toLowerCase(), password);
    } catch (err: any) {
      setError(err.message || 'Login failed');
      triggerShake();
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">

          {/* Logo/Brand */}
          <View style={styles.brand}>
            <View style={styles.logoCircle}>
              <Ionicons name="scan" size={40} color={Colors.primary} />
            </View>
            <Text style={styles.appName}>QEXmanage</Text>
            <Text style={styles.tagline}>Smart POS for your business</Text>
          </View>

          {/* Card */}
          <Animated.View style={[styles.card, { transform: [{ translateX: shake }] }]}>
            <Text style={styles.title}>Welcome back</Text>
            <Text style={styles.subtitle}>Sign in to continue</Text>

            {error ? (
              <View style={styles.errorBox}>
                <Ionicons name="alert-circle-outline" size={16} color={Colors.error} />
                <Text style={styles.errorText}>{error}</Text>
              </View>
            ) : null}

            {/* Email */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Email</Text>
              <View style={styles.inputWrap}>
                <Ionicons name="mail-outline" size={18} color={Colors.textMuted} style={styles.icon} />
                <TextInput
                  style={styles.input}
                  value={email}
                  onChangeText={setEmail}
                  placeholder="seller@shop.com"
                  placeholderTextColor={Colors.textMuted}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                  returnKeyType="next"
                />
              </View>
            </View>

            {/* Password */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Password</Text>
              <View style={styles.inputWrap}>
                <Ionicons name="lock-closed-outline" size={18} color={Colors.textMuted} style={styles.icon} />
                <TextInput
                  style={[styles.input, styles.flex]}
                  value={password}
                  onChangeText={setPassword}
                  placeholder="••••••••"
                  placeholderTextColor={Colors.textMuted}
                  secureTextEntry={!showPass}
                  returnKeyType="done"
                  onSubmitEditing={handleLogin}
                />
                <TouchableOpacity onPress={() => setShowPass(!showPass)} style={styles.eyeBtn}>
                  <Ionicons name={showPass ? 'eye-off-outline' : 'eye-outline'} size={18} color={Colors.textMuted} />
                </TouchableOpacity>
              </View>
            </View>

            {/* Login Button */}
            <TouchableOpacity
              style={[styles.loginBtn, isLoading && styles.loginBtnDisabled]}
              onPress={handleLogin}
              disabled={isLoading}
              activeOpacity={0.85}
            >
              {isLoading
                ? <Text style={styles.loginBtnText}>Signing in…</Text>
                : <>
                    <Ionicons name="log-in-outline" size={20} color={Colors.white} />
                    <Text style={styles.loginBtnText}>Sign In</Text>
                  </>
              }
            </TouchableOpacity>
          </Animated.View>

          <Text style={styles.footer}>QEXmanage POS v1.0 · Secured with JWT</Text>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe:        { flex: 1, backgroundColor: Colors.bg },
  flex:        { flex: 1 },
  scroll:      { flexGrow: 1, justifyContent: 'center', padding: Spacing.xl },
  brand:       { alignItems: 'center', marginBottom: Spacing.xxxl },
  logoCircle:  {
    width: 80, height: 80, borderRadius: 40,
    backgroundColor: Colors.surface2,
    justifyContent: 'center', alignItems: 'center',
    marginBottom: Spacing.lg,
    borderWidth: 2, borderColor: Colors.primary,
    ...Shadows.glow,
  },
  appName:     { color: Colors.textPrimary, fontSize: FontSizes.xxxl, fontWeight: '800', letterSpacing: 1 },
  tagline:     { color: Colors.textMuted, fontSize: FontSizes.sm, marginTop: 4 },
  card:        {
    backgroundColor: Colors.surface,
    borderRadius: Radius.xl,
    padding: Spacing.xxl,
    borderWidth: 1, borderColor: Colors.border,
    ...Shadows.md,
  },
  title:       { color: Colors.textPrimary, fontSize: FontSizes.xxl, fontWeight: '700', marginBottom: 4 },
  subtitle:    { color: Colors.textMuted, fontSize: FontSizes.sm, marginBottom: Spacing.xl },
  errorBox:    {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    backgroundColor: '#FF6B6B22', borderRadius: Radius.md,
    borderWidth: 1, borderColor: Colors.error,
    padding: Spacing.md, marginBottom: Spacing.lg,
  },
  errorText:   { color: Colors.error, fontSize: FontSizes.sm, flex: 1 },
  inputGroup:  { marginBottom: Spacing.lg },
  label:       { color: Colors.textSecondary, fontSize: FontSizes.sm, fontWeight: '600', marginBottom: 6 },
  inputWrap:   {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: Colors.surface2,
    borderRadius: Radius.md,
    borderWidth: 1, borderColor: Colors.border,
    paddingHorizontal: Spacing.md,
  },
  icon:        { marginRight: 8 },
  input:       { color: Colors.textPrimary, fontSize: FontSizes.md, paddingVertical: 14, flex: 1 },
  eyeBtn:      { padding: Spacing.sm },
  loginBtn:    {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, backgroundColor: Colors.primary,
    borderRadius: Radius.md, paddingVertical: 16, marginTop: Spacing.sm,
    ...Shadows.glow,
  },
  loginBtnDisabled: { opacity: 0.7 },
  loginBtnText:     { color: Colors.white, fontSize: FontSizes.lg, fontWeight: '700' },
  footer:           { color: Colors.textMuted, fontSize: FontSizes.xs, textAlign: 'center', marginTop: Spacing.xxl },
});
