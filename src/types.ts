/**
 * Selects which physical camera to use.
 *
 * @category Enums
 */
export enum CameraType {
  Front = 'front',
  Back = 'back',
}

/**
 * Supported barcode formats.
 *
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

/** Torch (flashlight) mode during preview. */
export type TorchMode = 'on' | 'off';

/** Flash mode used for still capture. */
export type FlashMode = 'on' | 'off' | 'auto';

/** Auto-focus mode for preview. */
export type FocusMode = 'on' | 'off';

/** Whether pinch-to-zoom is enabled. */
export type ZoomMode = 'on' | 'off';

/** How to scale/crop the preview content. */
export type ResizeMode = 'cover' | 'contain';

/**
 * Result of a successful capture.
 *
 * @remarks
 * `uri` is a file URI where supported; always a URI string for consistency.
 * `size` is only returned on iOS.
 */
export type CaptureData = {
  uri: string;
  name: string;
  height: number;
  width: number;
  // Android only
  id?: string;
  path?: string;
  // iOS only
  size?: number;
};

/**
 * Imperative API available from {@link Camera} via `ref`.
 *
 * @category Imperative API
 */
export type CameraApi = {
  /**
   * Capture a JPEG and return file information.
   *
   * @returns Promise resolved with {@link CaptureData}.
   */
  capture: () => Promise<CaptureData>;
  /**
   * Request camera authorization from the user.
   *
   * @remarks
   * Platform: iOS. On Android this method is not implemented and the platform
   * permission flow should be handled by an external library (see README).
   */
  requestDeviceCameraAuthorization: () => Promise<boolean>;
  /**
   * Check current camera authorization status.
   *
   * @remarks
   * Platform: iOS. On Android this method is not implemented.
   */
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
};
