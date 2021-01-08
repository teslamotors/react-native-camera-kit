import React, { Component } from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import CheckingScreen from './CheckingScreen';

export default class BarcodeScreenExample extends Component {
  constructor(props) {
    super(props);
    this.state = {
      example: undefined,
    };
  }

  onBottomButtonPressed(event) {
    const captureImages = JSON.stringify(event.captureImages);
    Alert.alert(
      `"${event.type}" Button Pressed`,
      `${captureImages}`,
      [{ text: 'OK', onPress: () => console.log('OK Pressed') }],
      { cancelable: false },
    );
  }

  render() {
    if (this.state.example) {
      const CameraScreen = this.state.example;
      return <CameraScreen />;
    }
    return (
      <CameraScreen
        actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
        onBottomButtonPressed={(event) => this.onBottomButtonPressed(event)}
        flashImages={{
          on: require('../images/flashOn.png'),
          off: require('../images/flashOff.png'),
          auto: require('../images/flashAuto.png'),
        }}
        showFrame
        scanBarcode
        laserColor={'blue'}
        surfaceColor={'black'}
        frameColor={'yellow'}
        onReadCode={(event) => {
          console.log(event);
          this.setState({ example: CheckingScreen });
        }}
        hideControls
        // offsetForScannerFrame = {10}
        // heightForScannerFrame = {300}
        colorForScannerFrame={'blue'}
      />
    );
  }
}
