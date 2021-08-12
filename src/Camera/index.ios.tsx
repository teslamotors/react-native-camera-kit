import * as _ from 'lodash';
import React from 'react';
import { requireNativeComponent, NativeModules, processColor } from 'react-native';
import { ICameraProps } from '..';

const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');

const Camera = React.forwardRef<any, ICameraProps>((props, ref) => {
  const nativeRef = React.useRef<any>();

  React.useImperativeHandle(ref, () => ({
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

  const transformedProps = _.cloneDeep(props);
  _.update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));

  return <NativeCamera ref={nativeRef} {...transformedProps} />;
});

Camera.defaultProps = {
  resetFocusTimeout: 0,
  resetFocusWhenMotionDetected: true,
  saveToCameraRoll: true,
};

export default Camera;
