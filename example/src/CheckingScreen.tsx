import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import BarcodeScreen from './BarcodeScreenExample';

const CheckingScreen: React.FC<{value: any}> = (props) => {
  const [example, setExample] = React.useState<any>(undefined);
  const [valueState, setValueState] = React.useState<any>(undefined);

  if (example) {
    const Screen = example;
    return <Screen value={valueState} />;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.valueText}>{props.value}</Text>
      <TouchableOpacity onPress={() => setExample(BarcodeScreen)}>
        <Text style={styles.buttonText}>Back button</Text>
      </TouchableOpacity>
    </View>);
};

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

export default CheckingScreen;
