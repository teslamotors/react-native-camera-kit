package com.wix.RNCameraKit.camera.params;

import com.wonderkiln.camerakit.CameraKit;

public class FlashModeParser {
    public @CameraParams.Flash int parse(String mode) {
        switch (mode) {
            case "on":
                return CameraKit.Constants.FLASH_ON;
            case "off":
                return CameraKit.Constants.FLASH_OFF;
            case "auto":
                return CameraKit.Constants.FLASH_AUTO;
            case "torch":
                return CameraKit.Constants.FLASH_TORCH;
            default:
                throw new RuntimeException("Unrecognized flash mode: " + mode);
        }
    }
}
