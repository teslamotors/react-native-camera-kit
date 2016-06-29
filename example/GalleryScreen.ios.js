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

import _ from 'lodash';

import {
  CameraKitGalleryView
} from 'react-native-camera-kit';

var groupByEveryN = require('groupByEveryN');
const ds = new ListView.DataSource({
  rowHasChanged: (r1, r2) => r1 !== r2
});

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

  async onNavigatorEvent(event) {
    if (event.type === 'NavBarButtonPress') {
      if (event.id === 'navBarDone') {
        const selected = await this.gallery.getSelectedImages();

        this.props.navigator.push({
          screen: 'media.PreviewScreen',
          title: 'Preview',
          backButtonTitle: 'Albums',
          passProps: {
            imagesData: selected.selectedImages
          },
          navigatorStyle: {
            navBarHidden: true
          }
        });
      }
    }
  }

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
        style={{flex:1}}
        albumName={this.state.album}/>
    )
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
    marginTop: 20
  },
  listView: {
    //flex:1,
    //flexDirection:'column',
    paddingTop: 0,
    margin: 8,
    backgroundColor: '#D6DAC2',

  },
  row: {
    flexDirection: 'column',
    flex: 1,
  },
  image: {
    width: innerSize,
    height: innerSize,
    alignItems: 'center',
    justifyContent: 'center'
  },
  rowContainer: {
    width: size,
    height: size,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

