import React, { Component } from 'react';
import {
  Alert
} from 'react-native';
import { CameraKitCameraScreen } from 'react-native-camera-kit';
import ExampleScreen from './ExampleScreen';


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
        frameColor={"yellow"}
       
        //onReadCode={((event) => Alert.alert(`Qr code found ${event.nativeEvent.codeStringValue} `))} 
        onReadCode = {((event) => this.setState({ example: ExampleScreen}))}
        hideControls={true} 
        isNeedMultipleScanBarcode = {true}
        // offsetForScannerFrame = {10}  
        // heightForScannerFrame = {300}  
        colorForScannerFrame = {'blue'} 
      />
    );
  }
}



