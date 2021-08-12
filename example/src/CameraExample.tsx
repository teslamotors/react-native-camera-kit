import React, { useRef } from 'react';
import { View, StyleSheet } from 'react-native';
import { Camera, CameraType } from '../../src';

interface IProps {}

const CameraExample: React.FC<IProps> = () => {
  const ref = useRef<typeof Camera>(null);
  const onReadCode = (event: any) => console.log(event.nativeEvent.codeStringValue);
  return (
    <View style={styles.cameraContainer}>
      <Camera
        ref={ref}
        style={styles.camera}
        cameraType={CameraType.Back} // optional
        flashMode="auto" // on/off/auto(default)
        focusMode="on" // off/on(default)
        zoomMode="on" // off/on(default)
        torchMode="off" // on/off(default)
        ratioOverlay="1:1" // optional
        ratioOverlayColor="#00000077" // optional
        resetFocusTimeout={0}
        resetFocusWhenMotionDetected={false}
        saveToCameraRoll={false} // iOS only
        scanBarcode={false} // optional
        showFrame={false} // Barcode only, optional
        laserColor="red" // Barcode only, optional
        frameColor="yellow" // Barcode only, optional
        surfaceColor="blue" // Barcode only, optional
        onReadCode={onReadCode}
      />
    </View>
  );
};

export default CameraExample;

const styles = StyleSheet.create({
  cameraContainer: {
    flex: 1,
    backgroundColor: 'black',
  },
  camera: {
    flex: 1,
  },
});
