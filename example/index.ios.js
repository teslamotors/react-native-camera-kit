import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  ListView,
  TouchableOpacity
} from 'react-native';

import {CameraKitCamera} from 'react-native-camera-kit';

class example extends Component {

  constructor(props) {
    super(props);
    this.state = {
      albumsName: (new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2})),
      shouldOpenCamera: false,
    }
  }


  render() {
    //console.error(CameraKitCamera);

        return (
            <View style={styles.container}>

              <TouchableOpacity style={{marginTop: 10}} onPress={this.onGetAlbumsPressed.bind(this)}>
                <Text style={styles.button}>get albums</Text>
              </TouchableOpacity>
              <ListView
                  dataSource={this.state.albumsName}
                  renderRow={(rowData) => <Text>{rowData}</Text>}
                  style={styles.listView}
              />

              <TouchableOpacity style={{marginTop: 10}} onPress={this.onOpenCameraPressed.bind(this)}>
                <Text style={styles.button}>{this.state.shouldOpenCamera ? "close camera" : "open camera"}</Text>
              </TouchableOpacity>

              {this._renderCameraView()}

            </View>

    );
  }

  _renderRow(rowData) {
    return (
    <View style={styles.row}>
      <Text style={styles.text}>
        {rowData}
      </Text>
    </View>
    )
  }
  async onGetAlbumsPressed() {
    const albumsNames = await CameraKitGallery.getAlbums();
    this.setState({albumsName:this.state.albumsName.cloneWithRows(albumsNames)});
  }

  _renderCameraView() {
    if (this.state.shouldOpenCamera) {
      return (
          <CameraKitCamera style={{margin:8, width: 300, height: 300}}/>
      )
    }
  }

  onOpenCameraPressed() {
    this.setState({shouldOpenCamera:!this.state.shouldOpenCamera});
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
    fontSize: 20
  },
  listView: {
    flex: 1,
    flexDirection:'column',
    margin: 8,
    backgroundColor: '#D6DAC2',
    alignSelf: 'stretch'

  },
});

AppRegistry.registerComponent('example', () => example);
