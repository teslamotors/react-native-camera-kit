import _update from 'lodash/update';
import _cloneDeep from 'lodash/cloneDeep';
import React from 'react';
import { requireNativeComponent, NativeModules, processColor } from 'react-native';
import { CameraApi } from './types';

const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');

const Camera = React.forwardRef((props: any, ref: any) => {
  const nativeRef = React.useRef();

  React.useImperativeHandle<any, CameraApi>(ref, () => ({
    capture: async () => {
      return await CKCameraManager.capture({});
    },
    requestDeviceCameraAuthorization: async () => {
      return await CKCameraManager.checkDeviceCameraAuthorizationStatus();
    },
    checkDeviceCameraAuthorizationStatus: async () => {
      return await CKCameraManager.checkDeviceCameraAuthorizationStatus();
    },
  }));

  const transformedProps = _cloneDeep(props);
  _update(transformedProps, 'cameraOptions.ratioOverlayColor', (c: any) => processColor(c));

  return (
    <NativeCamera
      style={{ minWidth: 100, minHeight: 100 }}
      ref={nativeRef}
      {...transformedProps}
    />
  );
});

Camera.defaultProps = {
  resetFocusTimeout: 0,
  resetFocusWhenMotionDetected: true,
};

export default Camera;
