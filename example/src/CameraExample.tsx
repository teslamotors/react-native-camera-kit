import React from 'react';
import { StyleSheet, View } from 'react-native';
import { CameraType } from '../../src/CameraScreen';
import Camera from '../../src/PlatformCamera';

const CameraExample: React.FC<{}> = () => {
  return (
    <View style={styles.cameraContainer}>
      <Camera
        style={{flex: 1}}
        cameraType={CameraType.Back} // optional
        flashMode="auto" // on/off/auto(default)
        focusMode="on" // off/on(default)
        zoomMode="on" // off/on(default)
        torchMode="off" // on/off(default)
        ratioOverlay="1:1" // optional
        ratioOverlayColor="#00000077" // optional
        resetFocusTimeout={0}
        resetFocusWhenMotionDetected={false}
        saveToCameraRole={false} // iOS only
        scanBarcode // optional
        showFrame={false} // Barcode only, optional
        laserColor="red" // Barcode only, optional
        frameColor="yellow" // Barcode only, optional
        surfaceColor="blue" // Barcode only, optional
        onReadCode={(event) => console.log(event.nativeEvent.codeStringValue)}
      />
    </View>
  );
};

const styles = StyleSheet.create(
  {
    cameraContainer: {
      flex: 1,
      backgroundColor: 'black',
    },
  },
);

export default CameraExample;
