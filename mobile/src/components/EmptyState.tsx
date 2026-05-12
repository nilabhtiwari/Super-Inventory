import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, FontSizes, Spacing } from '../theme';

interface Props {
  icon?: string;
  title: string;
  subtitle?: string;
}

export default function EmptyState({ icon = 'cube-outline', title, subtitle }: Props) {
  return (
    <View style={styles.container}>
      <View style={styles.iconWrap}>
        <Ionicons name={icon as any} size={48} color={Colors.textMuted} />
      </View>
      <Text style={styles.title}>{title}</Text>
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: Spacing.xxxl },
  iconWrap: {
    width: 88, height: 88, borderRadius: 44,
    backgroundColor: Colors.surface2,
    justifyContent: 'center', alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  title:    { color: Colors.textSecondary, fontSize: FontSizes.lg, fontWeight: '600', textAlign: 'center', marginBottom: Spacing.sm },
  subtitle: { color: Colors.textMuted, fontSize: FontSizes.sm, textAlign: 'center', lineHeight: 20 },
});
