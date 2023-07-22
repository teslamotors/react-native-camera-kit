export declare enum CameraType {
    Front = "front",
    Back = "back"
}
export declare type TorchMode = 'on' | 'off';
export declare type FlashMode = 'on' | 'off' | 'auto';
export declare type FocusMode = 'on' | 'off';
export declare type ZoomMode = 'on' | 'off';
export declare type CaptureData = {
    uri: string;
    name: string;
    id?: string;
    path?: string;
    height?: number;
    width?: number;
    size?: number;
};
export declare type CameraApi = {
    capture: () => Promise<CaptureData>;
    setTorchMode: (mode: TorchMode) => void;
    requestDeviceCameraAuthorization: () => Promise<boolean>;
    checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
};
