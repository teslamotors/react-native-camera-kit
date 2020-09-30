import * as _ from 'lodash';
import React from 'react';
import {
  requireNativeComponent,
  NativeModules,
  processColor,
  Platform,
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

  capture(options) {
    if (Platform.OS === 'ios') {
      return NativeCameraAction.capture(options);
    }
    if (Platform.OS === 'android') {
      // Android has not been updated to use props yet
      return NativeCameraAction.capture(!!this.props.saveToCameraRoll);
    }
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
      <NativeCamera {...transformedProps} />
    );
  }
}

CameraKitCamera.defaultProps = {
  resetFocusTimeout: 0,
  resetFocusWhenMotionDetected: true,
  saveToCameraRoll: true,
};
