import * as _ from 'lodash';
import React, { useEffect } from 'react';
import { requireNativeComponent, NativeModules, processColor } from 'react-native';

const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');

function Camera(props, ref) {
  const nativeRef = React.useRef();

  useEffect(() => {
    CKCameraManager.changeCamera();
  }, [props.type]);

  useEffect(() => {
    CKCameraManager.setFlashMode(props.flashMode);
  }, [props.flashMode]);

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
    changeCamera: async () => {
      return await CKCameraManager.changeCamera();
    },
    setFlashMode: async (flashMode = 'auto') => {
      return await CKCameraManager.setFlashMode(flashMode);
    },
    setTorchMode: async (torchMode = '') => {
      return await CKCameraManager.setTorchMode(torchMode);
    },
  }));

  const transformedProps = _.cloneDeep(props);
  _.update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));

  return <NativeCamera ref={nativeRef} {...transformedProps} />;
}

Camera.defaultProps = {
  resetFocusTimeout: 0,
  resetFocusWhenMotionDetected: true,
  saveToCameraRoll: true,
};

export default React.forwardRef(Camera);
