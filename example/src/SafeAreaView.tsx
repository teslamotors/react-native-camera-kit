import React from 'react';
import { View, Platform } from 'react-native';

/**
 * Minimal SafeAreaView used by the examples.
 *
 * @remarks
 * This is a placeholder to keep the example lightweight. For production
 * apps, prefer `react-native-safe-area-context`’s `SafeAreaView`.
 */
function SafeAreaView({ style, children }: { style?: any; children: React.ReactNode }) {
  return <View style={[{ paddingTop: 50, paddingBottom: 50 }, style]}>{children}</View>;
}

export default SafeAreaView;
