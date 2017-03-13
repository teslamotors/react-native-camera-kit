import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image
} from 'react-native';


import _ from 'lodash';


import CameraKitCamera from './CameraKitCamera';

const FLASH_MODE_AUTO = 'auto';
const FLASH_MODE_ON = 'on';
const FLASH_MODE_OFF = 'off';




export default class CameraScreen extends Component {

  constructor(props) {
    super(props);
    this.currentFlashArrayPosition = 0;
    this.flashArray = [{
      mode: FLASH_MODE_AUTO,
      image: _.get(this.props, 'flashImages.auto')
    },
    {
      mode: FLASH_MODE_ON,
      image: _.get(this.props, 'flashImages.on')
    },
    {
      mode: FLASH_MODE_OFF,
      image: _.get(this.props, 'flashImages.off')
    }
    ];
    this.state = {
      captureImages: [],
      flashData: this.flashArray[this.currentFlashArrayPosition],
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
      <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => this.onSetFlash(FLASH_MODE_AUTO)}>
        <Image
          style={{ flex: 1, justifyContent: 'center' }}
          source={this.state.flashData.image}
          resizeMode={Image.resizeMode.contain}
        />
      </TouchableOpacity>
    );
  }

  renderSwitchCameraButton() {
    if (this.props.cameraFlipImage) {
      return (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={this.onSwitchCameraPressed}>
          <Image
            style={{ flex: 1, justifyContent: 'center' }}
            source={_.get(this.props, 'cameraFlipImage', require('./../images/cameraFlipIcon.png'))}
            resizeMode={Image.resizeMode.contain}
          />
        </TouchableOpacity>
      );
    }
    return null;
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
          style={{ flex: 1, justifyContent: 'flex-end' }}
          cameraOptions={this.state.cameraOptions}
        />
      </View>
    );
  }


  renderCaptureButton() {
    return (
      <View style={styles.captureButtonContainer}>
        <TouchableOpacity
          onPress={() => this.onCaptureImagePressed()}
        >
          <Image
            style={styles.captureButton}
            source={_.get(this.props, 'captureButtonImage', require('./../images/cameraButton.png'))}
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
      <View style={{ flex: 1, flexDirection: 'column', justifyContent: 'flex-end' }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', paddingRight: 10, paddingLeft: 20 }}>
          <Text style={styles.ratioBestText}>Your images look best at a {this.state.ratios[0] || ''} ratio</Text>
          <TouchableOpacity
            style={{ flex: 1, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', padding: 8 }}
            onPress={() => this.onRatioButtonPressed()}
          >
            <Text style={styles.ratioText}>{this.state.cameraOptions.ratioOverlay}</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  onButtonPressed(type) {
    this.props.onBottomButtonPressed({ type, captureImages: this.state.captureImages })
  }


  renderBottomButton(type) {
    const buttonText = _(this.props).get(`actions.${type}ButtonText`)
    if (buttonText) {
      return (
        <TouchableOpacity
          style={[styles.bottomButton, {justifyContent: type === 'left' ? 'flex-start' : 'flex-end'}]}
          onPress={() => this.onButtonPressed(type)}
        >
          <Text style={styles.textStyle}>{_.get(this.props, `actions.${type}ButtonText`, type)}</Text>
        </TouchableOpacity>
      );
    }
    return (
      this.renderGap()
    );
  }

  renderBottomButtons() {
    return (
      <View style={styles.bottomButtons}>
        {this.renderBottomButton('left')}
        {this.renderCaptureButton()}
        {this.renderBottomButton('right')}
      </View>
    );
  }


  onSwitchCameraPressed() {
    this.camera.changeCamera();
  }

  async onSetFlash() {
    this.currentFlashArrayPosition = (this.currentFlashArrayPosition + 1) % 3;
    const newFlashData = this.flashArray[this.currentFlashArrayPosition];
    this.setState({ flashData: newFlashData });
    this.camera.setFlashMode(newFlashData.mode);
  }

  async onCaptureImagePressed() {
    const image = await this.camera.capture(true);

    if (image) {
      this.setState({ imageCaptured: image, captureImages: _.concat(this.state.captureImages, image) });
    }

  }

  onRatioButtonPressed() {
    const newRatiosArrayPosition = ((this.state.ratioArrayPosition + 1) % this.state.ratios.length);
    const newCameraOptions = _.update(this.state.cameraOptions, 'ratioOverlay', (val) => this.state.ratios[newRatiosArrayPosition]);
    this.setState({ ratioArrayPosition: newRatiosArrayPosition, cameraOptions: newCameraOptions });
  }

  render() {
    return (
      <View style={{ flex: 1, backgroundColor: 'black' }}>
        {this.renderTopButtons()}
        {this.renderCamera()}
        {this.renderRatioStrip()}
        {this.renderBottomButtons()}
      </View>
    );
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
    padding: 14
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
  },
  bottomButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10
  }
});
