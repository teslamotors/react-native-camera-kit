import React, { Component } from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import BarcodeScreen from './BarcodeScreen';

export default class ExampleScreen extends Component {
  constructor(props) {
    super(props);
    this.state = {
      example: undefined,
    };
  }

  render() {
    if (this.state.example) {
      const ExampleScreen = this.state.example;
      return <ExampleScreen />;
    }
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={() => this.setState({ example: BarcodeScreen })}>
          <Text style={styles.buttonText}>Back button</Text>
        </TouchableOpacity>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    // justifyContent: 'center',
    paddingTop: 60,
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  buttonText: {
    color: 'blue',
    marginBottom: 20,
    fontSize: 20,
  },
});
