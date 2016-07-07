import React, { Component } from 'react';
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

//import _ from 'lodash';
//import Immutable from 'seamless-immutable';

import {
	CameraKitGallery,
	CameraKitCamera,
  CameraKitGalleryView
} from 'react-native-camera-kit';

import GalleryScreen from './GalleryScreen';

export default class AlbumsScreen extends Component {

	constructor(props) {

		super(props);
		const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    this.state = {
      album: {albumName: 'All Photos'},
      albums: [],
      dropdownVisible: false
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
              //this.onSelectedChanged(result.nativeEvent.selected);
            }}
          //selectedImage={require('./../../images/selected.png')}
          //unSelectedImage={require('./../../images/unSelected.png')}
        />
			</View>
		);
	}

	_renderRow(rowData) {
		const base64Image = 'data:image/png;base64,' + rowData.image;
		return (
			<View style={{flex:1, backgroundColor: '#95a5a6', flexDirection: 'row', padding: 8 }}>
				<Image

					style={{width: 60, height: 60, backgroundColor: 'white'}}
					source={{uri: base64Image, scale: 3}}
				/>
				<TouchableOpacity style={{alignSelf: 'center', padding: 4}} onPress={() => this.setState({albumName: rowData.albumName})}>
					<Text style={{fontSize: 18}}>{rowData.albumName}</Text>
          <Text style={{fontSize: 18}}>{rowData.imagesCount}</Text>
				</TouchableOpacity>
			</View>
		)
	}
	async onGetAlbumsPressed() {
		let albums = await CameraKitGallery.getAlbumsWithThumbnails();
		albums = albums.albums;

		this.setState({albumsDS:this.state.albumsDS.cloneWithRows(albums), albums:{albums}, shouldShowListView: true});
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

	}
});


