export enum CameraType {
  Front = 'front',
  Back = 'back',
}

export type TorchMode = 'on' | 'off';

export type FlashMode = 'on' | 'off' | 'auto';

export type FocusMode = 'on' | 'off';

export type ZoomMode = 'on' | 'off';

export type CaptureData = {
  uri: string;
  name: string;
  // Android only
  id?: string;
  path?: string;
  height?: number;
  width?: number;
  // iOS only
  size?: number;
};

export type CameraApi = {
  capture: () => Promise<CaptureData>;
  requestDeviceCameraAuthorization: () => Promise<boolean>;
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
};
