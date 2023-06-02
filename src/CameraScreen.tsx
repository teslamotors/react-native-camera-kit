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
  ImageSourcePropType,
} from 'react-native';
import _ from 'lodash';
import Camera, { CameraProps } from './Camera';
import { CameraApi, CameraType, CaptureData, FlashMode } from './types';

const { width, height } = Dimensions.get('window');

type Actions = {
  leftButtonText?: string;
  leftCaptureRetakeButtonText?: string;
};

type CameraRatioOverlay = {
  ratios: string[];
};

type FlashImages = {
  on: ImageSourcePropType;
  off: ImageSourcePropType;
  auto: ImageSourcePropType;
};

type BottomButtonTypes = 'left' | 'capture';

type BottomPressedData = {
  type: BottomButtonTypes;
  captureImages: CaptureData[];
  captureRetakeMode: boolean;
  image?: CaptureData;
};

type CameraScreenProps = CameraProps & {
  // Controls
  actions?: Actions;
  flashImages?: FlashImages;
  flashImageStyle?: ImageStyle;
  torchOnImage?: ImageSourcePropType;
  torchOffImage?: ImageSourcePropType;
  torchImageStyle?: ImageStyle;
  captureButtonImage?: ImageSourcePropType;
  captureButtonImageStyle?: ImageStyle;
  cameraFlipImage?: ImageSourcePropType;
  cameraFlipImageStyle?: ImageStyle;
  hideControls?: boolean;
  onBottomButtonPressed?: (event: BottomPressedData) => void;
  // Overlay
  cameraRatioOverlay?: CameraRatioOverlay;
  showCapturedImageCount?: boolean;
  // Behavior
  allowCaptureRetake?: boolean;
};

type FlashData = {
  mode: FlashMode;
  image?: ImageSourcePropType;
};

type State = {
  captureImages: CaptureData[];
  flashData?: FlashData;
  torchMode: boolean;
  ratios: string[];
  ratioArrayPosition: number;
  imageCaptured?: CaptureData;
  captured: boolean;
  cameraType: CameraType;
};

export default class CameraScreen extends Component<CameraScreenProps, State> {
  static propTypes = {
    allowCaptureRetake: PropTypes.bool,
  };

  static defaultProps = {
    allowCaptureRetake: false,
  };

  currentFlashArrayPosition: number;
  flashArray: FlashData[];
  camera: CameraApi;

  constructor(props: CameraScreenProps) {
    super(props);
    this.currentFlashArrayPosition = 0;
    this.flashArray = [
      {
        mode: 'auto',
        image: props.flashImages?.auto,
      },
      {
        mode: 'on',
        image: props.flashImages?.on,
      },
      {
        mode: 'off',
        image: props.flashImages?.off,
      },
    ];

    this.state = {
      captureImages: [],
      flashData: this.flashArray[this.currentFlashArrayPosition],
      torchMode: false,
      ratios: [],
      ratioArrayPosition: -1,
      imageCaptured: undefined,
      captured: false,
      cameraType: CameraType.Back,
    };
  }

  componentDidMount() {
    let ratios: string[] = [];
    if (this.props.cameraRatioOverlay) {
      ratios = this.props.cameraRatioOverlay.ratios || [];
    }
    // eslint-disable-next-line react/no-did-mount-set-state
    this.setState({
      ratios: ratios,
      ratioArrayPosition: ratios.length > 0 ? 0 : -1,
    });
  }

  isCaptureRetakeMode() {
    return !!(this.props.allowCaptureRetake && !_.isUndefined(this.state.imageCaptured));
  }

  renderFlashButton() {
    return (
      this.state.flashData?.image &&
      !this.isCaptureRetakeMode() && (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => this.onSetFlash()}>
          <Image
            style={[{ flex: 1, justifyContent: 'center' }, this.props.flashImageStyle]}
            source={this.state.flashData.image}
            resizeMode='contain'
          />
        </TouchableOpacity>
      )
    );
  }

  renderTorchButton() {
    return (
      this.props.torchOnImage &&
      this.props.torchOffImage &&
      !this.isCaptureRetakeMode() && (
        <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={() => this.onSetTorch()}>
          <Image
            style={[{ flex: 1, justifyContent: 'center' }, this.props.torchImageStyle]}
            source={this.state.torchMode ? this.props.torchOnImage : this.props.torchOffImage}
            resizeMode='contain'
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
            style={[{ flex: 1, justifyContent: 'center' }, this.props.cameraFlipImageStyle]}
            source={this.props.cameraFlipImage}
            resizeMode='contain'
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
        {this.isCaptureRetakeMode() && this.state.imageCaptured ? (
          <Image style={{ flex: 1, justifyContent: 'flex-end' }} source={{ uri: this.state.imageCaptured.uri }} />
        ) : (
          <Camera
            ref={(cam: CameraApi) => (this.camera = cam)}
            style={{ flex: 1, justifyContent: 'flex-end' }}
            cameraType={this.state.cameraType}
            flashMode={this.state.flashData?.mode}
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
              resizeMode='contain'
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

  sendBottomButtonPressedAction(type: BottomButtonTypes, captureRetakeMode: boolean, image?: CaptureData) {
    if (this.props.onBottomButtonPressed) {
      this.props.onBottomButtonPressed({ type, captureImages: this.state.captureImages, captureRetakeMode, image });
    }
  }

  onBottomButtonPressed(type: BottomButtonTypes) {
    const captureRetakeMode = this.isCaptureRetakeMode();
    if (captureRetakeMode) {
      if (type === 'left') {
        this.setState({ imageCaptured: undefined });
      }
    } else {
      this.sendBottomButtonPressedAction(type, captureRetakeMode, undefined);
    }
  }

  renderBottomButton(type: 'left') {
    const showButton = true;
    if (showButton) {
      const buttonNameSuffix = this.isCaptureRetakeMode() ? 'CaptureRetakeButtonText' : 'ButtonText';
      const buttonText = _(this.props).get(`actions.${type}${buttonNameSuffix}`);
      return (
        <TouchableOpacity
          style={[styles.bottomButton, { justifyContent: type === 'left' ? 'flex-start' : 'flex-end' }]}
          onPress={() => this.onBottomButtonPressed(type)}
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

const styles = StyleSheet.create({
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
