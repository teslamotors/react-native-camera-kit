import Camera from './Camera';
import CameraScreen from './CameraScreen';
import type { CameraApi, CameraType, CaptureData, FlashMode, FocusMode, TorchMode, ZoomMode } from './types';
declare const CameraKit: any;
export declare const Orientation: {
    PORTRAIT: number;
    LANDSCAPE_LEFT: number;
    PORTRAIT_UPSIDE_DOWN: number;
    LANDSCAPE_RIGHT: number;
};
export default CameraKit;
export { Camera, CameraScreen, CameraType, TorchMode, FlashMode, FocusMode, ZoomMode, CameraApi, CaptureData };
