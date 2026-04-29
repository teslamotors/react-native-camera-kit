import type React from 'react';
import { useCallback, useState, useRef, useEffect } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, Image, Animated, ScrollView, type LayoutChangeEvent } from 'react-native';
import Camera from '../../src/Camera';
import { type CameraApi, CameraType, type CaptureData } from '../../src/types';
import { Orientation } from '../../src';
import {
  type FaceData,
  type FaceDetectionInstallState,
  type OnFaceDetectedData,
  type OnFaceDetectionInstallStatusData,
} from '../../src/CameraProps';
import SafeAreaView from './SafeAreaView';

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

function median(values: number[]): number {
  const sortedValues = [...values].sort((a, b) => a - b);
  const half = Math.floor(sortedValues.length / 2);
  return sortedValues.length % 2 ? sortedValues[half] : (sortedValues[half - 1] + sortedValues[half]) / 2;
}

// "Facing the camera" = head pointed within 15 degrees
// AND the face center is within 20% of the preview center. Bounds are normalized 0–1 with
// top-left origin, so the preview center is (0.5, 0.5) and faceCenter = corner + size/2.
const FACING_THRESHOLD_DEG = 15;
const CENTERING_TOLERANCE = 0.2;
function isFacingCamera(face: FaceData): boolean {
  const orientationOk = Math.abs(face.yaw) < FACING_THRESHOLD_DEG && Math.abs(face.pitch) < FACING_THRESHOLD_DEG;
  const centerX = face.boundsX + face.boundsWidth / 2;
  const centerY = face.boundsY + face.boundsHeight / 2;
  const centeredOk = Math.abs(centerX - 0.5) < CENTERING_TOLERANCE && Math.abs(centerY - 0.5) < CENTERING_TOLERANCE;
  return orientationOk && centeredOk;
}

function CaptureButton({ onPress, children }: { onPress: () => void; children?: React.ReactNode }) {
  const w = 80;
  const brdW = 4;
  const spc = 6;
  const cInner = 'white';
  const cOuter = 'white';
  return (
    <TouchableOpacity onPress={onPress} style={{ width: w, height: w }}>
      <View
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: w,
          height: w,
          borderColor: cOuter,
          borderWidth: brdW,
          borderRadius: w / 2,
        }}
      />
      <View
        style={{
          position: 'absolute',
          left: brdW + spc,
          top: brdW + spc,
          width: w - (brdW + spc) * 2,
          height: w - (brdW + spc) * 2,
          backgroundColor: cInner,
          borderRadius: (w - (brdW + spc) * 2) / 2,
        }}
      />
      {children}
    </TouchableOpacity>
  );
}

function FaceFrame({ face, layout }: { face: FaceData; layout: { width: number; height: number } }) {
  if (!layout.width || !layout.height) return null;
  const facing = isFacingCamera(face);
  const color = facing ? '#22c55e' : '#facc15';
  const left = face.boundsX * layout.width;
  const top = face.boundsY * layout.height;
  const height = face.boundsHeight * layout.height;
  return (
    <>
      <View
        pointerEvents="none"
        style={[
          styles.faceFrame,
          {
            left,
            top,
            width: face.boundsWidth * layout.width,
            height,
            borderColor: color,
          },
        ]}
      />
      <View pointerEvents="none" style={[styles.faceIdBadge, { left, top: top + height + 4, borderColor: color }]}>
        <Text style={[styles.faceIdText, { color }]}>ID {face.id}</Text>
      </View>
    </>
  );
}

function FaceStats({ faces }: { faces: FaceData[] }) {
  const face = faces[0];
  return (
    <View style={styles.statsBox} pointerEvents="none">
      <Text style={styles.statsText}>Faces: {faces.length}</Text>
      {face && (
        <>
          <Text style={styles.statsText}>Yaw: {face.yaw.toFixed(1)}°</Text>
          <Text style={styles.statsText}>Pitch: {face.pitch.toFixed(1)}°</Text>
          <Text style={styles.statsText}>Roll: {face.roll.toFixed(1)}°</Text>
          <Text style={styles.statsText}>Facing: {isFacingCamera(face) ? 'yes' : 'no'}</Text>
          <Text style={styles.statsText}>
            Box: {face.boundsX.toFixed(2)},{face.boundsY.toFixed(2)} {face.boundsWidth.toFixed(2)}×
            {face.boundsHeight.toFixed(2)}
          </Text>
        </>
      )}
    </View>
  );
}

