import React, { useState, useRef, useEffect } from 'react';
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
  Vibration,
} from 'react-native';
import Camera from '../../src/Camera';
import { CameraApi, CameraType, CaptureData } from '../../src/types';

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

const BarcodeExample = ({ onBack }: { onBack: () => void }) => {
  const cameraRef = useRef<CameraApi>(null);
  const [currentFlashArrayPosition, setCurrentFlashArrayPosition] = useState(0);
  const [captureImages, setCaptureImages] = useState<CaptureData[]>([]);
  const [flashData, setFlashData] = useState(flashArray[currentFlashArrayPosition]);
  const [torchMode, setTorchMode] = useState(false);
  // const [ratios, setRatios] = useState([]);
  // const [ratioArrayPosition, setRatioArrayPosition] = useState(-1);
  const [captured, setCaptured] = useState(false);
  const [cameraType, setCameraType] = useState(CameraType.Back);
  const [barcode, setBarcode] = useState<string>('');

  useEffect(() => {
    const t = setTimeout(() => {
      setBarcode('');
    }, 2000);
    return () => {
      clearTimeout(t);
    };
  }, [barcode]);

  // useEffect(() => {
  //   let updatedRatios = [...ratios];
  //   if (props.cameraRatioOverlay) {
  //     updatedRatios = updatedRatios.concat(props.cameraRatioOverlay.ratios || []);
  //   }
  //   setRatios(updatedRatios);
  //   setRatioArrayPosition(updatedRatios.length > 0 ? 0 : -1);
  // }, []);

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
    if (!cameraRef.current) return;
    const image = await cameraRef.current.capture();
    if (image) {
      setCaptured(true);
      setCaptureImages([...captureImages, image]);
      console.log('image', image);
    }
  };

  // const onRatioButtonPressed = () => {
  //   const newPosition = (ratioArrayPosition + 1) % ratios.length;
  //   setRatioArrayPosition(newPosition);
  // };

  const window = useWindowDimensions();
  const cameraRatio = 4 / 3;

  return (
    <View style={{ flexGrow: 1, flexShrink: 1, backgroundColor: 'black' }}>
      <SafeAreaView style={styles.top}>
        <View style={styles.topButtons}>
          {flashData.image && (
            <TouchableOpacity style={styles.flashMode} onPress={() => onSetFlash()}>
              <Image source={flashData.image} resizeMode='contain' />
            </TouchableOpacity>
          )}
          <TouchableOpacity style={styles.switchCamera} onPress={() => onSwitchCameraPressed()}>
            <Image source={require('../images/cameraFlipIcon.png')} resizeMode='contain' />
          </TouchableOpacity>
          <TouchableOpacity style={styles.torch} onPress={() => onSetTorch()}>
            <Image
              source={torchMode ? require('../images/torchOn.png') : require('../images/torchOff.png')}
              resizeMode='contain'
            />
          </TouchableOpacity>
        </View>
      </SafeAreaView>
      <View style={styles.cameraContainer}>
        <Camera
          ref={cameraRef}
          style={{ width: window.width, height: window.width * cameraRatio }}
          cameraType={cameraType}
          flashMode={flashData?.mode}
          zoomMode='on'
          focusMode='on'
          torchMode={torchMode ? 'on' : 'off'}
          onOrientationChange={(e) => {
            console.log('orientationChange', e.nativeEvent);
          }}
          // ratioOverlay={ratios[ratioArrayPosition]}
          laserColor="red"
          frameColor="white"
          scanBarcode
          showFrame
          onReadCode={(event) => {
            Vibration.vibrate(100);
            setBarcode(event.nativeEvent.codeStringValue);
            console.log('barcode', event.nativeEvent.codeStringValue);
          }}
        />
      </View>
      {/* {ratios.length > 0 && (
        <View style={{ flex: 1, flexDirection: 'column', justifyContent: 'flex-end' }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', paddingRight: 10, paddingLeft: 20 }}>
            <Text style={styles.ratioBestText}>Your images look best at a {ratios[0] || ''} ratio</Text>
            <TouchableOpacity
              style={{ flex: 1, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', padding: 8 }}
              onPress={() => onRatioButtonPressed()}
            >
              <Text style={styles.ratioText}>{ratios[ratioArrayPosition]}</Text>
            </TouchableOpacity>
          </View>
        </View>
      )} */}
      <SafeAreaView style={styles.bottomButtons}>
        <View style={styles.bottomButtonsInner}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={() => {
              onBack();
            }}
          >
            <Text style={styles.textStyle}>Back</Text>
          </TouchableOpacity>
          <View style={styles.captureButtonContainer}>
            <TouchableOpacity onPress={() => onCaptureImagePressed()}>
              <Image source={require('../images/cameraButton.png')} />
            </TouchableOpacity>
          </View>
          <View style={styles.rightBottomArea}>
            <Text numberOfLines={1} style={styles.textStyle}>
              {barcode}
            </Text>
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
};

export default BarcodeExample;

const styles = StyleSheet.create({
  top: {
    zIndex: 10,
  },
  topButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingVertical: 10,

    // borderColor: 'yellow',
    // position: 'relative',
  },
  flashMode: {
    position: 'absolute',
    left: 20,
    top: 10,
    bottom: 0,
  },
  switchCamera: {},
  torch: {
    position: 'absolute',
    right: 20,
    top: 10,
    bottom: 0,
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
    left: 20,
    top: 0,
    bottom: 0,
    justifyContent: 'center',
    zIndex: 10,
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
  },
  textStyle: {
    color: 'white',
    fontSize: 20,
  },
  // ratioBestText: {
  //   color: 'white',
  //   fontSize: 18,
  // },
  // ratioText: {
  //   color: '#ffc233',
  //   fontSize: 18,
  // },
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
});
