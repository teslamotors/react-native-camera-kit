package com.wix.RNCameraKit.torch;

import android.content.Context;
import android.hardware.Camera;
import android.hardware.camera2.CameraManager;
import android.os.Build;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class TorchModule extends ReactContextBaseJavaModule {
    private Boolean isTorchOn = false;
    private Camera camera;

    public TorchModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "CKTorch";
    }

    public void switchState(Boolean newState, Callback successCallback, Callback failureCallback) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                CameraManager cameraManager = (CameraManager) getReactApplicationContext().getSystemService(Context.CAMERA_SERVICE);
                String cameraId;
                if (cameraManager != null) {
                    cameraId = cameraManager.getCameraIdList()[0];
                    cameraManager.setTorchMode(cameraId, newState);
                }
                successCallback.invoke(true);
            } catch (Exception e) {
                String errorMessage = e.getMessage();
                failureCallback.invoke("Error: " + errorMessage);
            }
        } else {
            Camera.Parameters params;

            if (!isTorchOn) {
                camera = Camera.open();
                params = camera.getParameters();
                params.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);
                camera.setParameters(params);
                camera.startPreview();
                isTorchOn = true;
            } else {
                params = camera.getParameters();
                params.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);

                camera.setParameters(params);
                camera.stopPreview();
                camera.release();
                isTorchOn = false;
            }
        }
    }
}