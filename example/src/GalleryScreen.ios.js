import React, {Component} from 'react';
import {
  StyleSheet,
  View,
  Button,
  Image,
  Dimensions
} from 'react-native';

import {
  CameraKitGallery,
  CameraKitGalleryView
} from 'react-native-camera-kit';

const {width, height} = Dimensions.get('window');
const size = Math.floor((Dimensions.get('window').width) / 3);

export default class GalleryScreen extends Component {

  constructor(props) {
    super(props);
    this.state = {
      album: this.props.albumName,
      presentedImage: undefined
    }
  }

  async onTapImage(event) {
    const image = await CameraKitGallery.getImageForTapEvent(event.nativeEvent);

    if (image) {
      this.setState({presentedImage: image});
    }
  }

  renderPresentedImage() {
    return (
      <View style={{position: 'absolute', width, height, backgroundColor: 'green'}}>
        <View style={styles.container}>
          <Image
            resizeMode={Image.resizeMode.cover}
            style={{width: 300, height: 300}}
            source={{uri: this.state.presentedImage.imageUri}}
          />

          <Button
            title={'Back'}
            onPress={() => this.setState({presentedImage: undefined})}
          />
        </View>
      </View>
    )
  }

  render() {

    return (
      <View style={{flex: 1}}>
        <CameraKitGalleryView
          ref={(gallery) => {
            this.gallery = gallery;
          }}
          style={{flex:1, margin: 0, marginTop: 50}}
          albumName={this.state.album}
          minimumInteritemSpacing={10}
          minimumLineSpacing={10}
          columnCount={3}
          onTapImage={event => {this.onTapImage(event)}}
        />
        {this.state.presentedImage && this.renderPresentedImage()}
      </View>
    )
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  }
});
