package com.wix.RNCameraKit.camera.params;

import android.support.annotation.IntDef;

import com.wonderkiln.camerakit.CameraKit;

public class CameraParams {
    @IntDef({CameraKit.Constants.FLASH_ON, CameraKit.Constants.FLASH_OFF, CameraKit.Constants.FLASH_AUTO, CameraKit.Constants.FLASH_TORCH})
    public @interface Flash {}
}
