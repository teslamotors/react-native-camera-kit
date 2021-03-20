import { StyleProp, ViewStyle } from 'react-native';
import { CameraType } from '..';

export enum FlashMode {
  auto = 'auto',
  on = 'on',
  off = 'off'

}

export interface CommonCameraProps {
  style: StyleProp<ViewStyle>;
  cameraType: CameraType;
  flashMode?: FlashMode;
  focusMode?: 'on' | 'off';
  torchMode?: 'on' | 'off';
  zoomMode?: 'on' | 'off';
  ratioOverlay: string;
  showFrame?: boolean;
  saveToCameraRoll: boolean;
  scanBarcode?: boolean;
  laserColor?: string;
  frameColor?: string;
  surfaceColor?: string;
  onReadCode?: BarcodeReadEvent;
}

export type BarcodeReadEvent = (data: { nativeEvent: { codeStringValue: string } } ) => void;
