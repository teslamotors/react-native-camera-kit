import { View } from 'react-native';

type IViewProps = React.ComponentProps<typeof View>;

export enum CameraType {
  Front = 'front',
  Back = 'back',
}

export type IFlashMode = 'auto' | 'on' | 'off';
export type ITorchMode = 'on' | 'off';
export type IFocusMode = 'on' | 'off';
export type IZoomMode = 'on' | 'off';
export type IReadCodeEvent = (value: string) => void;

type IReadEventResult = { codeStringValue: string };

export interface ICameraProps {
  style?: IViewProps['style'];
  cameraType?: CameraType;
  flashMode?: IFlashMode;
  focusMode?: IFocusMode;
  zoomMode?: IZoomMode;
  torchMode?: ITorchMode;
  ratioOverlay?: string;
  ratioOverlayColor?: string;
  resetFocusTimeout?: number;
  resetFocusWhenMotionDetected: boolean;
  saveToCameraRoll: boolean;
  scanBarcode?: boolean;
  showFrame?: boolean;
  laserColor?: string;
  frameColor?: string;
  surfaceColor?: string;
  onReadCode: (event: { nativeEvent: IReadEventResult }) => void;
}

export interface IImage {
  width: number;
  height: number;
  id: string;
  name: string;
  path: string;
  uri: string;
}
