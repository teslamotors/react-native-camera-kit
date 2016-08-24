package com.wix.RNCameraKit.camera;

import android.Manifest;
import android.hardware.Camera;
import android.support.v4.content.PermissionChecker;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.wix.RNCameraKit.camera.commands.Capture;

public class CameraModule extends ReactContextBaseJavaModule {

    public CameraModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "CameraModule";
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
    public void capture(boolean saveToCameraRoll, final Promise promise) {
        new Capture(getReactApplicationContext()).execute(promise);
    }

    @ReactMethod
    public void hasCameraPermission(Promise promise) {
        boolean hasPermission = PermissionChecker.checkSelfPermission(getReactApplicationContext(), Manifest.permission.CAMERA)
                == PermissionChecker.PERMISSION_GRANTED;
        promise.resolve(hasPermission);
    }
}
