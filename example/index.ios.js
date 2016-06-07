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
      albums:{},
      albumsDS: ds,
      shouldOpenCamera: false,
      shouldShowListView: false,
      image:{imageURI:""},
      flashMode:FLASH_MODE_AUTO
    }
  }


  render() {
    if (this.state.shouldOpenCamera) {
      return (
          this._renderCameraView()
      )
    }
        return (
            <View style={styles.container}>
              <TouchableOpacity style={styles.apiButton} onPress={this.onGetAlbumsPressed.bind(this)}>
                <Text style={styles.button}>get albums</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.apiButton} onPress={this.onOpenCameraPressed.bind(this)}>
                <Text style={styles.button}>{this.state.shouldOpenCamera ? "close camera" : "open camera"}</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.apiButton} onPress={this.onCheckAuthoPressed.bind(this)}>
                <Text style={styles.button}>check device authorizarion status </Text>
              </TouchableOpacity>

              {this._renderListView()}
              {}

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
    console.log('rannnn', rowData.image);
    const base64Image = 'data:image/png;base64,' + rowData.image;
    return (
        <View style={{flex:1, backgroundColor: 'green'}}>
          <Image
              style={{width: 60, height: 60, backgroundColor: 'white'}}
              source={{uri: base64Image, scale: 3}}
          />
          <TouchableOpacity style={{marginTop: 10}} onPress={this.onAlbumNamePressed.bind(this, rowData)}>
            <Text style={{fontSize: 18}}>{rowData.name}</Text>
          </TouchableOpacity>
        </View>
    )
  }
  async onGetAlbumsPressed() {
    let albums = await CameraKitGallery.getAlbums();
    albums = albums.albums;
    console.log('albums',albums);
    //if (!albums) return;
    //const albumsNames = _.map(albums, 'albumName');
    //const albumsThumbnails = _.map(albums, 'albumName');
    const kk = this.state.albumsDS.cloneWithRows(albums);
    //console.log('kkkkkkkkkkk', kk);
    this.setState({...this.state, albumsDS:this.state.albumsDS.cloneWithRows(albums), albums:{albums}, shouldShowListView: true});
  }

  async onAlbumNamePressed(album) {

    let base64Image = await CameraKitGallery.getThumbnailForAlbumName(album.name);

    base64Image = 'data:image/png;base64,' + base64Image;

    album.image = base64Image;

    let albums = {};
    _.merge(albums, this.state.albums);
    albums = albums.albums;

    console.log('before', albums);
    const key = album.name;
    albums.key = album;
    //
    //console.log('after', _.toArray(albums));
    //
    ////console.log('llll', albums);
    //
    this.setState({...this.state, albumsDS:this.state.albumsDS.cloneWithRows(albums), albums:{albums}, shouldShowListView: true});


    //let album = _.find(newAlbums, function(o) {
    //  return o === albumName;
    //});
    //
    //console.log('newAlbums', newAlbums);
    //console.log('album', album);
    //const albumIndex = _.indexOf(newAlbums, album);
    //if (albumIndex < 0) {
    //  console.error('ERROR: albumIndex is' + albumIndex);
    //  return;
    //}
    //
    //let newArray = _.remove(newAlbums, function(o) {
    //  return o === album;
    //});
    //let albumWithImage = {...album, image:base64Image };
    //console.log('a', album);
    //newAlbums[albumIndex] = album;
    //console.error(album);
    //
    //let albums = this.state.albums;
    //albums = albums.albums;
    //console.log('before', albums);
    ////const key = album.name;
    ////albums.key = album;
    ////
    ////console.log('after', _.toArray(albums));
    ////
    //////console.log('llll', albums);
    ////
    //this.setState({...this.state, albumsDS:this.state.albumsDS.cloneWithRows(albums), albums:{albums}, shouldShowListView: true});



  }

  _renderCameraView() {
      return (
          <View style={{ flex:1,  backgroundColor: 'gray', marginBottom:8}}>

            <View style={{flex: 1, flexDirection:'column', backgroundColor:'black'}} onPress={this.onTakeIt.bind(this)}>
              <CameraKitCamera
                  ref={(cam) => {
                  this.camera = cam;
                }}
                  style={{flex: 1}}
                  cameraOptions= {{
                    flashMode: 'auto',    // on/off/auto(default)
                    focusMode: 'on',      // off/on(default)
                    zoomMode: 'on'        // off/on(default)
                  }}
              />
              <TouchableOpacity style={{alignSelf:'center', marginHorizontal: 4}} onPress={this.onTakeIt.bind(this)}>
                <Text style={{fontSize: 22, color: 'lightgray', backgroundColor: 'hotpink'}}>TAKE IT!</Text>
              </TouchableOpacity>
            </View>


            <View style={{flexDirection: 'row'}}>


              <Image
                  style={{ flexDirection:'row', backgroundColor: 'black', width: 100, height: 100}}
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
            <TouchableOpacity style={{position: 'absolute', width:25, height: 100,top:20, left:10, backgroundColor: 'transparent'}} onPress={this.onOpenCameraPressed.bind(this)}>
              <Text style={{fontWeight:'200',  fontSize: 40, color:'lightgray'}}>X</Text>
            </TouchableOpacity>
          </View>
      )
  }

  async onSwitchCameraPressed() {
    const success = await this.camera.changeCamera();
  }

  async onCheckAuthoPressed() {
    const success = await CameraKitCamera.checkDeviceAuthorizarionStatus();
    if (success){
      AlertIOS.alert('You rock!')
    }
    else {
      AlertIOS.alert('You fucked!')
    }
  }

  async onSetFlash(flashMode) {
    const success = await this.camera.setFleshMode(flashMode);
  }

  async onTakeIt() {
    const imageURI = await this.camera.capture(true);
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
    fontSize: 22,
    alignSelf: 'center',
    backgroundColor: 'transparent'
  },
  listView: {
    //flex:1,
    //flexDirection:'column',
    margin: 8,
    backgroundColor: '#D6DAC2',
    //alignSelf: 'stretch'

  },
  apiButton:{
    marginTop: 20,
    backgroundColor: 'gray',
    padding: 10
  }
});

AppRegistry.registerComponent('example', () => example);
