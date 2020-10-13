import { NativeModules } from 'react-native';

type CameraKitType = {
  multiply(a: number, b: number): Promise<number>;
};

const { CameraKit } = NativeModules;

export default CameraKit as CameraKitType;
