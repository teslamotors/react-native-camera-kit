import React from 'react';
import { findNodeHandle, processColor } from 'react-native';
import type { CameraApi } from './types';
import type { CameraProps } from './CameraProps';
import NativeCamera from './specs/CameraNativeComponent';
import NativeCameraKitModule from './specs/NativeCameraKitModule';

const Camera = React.forwardRef<CameraApi, CameraProps>((props, ref) => {
  const nativeRef = React.useRef(null);

  React.useImperativeHandle(ref, () => ({
    capture: async (options = {}) => {
      return await NativeCameraKitModule.capture(options, findNodeHandle(nativeRef.current) ?? undefined);
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

  // @ts-expect-error props for codegen differ a bit from the user-facing ones
  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...transformedProps} />;
});

export default Camera;
