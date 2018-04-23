import React, { Component } from 'react';
import {
  Alert,
  Dimensions
} from 'react-native';
import { CameraKitCameraScreen } from '../../src';
import CheckingScreen from './CheckingScreen';

const { width, height } = Dimensions.get('window');
const frameleft = parseInt(width / 7);
const frameTop = parseInt(height / 2.75);
const frameWidth = width - 2 * frameleft;
const frameHeight = height - 2 * frameTop;

export default class CameraScreen extends Component {

  constructor(props) {
    super(props);
    this.state = {
      example: undefined
    };
  }

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
    if (this.state.example) {
      const CameraScreen = this.state.example;
      return <CameraScreen />;
    }
    return (
      <CameraKitCameraScreen
        actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
        onBottomButtonPressed={(event) => this.onBottomButtonPressed(event)}
        flashImages={{
          on: require('./../images/flashOn.png'),
          off: require('./../images/flashOff.png'),
          auto: require('./../images/flashAuto.png')
        }}
        showFrame={true}
        scanBarcode={true}
        laserColor={"blue"}
        surfaceColor={"black"}
        frameColor={"yellow"}
        onReadCode={((event) => this.setState({ example: CheckingScreen }))}
        hideControls={true}
        colorForScannerFrame={'blue'}
        frameHeight={frameHeight}
        frameWidth={frameWidth}
        frameLeft={frameleft}
        frameTop={frameTop}
        overlayColor={'rgba(255, 0, 0, 0.5)'}
      />
    );
  }
}



