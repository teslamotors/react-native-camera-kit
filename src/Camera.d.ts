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

export type OnZoom = {
  nativeEvent: {
    zoom: number;
  };
}

export interface CameraProps {
  ref?: LegacyRef<Component<CameraApi, {}, any>>;
  style?: StyleProp<ViewStyle>;
  // Behavior
  flashMode?: FlashMode;
  focusMode?: FocusMode;
  /**
   * Enable or disable the pinch gesture handler
   * Example:
   * ```
   * <Camera zoomMode="on" />
   * ```
   */
  zoomMode?: ZoomMode;
  /**
   * Controls zoom. Higher values zooms in.
   * ## iOS
   * - "Default" zoom depends on the phone.
   * - iPhone 14 Pro Max uses `2.0`, iPhone 6 default is `1.0`.
   * - `1.0` is always the minimum allowed on iOS.
   * ## Android
   * - "Default" zoom is `1.0`.
   * - Wide angle is below `1.0`.
   * - Google Pixel 7 uses `0.7` for the widest angle.
   * ## Example
   * ```
   * const [zoom, setZoom] = useState(0);
   * <Button onPress={() => setZoom(0)} title="Reset" />
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
   * Triggered when:
   * - User pinches to zoom, or
   * - 'zoom={0}' prop is set to 0, which resets zoom for the camera
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
  /** **iOS Only**. Throttle how often the barcode scanner triggers a new scan */
  scanThrottleDelay?: number;
}

declare const Camera: React.FC<CameraProps>;

export default Camera;
