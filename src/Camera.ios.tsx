import React from 'react';
import { requireNativeComponent, NativeModules } from 'react-native';
import { CameraApi } from './types';
import { CameraProps } from './Camera';

const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');

const Camera = React.forwardRef((props: CameraProps, ref: any) => {
  const nativeRef = React.useRef();

  React.useImperativeHandle<any, CameraApi>(ref, () => ({
    capture: async () => {
      return await CKCameraManager.capture({});
    },
    setTorchMode: (mode = 'off') => {
      CKCameraManager.setTorchMode(mode);
    },
    requestDeviceCameraAuthorization: async () => {
      return await CKCameraManager.checkDeviceCameraAuthorizationStatus();
    },
    checkDeviceCameraAuthorizationStatus: async () => {
      return await CKCameraManager.checkDeviceCameraAuthorizationStatus();
    },
  }));

  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...props} />;
});

Camera.defaultProps = {
  resetFocusTimeout: 0,
  resetFocusWhenMotionDetected: true,
};

export default Camera;
