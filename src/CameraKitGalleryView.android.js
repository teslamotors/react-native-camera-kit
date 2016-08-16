import React, {Component} from 'react';
import ReactNative, {
    requireNativeComponent,
    UIManager
} from 'react-native';
const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');
import _ from 'lodash';

const GalleryView = requireNativeComponent('GalleryView', null);
const ALL_PHOTOS = 'All Photos';
export default class CameraKitGalleryView extends Component {

  static propTypes = {
      //TODO
  };

  constructor(props) {
    super(props);
    this.onTapImage = this.onTapImage.bind(this);
  }

  async refreshGalleryView(selectedImages = []) {

    UIManager.dispatchViewManagerCommand(
        ReactNative.findNodeHandle(this),
        1,
        [selectedImages]
    );
    return true;
  }

  render() {
    const transformedProps = {...this.props};
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    if (transformedProps.fileTypeSupport && transformedProps.fileTypeSupport.unsupportedImage) {
      _.update(transformedProps, 'fileTypeSupport.unsupportedImage', (image) => resolveAssetSource(image).uri);
    }
    return <GalleryView {...transformedProps} onTapImage={this.onTapImage}/>
  }

  onTapImage(event) {
    if(this.props.onTapImage) {
      this.props.onTapImage(event);
    }
  }
}
