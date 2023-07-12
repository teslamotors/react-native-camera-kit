import { NativeModules } from 'react-native';

import Camera from './Camera';
import { CameraApi, CameraType, CaptureData, FlashMode, FocusMode, TorchMode, ZoomMode } from './types';

const { CameraKit } = NativeModules;

// Start with portrait/pointing up, increment while moving counter-clockwise
export const Orientation = {
  PORTRAIT: 0, // ⬆️
  LANDSCAPE_LEFT: 1, // ⬅️
  PORTRAIT_UPSIDE_DOWN: 2, // ⬇️
  LANDSCAPE_RIGHT: 3, // ➡️
};

export default CameraKit;

export { Camera, CameraType, TorchMode, FlashMode, FocusMode, ZoomMode, CameraApi, CaptureData };
