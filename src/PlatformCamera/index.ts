import { Platform } from 'react-native';
import AndroidCamera from './AndroidCamera';
import IOSCamera from './IOSCamera';

const CameraComponent = Platform.select({
  android: AndroidCamera,
  ios: IOSCamera,
});

export default CameraComponent;
