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
    const transformedProps = _.cloneDeep(this.props);
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    transformedProps.columnCount = this.props.columnCount && this.props.columnCount > 0 ? this.props.columnCount : DEFAULT_COLUMN_COUNT;
    _.update(transformedProps, 'fileTypeSupport.unsupportedOverlayColor', (c) => processColor(c));
    _.update(transformedProps, 'fileTypeSupport.unsupportedTextColor', (c) => processColor(c));
    if (transformedProps.fileTypeSupport && transformedProps.fileTypeSupport.unsupportedImage) {
      _.update(transformedProps, 'fileTypeSupport.unsupportedImage', (image) => resolveAssetSource(image));
    }
    if (_.get(transformedProps, 'customButtonStyle.image')) {
      _.update(transformedProps, 'customButtonStyle.image', (image) => resolveAssetSource(image));
    }

    if (_.get(transformedProps, 'customButtonStyle.backgroundColor')) {
      _.update(transformedProps, 'customButtonStyle.backgroundColor', (c) => processColor(c));
    }

    if (_.get(transformedProps, 'selection.selectedImage')) {
      _.update(transformedProps, 'selection.selectedImage', (image) => resolveAssetSource(image));
    }

    if (_.get(transformedProps, 'selection.unselectedImage')) {
      _.update(transformedProps, 'selection.unselectedImage', (image) => resolveAssetSource(image));
    }

    if (_.get(transformedProps, 'selection.overlayColor')) {
      _.update(transformedProps, 'selection.overlayColor', (c) => processColor(c));
    }

    return <GalleryView {...transformedProps}/>
  }

  async getSelectedImages() {
    return await GalleryViewManager.getSelectedImages();
  }

  async refreshGalleryView(selectedImages = []) {
    return await GalleryViewManager.refreshGalleryView(selectedImages);
  }

  modifyGalleryViewContentOffset (offset) {
    GalleryViewManager.modifyGalleryViewContentOffset(offset);
  }
}
