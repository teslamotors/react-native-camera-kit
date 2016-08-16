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

  imageTapped(selected) {
    if (this.state.images.indexOf(selected) < 0) {
      this.setState({images: _.concat(this.state.images, [selected]) });
    }
    else {
      _.remove(this.state.images, (e)=> e === selected);
    }

  }

  render() {

    return (
      <View style={styles.container}>
        <CameraKitGalleryView
          ref={(gallery) => {
                            this.gallery = gallery;
                           }}
          style={{flex:1, backgroundColor:'green'}}
          minimumInteritemSpacing={10}
          minimumLineSpacing={10}
          columnCount={3}
          albumName={'all photos'}
          onTapImage={(result) => {
                    this.imageTapped(result.nativeEvent.selected);
          }}
          fileTypeSupport={{
                      supportedFileTypes: ['image/png'],
                      unsupportedOverlayColor: "#00000055",
                      unsupportedImage: require('./images/unsupportedImage.png'),
                      unsupportedText: 'Unsupported',
                      unsupportedTextColor: '#ffffff'
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
    console.log('getImagesForIds', this.state.images);
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
    //alignItems: 'center',
    backgroundColor: '#ff0000',
    marginTop: 20
  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20

  }
});


