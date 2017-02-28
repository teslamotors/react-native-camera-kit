import _ from 'lodash';
import React, {Component} from 'react';
import ReactNative, {
    requireNativeComponent,
    UIManager
} from 'react-native';

const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');
const GalleryView = requireNativeComponent('GalleryView', null);
const ALL_PHOTOS = 'All Photos';
const COMMAND_REFRESH_GALLERY = 1;

export default class CameraKitGalleryView extends Component {

  constructor(props) {
    super(props);
    this.onTapImage = this.onTapImage.bind(this);
  }

  async refreshGalleryView(lastEditedImage = '') {
    UIManager.dispatchViewManagerCommand(
        ReactNative.findNodeHandle(this),
        COMMAND_REFRESH_GALLERY,
        [lastEditedImage]
    );
    return true;
  }

  render() {
    const transformedProps = {...this.props};
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    if (transformedProps.fileTypeSupport && transformedProps.fileTypeSupport.unsupportedImage) {
      _.update(transformedProps, 'fileTypeSupport.unsupportedImage', (image) => resolveAssetSource(image).uri);
    }
    if (_.get(transformedProps, 'customButtonStyle.image')) {
      _.update(transformedProps, 'customButtonStyle.image', (image) => resolveAssetSource(image).uri);
    }
    if (transformedProps.selectedImageIcon) {
      transformedProps.selectedImageIcon = resolveAssetSource(transformedProps.selectedImageIcon).uri;
    }
    return <GalleryView {...transformedProps} onTapImage={this.onTapImage}/>
  }

  onTapImage(event) {
    if(this.props.onTapImage) {
      this.props.onTapImage(event);
    }
  }
}
