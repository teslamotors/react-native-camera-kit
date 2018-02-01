import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  AlertIOS
} from 'react-native';

import {
  CameraKitCamera,
  CameraKitGallery
} from 'react-native-camera-kit';

import CameraScreen from './src/CameraScreen';
import AlbumsScreen from './src/AlbumsScreen';
import GalleryScreen from './src/GalleryScreen';
import BarcodeScreen from './src/BarcodeScreen';

class example extends Component {

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
      AlertIOS.alert('You have permission 🤗')
    }
    else {
      AlertIOS.alert('No permission 😳')
    }
  }

  async onCheckGalleryAuthoPressed() {
    const success = await CameraKitGallery.checkDevicePhotosAuthorizationStatus();
    if (success) {
      AlertIOS.alert('You have permission 🤗')
    }
    else {
      AlertIOS.alert('No permission 😳')
    }
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    // justifyContent: 'center',
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

AppRegistry.registerComponent('example', () => example);
