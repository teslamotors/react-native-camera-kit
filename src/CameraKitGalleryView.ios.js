import _ from 'lodash';
import React, {Component} from 'react';

import {
  requireNativeComponent,
  NativeModules,
  processColor
} from 'react-native';

const GalleryView = requireNativeComponent('CKGalleryView', null);
const GalleryViewManager = NativeModules.CKGalleryViewManager;
const ALL_PHOTOS = 'All Photos';
const DEFAULT_COLUMN_COUNT = 3;
const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');

export default class CameraKitGalleryView extends Component {
  render() {
    const transformedProps = {...this.props};
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    transformedProps.columnCount = this.props.columnCount && this.props.columnCount > 0 ? this.props.columnCount : DEFAULT_COLUMN_COUNT;
    _.update(transformedProps, 'fileTypeSupport.unsupportedOverlayColor', (c) => processColor(c));
    _.update(transformedProps, 'fileTypeSupport.unsupportedTextColor', (c) => processColor(c));
    if (transformedProps.fileTypeSupport && transformedProps.fileTypeSupport.unsupportedImage) {
      _.update(transformedProps, 'fileTypeSupport.unsupportedImage', (image) => resolveAssetSource(image));
    }

    return <GalleryView {...transformedProps}/>
  }

  async getSelectedImages() {
    const selectedImages = await GalleryViewManager.getSelectedImages();
    return selectedImages;
  }

  async refreshGalleryView(selectedImages = []) {
    const isSuccess = await GalleryViewManager.refreshGalleryView(selectedImages);
    return isSuccess;
  }
}
