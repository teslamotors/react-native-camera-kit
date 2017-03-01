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
    if (_.get(transformedProps, 'selection.selectedImage')) {
      _.update(transformedProps, 'selection.selectedImage', (image) => resolveAssetSource(image).uri);
    }
    if (_.get(transformedProps, 'selection.position')) {
      const position = this.transformSelectedImagePosition(_.get(transformedProps, 'selection.position'));
      _.update(transformedProps, 'selection.position', (pos) => position);
    }
    return <GalleryView {...transformedProps} onTapImage={this.onTapImage}/>
  }

  onTapImage(event) {
    if(this.props.onTapImage) {
      this.props.onTapImage(event);
    }
  }

  transformSelectedImagePosition(position) {
    switch (position) {
      case 'top-right': return 0;
      case 'top-left': return 1;
      case 'bottom-right': return 2;
      case 'bottom-left': return 3;
      case 'center': return 4;
      default: return null;
    }
  }
}
