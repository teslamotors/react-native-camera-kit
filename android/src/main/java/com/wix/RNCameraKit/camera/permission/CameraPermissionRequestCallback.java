package com.wix.RNCameraKit.camera.permission;

import com.wix.RNCameraKit.camera.CameraModule;

public class CameraPermissionRequestCallback {

    private CameraModule cameraModule;

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        cameraModule.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    public void setCameraModule(CameraModule cameraModule) {
        this.cameraModule = cameraModule;
    }
}
