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
  Dimensions
} from 'react-native';

import {
  CameraKitGallery,
  CameraKitCamera,
  CameraKitGalleryView
} from 'react-native-camera-kit';
import _ from 'lodash';

import GalleryScreen from './GalleryScreen';

const {height, width} = Dimensions.get('window');

export default class AlbumsScreen extends Component {
  
  constructor(props) {
    
    super(props);
    const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    this.state = {
      album: {albumName: 'All Photos'},
      albums: [],
      dropdownVisible: false,
      images: [],
      imagesDetails: undefined
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
      console.log('RANG', 'imageTapped', 'selected', selected);
      this.setState({images: _.concat(this.state.images, selected) });
    }
    else {
      this.setState({images: _.without(this.state.images, selected)})
      
    }
    
  }
  
  render() {
    return (
      <View style={styles.container}>
        <CameraKitGalleryView
          ref={(gallery) => {
            this.gallery = gallery;
          }}
          style={{flex: 1, backgroundColor:'green'}}
          minimumInteritemSpacing={10}
          minimumLineSpacing={10}
          columnCount={3}
          albumName={'all photos'}
          onTapImage={(result) => {
            this.imageTapped(result.nativeEvent.selected);
          }}
          fileTypeSupport={{
            unsupportedOverlayColor: "#00000055",
            unsupportedImage: require('./images/unsupportedImage.png'),
            unsupportedText: 'Unsupported',
            unsupportedTextColor: '#ffffff'
          }}
          imageStrokeColor={'#edeff0'}
          customButtonStyle={{
            image: require('./images/openCamera.png'),
            backgroundColor: '#2dcedb'
          }}
          onCustomButtonPress={(result) => {
            
            this.onCustomButtonPressed();
          }}
        />
        
        
        
        <View style={{
          alignItems: 'center',
          justifyContent: 'space-between',}}>
          {this.renderImagesDetails()}
          
          <TouchableOpacity  onPress={() => this.getImagesForIds()}>
            <Text style={styles.buttonText}>
              Get Selected Images
            </Text>
          </TouchableOpacity>
        </View>
      
      </View>
    );
  }
  
  onCustomButtonPressed() {
    console.log('RANG', 'custom button pressed');
  }
  
  renderImagesDetails() {
    if (!this.state.imagesDetails) {
      return null;
    }
    
    return (
      <View>
        <Text>
          {JSON.stringify(this.state.imagesDetails)}
        </Text>
      </View>
    )
  }
  
  async getImagesForIds() {
    const imagesDict = await CameraKitGallery.getImagesForIds(this.state.images);
    this.setState({imagesDetails: imagesDict});
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
    backgroundColor: '#aabdc3c7',
    marginTop: 20
  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20
  }
});