const CameraExample = ({ onBack, stress }: { onBack: () => void; stress?: boolean }) => {
  const cameraRef = useRef<CameraApi>(null);
  const [currentFlashArrayPosition, setCurrentFlashArrayPosition] = useState(0);
  const [captureImages, setCaptureImages] = useState<CaptureData[]>([]);
  const [flashData, setFlashData] = useState(flashArray[currentFlashArrayPosition]);
  const [torchMode, setTorchMode] = useState(false);
  const [captured, setCaptured] = useState(false);
  const [cameraType, setCameraType] = useState(CameraType.Back);
  const [showImageUri, setShowImageUri] = useState<string>('');
  const [zoom, setZoom] = useState<number | undefined>();
  const [orientationAnim] = useState(new Animated.Value(3));
  const [resize, setResize] = useState<'contain' | 'cover'>('contain');
  const [faceDetection, setFaceDetection] = useState(false);
  const [faces, setFaces] = useState<FaceData[]>([]);
  const [cameraLayout, setCameraLayout] = useState({ width: 0, height: 0 });
  const [faceInstallState, setFaceInstallState] = useState<FaceDetectionInstallState | null>(null);

  useEffect(() => {
    if (!faceDetection) setFaces([]);
  }, [faceDetection]);

  // zoom to random positions every 10ms:
  useEffect(() => {
    if (stress !== true) return;
    const interval = setInterval(() => {
      setZoom(Math.random() * 10);
    }, 500);
    return () => clearInterval(interval);
  }, [stress]);

  // iOS will error out if capturing too fast,
  // so block capturing until the current capture is done
  // This also minimizes issues of delayed capturing
  const isCapturing = useRef(false);

  const numberOfImagesTaken = () => {
    const numberTook = captureImages.length;
    if (numberTook >= 2) {
      return numberTook;
    }
    if (captured) {
      return '1';
    }
    return '';
  };

  const onSwitchCameraPressed = () => {
    const direction = cameraType === CameraType.Back ? CameraType.Front : CameraType.Back;
    setCameraType(direction);
    setZoom(1); // When changing camera type, reset to default zoom for that camera
  };

  const onSetFlash = () => {
    const newPosition = (currentFlashArrayPosition + 1) % 3;
    setCurrentFlashArrayPosition(newPosition);
    setFlashData(flashArray[newPosition]);
  };

  const onSetResize = () => {
    if (resize === 'contain') {
      setResize('cover');
    } else {
      setResize('contain');
    }
  };

  const onSetTorch = () => {
    setTorchMode(!torchMode);
  };

  const onSetFaceDetection = () => {
    setFaceDetection(!faceDetection);
  };

  const onFaceDetected = useCallback((e: OnFaceDetectedData) => {
    const next = e.nativeEvent.faces;
    setFaces((prev) => (prev.length === 0 && next.length === 0 ? prev : next));
  }, []);

  const onCameraLayout = useCallback((e: LayoutChangeEvent) => {
    const width = e.nativeEvent.layout.width;
    const height = e.nativeEvent.layout.height;
    setCameraLayout({ width, height });
  }, []);

  const onFaceDetectionInstallStatus = useCallback((e: OnFaceDetectionInstallStatusData) => {
    setFaceInstallState(e.nativeEvent.state);
  }, []);

  const onCaptureImagePressed = async () => {
    const times: number[] = [];
    for (let i = 1; i <= 5; i++) {
      const start = Date.now();
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
      setCaptureImages((prev) => [...prev, image]);
      console.log('image', image);
      times.push(Date.now() - start);
    }
    console.log(`median capture time: ${median(times)}ms`);
  };

  // Counter-rotate the icons to indicate the actual orientation of the captured photo.
  // For this example, it'll behave incorrectly since UI orientation is allowed (and already-counter rotates the entire screen)
  // For real phone apps, lock your UI orientation using a library like 'react-native-orientation-locker'
  const rotateUi = true;
  const uiRotation = orientationAnim.interpolate({
    inputRange: [1, 4],
    outputRange: ['180deg', '-90deg'],
  });
  const uiRotationStyle = rotateUi ? { transform: [{ rotate: uiRotation }] } : undefined;

  function rotateUiTo(rotationValue: number) {
    Animated.timing(orientationAnim, {
      toValue: rotationValue,
      useNativeDriver: true,
      duration: 200,
      isInteraction: false,
    }).start();
  }

  return (
    <View style={styles.screen}>
      <SafeAreaView style={styles.topButtons}>
        {flashData.image && (
          <TouchableOpacity style={styles.topButton} onPress={onSetFlash}>
            <Animated.Image
              source={flashData.image}
              resizeMode="contain"
              style={[styles.topButtonImg, uiRotationStyle]}
            />
          </TouchableOpacity>
        )}

        <TouchableOpacity style={styles.topButton} onPress={onSwitchCameraPressed}>
          <Animated.Image
            source={require('../images/cameraFlipIcon.png')}
            resizeMode="contain"
            style={[styles.topButtonImg, uiRotationStyle]}
          />
        </TouchableOpacity>

        <TouchableOpacity style={styles.topButton} onPress={() => setZoom(1)}>
          <Animated.Text style={[styles.zoomFactor, uiRotationStyle]}>
            {zoom ? Number(zoom).toFixed(1) : '??'}x
          </Animated.Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.topButton} onPress={onSetTorch}>
          <Animated.Image
            source={torchMode ? require('../images/torchOn.png') : require('../images/torchOff.png')}
            resizeMode="contain"
            style={[styles.topButtonImg, uiRotationStyle]}
          />
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.topButton, faceDetection && styles.topButtonActive]}
          onPress={onSetFaceDetection}>
          <Animated.Image
            source={require('../images/faceDetection.png')}
            resizeMode="contain"
            style={[styles.topButtonImg, uiRotationStyle]}
          />
        </TouchableOpacity>

        <TouchableOpacity style={styles.topButton} onPress={onSetResize}>
          <Animated.Image
            source={require('../images/resize.png')}
            resizeMode="contain"
            style={[styles.topButtonImg, uiRotationStyle]}
          />
        </TouchableOpacity>
      </SafeAreaView>

      <View style={styles.cameraContainer}>
        {showImageUri ? (
          <ScrollView maximumZoomScale={10} contentContainerStyle={{ flexGrow: 1 }}>
            <Image source={{ uri: showImageUri }} style={styles.cameraPreview} />
          </ScrollView>
        ) : (
          <Camera
            ref={cameraRef}
            style={styles.cameraPreview}
            cameraType={cameraType}
            flashMode={flashData?.mode}
            resizeMode={resize}
            resetFocusWhenMotionDetected
            zoom={zoom}
            maxZoom={10}
            onZoom={(e) => {
              console.log('zoom', e.nativeEvent.zoom);
              setZoom(e.nativeEvent.zoom);
            }}
            torchMode={torchMode ? 'on' : 'off'}
            shutterPhotoSound
            maxPhotoQualityPrioritization="speed"
            faceDetectionEnabled={faceDetection}
            faceDetectionThrottleMs={50}
            onLayout={onCameraLayout}
            onFaceDetected={onFaceDetected}
            onFaceDetectionInstallStatus={onFaceDetectionInstallStatus}
            onCaptureButtonPressIn={() => {
              console.log('capture button pressed in');
            }}
            onCaptureButtonPressOut={() => {
              console.log('capture button released');
              onCaptureImagePressed();
            }}
            onOrientationChange={(e) => {
              // We recommend locking the camera UI to portrait (using a different library)
              // and rotating the UI elements counter to the orientation
              // However, we include onOrientationChange so you can match your UI to what the camera does
              switch (e.nativeEvent.orientation) {
                case Orientation.PORTRAIT_UPSIDE_DOWN:
                  console.log('orientationChange', 'PORTRAIT_UPSIDE_DOWN');
                  rotateUiTo(1);
                  break;
                case Orientation.LANDSCAPE_LEFT:
                  console.log('orientationChange', 'LANDSCAPE_LEFT');
                  rotateUiTo(2);
                  break;
                case Orientation.PORTRAIT:
                  console.log('orientationChange', 'PORTRAIT');
                  rotateUiTo(3);
                  break;
                case Orientation.LANDSCAPE_RIGHT:
                  console.log('orientationChange', 'LANDSCAPE_RIGHT');
                  rotateUiTo(4);
                  break;
                default:
                  console.log('orientationChange', e.nativeEvent);
                  break;
              }
            }}
          />
        )}

        {faceDetection && !showImageUri && faces.length > 0 && (
          <>
            {faces.map((face) => (
              <FaceFrame key={face.id} face={face} layout={cameraLayout} />
            ))}
            <FaceStats faces={faces} />
          </>
        )}

        {faceDetection && faceInstallState && faceInstallState !== 'ready' && (
          <View style={styles.installBanner} pointerEvents="none">
            <Text style={styles.installText}>
              {faceInstallState === 'pending'
                ? 'Preparing face detection…'
                : faceInstallState === 'downloading'
                ? 'Downloading face detection…'
                : faceInstallState === 'installing'
                ? 'Installing face detection…'
                : 'Face detection unavailable'}
            </Text>
          </View>
        )}
      </View>

      <SafeAreaView style={styles.bottomButtons}>
        <View style={styles.backBtnContainer}>
          <TouchableOpacity onPress={onBack}>
            <Animated.Text style={[styles.backTextStyle, uiRotationStyle]}>Back</Animated.Text>
          </TouchableOpacity>
        </View>

        <View style={styles.captureButtonContainer}>
          <CaptureButton onPress={onCaptureImagePressed}>
            <View style={styles.textNumberContainer}>
              <Text>{numberOfImagesTaken()}</Text>
            </View>
          </CaptureButton>
        </View>

        <View style={styles.thumbnailContainer}>
          {captureImages.length > 0 && (
            <TouchableOpacity
              onPress={() => {
                if (showImageUri) {
                  setShowImageUri('');
                } else {
                  setShowImageUri(captureImages[captureImages.length - 1].uri);
                }
              }}>
              <Image source={{ uri: captureImages[captureImages.length - 1].uri }} style={styles.thumbnail} />
            </TouchableOpacity>
          )}
        </View>
      </SafeAreaView>
    </View>
  );
};

