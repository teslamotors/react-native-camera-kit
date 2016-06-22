import React, {Component} from 'react';
import {
  requireNativeComponent,
  NativeModules
} from 'react-native';

const GalleryView = requireNativeComponent('CKGalleryView', null);
const GalleryViewManager = NativeModules.CKGalleryViewManager;

export default class CameraKitGalleryView extends Component {

  render() {
    return <GalleryView {...this.props}/>
  }

  async getSelectedImages() {

    const selectedImages = await GalleryViewManager.getSelectedImages();
    return selectedImages;
  }


}
