import { NativeModules } from 'react-native';

import Camera from './Camera';
import CameraScreen, { CameraType } from './CameraScreen';

const { CameraKit } = NativeModules;

export default CameraKit;

export { Camera, CameraScreen, CameraType };
