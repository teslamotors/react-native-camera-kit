import PropTypes from 'prop-types';
import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
  Dimensions,
  Platform,
  SafeAreaView,
  ImageStyle,
} from 'react-native';
import _ from 'lodash';
import Camera from './Camera';

const FLASH_MODE_AUTO = 'auto';
const FLASH_MODE_ON = 'on';
const FLASH_MODE_OFF = 'off';

const { width, height } = Dimensions.get('window');

export enum CameraType {
  Front = 'front',
  Back = 'back'
}

export type Props = {
  focusMode?: string,
  zoomMode?: string,
  ratioOverlay?: string,
  ratioOverlayColor?: string,
  allowCaptureRetake: boolean,
  cameraRatioOverlay: any,
  showCapturedImageCount?: boolean,
  captureButtonImage: any,
  captureButtonImageStyle: ImageStyle,
  cameraFlipImage: any,
  cameraFlipImageStyle: ImageStyle,
  hideControls: any,
  showFrame: any,
  scanBarcode: any,
  laserColor: any,
  frameColor: any,
  torchOnImage: any,
  torchOffImage: any,

  torchImageStyle: ImageStyle,
  onReadCode: (event: any) => void;
  onBottomButtonPressed: (event: any) => void;
}

type State = {
  captureImages: any[],
  flashData: any,
  torchMode: boolean,
  ratios: any[],
  ratioArrayPosition: number,
  imageCaptured: any,
  captured: boolean,
  cameraType: CameraType,
}

export default class CameraScreen extends Component<Props, State> {
  static propTypes = {
    allowCaptureRetake: PropTypes.bool,
  };

  static defaultProps = {
    allowCaptureRetake: false,
  };

  currentFlashArrayPosition: number;
  flashArray: any[];
  camera: any;

  constructor(props: Props) {
    super(props);
    this.currentFlashArrayPosition = 0;
    this.flashArray = [
      {
        mode: FLASH_MODE_AUTO,
        image: _.get(props, 'flashImages.auto'),
      },
      {
        mode: FLASH_MODE_ON,
        image: _.get(props, 'flashImages.on'),
      },
      {
        mode: FLASH_MODE_OFF,
        image: _.get(props, 'flashImages.off'),
      },
    ];

    this.state = {
      captureImages: [],
      flashData: this.flashArray[this.currentFlashArrayPosition],
      torchMode: false,
      ratios: [],
      ratioArrayPosition: -1,
      imageCaptured: false,
      captured: false,
      cameraType: CameraType.Back,
    };
  }

  componentDidMount() {
    let ratios = [];
    if (this.props.cameraRatioOverlay) {
      ratios = this.props.cameraRatioOverlay.ratios || [];
    }
    // eslint-disable-next-line react/no-did-mount-set-state
    this.setState({
      ratios: ratios || [],
      ratioArrayPosition: ratios.length > 0 ? 0 : -1,
    });
  }

  isCaptureRetakeMode() {
    return !!(this.props.allowCaptureRetake && !_.isUndefined(this.state.imageCaptured));
  }

