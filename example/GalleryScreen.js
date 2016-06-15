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
  CameraRoll
} from 'react-native';

import _ from 'lodash';
import Immutable from 'seamless-immutable';

import {
  CameraKitGallery
} from 'react-native-camera-kit';

var groupByEveryN = require('groupByEveryN');

function renderImage(asset) {
  var imageSize = 150;
  var imageStyle = [styles.image, {width: imageSize, height: imageSize}];
  return (
    <Image
      source={asset.node.image}
      style={imageStyle}
    />
  );
}

export default class GalleryScreen extends Component {

  constructor(props) {
    super(props);
    const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    this.state = {
      albums: {},
      dataSource: ds,
      albumName: this.props.albumName,
      assets: []
    }
  }

  componentDidMount() {
    if (this.state.albumName) {

      CameraKitGallery.getPhotosForAlbum(this.state.albumName, 100, (data) => this._appendAssets(data), (e) => logError(e));
    }
  }

  render() {
    return (
      <View style={styles.container}>
        <Text>{this.state.albumName}</Text>
        <ListView
          renderRow={this._renderRow}
          style={{flex: 1, backgroundColor: 'blue', }}
          dataSource={this.state.dataSource}
        />

      </View>
    );
  }

  rendererChanged() {
    console.log('ppppp');
    var ds = new ListView.DataSource({rowHasChanged: this._rowHasChanged});
    this.state.dataSource = ds.cloneWithRows(
      groupByEveryN(this.state.assets, this.props.imagesPerRow)
    );
  }

  _renderImage(asset) {
    var imageSize = 150;
    var imageStyle = [styles.image, {width: imageSize, height: imageSize}];
    return (
      <Image
        source={asset.node.image}
        style={imageStyle}
      />
    );
  }

  _renderRow(rowData:Array<Image>, sectionID:string, rowID:string) {
    console.log(rowID)
    var images = rowData.map((image) => {
      if (image === null) {
        return null;
      }
      return renderImage(image);
    });

    return (
      <View style={styles.row} key={rowID}>
        {images}
      </View>
    );
  }

  _appendAssets(data) {
    console.log('datadata', data);
    if (data) {

      var assets = data.edges;
      var newState:Object = {loadingMore: false};

      if (!data.page_info.has_next_page) {
        newState.noMore = true;
      }

      if (assets.length > 0) {

        newState.lastCursor = data.page_info.end_cursor;
        newState.assets = this.state.assets.concat(assets);

        newState.dataSource = this.state.dataSource.cloneWithRows(
          groupByEveryN(newState.assets, 25)
        );
      }
      this.setState(newState);
    }
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
    margin: 4,
    marginBottom: 0
  },
});


