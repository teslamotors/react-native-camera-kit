export enum CameraType {
  Front = 'front',
  Back = 'back',
}

export type CodeFormat =
  | 'code-128'
  | 'code-39'
  | 'code-93'
  | 'codabar'
  | 'ean-13'
  | 'ean-8'
  | 'itf'
  | 'upc-e'
  | 'qr'
  | 'pdf-417'
  | 'aztec'
  | 'data-matrix'
  | 'unknown';

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