  renderFlashButton() {
    return (
      !this.isCaptureRetakeMode() && (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => this.onSetFlash()}>
          <Image
            style={[{ flex: 1, justifyContent: 'center' }, this.props.torchImageStyle]}
            source={this.state.flashData.image}
            resizeMode="contain"
          />
        </TouchableOpacity>
      )
    );
  }

  renderTorchButton() {
    return (
      !this.isCaptureRetakeMode() && (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => this.onSetTorch()}>
          <Image
            style={[{ flex: 1, justifyContent: 'center' }, this.props.torchImageStyle]}
            source={this.state.torchMode ? this.props.torchOnImage : this.props.torchOffImage}
            resizeMode="contain"
          />
        </TouchableOpacity>
      )
    );
  }

  renderSwitchCameraButton() {
    return (
      this.props.cameraFlipImage &&
      !this.isCaptureRetakeMode() && (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => this.onSwitchCameraPressed()}>
          <Image
            style={{ flex: 1, justifyContent: 'center' }}
            source={this.props.cameraFlipImage}
            resizeMode="contain"
          />
        </TouchableOpacity>
      )
    );
  }

  renderTopButtons() {
    return (
      !this.props.hideControls && (
        <SafeAreaView style={styles.topButtons}>
          {this.renderFlashButton()}
          {this.renderSwitchCameraButton()}
          {this.renderTorchButton()}
        </SafeAreaView>
      )
    );
  }

  renderCamera() {
    return (
      <View style={styles.cameraContainer}>
        {this.isCaptureRetakeMode() ? (
          <Image style={{ flex: 1, justifyContent: 'flex-end' }} source={{ uri: this.state.imageCaptured.uri }} />
        ) : (
          <Camera
            ref={(cam: any) => (this.camera = cam)}
            style={{ flex: 1, justifyContent: 'flex-end' }}
            cameraType={this.state.cameraType}
            flashMode={this.state.flashData.mode}
            torchMode={this.state.torchMode ? 'on' : 'off'}
            focusMode={this.props.focusMode}
            zoomMode={this.props.zoomMode}
            ratioOverlay={this.state.ratios[this.state.ratioArrayPosition]}
            showFrame={this.props.showFrame}
            scanBarcode={this.props.scanBarcode}
            laserColor={this.props.laserColor}
            frameColor={this.props.frameColor}
            onReadCode={this.props.onReadCode}

          />
        )}
      </View>
    );
  }

  numberOfImagesTaken() {
    const numberTook = this.state.captureImages.length;
    if (numberTook >= 2) {
      return numberTook;
    } else if (this.state.captured) {
      return '1';
    } else {
      return '';
    }
  }

  renderCaptureButton() {
    return (
      this.props.captureButtonImage &&
      !this.isCaptureRetakeMode() && (
        <View style={styles.captureButtonContainer}>
          <TouchableOpacity onPress={() => this.onCaptureImagePressed()}>
            <Image
              source={this.props.captureButtonImage}
              style={this.props.captureButtonImageStyle}
              resizeMode="contain"
            />
            {this.props.showCapturedImageCount && (
              <View style={styles.textNumberContainer}>
                <Text>{this.numberOfImagesTaken()}</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      )
    );
  }

  renderRatioStrip() {
    if (this.state.ratios.length === 0 || this.props.hideControls) {
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
            <Text style={styles.ratioText}>{this.props.ratioOverlay}</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  sendBottomButtonPressedAction(type: string, captureRetakeMode: boolean, image: null) {
    if (this.props.onBottomButtonPressed) {
      this.props.onBottomButtonPressed({ type, captureImages: this.state.captureImages, captureRetakeMode, image });
    }
  }

  onButtonPressed(type: string) {
    const captureRetakeMode = this.isCaptureRetakeMode();
    if (captureRetakeMode) {
      if (type === 'left') {
        this.setState({ imageCaptured: undefined });
      }
    } else {
      this.sendBottomButtonPressedAction(type, captureRetakeMode, null);
    }
  }

  renderBottomButton(type: string) {
    const showButton = true;
    if (showButton) {
      const buttonNameSuffix = this.isCaptureRetakeMode() ? 'CaptureRetakeButtonText' : 'ButtonText';
      const buttonText = _(this.props).get(`actions.${type}${buttonNameSuffix}`);
      return (
        <TouchableOpacity
          style={[styles.bottomButton, { justifyContent: type === 'left' ? 'flex-start' : 'flex-end' }]}
          onPress={() => this.onButtonPressed(type)}
        >
          <Text style={styles.textStyle}>{buttonText}</Text>
        </TouchableOpacity>
      );
    } else {
      return <View style={styles.bottomContainerGap} />;
    }
  }

  renderBottomButtons() {
    return (
      !this.props.hideControls && (
        <SafeAreaView style={[styles.bottomButtons, { backgroundColor: '#ffffff00' }]}>
          {this.renderBottomButton('left')}
          {this.renderCaptureButton()}
        </SafeAreaView>
      )
    );
  }

  onSwitchCameraPressed() {
    const direction = this.state.cameraType === CameraType.Back ? CameraType.Front : CameraType.Back;
    this.setState({ cameraType: direction });
  }

  onSetFlash() {
    this.currentFlashArrayPosition = (this.currentFlashArrayPosition + 1) % 3;
    const newFlashData = this.flashArray[this.currentFlashArrayPosition];
    this.setState({ flashData: newFlashData });
  }

  onSetTorch() {
    this.setState({ torchMode: !this.state.torchMode });
  }

  async onCaptureImagePressed() {
    const image = await this.camera.capture();

    if (this.props.allowCaptureRetake) {
      this.setState({ imageCaptured: image });
    } else {
      if (image) {
        this.setState({
          captured: true,
          imageCaptured: image,
          captureImages: _.concat(this.state.captureImages, image),
        });
      }
      this.sendBottomButtonPressedAction('capture', false, image);
    }
  }

  onRatioButtonPressed() {
    const newRatiosArrayPosition = (this.state.ratioArrayPosition + 1) % this.state.ratios.length;
    this.setState({ ratioArrayPosition: newRatiosArrayPosition });
  }

  render() {
    return (
      <View style={{ flex: 1, backgroundColor: 'black' }} {...this.props}>
        {Platform.OS === 'android' && this.renderCamera()}
        {this.renderTopButtons()}
        {Platform.OS !== 'android' && this.renderCamera()}
        {this.renderRatioStrip()}
        {Platform.OS === 'android' && <View style={styles.gap} />}
        {this.renderBottomButtons()}
      </View>
    );
  }
}

const styles = StyleSheet.create(
  {
    bottomButtons: {
      flex: 2,
      flexDirection: 'row',
      justifyContent: 'space-between',
      padding: 14,
    },
    textStyle: {
      color: 'white',
      fontSize: 20,
    },
    ratioBestText: {
      color: 'white',
      fontSize: 18,
    },
    ratioText: {
      color: '#ffc233',
      fontSize: 18,
    },
    topButtons: {
      flex: 1,
      flexDirection: 'row',
      justifyContent: 'space-between',
      paddingTop: 8,
      paddingBottom: 0,
    },
    cameraContainer: {
      ...Platform.select({
        android: {
          position: 'absolute',
          top: 0,
          left: 0,
          width,
          height,
        },
        default: {
          flex: 10,
          flexDirection: 'column',
        },
      }),
    },
    captureButtonContainer: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
    },
    textNumberContainer: {
      position: 'absolute',
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
      justifyContent: 'center',
      alignItems: 'center',
    },
    bottomButton: {
      flex: 1,
      flexDirection: 'row',
      alignItems: 'center',
      padding: 10,
    },
    bottomContainerGap: {
      flex: 1,
      flexDirection: 'row',
      justifyContent: 'flex-end',
      alignItems: 'center',
      padding: 10,
    },
    gap: {
      flex: 10,
      flexDirection: 'column',
    },
  });
