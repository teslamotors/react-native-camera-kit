import React, {Component} from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  ListView,
  TouchableOpacity,
  Image,
  AlertIOS
} from 'react-native';

import {
  CameraKitGallery,
  CameraKitCamera,
  CameraKitGalleryView
} from 'react-native-camera-kit';
import _ from 'lodash';

import GalleryScreen from './GalleryScreen';

export default class AlbumsScreen extends Component {

  constructor(props) {

    super(props);
    const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    this.state = {
      album: {albumName: 'All Photos'},
      albums: [],
      dropdownVisible: false,
      images: []
    }
  }

  componentDidMount() {
    this.reloadAlbums();
  }

  async reloadAlbums() {
    const newAlbums = await CameraKitGallery.getAlbumsWithThumbnails();

    let albums = [];

    for (let name in newAlbums.albums) {
      albums.push(_.get(newAlbums, ['albums', name]));
    }
    this.setState({albums})
  }

  render() {

    return (
      <View style={styles.container}>
        <CameraKitGalleryView
          ref={(gallery) => {
                            this.gallery = gallery;
                           }}
          style={{width: 300, height: 300}}
          minimumInteritemSpacing={10}
          minimumLineSpacing={10}
          columnCount={3}
          albumName={'all photos'}
          onSelected={(result) => {
                    console.log(result.nativeEvent.selected);
                    this.setState({images:result.nativeEvent.selected });
          }}
        />

        <TouchableOpacity onPress={() => this.getImagesForIds()}>
          <Text style={styles.buttonText}>
            Albums Screen
          </Text>
        </TouchableOpacity>
      </View>
    );
  }

  async getImagesForIds() {
    const imagesDict = await CameraKitGallery.getImagesForIds(this.state.images);
    console.log('imagesDict', imagesDict);
  }

  async onGetAlbumsPressed() {
    let albums = await CameraKitGallery.getAlbumsWithThumbnails();
    albums = albums.albums;

    this.setState({albumsDS: this.state.albumsDS.cloneWithRows(albums), albums: {albums}, shouldShowListView: true});
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
    margin: 8,
    backgroundColor: '#D6DAC2'
    //alignSelf: 'stretch'

  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20

  }
});


