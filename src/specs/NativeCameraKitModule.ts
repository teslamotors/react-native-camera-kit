import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { Double, Int32, UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

type CaptureData = {
  uri: string;
  name: string;
  height: Int32;
  width: Int32;
  // Android only
  id?: string;
  path?: string;
  // iOS only
  size?: Int32;
};

export interface Spec extends TurboModule {
  capture(options?: UnsafeObject, tag?: Double): Promise<CaptureData>;
  requestDeviceCameraAuthorization: () => Promise<boolean>;
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RNCameraKitModule');
