import { NativeModules } from 'react-native';

import Camera from './Camera';
import CameraScreen from './CameraScreen';
import { CameraType, ICameraProps, IFlashMode, IFocusMode, IImage, ITorchMode, IZoomMode } from './types/camera';

const { CameraKit } = NativeModules;

// Start with portrait/pointing up, increment while moving counter-clockwise
export const Orientation = {
  PORTRAIT: 0, // ⬆️
  LANDSCAPE_LEFT: 1, // ⬅️
  PORTRAIT_UPSIDE_DOWN: 2, // ⬇️
  LANDSCAPE_RIGHT: 3, // ➡️
};

export default CameraKit;

export { Camera, CameraScreen, CameraType, IFlashMode, ITorchMode, IFocusMode, IZoomMode, ICameraProps, IImage };
