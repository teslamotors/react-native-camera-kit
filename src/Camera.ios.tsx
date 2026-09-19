import React from 'react';
import { findNodeHandle } from 'react-native';
import { supportedCodeFormats, type CameraApi } from './types';
import type { CameraProps } from './CameraProps';
import NativeCamera from './specs/CameraNativeComponent';
import NativeCameraKitModule from './specs/NativeCameraKitModule';

const Camera = React.forwardRef<CameraApi, CameraProps>((props, ref) => {
  const nativeRef = React.useRef(null);

  // RN doesn't support optional view props yet (sigh)
  // so we have to use -1 to indicate 'undefined'
  // All int/float/double props from src/specs/CameraNativeComponent.ts need be mentioned here
  //
  // These must land on a new object rather than on `props`: React freezes element.props in
  // development, so assigning to `props` is silently dropped there while it works in release.
  const nativeProps: CameraProps = {
    ...props,
    zoom: props.zoom ?? -1,
    maxZoom: props.maxZoom ?? -1,
    scanThrottleDelay: props.scanThrottleDelay ?? -1,
    faceDetectionThrottleMs: props.faceDetectionThrottleMs ?? -1,
    iOsDeferredStart: props.iOsDeferredStart ?? true,

    allowedBarcodeTypes: props.allowedBarcodeTypes ?? supportedCodeFormats,

    resetFocusTimeout: props.resetFocusTimeout ?? 0,
    resetFocusWhenMotionDetected: props.resetFocusWhenMotionDetected ?? true,
  };

  React.useImperativeHandle(ref, () => ({
    capture: async () => {
      return await NativeCameraKitModule.capture({}, findNodeHandle(nativeRef.current) ?? undefined);
    },
    requestDeviceCameraAuthorization: async () => {
      return await NativeCameraKitModule.checkDeviceCameraAuthorizationStatus();
    },
    checkDeviceCameraAuthorizationStatus: async () => {
      return await NativeCameraKitModule.checkDeviceCameraAuthorizationStatus();
    },
  }));

  // @ts-expect-error props for codegen differ a bit from the user-facing ones
  return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...nativeProps} />;
});

export default Camera;
