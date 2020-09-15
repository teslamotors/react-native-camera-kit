package com.rncamerakit.camera.permission;

import com.rncamerakit.camera.CameraModule;

public class CameraPermissionRequestCallback {

    private CameraModule cameraModule;

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        cameraModule.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    public void setCameraModule(CameraModule cameraModule) {
        this.cameraModule = cameraModule;
    }
}
