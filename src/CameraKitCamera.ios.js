import * as _ from 'lodash';
import React from 'react';
import {
  requireNativeComponent,
  NativeModules,
  processColor,
} from 'react-native';

const NativeCamera = requireNativeComponent('CKCamera', null);
const NativeCameraAction = NativeModules.CKCameraManager;

export default class CameraKitCamera extends React.Component {
  static async checkDeviceCameraAuthorizationStatus() {
    return await NativeCameraAction.checkDeviceCameraAuthorizationStatus();
  }

  static async requestDeviceCameraAuthorization() {
    return await NativeCameraAction.requestDeviceCameraAuthorization();
  }

  async capture(saveToCameraRoll = true) {
    return await NativeCameraAction.capture(saveToCameraRoll);
  }

  async changeCamera() {
    return await NativeCameraAction.changeCamera();
  }

  async setFlashMode(flashMode = 'auto') {
    return await NativeCameraAction.setFlashMode(flashMode);
  }

  async setTorchMode(torchMode = '') {
    return await NativeCameraAction.setTorchMode(torchMode);
  }

  render() {
    const transformedProps = _.cloneDeep(this.props);
    _.update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));
    return (
      <NativeCamera
        resetFocusTimeout={0}
        resetFocusWhenMotionDetected
        {...transformedProps}
      />
    );
  }
}
