import React, { useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import BarcodeScreen from './BarcodeScreenExample';

interface IProps {
  value: string;
}

const CheckingScreen: React.FC<IProps> = ({ value }) => {
  const [example, setExample] = useState<React.FunctionComponent>();

  if (example) {
    const Screen = example;
    return <Screen />;
  }
  return (
    <View style={styles.container}>
      <Text style={styles.valueText}>{value}</Text>
      <TouchableOpacity onPress={() => setExample(() => BarcodeScreen)}>
        <Text style={styles.buttonText}>Back button</Text>
      </TouchableOpacity>
    </View>
  );
};

export default CheckingScreen;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 60,
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  valueText: {
    marginBottom: 20,
    fontSize: 40,
  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20,
  },
});
