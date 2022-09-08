import { Component } from 'react';
import { ImageStyle } from 'react-native';
export declare enum CameraType {
    Front = "front",
    Back = "back"
}
export declare type Props = {
    focusMode?: string;
    zoomMode?: string;
    ratioOverlay?: string;
    ratioOverlayColor?: string;
    allowCaptureRetake: boolean;
    cameraRatioOverlay: any;
    showCapturedImageCount?: boolean;
    captureButtonImage: any;
    captureButtonImageStyle: ImageStyle;
    cameraFlipImage: any;
    cameraFlipImageStyle: ImageStyle;
    hideControls: any;
    showFrame: any;
    scanBarcode: any;
    laserColor: any;
    frameColor: any;
    torchOnImage: any;
    torchOffImage: any;
    torchImageStyle: ImageStyle;
    onReadCode: (event: any) => void;
    onBottomButtonPressed: (event: any) => void;
};
declare type State = {
    captureImages: any[];
    flashData: any;
    torchMode: boolean;
    ratios: any[];
    ratioArrayPosition: number;
    imageCaptured: any;
    captured: boolean;
    cameraType: CameraType;
};
export default class CameraScreen extends Component<Props, State> {
    static propTypes: {
        allowCaptureRetake: any;
    };
    static defaultProps: {
        allowCaptureRetake: boolean;
    };
    currentFlashArrayPosition: number;
    flashArray: any[];
    camera: any;
    constructor(props: Props);
    componentDidMount(): void;
    isCaptureRetakeMode(): boolean;
    renderFlashButton(): any;
    renderTorchButton(): any;
    renderSwitchCameraButton(): any;
    renderTopButtons(): any;
    renderCamera(): any;
    numberOfImagesTaken(): any;
    renderCaptureButton(): any;
    renderRatioStrip(): any;
    sendBottomButtonPressedAction(type: string, captureRetakeMode: boolean, image: null): void;
    onButtonPressed(type: string): void;
    renderBottomButton(type: string): any;
    renderBottomButtons(): any;
    onSwitchCameraPressed(): void;
    onSetFlash(): void;
    onSetTorch(): void;
    onCaptureImagePressed(): Promise<void>;
    onRatioButtonPressed(): void;
    render(): any;
}
export {};
