import React from 'react';
import { requireNativeComponent, findNodeHandle, NativeModules, processColor } from 'react-native';
import type { CameraApi } from './types';
import type { CameraProps } from './CameraProps';

const { RNCameraKitModule } = NativeModules;
const NativeCamera = requireNativeComponent('CKCameraManager');

const Camera = React.forwardRef<CameraApi, CameraProps>((props, ref) => {
  const nativeRef = React.useRef(null);

  React.useImperativeHandle(ref, () => ({
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

  const transformedProps: CameraProps = { ...props };
  transformedProps.ratioOverlayColor = processColor(props.ratioOverlayColor) as any;
  transformedProps.frameColor = processColor(props.frameColor) as any;
  transformedProps.laserColor = processColor(props.laserColor) as any;

  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...transformedProps} />;
});

export default Camera;
