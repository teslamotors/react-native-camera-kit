import React, { Component } from 'react';
import { Alert, View, Text, SafeAreaView, StyleSheet } from 'react-native';
import Camera from '../../src/Camera';
import { CameraType } from '../../src/CameraScreen/CameraScreenBase';

export default class CameraExample extends Component {
  render() {
    return (
      <View style={styles.cameraContainer}>
        <Camera
          ref={(ref) => (this.camera = ref)}
          type={CameraType.Back} // optional
          style={{ flex: 1 }}
          flashMode="auto"
          cameraOptions={{
            flashMode: 'auto', // on/off/auto(default)
            focusMode: 'on', // off/on(default)
            zoomMode: 'on', // off/on(default)
            ratioOverlay: '1:1', // optional
            ratioOverlayColor: '#00000077', // optional
          }}
          resetFocusTimeout={0}
          resetFocusWhenMotionDetected={false}
          saveToCameraRole={false} // iOS only
          scanBarcode={false} // optional
          showFrame={false} // Barcode only, optional
          laserColor="red" // Barcode only, optional
          frameColor="yellow" // Barcode only, optional
          surfaceColor="blue" // Barcode only, optional
          onReadCode={(  // optional
            event,
          ) => console.log(event.nativeEvent.codeStringValue)}
        />
      </View>
    );
  }
}

const styles = StyleSheet.create(
  {
    cameraContainer: {
      flex: 1,
      backgroundColor: 'black',
    },
  },
);
