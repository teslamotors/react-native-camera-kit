import React, { Component } from 'react';
import { CameraKitBarcode } from 'react-native-camera-kit';


export default class BarcodeScreen extends Component {

  render() {
    return <CameraKitBarcode style={{ flex: 1 }} />
  }
}



