import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
} from 'react-native';

import CameraScreen from './CameraScreen';
import BarcodeScreen from './BarcodeScreen';

export default class App extends Component {

  constructor(props) {
    super(props);
    this.state = {
      example: undefined
    };
  }

  render() {
    if (this.state.example) {
      const Example = this.state.example;
      return <Example />;
    }
    return (
      <View style={{ flex: 1 }}>
        <View style={styles.headerContainer}>
          <Text style={{ fontSize: 60 }}>🎈</Text>
          <Text style={styles.headerText}>
            React Native Camera Kit
          </Text>
        </View>
        <View style={styles.container}>
          <TouchableOpacity style={styles.button} onPress={() => this.setState({ example: CameraScreen })}>
            <Text style={styles.buttonText}>
              Camera
            </Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.button} onPress={() => this.setState({ example: BarcodeScreen })}>
            <Text style={styles.buttonText}>
              Barcode Scanner
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }
}

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
    paddingTop: 100
  },
  headerText: {
    color: 'black',
    fontSize: 24
  },
  button: {
    height: 60,
    borderRadius: 30,
    marginVertical: 12,
    width: '100%',
    backgroundColor: '#dddddd',
    justifyContent: 'center'
  },
  buttonText: {
    textAlign: 'center',
    fontSize: 20,
  }
});
