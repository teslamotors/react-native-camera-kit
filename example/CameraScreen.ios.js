import React, {Component} from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image
} from 'react-native';


import _ from 'lodash';


import {CameraKitCamera} from 'react-native-camera-kit';

const FLASH_MODE_AUTO = 'auto';
const FLASH_MODE_ON = 'on';
const FLASH_MODE_OFF = 'off';

const OVERLAY_DEFAULT_COLOR = '#00000077';

const flashAutoImage = require('./images/flashAuto.png');
const flashOnImage = require('./images/flashOn.png');
const flashOffImage = require('./images/flashOff.png');
const flashArray = [
  {
    mode: FLASH_MODE_AUTO,
    image: flashAutoImage
  },
  {
    mode: FLASH_MODE_ON,
    image: flashOnImage
  },
  {
    mode: FLASH_MODE_OFF,
    image: flashOffImage
  }
];


export default class CameraScreen extends Component {

  constructor(props) {
    super(props);
    this.currentFlashArrayPosition = 0;
    this.state = {
      images: [],
      flashData: flashArray[this.currentFlashArrayPosition],
      ratios: [],
      cameraOptions: {},
      ratioArrayPosition: -1,
      imageCaptured: undefined
    };
    this.onSetFlash = this.onSetFlash.bind(this);
    this.onSwitchCameraPressed = this.onSwitchCameraPressed.bind(this);
  }

  componentDidMount() {
    const cameraOptions = this.getCameraOptions();
    let ratios = [];
    if (this.props.cameraRatioOverlay) {
      ratios = this.props.cameraRatioOverlay.ratios || [];
    }
    this.setState({
      cameraOptions,
      ratios: (ratios || []),
      ratioArrayPosition: ((ratios.length > 0) ? 0 : -1)
    });
  }

  getCameraOptions() {
    const cameraOptions = {
      flashMode: 'auto',
      focusMode: 'on',
      zoomMode: 'on'
    };
    if (this.props.cameraRatioOverlay) {
      const overlay = this.props.cameraRatioOverlay;
      cameraOptions.ratioOverlayColor = overlay.color || OVERLAY_DEFAULT_COLOR;

      if (overlay.ratios && overlay.ratios.length > 0) {
        cameraOptions.ratioOverlay = overlay.ratios[0];
      }
    }

    return cameraOptions;
  }

  renderFlashButton() {
    return (
      <TouchableOpacity style={{paddingHorizontal: 15}} onPress={() => this.onSetFlash(FLASH_MODE_AUTO)}>
        <Image
          style={{flex: 1, justifyContent: 'center'}}
          source={this.state.flashData.image}
          resizeMode={Image.resizeMode.contain}
        />
      </TouchableOpacity>
    );
  }

  renderSwitchCameraButton() {
    return (
      <TouchableOpacity style={{paddingHorizontal: 15}} onPress={this.onSwitchCameraPressed}>
        <Image
          style={{flex: 1, justifyContent: 'center'}}
          source={require('./images/cameraFlipIcon@2x.png')}
          resizeMode={Image.resizeMode.contain}
        />
      </TouchableOpacity>
    );
  }

  renderTopButtons() {
    return (
      <View style={styles.topButtons}>
        {this.renderFlashButton()}
        {this.renderSwitchCameraButton()}
      </View>
    );
  }

  renderCamera() {
    return (
      <View style={styles.cameraContainer}>
        <CameraKitCamera
          ref={(cam) => this.camera = cam}
          style={{flex: 1, justifyContent: 'flex-end'}}
          cameraOptions={this.state.cameraOptions}
        />
      </View>
    );
  }

  renderPreview() {
    if (!this.state.imageCaptured) {
      return <View style={{flex: 1, justifyContent: 'center', padding: 10}}/>

    }
    return (
      <View style={{flex: 1, justifyContent: 'center', padding: 10}}>

        <Image
          style={{flex: 1}}
          source={{uri: this.state.imageCaptured.uri}}
          resizeMode={Image.resizeMode.contain}
        />
      </View>
    )
  }

  renderCaptureButton() {
    return (
      <View style={styles.captureButtonContainer}>
        <TouchableOpacity
          onPress={() => this.onCaptureImagePressed()}
        >
          <Image
            style={styles.captureButton}
            source={require('./images/cameraButton@2x.png')}
            resizeMode={'contain'}
          />
        </TouchableOpacity>
      </View>
    );
  }

  renderGap() {
      return (
        <View
          style={styles.gap}
        >
        </View>
      );

  }

  renderRatioStrip() {
    if (this.state.ratios.length === 0) {
      return null;
    }
    return (
      <View style={{flex: 1, flexDirection: 'column', justifyContent: 'flex-end'}}>
        <View style={{flexDirection: 'row', alignItems: 'center', paddingRight: 10, paddingLeft: 20}}>
          <Text style={styles.ratioBestText}>Your images look best at a {this.state.ratios[0] || ''} ratio</Text>
          <TouchableOpacity
            style={{flex: 1, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', padding: 8}}
            onPress={() => this.onRatioButtonPressed()}
          >
            <Text style={styles.ratioText}>{this.state.cameraOptions.ratioOverlay}</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  renderBottomButtons() {
    return (
      <View style={styles.bottomButtons}>
        {this.renderPreview()}
        {this.renderCaptureButton()}
        {this.renderGap()}
      </View>
    );
  }

  render() {
    return (
      <View style={{flex: 1, backgroundColor: 'black'}}>
        {this.renderTopButtons()}
        {this.renderCamera()}
        {this.renderRatioStrip()}
        {this.renderBottomButtons()}
      </View>
    );
  }

  onSwitchCameraPressed() {
    this.camera.changeCamera();
  }

  async onSetFlash() {
    this.currentFlashArrayPosition = (this.currentFlashArrayPosition + 1) % 3;
    const newFlashData = flashArray[this.currentFlashArrayPosition];
    this.setState({flashData: newFlashData});
    this.camera.setFlashMode(newFlashData.mode);
  }

  async onCaptureImagePressed() {
    const image = await this.camera.capture(true);

    if (image) {
      this.setState({imageCaptured: image});
    }
  }

  onRatioButtonPressed() {
    const newRatiosArrayPosition = ((this.state.ratioArrayPosition + 1) % this.state.ratios.length);
    const newCameraOptions = _.update(this.state.cameraOptions, 'ratioOverlay', (val) => this.state.ratios[newRatiosArrayPosition]);
    this.setState({ratioArrayPosition: newRatiosArrayPosition, cameraOptions: newCameraOptions});
  }
}

const styles = StyleSheet.create({
  textStyle: {
    color: 'white',
    fontSize: 20
  },
  ratioBestText: {
    color: 'white',
    fontSize: 18,
  },
  ratioText: {
    color: '#ffc233',
    fontSize: 18
  },
  topButtons: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: 8,
    paddingBottom: 0
  },
  cameraContainer: {
    flex: 10,
    flexDirection: 'column'
  },
  bottomButtons: {
    flex: 2,
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 10
  },
  gap: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    padding: 10
  },
  captureButtonContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  captureButton: {
    flex: 1,
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center'
  },
  captureNumber: {
    justifyContent: 'center',
    color: 'black',
    backgroundColor: 'transparent'
  }
});
