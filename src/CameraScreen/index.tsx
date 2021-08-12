import _ from 'lodash';
import React, { useEffect, useRef, useState } from 'react';
import {
  Dimensions,
  Image,
  ImageSourcePropType,
  Platform,
  SafeAreaView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { Camera } from '..';
import FlashButton from './FlashButton';
import SwitchCameraButton from './SwitchCameraButton';
import TorchButton from './TorchButton';
import { CameraType, IFlashMode, IFocusMode, IImage, IReadCodeEvent, ITorchMode, IZoomMode } from '../types/camera';

const { width, height } = Dimensions.get('window');

export type IIconType = ImageSourcePropType | React.ReactElement;
export type IFlashImageData = {
  [key in IFlashMode]: IIconType;
};

export type ITorchImageData = {
  [key in ITorchMode]: IIconType;
};

type IRatio = string;

type IBottomButtonPressed = {
  type: 'capture';
  captureRetakeMode: boolean;
  image?: IImage;
  captureImages: IImage[];
};

interface IProps {
  allowCaptureRetake?: boolean;
  cameraRatioOverlay?: {
    ratios: IRatio[];
  };

  flashImages?: IFlashImageData;
  torchImages?: ITorchImageData;

  ratioOverlay?: string;
  ratioOverlayColor?: string;
  showCapturedImageCount?: boolean;
  captureButtonImage?: IIconType;
  cameraFlipImage?: IIconType;
  hideControls?: boolean;
  showFrame?: boolean;
  scanBarcode?: boolean;
  laserColor?: string;
  frameColor?: string;
  onReadCode?: IReadCodeEvent;
  onBottomButtonPressed?: (event: IBottomButtonPressed) => void;

  focusMode?: IFocusMode;
  zoomMode?: IZoomMode;

  actions: {
    rightButtonText: string;
    leftButtonText: string;
  };
}

const CameraScreen: React.FC<IProps> = ({
  cameraRatioOverlay,
  allowCaptureRetake,
  hideControls = false,
  showFrame = false,
  scanBarcode = false,
  laserColor = 'red',
  frameColor = 'white',
  focusMode = 'on',
  zoomMode = 'on',
  flashImages,
  torchImages,
  ...props
}) => {
  const camera = useRef<any>(null);
  const [captureImages, setCaptureImages] = useState<IImage[]>([]);
  const [torchMode, setTorchMode] = useState<ITorchMode>('off');
  const [ratios, setRatios] = useState<IRatio[]>([]);
  const [ratioArrayPosition, setRatioArrayPosition] = useState(-1);
  const [imageCaptured, setImageCaptured] = useState<IImage | undefined>(undefined);
  const [captured, setCaptured] = useState(false);
  const [cameraType, setCameraType] = useState(CameraType.Back);
  const [flashArrayPosition, setFlashArrayPosition] = useState(0);

  useEffect(() => {
    let result: any[] = [];
    if (cameraRatioOverlay) {
      result = cameraRatioOverlay.ratios || [];
    }
    setRatios(result || []);
    setRatioArrayPosition(result.length > 0 ? 0 : -1);
  }, [cameraRatioOverlay]);

  const isCaptureRetakeMode = () => {
    return !!(allowCaptureRetake && !_.isUndefined(imageCaptured));
  };

  const onSetFlash = () => setFlashArrayPosition((prev) => (prev + 1) % 3);
  const onSetTorch = () => setTorchMode((prev) => (prev === 'on' ? 'off' : 'on'));

  const onSwitchCameraPressed = () =>
    setCameraType((prev) => (prev === CameraType.Back ? CameraType.Front : CameraType.Back));

  const renderTopButtons = () => {
    if (hideControls) return;
    return (
      <SafeAreaView style={styles.topButtons}>
        {!isCaptureRetakeMode() && (
          <>
            <FlashButton index={flashArrayPosition} flashImages={flashImages} onPress={onSetFlash} />
            <SwitchCameraButton cameraFlipImage={props.cameraFlipImage} onPress={onSwitchCameraPressed} />
            <TorchButton torchMode={torchMode} data={torchImages} onPress={onSetTorch} />
          </>
        )}
      </SafeAreaView>
    );
  };

  const renderCamera = () => {
    return (
      <View style={styles.cameraContainer}>
        {isCaptureRetakeMode() ? (
          <Image style={{ flex: 1, justifyContent: 'flex-end' }} source={{ uri: imageCaptured?.uri }} />
        ) : (
          <Camera
            ref={camera}
            style={{ flex: 1, justifyContent: 'flex-end' }}
            cameraType={cameraType}
            flashMode={flashArrayPosition === 0 ? 'auto' : flashArrayPosition === 1 ? 'on' : 'off'}
            torchMode={torchMode ? 'on' : 'off'}
            focusMode={focusMode}
            zoomMode={zoomMode}
            ratioOverlay={ratios[ratioArrayPosition]}
            saveToCameraRoll={!allowCaptureRetake}
            showFrame={showFrame}
            scanBarcode={scanBarcode}
            laserColor={laserColor}
            frameColor={frameColor}
            onReadCode={(event) => props.onReadCode?.(event.nativeEvent.codeStringValue)}
            resetFocusWhenMotionDetected={false}
          />
        )}
      </View>
    );
  };

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

  const onCaptureImagePressed = async () => {
    const image = (await camera.current?.capture()) as IImage;

    if (allowCaptureRetake) {
      setImageCaptured(image);
    } else {
      if (image) {
        setCaptured(true);
        setImageCaptured(image);
        setCaptureImages((prev) => [...prev, image]);
      }
      sendBottomButtonPressedAction('capture', false, image);
    }
  };

  const renderCaptureButton = () => {
    return (
      props.captureButtonImage &&
      !isCaptureRetakeMode() && (
        <View style={styles.captureButtonContainer}>
          <TouchableOpacity onPress={onCaptureImagePressed}>
            {React.isValidElement(props.captureButtonImage) ? (
              <View style={{ flex: 1, justifyContent: 'center' }}>{props.captureButtonImage}</View>
            ) : (
              <Image source={props.captureButtonImage} resizeMode="contain" />
            )}
            {props.showCapturedImageCount && (
              <View style={styles.textNumberContainer}>
                <Text>{numberOfImagesTaken()}</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      )
    );
  };

  const renderRatioStrip = () => {
    if (ratios.length === 0 || hideControls) {
      return null;
    }
    return (
      <View style={{ flex: 1, flexDirection: 'column', justifyContent: 'flex-end' }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', paddingRight: 10, paddingLeft: 20 }}>
          <Text style={styles.ratioBestText}>Your images look best at a {ratios[0] || ''} ratio</Text>
          <TouchableOpacity
            style={{ flex: 1, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', padding: 8 }}
            onPress={onRatioButtonPressed}
          >
            <Text style={styles.ratioText}>{cameraRatioOverlay}</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const sendBottomButtonPressedAction = (type, captureRetakeMode, image) => {
    if (props.onBottomButtonPressed) {
      props.onBottomButtonPressed({ type, captureImages: captureImages, captureRetakeMode, image });
    }
  };

  const onButtonPressed = (type) => {
    const captureRetakeMode = isCaptureRetakeMode();
    if (captureRetakeMode) {
      if (type === 'left') {
        setImageCaptured(undefined);
      }
    } else {
      sendBottomButtonPressedAction(type, captureRetakeMode, null);
    }
  };

  const renderBottomButton = (type) => {
    const showButton = true;
    if (showButton) {
      const buttonNameSuffix = isCaptureRetakeMode() ? 'CaptureRetakeButtonText' : 'ButtonText';
      const buttonText = _(props).get(`actions.${type}${buttonNameSuffix}`);
      return (
        <TouchableOpacity
          style={[styles.bottomButton, { justifyContent: type === 'left' ? 'flex-start' : 'flex-end' }]}
          onPress={() => onButtonPressed(type)}
        >
          <Text style={styles.textStyle}>{buttonText}</Text>
        </TouchableOpacity>
      );
    } else {
      return <View style={styles.bottomContainerGap} />;
    }
  };

  const renderBottomButtons = () => {
    return (
      !hideControls && (
        <SafeAreaView style={[styles.bottomButtons, { backgroundColor: '#ffffff00' }]}>
          {renderBottomButton('left')}
          {renderCaptureButton()}
        </SafeAreaView>
      )
    );
  };

  const onRatioButtonPressed = () => {
    const newRatiosArrayPosition = (ratioArrayPosition + 1) % ratios.length;
    setRatioArrayPosition(newRatiosArrayPosition);
  };

  return (
    <View style={{ flex: 1, backgroundColor: 'black' }} {...props}>
      {Platform.OS === 'android' && renderCamera()}
      {renderTopButtons()}
      {Platform.OS !== 'android' && renderCamera()}
      {renderRatioStrip()}
      {Platform.OS === 'android' && <View style={styles.gap} />}
      {renderBottomButtons()}
    </View>
  );
};

export default CameraScreen;

const styles = StyleSheet.create({
  bottomButtons: {
    flex: 2,
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 14,
  },
  textStyle: {
    color: 'white',
    fontSize: 20,
  },
  ratioBestText: {
    color: 'white',
    fontSize: 18,
  },
  ratioText: {
    color: '#ffc233',
    fontSize: 18,
  },
  topButtons: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: 8,
    paddingBottom: 0,
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
        flex: 10,
        flexDirection: 'column',
      },
    }),
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
  bottomButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
  },
  bottomContainerGap: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    padding: 10,
  },
  gap: {
    flex: 10,
    flexDirection: 'column',
  },
});
