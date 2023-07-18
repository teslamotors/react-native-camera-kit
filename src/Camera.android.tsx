import React from 'react';
import _cloneDeep from 'lodash/cloneDeep';
import { requireNativeComponent, findNodeHandle, NativeModules, processColor } from 'react-native';
import { CameraApi } from './types';
import { CameraProps } from './Camera';

const { RNCameraKitModule } = NativeModules;
const NativeCamera = requireNativeComponent('CKCameraManager');

const Camera = React.forwardRef((props: CameraProps, ref) => {
  const nativeRef = React.useRef();

  React.useImperativeHandle<any, CameraApi>(ref, () => ({
    capture: async (options = {}) => {
      // Because RN doesn't support return types for ViewManager methods
      // we must use the general module and tell it what View it's supposed to be using
      return await RNCameraKitModule.capture(options, findNodeHandle(nativeRef.current ?? null));
    },
    requestDeviceCameraAuthorization: () => {
      throw new Error('Not implemented');
    },
    checkDeviceCameraAuthorizationStatus: () => {
      throw new Error('Not implemented');
    },
  }));

  const transformedProps: CameraProps = _cloneDeep(props);
  transformedProps.ratioOverlayColor = processColor(props.ratioOverlayColor);
  transformedProps.frameColor = processColor(props.frameColor);
  transformedProps.laserColor = processColor(props.laserColor);

  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...transformedProps} />;
});

export default Camera;
