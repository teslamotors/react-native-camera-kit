import * as _ from 'lodash';
import React from 'react';
import { requireNativeComponent, NativeModules, processColor } from 'react-native';

const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');

function Camera(props, ref) {
  const nativeRef = React.useRef();

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

  return <NativeCamera style={{flex: 1}} ref={nativeRef} {...transformedProps} />;
}

Camera.defaultProps = {
  resetFocusTimeout: 0,
  resetFocusWhenMotionDetected: true,
  saveToCameraRoll: true,
};

export default React.forwardRef(Camera);
