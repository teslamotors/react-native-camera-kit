import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Alert
} from 'react-native';

import {CameraKitGallery, CameraKitCamera} from '../../src';

import CameraScreen from './CameraScreen';
import AlbumsScreen from './AlbumsScreen';
import GalleryScreen from './GalleryScreen';
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
          <Text style={styles.headerText}>
            Welcome to Camera Kit
          </Text>
          <Text style={{ fontSize: 40 }}>📷</Text>
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

          <TouchableOpacity onPress={() => this.setState({ example: AlbumsScreen })}>
            <Text style={styles.buttonText}>
              Albums Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.setState({ example: GalleryScreen })}>
            <Text style={styles.buttonText}>
              Gallery Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.onCheckCameraAuthoPressed()}>
            <Text style={styles.buttonText}>
              Camera Autotization Status
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.onCheckGalleryAuthoPressed()}>
            <Text style={styles.buttonText}>
              Photos Autotization Status
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

  async onCheckGalleryAuthoPressed() {
    const success = await CameraKitGallery.checkDevicePhotosAuthorizationStatus();
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
