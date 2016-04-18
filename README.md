# react-native-camera-kit
Currently work-in-progress

Advanced native camera control with pre-defined aspect ratio, crop, etc

## Install

1. In your project folder run `npm install react-native-camera-kit --save`
2. Install Cocoa Pods by running `sudo gem install cocoapods`
3. Go to 'your-project-folder/ios' and run `pod install`
4. Close your XCode and open the `your-project.xcworkspace` that was created

## Usage

All you need is to `require` the `react-native-camera-kit` module, import `NativeModules` from `react-native` and then use the
`ReactNativeCameraKit` native module.

## Example

```javascript
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
      takePhotoActionTitle: 'Take a photo',
      pickPhotoActionTitle: 'Gallery',
      cancelActionTitle: 'Cancel',
      sendSelectedPhotosTitle: 'Send %lu photo(s)',
      aspectRatioInfoMessage: 'Your images look best with 16:9 ratio',
      aspectRatios: ["16:9", "1:1", "4:3"],
      collectionName: 'your-folder'
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
                { this.state.photoSource === null 
                  ? <Text>Select a Photo</Text> 
                  : <Image style={styles.photo} source={this.state.photoSource} />
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
    width: 100,
    height: 100
  }
});

AppRegistry.registerComponent('ReactNativeCameraKit', () => Example);
```
