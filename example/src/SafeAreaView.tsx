import React from 'react';
import { View, Platform } from 'react-native';

// Dummy implementation of SafeAreaView
// In a real app, please use the react-native-safe-area-context package
function SafeAreaView({ style, children }: { style?: any; children: React.ReactNode }) {
  const paddingTop = Platform.OS === 'android' ? 50 : 0;
  const paddingBottom = Platform.OS === 'android' ? 50 : 0;
  return <View style={[{ paddingTop, paddingBottom }, style]}>{children}</View>;
}

export default SafeAreaView;
