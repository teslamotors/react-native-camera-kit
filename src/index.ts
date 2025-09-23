import { NativeModules } from 'react-native';
import NativeCameraKitModule from './specs/NativeCameraKitModule';

import Camera from './Camera';
import {
  CameraType,
  type CameraApi,
  type CaptureData,
  type FlashMode,
  type FocusMode,
  type TorchMode,
  type ZoomMode,
  type ResizeMode,
} from './types';

/**
 * Low‑level native module for advanced use.
 *
 * @remarks
 * - Prefer using the {@link Camera} ref API for capture. The default export is
 *   provided for advanced scenarios where calling the TurboModule directly is
 *   necessary.
 * - API surface mirrors {@link CameraApi} methods but is not tied to a view
 *   instance; you must pass a view tag when required.
 *
 * @example Direct capture (advanced)
 * ```ts
 * import CameraKit from 'react-native-camera-kit'; // default export
 * import { findNodeHandle } from 'react-native';
 * const tag = findNodeHandle(ref.current);
 * const photo = await CameraKit.capture({}, tag);
 * ```
 */
// (Unused here) NativeModules kept to illustrate how to reach low-level APIs if needed.

/**
 * Orientation constants for {@link CameraProps.onOrientationChange}.
 *
 * Start with portrait/pointing up and increment while moving counter‑clockwise.
 *
 * Mapping:
 * - `PORTRAIT` = 0
 * - `LANDSCAPE_LEFT` = 1
 * - `PORTRAIT_UPSIDE_DOWN` = 2
 * - `LANDSCAPE_RIGHT` = 3
 *
 * @example
 * ```ts
 * const onOrientationChange = ({ nativeEvent }) => {
 *   if (nativeEvent.orientation === Orientation.LANDSCAPE_LEFT) {
 *     // adjust your UI
 *   }
 * };
 * ```
 * @category Constants
 */
export const Orientation = {
  PORTRAIT: 0, // ⬆️
  LANDSCAPE_LEFT: 1, // ⬅️
  PORTRAIT_UPSIDE_DOWN: 2, // ⬇️
  LANDSCAPE_RIGHT: 3, // ➡️
} as const;

/** @internal */
/**
 * Typed TurboModule instance for advanced use.
 *
 * @see default export (alias)
 */
export const CameraKit = NativeCameraKitModule;

// Keep default export as an alias so docs list both "CameraKit" and "default".
export default CameraKit;

export { Camera, CameraType };
export type { TorchMode, FlashMode, FocusMode, ZoomMode, CameraApi, CaptureData, ResizeMode, CodeFormat } from './types';
export type { CameraProps, OnReadCodeData, OnOrientationChangeData, OnZoom } from './CameraProps';
