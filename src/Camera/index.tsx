import React, { forwardRef, useRef } from 'react';
import _ from 'lodash';
import { requireNativeComponent, findNodeHandle, NativeModules, processColor } from 'react-native';
import { ICameraProps } from '../types/camera';

const { RNCameraKitModule } = NativeModules;
const NativeCamera = requireNativeComponent('CKCameraManager');

const Camera = forwardRef<any, ICameraProps>((props, ref) => {
  const nativeRef = useRef<any>();

  React.useImperativeHandle(ref, () => ({
    capture: async (options = {}) => {
      if (!nativeRef || !nativeRef.current) return;
      // Because RN doesn't support return types for ViewManager methods
      // we must use the general module and tell it what View it's supposed to be using
      return await RNCameraKitModule.capture(options, findNodeHandle(nativeRef.current));
    },
    requestDeviceCameraAuthorization: async () => {
      return await RNCameraKitModule.requestDeviceCameraAuthorization();
    },
  }));

  const transformedProps = _.cloneDeep(props);
  _.update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));
  _.update(transformedProps, 'frameColor', (c) => processColor(c));
  _.update(transformedProps, 'laserColor', (c) => processColor(c));
  _.update(transformedProps, 'surfaceColor', (c) => processColor(c));

  return <NativeCamera ref={nativeRef} {...transformedProps} />;
});

export default Camera;
