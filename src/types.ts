export type CameraApi = {
  capture: () => Promise<{ uri: string }>,
  requestDeviceCameraAuthorization: () => Promise<boolean>,
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>,
};
