import { NativeModules } from 'react-native';
import Camera from './Camera';
import CameraScreen, { CameraType } from './CameraScreen';
const { CameraKit } = NativeModules;
export const Orientation = {
    PORTRAIT: 0,
    LANDSCAPE_LEFT: 1,
    PORTRAIT_UPSIDE_DOWN: 2,
    LANDSCAPE_RIGHT: 3,
};
export default CameraKit;
export { Camera, CameraScreen, CameraType };
//# sourceMappingURL=index.js.map