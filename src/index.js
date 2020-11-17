import { NativeModules } from 'react-native';

import CameraKitCamera from './CameraKitCamera';
import CameraKitCameraScreen from './CameraScreen/CameraKitCameraScreen';

const { CameraKit } = NativeModules;

export default CameraKit;

export { CameraKitCamera, CameraKitCameraScreen };
