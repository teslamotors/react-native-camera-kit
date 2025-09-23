/**
 * Lens facing direction used by {@link CameraProps.cameraType}.
 *
 * @example Switch cameras
 * ```tsx
 * <Camera cameraType={CameraType.Back} />
 * ```
 * @category Enums
 */
export enum CameraType {
  /** Front/selfie camera. */
  Front = 'front',
  /** Rear/world camera. */
  Back = 'back',
}

/**
 * Barcode/QR code format for {@link OnReadCodeData}.
 *
 * @remarks
 * Values mirror underlying platform analyzers (AVFoundation on iOS, ML Kit on Android).
 * Unknown or device‑specific formats map to `unknown`.
 * @category Types
 */
export type CodeFormat =
  | 'code-128'
  | 'code-39'
  | 'code-93'
  | 'codabar'
  | 'ean-13'
  | 'ean-8'
  | 'itf'
  | 'upc-e'
  | 'qr'
  | 'pdf-417'
  | 'aztec'
  | 'data-matrix'
  | 'unknown';

/** Torch/flashlight state (continuous).
 * @category Types
 */
export type TorchMode = 'on' | 'off';

/**
 * Photo capture flash mode.
 *
 * @remarks
 * Maps to the platform capture pipeline; independent from {@link TorchMode}.
 * @category Types
 */
export type FlashMode = 'on' | 'off' | 'auto';

/** Autofocus mode.
 * @category Types
 */
export type FocusMode = 'on' | 'off';

/** Enables pinch‑to‑zoom gesture when 'on'.
 * @category Types
 */
export type ZoomMode = 'on' | 'off';

/** How the preview fits its bounds.
 * @category Types
 */
export type ResizeMode = 'cover' | 'contain';

/**
 * Result of a successful {@link CameraApi.capture | capture()} call.
 *
 * @remarks
 * - The image is written to a temporary, app‑scoped location. On iOS this is
 *   the Caches folder under a library‑specific subdirectory; on Android it is
 *   a temporary file created by the capture pipeline. You should move the file
 *   to a permanent location if you need to keep it (see example).
 * - Orientation is already encoded in pixel `width`/`height` and the image
 *   EXIF metadata. No additional rotation is necessary on JS.
 *
 * @example Move to app documents (react-native-fs)
 * ```ts
 * import RNFS from 'react-native-fs';
 * const photo = await ref.current?.capture();
 * if (photo?.uri?.startsWith('file://')) {
 *   const fileName = photo.name;
 *   const dest = `${RNFS.DocumentDirectoryPath}/${fileName}`;
 *   await RNFS.moveFile(photo.uri.replace('file://', ''), dest);
 * }
 * ```
 * @category Types
 */
export type CaptureData = {
  /**
   * Local URI to the captured image.
   * - iOS: `file:///.../Library/Caches/<bundleId>/com.tesla.react-native-camera-kit/<unique>.jpg`
   * - Android: usually a `file://` path; may be a `content://` URI depending on device/storage.
   */
  uri: string;

  /** File name (no path), suitable for display or saving elsewhere. */
  name: string;

  /** Image width in pixels after all processing is applied. */
  width: number;

  /** Image height in pixels after all processing is applied. */
  height: number;

  /**
   * Android only: MediaStore ID when available.
   * Useful for interacting with the platform media APIs.
   */
  id?: string;

  /**
   * Android only: absolute filesystem path when available.
   * May be empty on devices which only return a `content://` URI.
   */
  path?: string;

  /**
   * iOS only: byte size of the image data written to the temporary file.
   * Provided for convenience when saving/uploading the file.
   */
  size?: number;
};

/**
 * Methods exposed on the {@link Camera} ref.
 *
 * @example Capture a photo
 * ```tsx
 * const ref = useRef<CameraApi>(null);
 * const photo = await ref.current?.capture();
 * console.log(photo?.uri);
 * ```
 * @category Types
 */
export type CameraApi = {
  /** Take a photo associated with this view instance. */
  capture: () => Promise<CaptureData>;
  /** iOS only: request camera permission via native dialog. */
  requestDeviceCameraAuthorization: () => Promise<boolean>;
  /** iOS only: check current camera permission status. */
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
};
