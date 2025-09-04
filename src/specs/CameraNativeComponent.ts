import type {
  ViewProps,
  ColorValue,
  HostComponent,
} from 'react-native';
import type {
  DirectEventHandler,
  Double,
  Float,
  Int32,
  WithDefault
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

type OnReadCodeData = {
    codeStringValue: string;
    codeFormat: string;
};

type OnOrientationChangeData = {
    orientation: Int32;
};

type OnZoom = {
    zoom: Double;
}

// We have to use -1 until RN Fabric (New Arch for view components) supports optional values:
// https://github.com/facebook/react-native/issues/49920#issuecomment-3237917813
export interface NativeProps extends ViewProps {
  flashMode?: string;
  focusMode?: string;
  maxPhotoQualityPrioritization?: string;
  zoomMode?: string;
  zoom?: WithDefault<Double, -1>;
  maxZoom?: WithDefault<Double, -1>;
  torchMode?: string;
  cameraType?: string;
  scanBarcode?: boolean;
  showFrame?: boolean;
  laserColor?: ColorValue;
  frameColor?: ColorValue;
  ratioOverlay?: string;
  ratioOverlayColor?: ColorValue;
  resetFocusTimeout?: WithDefault<Int32, -1>;
  resetFocusWhenMotionDetected?: boolean;
  resizeMode?: string;
  scanThrottleDelay?: WithDefault<Int32, -1>;
  barcodeFrameSize?: { width?: WithDefault<Float, 300>; height?: WithDefault<Float, 150> };
  shutterPhotoSound?: boolean;
  onOrientationChange?: DirectEventHandler<OnOrientationChangeData>;
  onZoom?: DirectEventHandler<OnZoom>;
  onError?: DirectEventHandler<{errorMessage: string }>;
  onReadCode?: DirectEventHandler<OnReadCodeData>;
  onCaptureButtonPressIn?: DirectEventHandler<{}>;
  onCaptureButtonPressOut?: DirectEventHandler<{}>;

  // not mentioned in props but available on the native side
  shutterAnimationDuration?: WithDefault<Int32, -1>;
  outputPath?: string;
  onPictureTaken?: DirectEventHandler<{uri: string}>;
}

export default codegenNativeComponent<NativeProps>('CKCamera') as HostComponent<NativeProps>;
