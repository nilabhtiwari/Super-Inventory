import React from 'react';
import { View, ActivityIndicator, StyleSheet, Text } from 'react-native';
import { Colors, FontSizes } from '../theme';

interface Props {
  visible: boolean;
  message?: string;
}

export default function LoadingOverlay({ visible, message }: Props) {
  if (!visible) return null;
  return (
    <View style={styles.overlay}>
      <View style={styles.box}>
        <ActivityIndicator size="large" color={Colors.primary} />
        {message ? <Text style={styles.msg}>{message}</Text> : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.65)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 999,
  },
  box: {
    backgroundColor: Colors.surface2,
    borderRadius: 14,
    padding: 28,
    alignItems: 'center',
    gap: 14,
    minWidth: 140,
  },
  msg: {
    color: Colors.textSecondary,
    fontSize: FontSizes.sm,
    textAlign: 'center',
  },
});
