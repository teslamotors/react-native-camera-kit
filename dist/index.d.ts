import Camera from './Camera';
import CameraScreen, { CameraType } from './CameraScreen';
import type { CameraApi } from './types';
declare const CameraKit: any;
export declare const Orientation: {
    PORTRAIT: number;
    LANDSCAPE_LEFT: number;
    PORTRAIT_UPSIDE_DOWN: number;
    LANDSCAPE_RIGHT: number;
};
export default CameraKit;
export { Camera, CameraScreen, CameraType, CameraApi };
