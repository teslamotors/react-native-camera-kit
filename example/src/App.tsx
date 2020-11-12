import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Alert
} from 'react-native';

import { CameraKitCamera } from '../../src';

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
          <TouchableOpacity onPress={() => this.setState({ example: BarcodeScreen })}>
            <Text style={styles.buttonText}>
              Barcode scanner Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.setState({ example: CameraScreen })}>
            <Text style={styles.buttonText}>
              Camera Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.onCheckCameraAuthoPressed()}>
            <Text style={styles.buttonText}>
              Camera Permission Status
            </Text>
          </TouchableOpacity>
        </View>

      </View>

    );
  }

  async onCheckCameraAuthoPressed() {
    const success = await CameraKitCamera.checkDeviceCameraAuthorizationStatus();
    if (success) {
      Alert.alert('You have permission 🤗')
    }
    else {
      Alert.alert('No permission 😳')
    }
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 60,
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
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
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20
  }
});
