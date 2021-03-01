import * as _ from 'lodash';
import React from 'react';
import { requireNativeComponent, NativeModules, processColor } from 'react-native';

const { CKCameraManager } = NativeModules;
const NativeCamera = requireNativeComponent('CKCamera');

interface Props {
  resetFocusTimeout?: number;
  resetFocusWhenMotionDetected?: boolean;
  saveToCameraRoll?: boolean;
}

const Camera: React.ForwardRefRenderFunction<{}, Props> = ({
  resetFocusTimeout = 0,
  resetFocusWhenMotionDetected = true,
  saveToCameraRoll = true,
}, ref) => {
  const nativeRef = React.useRef<any>(); //typeof NativeCamera

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

  const transformedProps = _.cloneDeep({resetFocusTimeout, resetFocusWhenMotionDetected, saveToCameraRoll});
  _.update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));

  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...transformedProps} />;
};

export default React.forwardRef(Camera);
