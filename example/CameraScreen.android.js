import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
  Alert
} from 'react-native';


import _ from 'lodash';

const BUTTON_TYPE_CANCEL = 'left';
const BUTTON_TYPE_DONE = 'right';

import { CameraKitCameraScreen } from 'react-native-camera-kit';

export default class CameraScreen extends Component {


  onBottomButtonPressed(event) {
    const captureImages = JSON.stringify(event.captureImages);
    Alert.alert(
      `${event.type} button pressed`,
      `${captureImages}`,
      [
        { text: 'OK', onPress: () => console.log('OK Pressed') },
      ],
      { cancelable: false }
    )
  }

  render() {
    return (
      <CameraKitCameraScreen
        actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
        onBottomButtonPressed={(event) => this.onBottomButtonPressed(event)}
        flashImages={{
          on: require('./images/flashOn.png'),
          off: require('./images/flashOff.png'),
          auto: require('./images/flashAuto.png')
        }}
        cameraFlipImage={require('./images/cameraFlipIcon.png')}
        captureButtonImage={require('./images/cameraButton.png')}
      />
    );
  }
}



