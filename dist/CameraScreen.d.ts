import PropTypes from 'prop-types';
import { Component } from 'react';
import { ImageStyle, ImageSourcePropType } from 'react-native';
import { CameraProps } from './Camera';
import { CameraApi, CameraType, CaptureData, FlashMode } from './types';
declare type Actions = {
    leftButtonText?: string;
    leftCaptureRetakeButtonText?: string;
};
declare type CameraRatioOverlay = {
    ratios: string[];
};
declare type FlashImages = {
    on: ImageSourcePropType;
    off: ImageSourcePropType;
    auto: ImageSourcePropType;
};
declare type BottomButtonTypes = 'left' | 'capture';
declare type BottomPressedData = {
    type: BottomButtonTypes;
    captureImages: CaptureData[];
    captureRetakeMode: boolean;
    image?: CaptureData;
};
declare type CameraScreenProps = CameraProps & {
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
    cameraRatioOverlay?: CameraRatioOverlay;
    showCapturedImageCount?: boolean;
    allowCaptureRetake?: boolean;
};
declare type FlashData = {
    mode: FlashMode;
    image?: ImageSourcePropType;
};
declare type State = {
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
    static propTypes: {
        allowCaptureRetake: PropTypes.Requireable<boolean>;
    };
    static defaultProps: {
        allowCaptureRetake: boolean;
    };
    currentFlashArrayPosition: number;
    flashArray: FlashData[];
    camera: CameraApi;
    constructor(props: CameraScreenProps);
    componentDidMount(): void;
    isCaptureRetakeMode(): boolean;
    renderFlashButton(): false | 0 | JSX.Element | undefined;
    renderTorchButton(): false | 0 | JSX.Element | undefined;
    renderSwitchCameraButton(): false | 0 | JSX.Element | undefined;
    renderTopButtons(): false | JSX.Element;
    renderCamera(): JSX.Element;
    numberOfImagesTaken(): number | "1" | "";
    renderCaptureButton(): false | 0 | JSX.Element | undefined;
    renderRatioStrip(): JSX.Element | null;
    sendBottomButtonPressedAction(type: BottomButtonTypes, captureRetakeMode: boolean, image?: CaptureData): void;
    onBottomButtonPressed(type: BottomButtonTypes): void;
    renderBottomButton(type: 'left'): JSX.Element;
    renderBottomButtons(): false | JSX.Element;
    onSwitchCameraPressed(): void;
    onSetFlash(): void;
    onSetTorch(): void;
    onCaptureImagePressed(): Promise<void>;
    onRatioButtonPressed(): void;
    render(): JSX.Element;
}
export {};
