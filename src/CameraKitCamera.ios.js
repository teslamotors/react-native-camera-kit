import React, {Component} from 'react';
import {
	requireNativeComponent,
	NativeModules
} from 'react-native';

const NativeCamera = requireNativeComponent('CKCamera', null);
const NativeCameraAction = NativeModules.CKCameraManager;

export default class CameraKitCamera extends React.Component {
	render() {
		return <NativeCamera {...this.props}/>
	}

	static async checkDeviceAuthorizarionStatus() {
		const deviceAutorizationStatus = await NativeCameraAction.checkDeviceAuthorizationStatus();
		
		return deviceAutorizationStatus;
	}

	async capture(saveToCameraRoll = true) {
		const imageTmpPath = await NativeCameraAction.capture(saveToCameraRoll);
		return imageTmpPath;
	}

	async changeCamera() {
		const success = await NativeCameraAction.changeCamera();
		return success;
	}

	async setFlashMode(flashMode = 'auto') {
		const success = await NativeCameraAction.setFlashMode(flashMode);
		return success;
	}
}
