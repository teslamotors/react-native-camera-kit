/**
 * Fabric host component spec for the native `CKCamera` view.
 *
 * @remarks
 * - This file declares the strongly typed prop/event contract consumed by React Native codegen.
 * - Public JS props in `src/CameraProps.ts` map 1:1 to these native props, with numeric
 *   optionals expressed via `WithDefault<..., -1>` until Fabric supports true optional numbers.
 * - Platform specifics:
 *   - iOS: supports ratio overlay, resize mode, focus timers, quality prioritization.
 *   - Android: supports shutter sound, analyzer throttling, frame/laser overlay.
 *
 * @internal
 */
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

/** Emitted when a barcode/QR is decoded. */
type OnReadCodeData = {
    codeStringValue: string;
    codeFormat: string;
};

/** Emitted when device orientation changes; value maps to {@link Orientation} constants. */
type OnOrientationChangeData = {
    orientation: Int32;
};

/** Emitted on zoom changes; includes current zoom factor. */
type OnZoom = {
    zoom: Double;
}

/**
 * Native view props for the camera component.
 *
 * @remarks
 * - Numeric optionals use `WithDefault<..., -1>` to indicate “unset”.
 *   See https://github.com/facebook/react-native/issues/49920#issuecomment-3237917813.
 * - Color props accept `ColorValue`; Android converts strings via `processColor`.
 */
export interface NativeProps extends ViewProps {
  /** Still-capture flash mode (`on` | `off` | `auto`). */
  flashMode?: string;
  /** Auto-focus mode (`on` | `off`). */
  focusMode?: string;
  /** iOS: photo quality prioritization (`balanced` | `quality` | `speed`). */
  maxPhotoQualityPrioritization?: string;
  /** Enable pinch-to-zoom gesture (`on` | `off`). */
  zoomMode?: string;
  /** Zoom factor (normalized); `-1` treated as unset (uncontrolled). */
  zoom?: WithDefault<Double, -1>;
  /** Cap the maximum zoom factor; `-1` uses device maximum. */
  maxZoom?: WithDefault<Double, -1>;
  /** Continuous torch/flashlight (`on` | `off`). */
  torchMode?: string;
  /** Lens facing direction (`front` | `back`). */
  cameraType?: string;
  /** Enable barcode/QR analysis. */
  scanBarcode?: boolean;
  /** Show a scanning frame overlay. */
  showFrame?: boolean;
  /** Color of the animated scanning laser. */
  laserColor?: ColorValue;
  /** Color of the scanning frame. */
  frameColor?: ColorValue;
  /** iOS: ratio overlay guide (e.g., '1:1', '4:3', '16:9'). */
  ratioOverlay?: string;
  /** iOS: overlay color used with `ratioOverlay`. */
  ratioOverlayColor?: ColorValue;
  /** iOS: auto-reset focus timeout in ms; `-1` treated as unset (defaults to 0). */
  resetFocusTimeout?: WithDefault<Int32, -1>;
  /** iOS: reset manual focus when motion is detected. */
  resetFocusWhenMotionDetected?: boolean;
  /** iOS: preview scaling mode (`cover` | `contain`). */
  resizeMode?: string;
  /** Scan throttle in ms; Android coerces negatives to 2000; 0 disables throttling. */
  scanThrottleDelay?: WithDefault<Int32, -1>;
  /** Size of the scanning frame (defaults to {width:300, height:150}). */
  barcodeFrameSize?: { width?: WithDefault<Float, 300>; height?: WithDefault<Float, 150> };
  /** Android only: play shutter click when capturing. */
  shutterPhotoSound?: boolean;
  /** Orientation change event. */
  onOrientationChange?: DirectEventHandler<OnOrientationChangeData>;
  /** Zoom changes from pinch or initialization. */
  onZoom?: DirectEventHandler<OnZoom>;
  /** Errors during init/binding (Android). */
  onError?: DirectEventHandler<{errorMessage: string }>;
  /** Barcode decoded event. */
  onReadCode?: DirectEventHandler<OnReadCodeData>;
  /** iOS 17.2+: press-in from physical capture/volume buttons. */
  onCaptureButtonPressIn?: DirectEventHandler<{}>;
  /** iOS 17.2+: press-out from physical capture/volume buttons. */
  onCaptureButtonPressOut?: DirectEventHandler<{}>;

  // not mentioned in props but available on the native side
  /** @internal Android-only: shutter flash animation duration in ms. */
  shutterAnimationDuration?: WithDefault<Int32, -1>;
  /** @internal Android-only: output file path override for captures. */
  outputPath?: string;
  /** @internal Android-only: internal picture taken event. */
  onPictureTaken?: DirectEventHandler<{uri: string}>;
}

/**
 * Typed host component for the native `CKCamera` view.
 * @internal Use via the high-level `Camera` component.
 */
export default codegenNativeComponent<NativeProps>('CKCamera') as HostComponent<NativeProps>;
