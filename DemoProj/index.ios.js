/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, {
  AppRegistry,
  Component,
  StyleSheet,
  Text,
  View,
    NativeModules
} from 'react-native';

class DemoProj extends Component {
  componentDidMount() {
    console.log('NATIVE', NativeModules.ReactNativeCameraKit);
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

    NativeModules.ReactNativeCameraKit.presentPhotoPicker(options, (response) => {
      if (response.images) {
        //TODO: save photos
        for (var image of response.images) {
          this.state.media.push({
            base64Source: {uri: 'data:image/jpeg;base64,' + image, isStatic: true},
            index: this.state.media.length
          });
        }
        this.setState({
          order: Object.keys(this.state.media)
        });
      }
    });
  }
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native!
        </Text>
        <Text style={styles.instructions}>
          To get started, edit index.ios.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for dev menu
        </Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('DemoProj', () => DemoProj);
