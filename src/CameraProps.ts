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
 * Payload for {@link CameraProps.onReadCode}.
 * @category Events
 */
export type OnReadCodeData = {
  /** Event payload. */
  nativeEvent: {
    /** Decoded text of the detected barcode/QR. */
    codeStringValue: string;
    /** Detected barcode format (e.g., `qr`, `ean-13`, `pdf-417`). */
    codeFormat: CodeFormat;
  };
};

/** Payload for {@link CameraProps.onOrientationChange}.
 * @category Events
 */
export type OnOrientationChangeData = {
  /** Event payload. */
  nativeEvent: {
    /** One of {@link Orientation}. */
    orientation: typeof Orientation[keyof typeof Orientation];
  };
};

/** Payload for {@link CameraProps.onZoom}.
 * @category Events
 */
export type OnZoom = {
  /** Event payload. */
  nativeEvent: {
    /** Current zoom factor after user gesture or initialization. */
    zoom: number;
  };
}

/**
 * Props for the `Camera` component.
 *
 * @remarks
 * - Optional numeric props are normalized to `-1` internally to represent “unset” (RN Codegen limitation for view props).
 * - Color props accept numbers or strings; on Android strings are converted via `processColor`.
 * - Platform‑specific behavior is noted per prop.
 * - Controlled vs uncontrolled zoom: When `zoom` is provided (controlled), pinch does not change the native zoom; when `zoom` is `undefined` and `zoomMode='on'` (uncontrolled), pinch adjusts zoom and emits {@link CameraProps.onZoom}.
 *
 * Note: The component accepts all React Native `ViewProps` at runtime, but
 * for readability in the generated docs we hide inherited members.
 *
 * @noInheritDoc
 * @category Types
 */
export interface CameraProps extends ViewProps {
  // Behavior
  /**
   * Photo capture flash mode.
   * Maps to the platform capture pipeline (not the continuous torch).
   * @defaultValue `auto`
   */
  flashMode?: FlashMode;
  /** Autofocus mode.
   * @defaultValue `on`
   */
  focusMode?: FocusMode;
  /**
   * Enable or disable the pinch gesture handler.
   * If `zoomMode` is `on`, you must pass `zoom` as `undefined`, or
   * avoid setting `zoom` it to allow pinch to zoom.
   * @defaultValue `on`
   * Examples:
   * ```
   * <Camera zoomMode="on" />
   * <Camera zoomMode="on" zoom={undefined} />
   * <Camera zoomMode="off" zoom={1.0} />
   * ```
   */
  zoomMode?: ZoomMode;
  /**
   * Controls zoom. Higher values zoom in.
   * Default zoom is `1.0`, relative to the wide‑angle lens on multi‑camera devices.
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
   * @defaultValue 1.0
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
  maxZoom?: number; // Camera maximum is used when unset.
  /**
   * Torch/flashlight state (continuous light while previewing).
   * Independent from {@link CameraProps.flashMode}.
   * @defaultValue `off`
  */
  torchMode?: TorchMode;
  /** Lens facing direction (`front` or `back`). @defaultValue `back` */
  cameraType?: CameraType;
  /** Called when device orientation changes; see {@link Orientation}. */
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
  /** **Android only**. Triggered when camera fails to initialize or bind use cases. */
  onError?: (event: { nativeEvent: { errorMessage: string } }) => void;
  // Barcode only
  /** Enable barcode/QR analysis. Emits {@link CameraProps.onReadCode}.
   * @defaultValue `false`
   */
  scanBarcode?: boolean;
  /** Show a visual scanning frame overlay.
   * @defaultValue `false`
   */
  showFrame?: boolean;
  /** Color of the animated scanning laser (when `showFrame` is true). */
  laserColor?: number | string;
  /** Color of the scanning frame (when `showFrame` is true). */
  frameColor?: number | string;
  /** Size of the scanning frame.
   * @defaultValue `{ width: 300, height: 150 }`
   */
  barcodeFrameSize?: {
    /** Frame width in pixels. */
    width: number;
    /** Frame height in pixels. */
    height: number;
  };
  /**
   * Called when a barcode/QR is decoded.
   *
   * @example
   * ```tsx
   * <Camera
   *   scanBarcode
   *   onReadCode={(e) => console.log(e.nativeEvent.codeStringValue)}
   * />
   * ```
   */
  onReadCode?: (event: OnReadCodeData) => void;
  // Specific to iOS
  /**
   * Show a translucent aspect‑ratio guide over the preview.
   * Example: `'1:1'`, `'4:3'`, `'16:9'`.
  */
  ratioOverlay?: string;
  /** Overlay color used with {@link CameraProps.ratioOverlay}.
   * @remarks
   * Default is semi‑transparent black if unset.
   * @defaultValue `#0000004D`
   */
  ratioOverlayColor?: number | string;
  /** Time in ms after which the focus rectangle resets; `0` disables auto‑reset.
   * @defaultValue `0`
   */
  resetFocusTimeout?: number;
  /** Automatically reset focus when motion is detected.
   * @remarks
   * JS default is `true`; native default is `false` unless set by JS.
   * @defaultValue `true`
   */
  resetFocusWhenMotionDetected?: boolean;
  /** How the preview fits its bounds.
   * @remarks iOS only; Android preview is managed by CameraX.
   * @defaultValue `contain`
   */
  resizeMode?: ResizeMode;
  /** Throttle (ms) to limit how often barcode scans can fire.
   * @remarks
   * iOS: negative values effectively disable throttling.
   * Android: negative values are coerced to `2000`; use `0` to disable.
   * @defaultValue `2000`
   */
  scanThrottleDelay?: number;
  /** iOS capture pipeline quality prioritization.
   * @defaultValue `balanced`
   */
  maxPhotoQualityPrioritization?: 'balanced' | 'quality' | 'speed';
  /** **Android only**. Play a shutter capture sound when capturing a photo.
   * @defaultValue `true`
   */
  shutterPhotoSound?: boolean;
  /** Press‑in event from physical capture buttons (iOS 17.2+). */
  onCaptureButtonPressIn?: ({ nativeEvent: {} }) => void;
  /** Press‑out event from physical capture buttons (iOS 17.2+). */
  onCaptureButtonPressOut?: ({ nativeEvent: {} }) => void;
}
