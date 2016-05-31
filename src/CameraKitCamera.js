import React, {Component} from 'react';
import {
	requireNativeComponent,
} from 'react-native';

const NativeCamera = requireNativeComponent('CKCamera', null);

export default class CameraKitCamera extends React.Component {
	render() {
		return <NativeCamera {...this.props}/>
	}
}