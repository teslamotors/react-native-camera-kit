import React, {Component} from 'react';
import {
    AppRegistry,
    Text,
    View,
    ListView,
    TouchableOpacity,
    Image,
    AlertIOS,
    CameraRoll,
    Dimensions
} from 'react-native';

import {
    CameraKitGalleryView
} from 'react-native-camera-kit';

import CameraScreen from './CameraScreen';

const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');

export default class GalleryScreenNative extends Component {

  constructor(props) {
    super(props);
    this.state = {
      album: this.props.albumName,
      shouldRenderCameraScreen: false
    }
  }

  render() {
    if (this.state.shouldRenderCameraScreen) {
      return (<CameraScreen/>);
    }

    return (
        <CameraKitGalleryView
            ref={(gallery) => {
                this.gallery = gallery;
            }}
            style={{flex:1, margin: 0, backgroundColor: '#ffffff', marginTop: 50}}
            albumName={this.state.album}
            minimumInteritemSpacing={10}
            minimumLineSpacing={10}
            columnCount={3}
            onSelected={(result) => {
            }}
            onTapImage={(event) => console.log('Tapped on an image: ' + event.nativeEvent.selected)}
            selection={{
              selectedImage: require('./images/wix_logo.png'),
              position: "bottomRight",
              size: "large"
            }}
            fileTypeSupport={{
                supportedFileTypes: ['image/jpeg'],
                unsupportedOverlayColor: "#00000055",
                unsupportedImage: require('./images/unsupportedImage.png'),
                //unsupportedText: 'JPEG!!',
                unsupportedTextColor: '#ff0000'
            }}
            customButtonStyle={{
                image: require('./images/openCamera.png'),
                backgroundColor: '#06c4e9'
            }}
            onCustomButtonPress={() => this.setState({shouldRenderCameraScreen: true})}
        />
    )
  }
}
