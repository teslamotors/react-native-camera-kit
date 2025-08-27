import React, { useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, ScrollView } from 'react-native';

import BarcodeScreenExample from './BarcodeScreenExample';
import CameraExample from './CameraExample';

const App = () => {
  const [example, setExample] = useState<JSX.Element>();

  if (example) {
    return example;
  }

  const onBack = () => setExample(undefined);

  return (
    <ScrollView style={styles.scroll}>
      <View style={styles.container}>
        <Text style={{ fontSize: 60 }}>🎈</Text>
        <Text style={styles.headerText}>React Native Camera Kit</Text>
        <TouchableOpacity style={styles.button} onPress={() => setExample(<CameraExample onBack={onBack} />)}>
          <Text style={styles.buttonText}>Camera</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(<BarcodeScreenExample onBack={onBack} />)}>
          <Text style={styles.buttonText}>Barcode Scanner</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

export default App;

const styles = StyleSheet.create({
  scroll: {
    flexGrow: 1,
    backgroundColor: '#000000',
  },
  container: {
    flexGrow: 1,
    paddingTop: 100,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  headerText: {
    color: 'white',
    fontSize: 24,
    fontWeight: 'bold',
    marginBlockEnd: 24,
  },
  button: {
    height: 60,
    borderRadius: 30,
    marginVertical: 12,
    width: '100%',
    backgroundColor: '#666666',
    justifyContent: 'center',
  },
  buttonText: {
    color: 'white',
    textAlign: 'center',
    fontSize: 20,
  },
});
