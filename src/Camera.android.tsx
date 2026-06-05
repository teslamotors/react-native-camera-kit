import React from 'react';
import { findNodeHandle, processColor } from 'react-native';
import { supportedCodeFormats, type CameraApi } from './types';
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

  // RN can't express optional int/float view props yet, so we default
  // undefined -> -1 (and other sentinels). Build a NEW object instead of
  // mutating `props`: React freezes element props in dev, so writing to them
  // throws "Cannot add new property" once the module runs in strict mode
  // (ES modules are always strict).
  const transformedProps: CameraProps = {
    ...props,
    zoom: props.zoom ?? -1,
    maxZoom: props.maxZoom ?? -1,
    scanThrottleDelay: props.scanThrottleDelay ?? -1,
    faceDetectionThrottleMs: props.faceDetectionThrottleMs ?? -1,
    allowedBarcodeTypes: props.allowedBarcodeTypes ?? supportedCodeFormats,
    ratioOverlayColor: processColor(props.ratioOverlayColor) as any,
    frameColor: processColor(props.frameColor) as any,
    laserColor: processColor(props.laserColor) as any,
  };

  // @ts-expect-error props for codegen differ a bit from the user-facing ones
  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...transformedProps} />;
});

export default Camera;
