import React, {Component} from 'react';
import {
  requireNativeComponent, DeviceEventEmitter
  //NativeModules
} from 'react-native';

const GalleryView = requireNativeComponent('GalleryView', null);
//const GalleryViewManager = NativeModules.GalleryViewManager;
const ALL_PHOTOS = 'All Photos';

export default class CameraKitGalleryView extends Component {

  static propTypes = {
      //TODO
  };

  constructor(props) {
    super(props);
    this.onTapImage = this.onTapImage.bind(this);
  }

  componentWillMount() {
    DeviceEventEmitter.addListener('onTapImage', this.onTapImage);
  }

  render() {
    const transformedProps = {...this.props};
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    return <GalleryView {...transformedProps}/>
  }

  onTapImage(event) {
    if(this.props.onTapImage) {
      this.props.onTapImage(event);
    }
  }

  //async getSelectedImages() {
  //
  //  const selectedImages = await GalleryViewManager.getSelectedImages();
  //  return selectedImages;
  //}


}
