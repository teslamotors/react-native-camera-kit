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
    CameraKitCamera,
} from 'react-native-camera-kit';

import CameraScreen from  './CameraScreen';
import AlbumsScreen from  './AlbumsScreen';


class example extends Component {

  constructor(props) {
    super(props);
    this.state = {
      example: undefined
    };
  }

  render() {
    if (this.state.example) {
      const Example = this.state.example;
      return <Example />;
    }
    return (
        <View style={styles.container}>

          <TouchableOpacity onPress={() => this.setState({example: CameraScreen})}>
            <Text style={styles.buttonText}>
              Camera Screen
            </Text>
          </TouchableOpacity>

          <TouchableOpacity onPress={() => this.setState({example: AlbumsScreen})}>
            <Text style={styles.buttonText}>
              Albums Screen
            </Text>
          </TouchableOpacity>
  
          <TouchableOpacity onPress={this.onCheckAuthoPressed.bind(this)}>
            <Text style={styles.buttonText}>
              Check Autotization Status
            </Text>
          </TouchableOpacity>

        </View>

    );
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
}



const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20

  }
});


AppRegistry.registerComponent('example', () => example);