export default CameraExample;

const styles = StyleSheet.create({
  screen: {
    height: '100%',
    backgroundColor: 'black',
  },
  topButtons: {
    margin: 10,
    zIndex: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  topButton: {
    backgroundColor: '#222',
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
  },
  topButtonActive: {
    backgroundColor: '#1e7eff',
  },
  topButtonImg: {
    margin: 10,
    width: 24,
    height: 24,
    tintColor: 'white',
  },
  cameraContainer: {
    justifyContent: 'center',
    flex: 1,
  },
  cameraPreview: {
    width: '100%',
    height: '100%',
  },
  bottomButtons: {
    margin: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  backBtnContainer: {
    flex: 1,
    alignItems: 'flex-start',
  },
  backTextStyle: {
    padding: 10,
    color: 'white',
    fontSize: 20,
  },
  captureButtonContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
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
  zoomFactor: {
    color: '#ffffff',
  },
  thumbnailContainer: {
    flex: 1,
    alignItems: 'flex-end',
    justifyContent: 'center',
  },
  thumbnail: {
    width: 48,
    height: 48,
    borderRadius: 4,
    marginEnd: 10,
  },
  faceFrame: {
    position: 'absolute',
    borderWidth: 3,
    borderRadius: 8,
  },
  faceIdBadge: {
    position: 'absolute',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
  },
  faceIdText: {
    fontSize: 11,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  statsBox: {
    position: 'absolute',
    top: 10,
    right: 25,
    backgroundColor: 'rgba(0,0,0,0.55)',
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 6,
  },
  statsText: {
    color: 'white',
    fontSize: 11,
    fontVariant: ['tabular-nums'],
  },
  installBanner: {
    position: 'absolute',
    top: 30,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(0,0,0,0.7)',
    padding: 12,
    borderRadius: 6,
  },
  installText: {
    color: 'white',
    fontSize: 13,
    textAlign: 'center',
  },
});
