import React, {Component} from 'react';
import {
  requireNativeComponent
} from 'react-native';

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

  componentWillMount() {
    //UIManagerModule.addListener('onTapImage', this.onTapImage);
  }

  render() {
    const transformedProps = {...this.props};
    transformedProps.albumName = this.props.albumName ? this.props.albumName : ALL_PHOTOS;
    return <GalleryView {...transformedProps} onTapImage={this.onTapImage}/>
  }

  onTapImage(event) {
    if(this.props.onTapImage) {
      this.props.onTapImage(event.nativeEvent);
    }
  }


}
