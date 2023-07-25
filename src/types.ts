export enum CameraType {
  Front = 'front',
  Back = 'back',
}

export type TorchMode = 'on' | 'off';

export type FlashMode = 'on' | 'off' | 'auto';

export type FocusMode = 'on' | 'off';

export type ZoomMode = 'on' | 'off';

export type CaptureData = {
  /** URI of photo stored in a temporary directory. */
  uri: string;
  /** **iOS only**. Experimental! URL of the thumbnail, if one was generated. */
  thumb?: string;
  name: string;
  /** **Android only** */
  id?: string;
  path?: string;
  width?: number;
  height?: number;
  /** **iOS only**. Size of the main photo file, in bytes. */
  size?: number;
};

export type CameraApi = {
  capture: () => Promise<CaptureData>;
  requestDeviceCameraAuthorization: () => Promise<boolean>;
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
};
