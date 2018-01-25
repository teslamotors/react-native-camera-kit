import React, { PropTypes, Component } from 'react';
import {
  requireNativeComponent,
  UIManager,
  findNodeHandle,
  View
} from 'react-native';

export default class CameraKitBarcode extends React.Component {

  render() {
    return (
      <View {...this.props} collapsable={false}>
        <BarcodeCamera ref={r => this.barcodeScanner = r} style={{ flex: 1 }} />
      </View>
    )
  }

  componentDidMount() {
    UIManager.dispatchViewManagerCommand(
      findNodeHandle(this.barcodeScanner),
      UIManager.BarcodeCameraView.Commands.startCamera,
      [],
    );
  }

  componentWillUnmount() {
    UIManager.dispatchViewManagerCommand(
      findNodeHandle(this.barcodeScanner),
      UIManager.BarcodeCameraView.Commands.stopCamera,
      [],
    );
  }

}

CameraKitBarcode.propTypes = {
  ...View.propTypes,
};

const BarcodeCamera = requireNativeComponent('BarcodeCameraView', CameraKitBarcode);