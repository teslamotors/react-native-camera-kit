import React from 'react-native';

const {
    AppRegistry,
    Component,
    StyleSheet,
    Text,
    View,
    Image,
    TouchableOpacity,
    PixelRatio,
    NativeModules: {
        ReactNativeCameraKit
        }
    } = React;

class Example extends Component {
  state = {
    photoSource: null,
    error: null
  };

  selectPhotoTapped() {
    const options = {
      message: 'Recent Images',
      takePhotoActionTitle: 'Take a Photo',
      pickPhotoActionTitle: 'Gallery',
      cancelActionTitle: 'Cancel',
      sendSelectedPhotosTitle: 'Send %lu Photo',
      aspectRatioInfoMessage: 'Your images look best with 16:9 ratio',
      aspectRatios: ["16:9", "1:1", "4:3", "3:2", "2:3", "3:4", "9:16"],
      collectionName: 'eCom'
    };

      ReactNativeCameraKit.presentPhotoPicker(options, (response) => {
      if (response.images) {
        const source = {uri: 'data:image/jpeg;base64,' + response.images[response.images.length -1], isStatic: true};
        this.setState({
          photoSource: source
        });
      }
      if (response.error) {
        this.setState({
          error: response.error
        });
      }
    });
  }
  render() {
    return (
        <View style={styles.container}>
<TouchableOpacity onPress={this.selectPhotoTapped.bind(this)}>
<View style={[styles.photo, styles.photoContainer, {marginBottom: 20}]}>
{ this.state.photoSource === null ? <Text>Select a Photo</Text> :
<Image style={styles.photo} source={this.state.photoSource} />
}
</View>
{ this.state.error ? <Text>this.state.error</Text> : null }
</TouchableOpacity>
</View>
);
}
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF'
  },
  photoContainer: {
    borderColor: '#9B9B9B',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1 / PixelRatio.get()
  },
  photo: {
    width: 150,
    height: 150
  }
});

AppRegistry.registerComponent('ReactNativeCameraKit', () => Example);
