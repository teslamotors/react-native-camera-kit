import React, { Component } from 'react';
import {
	requireNativeComponent,
	NativeModules
} from 'react-native';

const NativeCamera = requireNativeComponent('CameraView', null);
const NativeCameraModule = NativeModules.CameraModule;

export default class CameraKitCamera extends React.Component {

  render() {
    const transformedProps = _.cloneDeep(this.props);
    _.update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));

    return <NativeCamera {...transformedProps}/>
  }

  async logData() {
    console.log('front Camera?', await NativeCameraModule.hasFrontCamera());
    console.log('hasFlash?', await NativeCameraModule.hasFlashForCurrentCamera());
    console.log('flashMode?', await NativeCameraModule.getFlashMode());
  }

  static async requestDeviceCameraAuthorization() {
    const usersAuthorizationAnswer = await NativeCameraModule.requestDeviceCameraAuthorization();
    return usersAuthorizationAnswer;
  }

  async capture(saveToCameraRoll = true) {
    const imageTmpPath = await NativeCameraModule.capture(saveToCameraRoll);
    return imageTmpPath;
  }

  async changeCamera() {
    const success = await NativeCameraModule.changeCamera();
    return success;
  }

  async setFlashMode(flashMode = 'auto') {
    const success = await NativeCameraModule.setFlashMode(flashMode);
    return success;
  }

  static async checkDeviceCameraAuthorizationStatus() {
    return await NativeCameraModule.checkDeviceCameraAuthorizationStatus();
  }

  static async hasCameraPermission() {
    const success = await NativeCameraModule.hasCameraPermission();
    return success;
  }
}
