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
   * <Camera zoom="on" />
   * ```
   */
  zoomMode?: ZoomMode;
  /**
   * **iOS only.**
   * Control zoom. `0` is resets zoom. `1` is the widest zoom possible. Higher values zooms in.
   * Example:
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
   * Should be at least 1.0 (no zoom, widest angle).
   * The purpose of limiting is because some modern iPhones report max zoom of 150+
   * which is probably beyond what you want.
   * Example:
   * ```
   * <Camera
   *   maxZoom={15}
   * />
   * ```
   */
  maxZoom?: number;
  torchMode?: TorchMode;
  cameraType?: CameraType;
  onOrientationChange?: (event: OnOrientationChangeData) => void;
  /**
   * **iOS only.**
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
