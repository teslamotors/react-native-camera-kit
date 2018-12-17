import React, { Component } from 'react';
import {
    StyleSheet,
    Text,
    View,
    TouchableOpacity,
    Image,
    FlatList
} from 'react-native';

import {CameraKitGallery} from '../../src';

import GalleryScreen from './GalleryScreen';

export default class AlbumsScreen extends Component {

  constructor(props) {

    super(props);
    this.state = {
      albums:{},
      albumsDS: [],
      albumName: undefined
    }
  }

  componentDidMount() {
    this.onGetAlbumsPressed();
  }

  render() {

    if (this.state.albumName) {
      const albumName = this.state.albumName;
      return <GalleryScreen albumName={albumName}/>;
    }

    return (
        <View style={styles.container}>
          <FlatList
              style={styles.listView}
              data={this.state.albumsDS}
              renderItem={this._renderRow}
          />
        </View>
    );
  }

  _renderRow(rowData) {
    const item = rowData.item;
    const image = 'file://' + item.thumbUri;
    return (
        <View key={item.thumbUri} style={{flex:1, backgroundColor: '#95a5a6', flexDirection: 'row', padding: 8 }}>
          <Image

              style={{width: 60, height: 60, backgroundColor: 'white'}}
              source={{uri: image, scale: 3}}
          />
          <TouchableOpacity style={{alignSelf: 'center', padding: 4}} onPress={() => this.setState({albumName: item.albumName})}>
            <Text style={{fontSize: 18}}>{item.albumName}</Text>
            <Text style={{fontSize: 18}}>{item.imagesCount}</Text>
          </TouchableOpacity>
        </View>
    )
  }
  async onGetAlbumsPressed() {
    let albums = await CameraKitGallery.getAlbumsWithThumbnails();
    albums = albums.albums;

    this.setState({albumsDS: albums, albums:{albums}, shouldShowListView: true});
  }

}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5FCFF',
    marginTop: 20
  },
  listView: {
    margin: 8,
    backgroundColor: '#D6DAC2'
  }
});


