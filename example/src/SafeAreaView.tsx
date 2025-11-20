import React from 'react';
import { View, Platform } from 'react-native';

// Dummy implementation of SafeAreaView
// In a real app, please use the react-native-safe-area-context package
function SafeAreaView({ style, children }: { style?: any; children: React.ReactNode }) {
  return <View style={[{ paddingTop: 50, paddingBottom: 50 }, style]}>{children}</View>;
}

export default SafeAreaView;
