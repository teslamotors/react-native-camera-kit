import React, { Component } from 'react';
import {
    AppRegistry,
    StyleSheet,
    Text,
    View,
    ListView,
    TouchableOpacity,
    Image,
    Alert
} from 'react-native';
import {
  CameraKitCamera,
  CameraKitGallery
} from 'react-native-camera-kit';

import CameraScreen from  './CameraScreen';
import AlbumsScreen from  './AlbumsScreen';


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
        <View style={styles.container}>

          <TouchableOpacity onPress={() => this.setState({example: CameraScreen})}>
            <Text style={styles.buttonText}>
              Camera Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.setState({example: AlbumsScreen})}>
            <Text style={styles.buttonText}>
              Albums Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.onCheckCameraAuthoPressed()}>
            <Text style={styles.buttonText}>
              Check Camera Autotization Status
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.onCheckGalleryAuthoPressed()}>
            <Text style={styles.buttonText}>
              Check Photos Autotization Status
            </Text>
          </TouchableOpacity>

        </View>

    );
  }


  async onCheckCameraAuthoPressed() {
    const success = await CameraKitCamera.checkDeviceCameraAuthorizationStatus();
    if (success) {
      Alert.alert('You have permission!')
    }
    else {
      Alert.alert('No permission :(')
    }
  }

  async onCheckGalleryAuthoPressed() {
    const success = await CameraKitGallery.checkDevicePhotosAuthorizationStatus();
    if (success) {
      Alert.alert('You have permission!')
    }
    else {
      Alert.alert('No permission :(')
    }
  }

}



const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20

  }
});


AppRegistry.registerComponent('example', () => example);
