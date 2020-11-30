import { NativeModules } from 'react-native';

import Camera from './Camera';
import CameraScreen from './CameraScreen/CameraScreen';

const { CameraKit } = NativeModules;

export default CameraKit;

export { Camera, CameraScreen };
