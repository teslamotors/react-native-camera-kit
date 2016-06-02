import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  ListView,
  TouchableOpacity,
  Image,
} from 'react-native';

import _ from 'lodash';
import Immutable from 'seamless-immutable';

import {
    CameraKitGallery,
    CameraKitCamera,
} from 'react-native-camera-kit';

const FLASH_MODE_AUTO = "auto";
const FLASH_MODE_ON = "on";
const FLASH_MODE_OFF = "off";

class example extends Component {

  constructor(props) {
    super(props);
    const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    this.state = {
      albums:[],
      albumsDS: ds,
      shouldOpenCamera: false,
      shouldShowListView: false,
      image:{imageURI:""},
      flashMode:FLASH_MODE_AUTO
    }
  }


  render() {
        return (
            <View style={styles.container}>
              <TouchableOpacity style={{marginTop: 10, backgroundColor: 'black'}} onPress={this.onGetAlbumsPressed.bind(this)}>
                <Text style={styles.button}>get albums</Text>
              </TouchableOpacity>
              <TouchableOpacity style={{marginTop: 10}} onPress={this.onOpenCameraPressed.bind(this)}>
                <Text style={styles.button}>{this.state.shouldOpenCamera ? "close camera" : "open camera"}</Text>
              </TouchableOpacity>
              {this._renderListView()}
              {this._renderCameraView()}

            </View>

    );
  }

  _renderListView() {
    if (this.state.shouldShowListView) {
      return(
        <ListView
            style={styles.listView}
            dataSource={this.state.albumsDS}
            renderRow={(rowData) =>
                      this._renderRow(rowData)
                    }
        />
      )
    }
  }


  _renderRow(rowData) {
    //console.log('ran', rowData);
    return (
        <View style={{backgroundColor: 'green'}}>
          <Image
              style={{flex:1}}
              source={{uri: rowData.image, scale: 3}}
          />
          <TouchableOpacity style={{marginTop: 10}} onPress={this.onAlbumNamePressed.bind(this, rowData.albumName)}>
            <Text style={{fontSize: 18}}>{rowData.albumName}</Text>
          </TouchableOpacity>
        </View>
    )
  }
  async onGetAlbumsPressed() {
    const albums = await CameraKitGallery.getAlbums();
    const albumsNames = _.map(albums, 'albumName');
    const albumsThumbnails = _.map(albums, 'albumName');

    this.setState({...this.state, albumsDS:this.state.albumsDS.cloneWithRows(albums), albums:albums, shouldShowListView: true});
  }

  async onAlbumNamePressed(albumName) {
    let base64Image = await CameraKitGallery.getThumbnailForAlbumName(albumName);
    let newAlbums = _.uniq(this.state.albums);

    let albumWithImage =
    base64Image = 'data:image/png;base64,' + base64Image;
    let album = _.find(newAlbums, function(o) {
      return o.albumName === albumName;
    });
    const albumIndex = _.indexOf(newAlbums, album);
    album = {...album, image:base64Image };
    newAlbums[albumIndex] = album;

    this.setState({albumsDS:this.state.albumsDS.cloneWithRows(newAlbums), albums:newAlbums});

  }

  _renderCameraView() {
    if (this.state.shouldOpenCamera) {
      return (
          <View style={{ flex:1,  backgroundColor: 'gray', marginHorizontal: 8, marginBottom:8}}>

            <TouchableOpacity style={{flex: 1, flexDirection:'row'}} onPress={this.onTakeIt.bind(this)}>
              <CameraKitCamera
                  ref={(cam) => {
                  this.camera = cam;
                }}
                  style={{flex: 1}}
                  cameraOptions= {{
                    flashMode: 'auto',
                    focusMode: 'on'
                  }}
              />
            </TouchableOpacity>
            <View style={{flexDirection: 'row'}}>


              <Image
                  style={{ flexDirection:'row', backgroundColor: 'gray', width: 100, height: 100}}
                  source={{uri: this.state.image.imageURI, scale: 3}}
              />

              <TouchableOpacity style={{alignSelf:'center', marginHorizontal: 4}} onPress={this.onSwitchCameraPressed.bind(this)}>
                <Text>switch camera</Text>
              </TouchableOpacity>

              <View style={{ flexDirection:'column', justifyContent: 'space-between'}}>
                <TouchableOpacity style={{ marginHorizontal: 4}} onPress={this.onSetFlash.bind(this, FLASH_MODE_AUTO)}>
                  <Text>flash auto</Text>
                </TouchableOpacity>

                <TouchableOpacity style={{ marginHorizontal: 4, }} onPress={this.onSetFlash.bind(this, FLASH_MODE_ON)}>
                  <Text>flash on</Text>
                </TouchableOpacity>
                
                <TouchableOpacity style={{ marginHorizontal: 4,}} onPress={this.onSetFlash.bind(this, FLASH_MODE_OFF)}>
                  <Text>flash off</Text>
                </TouchableOpacity>
              </View>

            </View>
          </View>

      )
    }
  }

  async onSwitchCameraPressed() {
    const success = await this.camera.changeCamera();
  }

  async onSetFlash(flashMode) {
    const success = await this.camera.setFleshMode(flashMode);
  }

  async onTakeIt() {
    const imageURI = await this.camera.capture(false);
    let newImage = {imageURI: imageURI};
    this.setState({...this.state, image:newImage});
  }

  onOpenCameraPressed() {
    this.setState({shouldOpenCamera:!this.state.shouldOpenCamera});
  }


}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    //justifyContent: 'center',
    //alignItems: 'center',
    backgroundColor: '#F5FCFF',
    marginTop: 20
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
  row: {
    flexDirection: 'row',
    justifyContent: 'center',
    padding: 10,
    backgroundColor: '#F6F6F6',
  },
  text: {
    flex: 1,
  },
  button: {
    fontSize: 18,
    alignSelf: 'center',
    backgroundColor: 'green'
  },
  listView: {
    //flex:1,
    //flexDirection:'column',
    margin: 8,
    backgroundColor: '#D6DAC2',
    //alignSelf: 'stretch'

  },
});

AppRegistry.registerComponent('example', () => example);
