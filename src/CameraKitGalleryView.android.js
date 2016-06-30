import React, {Component} from 'react';
import {
  requireNativeComponent,
  //NativeModules
} from 'react-native';

const GalleryView = requireNativeComponent('GalleryView', null);
//const GalleryViewManager = NativeModules.GalleryViewManager;
const ALL_PHOTOS = 'All Photos';

export default class CameraKitGalleryView extends Component {

  render() {
    const transformedProps = {...this.props};
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;

    return <GalleryView {...transformedProps}/>
  }

  //async getSelectedImages() {
  //
  //  const selectedImages = await GalleryViewManager.getSelectedImages();
  //  return selectedImages;
  //}


}
