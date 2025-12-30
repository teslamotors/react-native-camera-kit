export enum CameraType {
  Front = 'front',
  Back = 'back',
}

const codeFormatAndroid = [
  'code-128',
  'code-39',
  'code-93',
  'codabar',
  'ean-13',
  'ean-8',
  'itf',
  'upc-a',
  'upc-e',
  'qr',
  'pdf-417',
  'aztec',
  'data-matrix',
  'unknown',
] as const;

const codeFormatIOS = [
  'code-128',
  'code-39',
  'code-93',
  'codabar', // only iOS 15.4+
  'ean-13',
  'ean-8',
  'itf-14',
  'upc-e',
  'qr',
  'pdf-417',
  'aztec',
  'data-matrix',
  'code-39-mod-43',
  'interleaved-2of5',
] as const;

export const supportedCodeFormats = Array.from(new Set([...codeFormatAndroid, ...codeFormatIOS]));

type CodeFormatAndroid = (typeof codeFormatAndroid)[number];
type CodeFormatIOS = (typeof codeFormatIOS)[number];

export type CodeFormat = CodeFormatAndroid | CodeFormatIOS | 'unknown';

export type TorchMode = 'on' | 'off';

export type FlashMode = 'on' | 'off' | 'auto';

export type FocusMode = 'on' | 'off';

export type ZoomMode = 'on' | 'off';

export type ResizeMode = 'cover' | 'contain';

export type CaptureData = {
  uri: string;
  name: string;
  height: number;
  width: number;
  // Android only
  id?: string;
  path?: string;
  // iOS only
  size?: number;
};

export type CameraApi = {
  capture: () => Promise<CaptureData>;
  requestDeviceCameraAuthorization: () => Promise<boolean>;
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
};
