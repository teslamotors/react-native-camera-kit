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

/**
 * Payload for the {@link CameraProps.onReadCode | onReadCode} event.
 *
 * @category Events
 */

export type OnReadCodeData = {
  nativeEvent: {
    codeStringValue: string;
    codeFormat: CodeFormat;
  };
};

/**
 * Payload for the {@link CameraProps.onOrientationChange | onOrientationChange} event.
 *
 * @remarks
 * `orientation` maps to {@link Orientation} constants.
 *
 * @category Events
 */
export type OnOrientationChangeData = {
  nativeEvent: {
    orientation: typeof Orientation[keyof typeof Orientation];
  };
};

/**
 * Payload for the {@link CameraProps.onZoom | onZoom} event.
 *
 * @category Events
 */
export type OnZoom = {
  nativeEvent: {
    zoom: number;
  };
}

/**
 * Props for the {@link Camera} component.
 *
 * @remarks
 * - Optional numeric props may be normalized to `-1` internally to represent “unset” (RN Codegen limitation).
 * - Color props accept numbers or strings; on Android strings are converted via `processColor`.
 * - Platform-specific behavior is noted per prop.
 *
 * @category Components
 */
export interface CameraProps extends ViewProps {
  // Behavior
  /** Flash behavior used for still capture.
   * @defaultValue `auto`
   */
  flashMode?: FlashMode;
  /** Auto-focus mode for the preview.
   * @defaultValue `on`
   */
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
  /** Continuous torch (flashlight) state while previewing.
   * @defaultValue `off`
   */
  torchMode?: TorchMode;
  /** Selects the active camera device.
   * @defaultValue `back`
   */
  cameraType?: CameraType;
  /** Fires when the device orientation changes (see {@link Orientation}). */
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
  /** Enable barcode scanning.
   * @defaultValue `false`
   */
  scanBarcode?: boolean;
  /** Show an on‑screen frame overlay when scanning.
   * @defaultValue `false`
   */
  showFrame?: boolean;
  /** Color of the moving laser indicator (when `showFrame` is true). */
  laserColor?: number | string;
  /** Color of the frame outline (when `showFrame` is true). */
  frameColor?: number | string;
  /** Frame size used to guide scanning focus. */
  barcodeFrameSize?: { width: number; height: number };
  /** Emitted when a barcode is successfully read. */
  onReadCode?: (event: OnReadCodeData) => void;
  // Specific to iOS
  /** Show a ratio overlay guide over the preview (no cropping). Example: `'16:9'`. */
  ratioOverlay?: string;
  /** Color of the ratio overlay.
   * @defaultValue `#ffffff77`
   */
  ratioOverlayColor?: number | string;
  /** Dismiss tap‑to‑focus after this many milliseconds. `0` disables.
   * @defaultValue `0`
   */
  resetFocusTimeout?: number;
  /** Dismiss tap‑to‑focus when the subject area changes (iOS feature).
   * @defaultValue `true`
   */
  resetFocusWhenMotionDetected?: boolean;
  /** Scaling mode for the preview inside the view bounds. */
  resizeMode?: ResizeMode;
  /** Throttle how often the barcode scanner triggers a new scan
   * @defaultValue `2000`
   */
  scanThrottleDelay?: number;
  /** **iOS Only**. 'speed' provides 60-80% faster image capturing
   * @defaultValue `balanced`
   */
  maxPhotoQualityPrioritization?: 'balanced' | 'quality' | 'speed';
  /** **Android only**. Play a shutter capture sound when capturing a photo
   * @defaultValue `true`
   */
  shutterPhotoSound?: boolean;
  /** Emitted when the hardware capture/volume button is pressed. */
  onCaptureButtonPressIn?: ({ nativeEvent: {} }) => void;
  /** Emitted when the hardware capture/volume button is released. */
  onCaptureButtonPressOut?: ({ nativeEvent: {} }) => void;
}
