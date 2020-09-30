package com.rncamerakit.camera;

import android.app.Activity;
import android.hardware.Camera;
import android.view.Surface;

import com.rncamerakit.DeviceUtils;

import static com.rncamerakit.camera.CameraViewManager.getCameraInfo;

@SuppressWarnings({"MagicNumber", "deprecation"})
class Orientation {
    private static final int PORTRAIT_ROTATION = 90;

    static int getDeviceOrientation(Activity activity) {
        if (activity == null) return PORTRAIT_ROTATION;
        int rotation = activity.getWindowManager().getDefaultDisplay().getRotation();
        Camera.CameraInfo info = getCameraInfo();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0: degrees = 0; break;
            case Surface.ROTATION_90: degrees = 90; break;
            case Surface.ROTATION_180: degrees = 180; break;
            case Surface.ROTATION_270: degrees = 270; break;
        }

        int result;
        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (info.orientation + degrees) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (info.orientation - degrees + 360) % 360;
        }
        return result;
    }

    static int getSupportedRotation(int rotation) {
        int degrees = convertRotationToSupportedAxis(rotation);
        return isFrontFacingCamera() ? adaptFrontCamera(degrees) : adaptBackCamera(degrees);
    }

    private static int convertRotationToSupportedAxis(int rotation) {
        if (rotation < 45) {
            return 0;
        } else if (rotation < 135) {
            return  90;
        } else if (rotation < 225) {
            return 180;
        } else if (rotation < 315){
            return 270;
        }
        return 0;
    }

    private static boolean isFrontFacingCamera() {
        return getCameraInfo().facing == Camera.CameraInfo.CAMERA_FACING_FRONT;
    }

    private static int adaptBackCamera(int degrees) {
        return (getCameraInfo().orientation - degrees + 360) % 360;
    }

    private static int adaptFrontCamera(int degrees) {
        if (DeviceUtils.isGoogleDevice()) {
            int result = (getCameraInfo().orientation + degrees) % 360;
            result = (result) % 360;  // compensate the mirror
            return result;
        } else {
            int result = (getCameraInfo().orientation + degrees + 180) % 360;
            result = (result) % 360;  // compensate the mirror
            return result;
        }
    }
}
