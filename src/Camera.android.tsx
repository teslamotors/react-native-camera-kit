import React from 'react';
import _ from 'lodash';
import { requireNativeComponent, findNodeHandle, NativeModules, processColor } from 'react-native';

const { RNCameraKitModule } = NativeModules;
const NativeCamera = requireNativeComponent('CKCameraManager');

const Camera = React.forwardRef((props, ref) => {
  const nativeRef = React.useRef();

  React.useImperativeHandle(ref, () => ({
    capture: async (options = {}) => {
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

  return (
    <NativeCamera
      style={{ minWidth: 100, minHeight: 100 }}
      flashMode={props.flashMode}
      ref={nativeRef}
      {...transformedProps}
    />);
});

export default Camera;
