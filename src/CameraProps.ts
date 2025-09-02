import { type ViewProps } from 'react-native';
import {
  CameraType,
  type FlashMode,
  type FocusMode,
  type ZoomMode,
  type TorchMode,
  type ResizeMode,
  type CodeFormat,
} from './types';
import { Orientation } from './index';

export type OnReadCodeData = {
  nativeEvent: {
    codeStringValue: string;
    codeFormat: CodeFormat;
  };
};

export type OnOrientationChangeData = {
  nativeEvent: {
    orientation: typeof Orientation[keyof typeof Orientation];
  };
};

export type OnZoom = {
  nativeEvent: {
    zoom: number;
  };
}

export interface CameraProps extends ViewProps {
  // Behavior
  flashMode?: FlashMode;
  focusMode?: FocusMode;
  /**
   * Enable or disable the pinch gesture handler.
   * If `zoomMode` is `on`, you must pass `zoom` as `undefined`, or
   * avoid setting `zoom` it to allow pinch to zoom.
   * Examples:
   * ```
   * <Camera zoomMode="on" />
   * <Camera zoomMode="on" zoom={undefined} />
   * <Camera zoomMode="off" zoom={1.0} />
   * ```
   */
  zoomMode?: ZoomMode;
  /**
   * Controls zoom. Higher values zooms in.
   * Default zoom is `1.0`, relative to 'wide angle' camera.
   * Examples of minimum/widest zoom:
   * - iPhone 6S Plus minimum is `1.0`
   * - iPhone 14 Pro Max minimum `0.5`
   * - Google Pixel 7 minimum is `0.7`
   * ## Example
   * ```
   * const [zoom, setZoom] = useState(1.0);
   * <Button onPress={() => setZoom(1.0)} title="Reset" />
   * <Camera
   *   zoom={zoom}
   *   onZoom={(e) => {
   *     setZoom(e.nativeEvent.zoom);
   *     console.log('zoom', e.nativeEvent.zoom);
   *   }}
   * />
   * ```
   */
  zoom?: number;
  /**
   * Limits the maximum zoom factor to something smaller than the camera's maximum.
   * You cannot go beyond the camera's maximum, only below.
   * The purpose of limiting zoom is because some modern iPhones report max zoom of 150+
   * which is probably beyond what you want. See documentation for the `zoom` prop for more info.
   * Example:
   * ```
   * <Camera
   *   maxZoom={15.0}
   * />
   * ```
   */
  maxZoom?: number;
  torchMode?: TorchMode;
  cameraType?: CameraType;
  onOrientationChange?: (event: OnOrientationChangeData) => void;
  /**
   * Callback triggered when user pinches to zoom and on startup.
   * Example:
   * ```
   * <Camera
   *   onZoom={(e) => {
   *     console.log('zoom', e.nativeEvent.zoom);
   *   }}
   * />
   * ```
   */
  onZoom?: (event: OnZoom) => void;
  /** **Android only**. Triggered when camera fails to initialize */
  onError?: (event: { nativeEvent: { errorMessage: string } }) => void;
  // Barcode only
  scanBarcode?: boolean;
  showFrame?: boolean;
  laserColor?: number | string;
  frameColor?: number | string;
  barcodeFrameSize?: { width: number; height: number };
  onReadCode?: (event: OnReadCodeData) => void;
  // Specific to iOS
  ratioOverlay?: string;
  ratioOverlayColor?: number | string;
  resetFocusTimeout?: number;
  resetFocusWhenMotionDetected?: boolean;
  resizeMode?: ResizeMode;
  /** Throttle how often the barcode scanner triggers a new scan */
  scanThrottleDelay?: number;
  /** **iOS Only**. 'speed' provides 60-80% faster image capturing */
  maxPhotoQualityPrioritization?: 'balanced' | 'quality' | 'speed';
  /** **Android only**. Play a shutter capture sound when capturing a photo */
  shutterPhotoSound?: boolean;
  onCaptureButtonPressIn?: ({ nativeEvent: {} }) => void;
  onCaptureButtonPressOut?: ({ nativeEvent: {} }) => void;
}
