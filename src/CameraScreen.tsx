import _ from 'lodash';
import React from 'react';
import {
  Dimensions, Image,


  ImageSourcePropType, Platform,
  SafeAreaView, StyleSheet,
  Text,

  TouchableOpacity, View,
} from 'react-native';
import Camera from './PlatformCamera';
import { FlashMode } from './PlatformCamera/common-types';

const { width, height } = Dimensions.get('window');

export enum CameraType {
  Front = 'front',
  Back = 'back',
}

export type IconType = ImageSourcePropType | React.ReactElement;

export type FlashDataType = {
  [key in FlashMode]: IconType;
};

export interface CameraScreenProps {
  actions?: { rightButtonText: string; leftButtonText: string };
  ratioOverlay?: string;
  ratioOverlayColor?: string;
  allowCaptureRetake?: boolean;
  cameraRatioOverlay?: any;
  showCapturedImageCount?: boolean;
  captureButtonImage?: IconType;
  cameraFlipImage?: IconType;
  hideControls?: boolean;
  showFrame?: boolean;
  scanBarcode?: boolean;
  laserColor?: string;
  frameColor?: string;
  surfaceColor?: string;
  torchOnImage?: IconType;
  torchOffImage?: IconType;
  flashData?: FlashDataType;
  focusMode?: 'on' | 'off';
  zoomMode?: 'on' | 'off';
  onReadCode?: (data: { codeStringValue: string }) => void;
  onBottomButtonPressed?: (any) => void;
}

let currentFlashArrayPosition = 0;
let cameraRef: any;

