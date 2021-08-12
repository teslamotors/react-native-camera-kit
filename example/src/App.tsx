import React, { useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import BarcodeScreenExample from './BarcodeScreenExample';
import CameraExample from './CameraExample';
import CameraScreenExample from './CameraScreenExample';
import CustomIconScreenExample from './CustomIconScreenExample';

interface IProps {}

const App: React.FC<IProps> = () => {
  const [example, setExample] = useState<React.FunctionComponent>();

  if (example) {
    const Example = example;
    return <Example />;
  }

  return (
    <View style={{ flex: 1 }}>
      <View style={styles.headerContainer}>
        <Text style={{ fontSize: 60 }}>🎈</Text>
        <Text style={styles.headerText}>React Native Camera Kit</Text>
      </View>
      <View style={styles.container}>
        <TouchableOpacity style={styles.button} onPress={() => setExample(() => CameraExample)}>
          <Text style={styles.buttonText}>Camera</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(() => CameraScreenExample)}>
          <Text style={styles.buttonText}>Camera Screen</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(() => BarcodeScreenExample)}>
          <Text style={styles.buttonText}>Barcode Scanner</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(() => CustomIconScreenExample)}>
          <Text style={styles.buttonText}>Camera Screen with custom icons</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default App;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 30,
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
    marginHorizontal: 24,
  },
  headerContainer: {
    flexDirection: 'column',
    backgroundColor: '#F5FCFF',
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 100,
  },
  headerText: {
    color: 'black',
    fontSize: 24,
    fontWeight: 'bold',
  },
  button: {
    height: 60,
    borderRadius: 30,
    marginVertical: 12,
    width: '100%',
    backgroundColor: '#dddddd',
    justifyContent: 'center',
  },
  buttonText: {
    textAlign: 'center',
    fontSize: 20,
  },
});
