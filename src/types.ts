type TorchMode = 'on'| 'off';

export type CameraApi = {
  capture: () => Promise<{ uri: string }>,
  setTorchMode: (mode: TorchMode) => void;
  requestDeviceCameraAuthorization: () => Promise<boolean>,
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>,
};