const CameraScreen: React.FC<CameraScreenProps> = ({
  showFrame,
  focusMode = 'on',
  zoomMode = 'on',
  flashData,
  scanBarcode = false,
  laserColor = 'red',
  frameColor = 'yellow',
  surfaceColor = 'blue',
  captureButtonImage,
  showCapturedImageCount,
  allowCaptureRetake = false,
  cameraRatioOverlay,
  torchOnImage,
  torchOffImage,
  hideControls,
  cameraFlipImage,
  onBottomButtonPressed,
  onReadCode,
  ...props}) => {
  const [imageCaptured, setImageCaptured] = React.useState<any>(undefined);
  const [torchMode, setTorchMode] = React.useState<boolean>(false);
  const [cameraType, setCameraType] = React.useState<CameraType>(CameraType.Back);
  const [captureImages, setCaptureImages] = React.useState<any[]>([]);
  const [captured, setCaptured] = React.useState<boolean>(false);
  const [ratios, setRatios] = React.useState<string[]>(cameraRatioOverlay?.ratios ?? []);
  const [ratioArrayPosition, setRatioArrayPosition] = React.useState(
    (cameraRatioOverlay?.ratios ?? 0) > 0 ? 0 : -1,
  );

  const isCaptureRetakeMode = () => !!(allowCaptureRetake && !_.isUndefined(imageCaptured));

  const renderTorchButton = () => {
    const _component = torchMode ? torchOnImage : torchOffImage;
    return (
      !isCaptureRetakeMode() && (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => setTorchMode(!torchMode)}>
          {React.isValidElement(_component) ? (
            <View style={{ flex: 1, justifyContent: 'center' }}>{_component}</View>
          ) : (
            <Image style={{ flex: 1, justifyContent: 'center' }} source={_component} resizeMode="contain" />
          )}
        </TouchableOpacity>
      )
    );
  };

  const renderFlashButton = () => {
    if (!flashData) {
      return undefined;
    }

    const _component =
      currentFlashArrayPosition === 0
        ? flashData?.auto
        : currentFlashArrayPosition === 1
          ? flashData?.on
          : flashData?.off;

    if (!_component) return undefined;

    return (
      !isCaptureRetakeMode() && (
        <TouchableOpacity
          style={{ paddingHorizontal: 15 }}
          onPress={() => {
            currentFlashArrayPosition = (currentFlashArrayPosition + 1) % 3;
          }}
        >
          {React.isValidElement(_component) ? (
            <View style={{ flex: 1, justifyContent: 'center' }}>{_component}</View>
          ) : (
            <Image style={{ flex: 1, justifyContent: 'center' }} source={_component} resizeMode="contain" />
          )}
        </TouchableOpacity>
      )
    );
  };

  const renderSwitchCameraButton = () =>
    cameraFlipImage &&
    !isCaptureRetakeMode() && (
      <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={onSwitchCameraPressed}>
        {React.isValidElement(cameraFlipImage) ? (
          <View style={{ flex: 1, justifyContent: 'center' }}>{cameraFlipImage}</View>
        ) : (
          <Image style={{ flex: 1, justifyContent: 'center' }} source={cameraFlipImage} resizeMode="contain" />
        )}
      </TouchableOpacity>
    );

  const renderTopButtons = () =>
    !hideControls && (
      <SafeAreaView style={styles.topButtons}>
        {renderFlashButton()}
        {renderSwitchCameraButton()}
        {renderTorchButton()}
      </SafeAreaView>
    );

  const renderCamera = () => (
    <View style={styles.cameraContainer}>
      {isCaptureRetakeMode() ? (
        <Image style={{ flex: 1, justifyContent: 'flex-end' }} source={{ uri: imageCaptured.uri }} />
      ) : (
        Camera &&
        <Camera
          ref={cameraRef}
          style={{ flex: 1, justifyContent: 'flex-end' }}
          cameraType={cameraType}
          flashMode={
            currentFlashArrayPosition === 0
              ? FlashMode.auto
              : currentFlashArrayPosition === 1
                ? FlashMode.on
                : FlashMode.off
          }
          torchMode={torchMode ? 'on' : 'off'}
          focusMode={focusMode}
          zoomMode={zoomMode}
          ratioOverlay={ratios[ratioArrayPosition]}
          saveToCameraRoll={!allowCaptureRetake}
          showFrame={showFrame}
          scanBarcode={scanBarcode}
          laserColor={laserColor}
          frameColor={frameColor}
          surfaceColor={surfaceColor}
          onReadCode={onReadCode}
        />
      )}
    </View>
  );

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

  const renderCaptureButton = () => {
    return (
      captureButtonImage &&
      !isCaptureRetakeMode() && (
        <View style={styles.captureButtonContainer}>
          <TouchableOpacity onPress={onCaptureImagePressed}>
            {React.isValidElement(captureButtonImage) ? (
              <View style={{ flex: 1, justifyContent: 'center' }}>{captureButtonImage}</View>
            ) : (
              <Image source={captureButtonImage} resizeMode="contain" />
            )}
            {showCapturedImageCount && (
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
      return undefined;
    }
    return (
      <View style={{ flex: 1, flexDirection: 'column', justifyContent: 'flex-end' }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', paddingRight: 10, paddingLeft: 20 }}>
          <Text style={styles.ratioBestText}>Your images look best at a {ratios[0] || ''} ratio</Text>
          <TouchableOpacity
            style={{ flex: 1, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', padding: 8 }}
            onPress={() => onRatioButtonPressed()}
          >
            <Text style={styles.ratioText}>{cameraRatioOverlay}</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const sendBottomButtonPressedAction = (type, captureRetakeMode, image) => {
    onBottomButtonPressed?.({ type, captureImages: captureImages, captureRetakeMode, image });
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

  const onSwitchCameraPressed = () => {
    const direction = cameraType === CameraType.Back ? CameraType.Front : CameraType.Back;
    setCameraType(direction);
  };

  const onCaptureImagePressed = async () => {
    const image = await cameraRef.current?.capture();

    if (allowCaptureRetake) {
      setImageCaptured(image);
    } else {
      if (image) {
        setCaptured(true);
        setImageCaptured(image);
        setCaptureImages(_.concat(captureImages, image));
      }
      sendBottomButtonPressedAction('capture', false, image);
    }
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

export default CameraScreen;
