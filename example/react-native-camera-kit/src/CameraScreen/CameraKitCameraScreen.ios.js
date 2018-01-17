import React, { Component } from 'react';
import {View} from 'react-native';
import CameraScreenBase from './CameraKitCameraScreenBase';

export default class CameraScreen extends CameraScreenBase {

  render() {
    return (
      <View style={{ flex: 1, backgroundColor: 'black' }} {...this.props}>
        {this.renderTopButtons()}
        {this.renderCamera()}
        {this.renderRatioStrip()}
        {this.renderBottomButtons()}
      </View>
    );
  }
}
