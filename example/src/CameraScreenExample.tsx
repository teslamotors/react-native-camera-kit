import React, { Component } from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import { CameraOptions } from '../../src/CameraScreen/CameraScreenBase';

export default class CameraScreenExample extends Component {
  onBottomButtonPressed(event) {
    const captureImages = JSON.stringify(event.captureImages);
    Alert.alert(
      `${event.type} button pressed`,
      `${captureImages}`,
      [{ text: 'OK', onPress: () => console.log('OK Pressed') }],
      { cancelable: false },
    );
  }

  render() {
    const options: CameraOptions = { flashMode: 'auto', focusMode: 'on', zoomMode: 'on' };
    return (
      <CameraScreen
        actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
        onBottomButtonPressed={(event) => this.onBottomButtonPressed(event)}
        cameraOptions={options}
        flashImages={{
          on: require('../images/flashOn.png'),
          off: require('../images/flashOff.png'),
          auto: require('../images/flashAuto.png'),
        }}
        cameraFlipImage={require('../images/cameraFlipIcon.png')}
        captureButtonImage={require('../images/cameraButton.png')}
      />
    );
  }
}
