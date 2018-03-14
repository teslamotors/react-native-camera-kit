import React, { Component } from 'react';
import {
  Alert
} from 'react-native';
import { CameraKitCameraScreen } from 'react-native-camera-kit';


export default class CameraScreen extends Component {

  showCodeAlert = ({ nativeEvent: { codeStringValue } }) => {
    if (this.codeStringValue !== codeStringValue) {
      this.codeStringValue = codeStringValue;
      Alert.alert(`Qr code found ${this.codeStringValue} `)
    }
  }

  render() {
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
        frameColor={"yellow"}

        onReadCode={this.showCodeAlert}
        hideControls={true}
        // offsetForScannerFrame = {10}  
        // heightForScannerFrame = {300}  
        colorForScannerFrame={'blue'}
      />
    );
  }
}



