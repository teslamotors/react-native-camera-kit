package com.wix.RNCameraKit.camera;

import android.app.Activity;
import android.hardware.Camera;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.widget.Toast;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;

import java.io.IOException;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraViewManager extends SimpleViewManager<CameraView> {

    private static Camera camera = null;
    private static int currentCamera = 0;
    private static String flashMode = Camera.Parameters.FLASH_MODE_AUTO;
    private static SurfaceHolder holder;
    private static ThemedReactContext reactContext;

    public static Camera getCamera() {
        return camera;
    }

    public static String getFlashMode() {
        return flashMode;
    }

    @Override
    public String getName() {
        return "CameraView";
    }

    @Override
    protected CameraView createViewInstance(ThemedReactContext reactContext) {
        this.reactContext = reactContext;
        if (camera == null) {
            initCamera();
        }
        return new CameraView(reactContext);
    }

    public static void setHolder(SurfaceHolder holder) {
        CameraViewManager.holder = holder;
        connectHolder();
    }

    public static boolean setFlashMode(String mode) {
        if (camera == null) {
            return false;
        }
        Camera.Parameters parameters = camera.getParameters();
        if(parameters.getSupportedFlashModes().contains(mode)) {
            flashMode = mode;
            parameters.setFlashMode(flashMode);
            camera.setParameters(parameters);
            camera.startPreview();
            return true;
        } else {
            return false;
        }
    }

    public static boolean changeCamera() {
        if (Camera.getNumberOfCameras() == 1) {
            return false;
        }
        currentCamera++;
        currentCamera = currentCamera % Camera.getNumberOfCameras();
        initCamera();
        return true;
    }

    public static void initCamera() {
        if (camera != null) {
            camera.release();
        }
        try {
            camera = Camera.open(currentCamera);
            connectHolder();
        } catch (RuntimeException e) {
            Toast.makeText(reactContext, "Cannot connect to Camera", Toast.LENGTH_SHORT).show();
        }
    }

    private static void connectHolder() {
        if (camera == null || holder == null) return;

        try {
            camera.stopPreview();
            camera.setPreviewDisplay(holder);
            camera.startPreview();
            setCameraDisplayOrientation(((Activity) reactContext.getBaseContext()), 0, camera);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void setCameraDisplayOrientation(Activity activity, int cameraId, Camera camera) {
        android.hardware.Camera.CameraInfo info =
                new android.hardware.Camera.CameraInfo();
        android.hardware.Camera.getCameraInfo(cameraId, info);
        int rotation = activity.getWindowManager().getDefaultDisplay()
                .getRotation();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0:
                degrees = 0;
                break;
            case Surface.ROTATION_90:
                degrees = 90;
                break;
            case Surface.ROTATION_180:
                degrees = 180;
                break;
            case Surface.ROTATION_270:
                degrees = 270;
                break;
        }

        int result;
        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (info.orientation + degrees) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (info.orientation - degrees + 360) % 360;
        }
        camera.setDisplayOrientation(result);
    }
}
