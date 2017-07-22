import _ from 'lodash';
import React, {Component} from 'react';
import ReactNative, {
    requireNativeComponent,
    UIManager,
    processColor
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

  modifyGalleryViewContentOffset (offset) {
    //do nothing. compatability with ios
  }

  render() {
    const transformedProps = _.cloneDeep(this.props);
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    if (transformedProps.fileTypeSupport && transformedProps.fileTypeSupport.unsupportedImage) {
      _.update(transformedProps, 'fileTypeSupport.unsupportedImage', (image) => resolveAssetSource(image).uri);
    }

    if (_.get(transformedProps, 'customButtonStyle.image')) {
      _.update(transformedProps, 'customButtonStyle.image', (image) => resolveAssetSource(image).uri);
    }

    const customButtonBkgColor = _.get(transformedProps, 'customButtonStyle.backgroundColor');
    if (customButtonBkgColor) {
      _.update(transformedProps, 'customButtonStyle.backgroundColor', (color) => processColor(customButtonBkgColor));
    }

    const selectedImageDeprecated = transformedProps.selectedImageIcon;
    if (selectedImageDeprecated && _.isNumber(selectedImageDeprecated)) {
      transformedProps.selectedImageIcon = resolveAssetSource(selectedImageDeprecated).uri;
    }

    const unselectedImageDeprecated = transformedProps.unSelectedImageIcon;
    if (unselectedImageDeprecated && _.isNumber(unselectedImageDeprecated)) {
      transformedProps.unSelectedImageIcon = resolveAssetSource(unselectedImageDeprecated).uri;
    }

    const selectedImage = _.get(transformedProps, 'selection.selectedImage');
    if (selectedImage && _.isNumber(selectedImage)) {
      _.update(transformedProps, 'selection.selectedImage', (image) => resolveAssetSource(image).uri);
    }

    const unselectedImage = _.get(transformedProps, 'selection.unselectedImage');
    if (unselectedImage && _.isNumber(unselectedImage)) {
      _.update(transformedProps, 'selection.unselectedImage', (image) => resolveAssetSource(image).uri);
    }

    const selectionPosition = _.get(transformedProps, 'selection.imagePosition');
    if (selectionPosition) {
      const positionCode = this.transformSelectedImagePosition(selectionPosition);
      _.update(transformedProps, 'selection.imagePosition', (position) => positionCode);
    }

    const selectionOverlayColor = _.get(transformedProps, 'selection.overlayColor');
    if (selectionOverlayColor) {
      _.update(transformedProps, 'selection.overlayColor', (color) => processColor(selectionOverlayColor));
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
