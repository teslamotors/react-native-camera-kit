import React from 'react';
import { findNodeHandle } from 'react-native';
import { supportedCodeFormats, type CameraApi } from './types';
import type { CameraProps } from './CameraProps';
import NativeCamera from './specs/CameraNativeComponent';
import NativeCameraKitModule from './specs/NativeCameraKitModule';

const Camera = React.forwardRef<CameraApi, CameraProps>((props, ref) => {
  const nativeRef = React.useRef(null);

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
  return (
    <NativeCamera
      style={{ minWidth: 100, minHeight: 100 }}
      ref={nativeRef}
      {...transformedProps}
    />
  );
});

export default Camera;
