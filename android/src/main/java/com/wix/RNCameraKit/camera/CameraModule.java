package com.wix.RNCameraKit.camera;

import android.hardware.Camera;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.wix.RNCameraKit.camera.commands.Capture;
import com.wix.RNCameraKit.camera.permission.CameraPermission;
import com.wix.RNCameraKit.torch.TorchModule;


public class CameraModule extends ReactContextBaseJavaModule {

    private final CameraPermission cameraPermission;
    private Promise checkPermissionStatusPromise;
    private TorchModule torchModule;

    public CameraModule(ReactApplicationContext reactContext) {
        super(reactContext);
        cameraPermission = new CameraPermission();
        checkPermissionWhenActivityIsAvailable();
    }

    private void checkPermissionWhenActivityIsAvailable() {
        getReactApplicationContext().addLifecycleEventListener(new LifecycleEventListener() {
            @Override
            public void onHostResume() {
                if (checkPermissionStatusPromise != null  && getCurrentActivity() != null) {
                    getCurrentActivity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            checkPermissionStatusPromise.resolve(cameraPermission.checkAuthorizationStatus(getCurrentActivity()));
                            checkPermissionStatusPromise = null;
                        }
                    });
                }
            }

            @Override
            public void onHostPause() {

            }

            @Override
            public void onHostDestroy() {

            }
        });
    }

    @Override
    public String getName() {
        return "CameraModule";
    }

    @ReactMethod
    public void checkDeviceCameraAuthorizationStatus(Promise promise) {
        if (getCurrentActivity() == null) {
            checkPermissionStatusPromise = promise;
        } else {
            promise.resolve(cameraPermission.checkAuthorizationStatus(getCurrentActivity()));
        }
    }

    @ReactMethod
    public void requestDeviceCameraAuthorization(Promise promise) {
        cameraPermission.requestAccess(getCurrentActivity(), promise);
    }

    @ReactMethod
    public void hasFrontCamera(Promise promise) {

        int numCameras = Camera.getNumberOfCameras();
        for (int i = 0; i < numCameras; i++) {
            Camera.CameraInfo info = new Camera.CameraInfo();
            Camera.getCameraInfo(i, info);
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                promise.resolve(true);
                return;
            }
        }
        promise.resolve(false);
    }

    @ReactMethod
    public void hasFlashForCurrentCamera(Promise promise) {
        Camera camera = CameraViewManager.getCamera();
        promise.resolve(camera.getParameters().getSupportedFlashModes() != null);
    }

    @ReactMethod
    public void changeCamera(Promise promise) {
        promise.resolve(CameraViewManager.changeCamera());
    }

    @ReactMethod
    public void setFlashMode(String mode, Promise promise) {
        promise.resolve(CameraViewManager.setFlashMode(mode));
    }

    @ReactMethod
    public void getFlashMode(Promise promise) {
        Camera camera = CameraViewManager.getCamera();
        promise.resolve(camera.getParameters().getFlashMode());
    }

    @ReactMethod
    public void setTorchMode(Boolean newState, Callback successCallback, Callback failureCallback) {
        torchModule.switchState(newState, successCallback, failureCallback);
    }

    @ReactMethod
    public void capture(boolean saveToCameraRoll, final Promise promise) {
        new Capture(getReactApplicationContext(), saveToCameraRoll).execute(promise);
    }

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        cameraPermission.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }
}
