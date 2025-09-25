/**
 * Lens facing direction used by {@link CameraProps.cameraType}.
 *
 * @remarks
 * Platform mappings:
 * - iOS → `AVCaptureDevice.Position`
 * - Android → CameraX `CameraSelector.LENS_FACING_*`
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
 * Platform analyzers:
 * - iOS → AVFoundation (`AVMetadataObject.ObjectType`)
 * - Android → ML Kit (`Barcode` format)
 * Unknown or device‑specific formats map to `'unknown'`.
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

/** Torch/flashlight state (continuous light during preview).
 *
 * @remarks
 * Independent from {@link FlashMode}, which applies to still capture only.
 * @category Types
 */
export type TorchMode = 'on' | 'off';

/**
 * Photo capture flash mode.
 *
 * @remarks
 * Applies only during still capture; independent from {@link TorchMode}.
 * - iOS → `AVCaptureFlashMode`
 * - Android → CameraX `ImageCapture.flashMode`
 * @category Types
 */
export type FlashMode = 'on' | 'off' | 'auto';

/** Autofocus mode.
 *
 * @remarks
 * - iOS: `on` enables tap‑to‑focus UI and custom focus behavior; `off` removes the tap gesture and keeps continuous AF.
 * - Android: `on` cancels manual metering points (continuous AF); `off` lets manual tap focus persist (no auto‑cancel).
 * @category Types
 */
export type FocusMode = 'on' | 'off';

/** Enables pinch‑to‑zoom gesture when `'on'`.
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
 * - iOS: Saves a JPEG under Caches at `.../Library/Caches/<bundleId>/com.tesla.react-native-camera-kit/<unique>.jpg`.
 *   Includes `size` in bytes; `width`/`height` reflect the final pixel dimensions.
 * - Android: Uses MediaStore/output file; returns a `file://` or `content://` URI.
 *   `id`/`path` may be empty on some devices. `width`/`height` intend to describe the saved image.
 * - Orientation is already encoded in pixels and EXIF. No JS rotation required.
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
 * @example Handling content URIs (Android)
 * ```ts
 * if (photo?.uri?.startsWith('content://')) {
 *   // copy stream to app storage before long‑term use
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
