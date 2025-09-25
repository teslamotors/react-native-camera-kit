import React from 'react';
import { findNodeHandle, processColor } from 'react-native';
import type { CameraApi } from './types';
import type { CameraProps } from './CameraProps';
import NativeCamera from './specs/CameraNativeComponent';
import NativeCameraKitModule from './specs/NativeCameraKitModule';

/**
 * Android implementation of {@link Camera}.
 *
 * @remarks
 * - Normalizes optional numeric props to `-1` for RN Codegen.
 * - Converts color strings to ARGB numbers via `processColor` before passing to native.
 * - Exposes `capture()` on the ref.
 */
const Camera = React.forwardRef<CameraApi, CameraProps>((props, ref) => {
  const nativeRef = React.useRef(null);

  // RN doesn't support optional view props yet (sigh),
  // so we use -1 to indicate 'undefined'.
  // All int/float/double props from src/specs/CameraNativeComponent.ts need to be normalized here.
  props.zoom = props.zoom ?? -1;
  props.maxZoom = props.maxZoom ?? -1;
  props.scanThrottleDelay = props.scanThrottleDelay ?? -1;

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
