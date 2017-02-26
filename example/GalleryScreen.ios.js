import React, {Component} from 'react';
import {
  AppRegistry,
  StyleSheet,
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

const size = Math.floor((Dimensions.get('window').width) / 3);
const innerSize = size - 6;

export default class GalleryScreenNative extends Component {

  static navigatorButtons = {
    rightButtons: [
      {
        title: 'Done',
        id: 'navBarDone'
      }
    ]
  };

  constructor(props) {
    super(props);
    this.state = {
      album: this.props.albumName,
    }
  }

  render() {
    return (
      <CameraKitGalleryView
        ref={(gallery) => {
                  this.gallery = gallery;
                }}
        style={{flex:1, margin: 0, marginTop: 50}}
        albumName={this.state.album}
        minimumInteritemSpacing={10}
        minimumLineSpacing={10}
        columnCount={3}
        onSelected={(result) => {

        }}
      />
    )
  }
}

const styles = StyleSheet.create({});

