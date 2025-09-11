import { NativeModules } from 'react-native';

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
import type { CameraProps } from './CameraProps';

const { CameraKit } = NativeModules;

/**
 * Orientation constants reported by the native camera implementation.
 *
 * @remarks
 * Values start at portrait (top of device up) and increment counter‑clockwise.
 * These mirror native constants exposed by the underlying modules on iOS and Android.
 * Use them to interpret orientation values in `onOrientationChange` events.
 *
 * Mapping:
 * - `PORTRAIT` = 0
 * - `LANDSCAPE_LEFT` = 1
 * - `PORTRAIT_UPSIDE_DOWN` = 2
 * - `LANDSCAPE_RIGHT` = 3
 *
 * @category Constants
 */
export const Orientation = {
  PORTRAIT: 0, // ⬆️
  LANDSCAPE_LEFT: 1, // ⬅️
  PORTRAIT_UPSIDE_DOWN: 2, // ⬇️
  LANDSCAPE_RIGHT: 3, // ➡️
} as const;

/**
 * Low‑level native module.
 *
 * @remarks
 * Most apps should use the {@link Camera} component and its ref API instead of
 * calling this module directly. The available methods are platform‑dependent:
 *
 * - iOS: capture plus camera authorization helpers.
 * - Android: capture; authorization helpers are not implemented.
 *
 * @category Native Module
 * @hidden
 */
export default CameraKit;

/**
 * Cross‑platform camera component.
 *
 * @remarks
 * This is a lazy re‑export; the actual implementation is platform‑specific
 * (`Camera.ios.tsx` / `Camera.android.tsx`). Attach a `ref` of type
 * {@link CameraApi} to access imperative methods such as `capture()`.
 * See {@link CameraProps | Camera props} for configuration.
 *
 * @category Components
 */
export { Camera, CameraType };

/**
 * Public types re‑exported for convenience.
 *
 * @category Types
 */
export type {
  TorchMode,
  FlashMode,
  FocusMode,
  ZoomMode,
  CameraApi,
  CaptureData,
  ResizeMode,
  CameraProps,
};
