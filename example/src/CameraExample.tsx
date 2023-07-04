import React, { useState, useRef } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
  Dimensions,
  Platform,
  SafeAreaView,
  useWindowDimensions,
} from 'react-native';
import Camera from '../../src/Camera';
import { CameraApi, CameraType, CaptureData } from '../../src/types';
import { Orientation } from '../../src';

const { width, height } = Dimensions.get('window');

const flashImages = {
  on: require('../images/flashOn.png'),
  off: require('../images/flashOff.png'),
  auto: require('../images/flashAuto.png'),
};

const flashArray = [
  {
    mode: 'auto',
    image: flashImages.auto,
  },
  {
    mode: 'on',
    image: flashImages.on,
  },
  {
    mode: 'off',
    image: flashImages.off,
  },
] as const;

const CameraExample = ({ onBack }: { onBack: () => void }) => {
  const cameraRef = useRef<CameraApi>(null);
  const [currentFlashArrayPosition, setCurrentFlashArrayPosition] = useState(0);
  const [captureImages, setCaptureImages] = useState<CaptureData[]>([]);
  const [flashData, setFlashData] = useState(flashArray[currentFlashArrayPosition]);
  const [torchMode, setTorchMode] = useState(false);
  const [captured, setCaptured] = useState(false);
  const [cameraType, setCameraType] = useState(CameraType.Back);
  const [showImageUri, setShowImageUri] = useState<string>('');

  // iOS will error out if capturing too fast,
  // so block capturing until the current capture is done
  // This also minimizes issues of delayed capturing
  const isCapturing = useRef(false);

  const numberOfImagesTaken = () => {
    const numberTook = captureImages.length;
    if (numberTook >= 2) {
      return numberTook;
    } else if (captured) {
      return '1';
    } else {
      return '';
    }
  };

  const onSwitchCameraPressed = () => {
    const direction = cameraType === CameraType.Back ? CameraType.Front : CameraType.Back;
    setCameraType(direction);
  };

  const onSetFlash = () => {
    const newPosition = (currentFlashArrayPosition + 1) % 3;
    setCurrentFlashArrayPosition(newPosition);
    setFlashData(flashArray[newPosition]);
  };

  const onSetTorch = () => {
    setTorchMode(!torchMode);
  };

  const onCaptureImagePressed = async () => {
    if (showImageUri) {
      setShowImageUri('');
      return;
    }
    if (!cameraRef.current || isCapturing.current) return;
    let image: CaptureData | undefined;
    try {
      isCapturing.current = true;
      image = await cameraRef.current.capture();
    } catch (e) {
      console.log('error', e);
    } finally {
      isCapturing.current = false;
    }
    if (!image) return;

    setCaptured(true);
    setCaptureImages([...captureImages, image]);
    console.log('image', image);
  };

  const window = useWindowDimensions();
  const cameraRatio = 4 / 3;

  return (
    <View style={{ flexGrow: 1, flexShrink: 1, backgroundColor: 'black' }}>
      <SafeAreaView style={styles.top}>
        <View style={styles.topButtons}>
          {flashData.image && (
            <TouchableOpacity style={styles.flashMode} onPress={() => onSetFlash()}>
              <Image source={flashData.image} resizeMode="contain" />
            </TouchableOpacity>
          )}
          <TouchableOpacity style={styles.switchCamera} onPress={() => onSwitchCameraPressed()}>
            <Image source={require('../images/cameraFlipIcon.png')} resizeMode="contain" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.torch} onPress={() => onSetTorch()}>
            <Image
              source={torchMode ? require('../images/torchOn.png') : require('../images/torchOff.png')}
              resizeMode="contain"
            />
          </TouchableOpacity>
        </View>
      </SafeAreaView>
      <View style={styles.cameraContainer}>
        {showImageUri ? (
          <Image
            source={{ uri: showImageUri }}
            style={{ width: window.width, height: window.width * cameraRatio }}
            resizeMode="contain"
          />
        ) : (
          <Camera
            ref={cameraRef}
            style={{ width: window.width, height: window.width * cameraRatio, backgroundColor: 'magenta' }}
            cameraType={cameraType}
            flashMode={flashData?.mode}
            zoomMode="on"
            focusMode="on"
            torchMode={torchMode ? 'on' : 'off'}
            onOrientationChange={(e) => {
              // We recommend locking the camera UI to portrait (using a different library)
              // and rotating the UI elements counter to the orientation
              // However, we include onOrientationChange so you can match your UI to what the camera does
              const isLandscape = [Orientation.LANDSCAPE_LEFT, Orientation.LANDSCAPE_RIGHT].includes(
                e.nativeEvent.orientation,
              );
              console.log('orientationChange', isLandscape ? 'landscape' : 'portrait');
            }}
          />
        )}
      </View>
      <SafeAreaView style={styles.bottomButtons}>
        <View style={styles.bottomButtonsInner}>
          <TouchableOpacity style={styles.backBtn} onPress={() => onBack()}>
            <Text style={styles.textStyle}>Back</Text>
          </TouchableOpacity>
          <View style={styles.captureButtonContainer}>
            <TouchableOpacity onPress={() => onCaptureImagePressed()}>
              <Image source={require('../images/cameraButton.png')} />
              <View style={styles.textNumberContainer}>
                <Text>{numberOfImagesTaken()}</Text>
              </View>
            </TouchableOpacity>
          </View>
          <View style={styles.rightBottomArea}>
            {captureImages.length > 0 && (
              <TouchableOpacity
                onPress={() => {
                  if (showImageUri) {
                    setShowImageUri('');
                  } else {
                    setShowImageUri(captureImages[captureImages.length - 1].uri);
                  }
                }}
              >
                <Image source={{ uri: captureImages[captureImages.length - 1].uri }} style={styles.preview} />
              </TouchableOpacity>
            )}
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
};

export default CameraExample;

const styles = StyleSheet.create({
  top: {
    zIndex: 10,
  },
  topButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    // borderColor: 'yellow',
    // position: 'relative',
  },
  flashMode: {
    position: 'absolute',
    left: 10,
    top: 0,
    bottom: 0,
    padding: 10,
  },
  switchCamera: {
    padding: 10,
  },
  torch: {
    position: 'absolute',
    right: 10,
    top: 0,
    bottom: 0,
    padding: 10,
  },
  cameraContainer: {
    ...Platform.select({
      android: {
        position: 'absolute',
        top: 0,
        left: 0,
        width,
        height,
      },
      default: {
        justifyContent: 'center',
        flex: 1,
        // zIndex: 0
      },
    }),
  },

  bottomButtons: {
    bottom: 0,
    left: 0,
    right: 0,
  },
  bottomButtonsInner: {
    paddingVertical: 10,
  },
  backBtn: {
    position: 'absolute',
    left: 10,
    top: 0,
    bottom: 0,
    justifyContent: 'center',
    zIndex: 10,
    padding: 10,
  },
  captureButtonContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 9,
  },
  rightBottomArea: {
    position: 'absolute',
    right: 20,
    top: 0,
    bottom: 0,
    zIndex: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textStyle: {
    color: 'white',
    fontSize: 20,
  },
  textNumberContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
    justifyContent: 'center',
    alignItems: 'center',
  },
  gap: {
    flex: 10,
    flexDirection: 'column',
  },
  preview: {
    width: 48,
    height: 48,
    borderRadius: 4,
  },
});
