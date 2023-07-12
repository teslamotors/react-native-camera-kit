import { CameraApi, FlashMode, FocusMode, ZoomMode, TorchMode, CameraType } from './types';
import { Orientation } from './index';

export type OnReadCodeData = {
  nativeEvent: {
    codeStringValue: string;
  };
};

export type OnOrientationChangeData = {
  nativeEvent: {
    orientation: Orientation;
  };
};

export interface CameraProps {
  ref?: LegacyRef<Component<CameraApi, {}, any>>;
  style?: StyleProp<ViewStyle>;
  // Behavior
  flashMode?: FlashMode;
  focusMode?: FocusMode;
  zoomMode?: ZoomMode;
  torchMode?: TorchMode;
  cameraType?: CameraType;
  onOrientationChange?: (event: OnOrientationChangeData) => void;
  // Barcode only
  scanBarcode?: boolean;
  showFrame?: boolean;
  laserColor?: number | string;
  frameColor?: number | string;
  onReadCode?: (event: OnReadCodeData) => void;
  // Specific to iOS
  ratioOverlay?: string;
  ratioOverlayColor?: number | string;
  resetFocusTimeout?: number;
  resetFocusWhenMotionDetected?: boolean;
  scanThrottleDelay: number;
}

declare const Camera: React.FC<CameraProps>;

export default Camera;
