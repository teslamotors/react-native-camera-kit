package com.wix.RNCameraKit.camera;

import android.app.Activity;
import android.hardware.Camera;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.widget.Toast;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;

import java.io.IOException;
import java.util.List;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraViewManager extends SimpleViewManager<CameraView> {

    private static Camera camera = null;
    private static int currentCamera = 0;
    private static String flashMode = Camera.Parameters.FLASH_MODE_AUTO;
    private static CameraView cameraView;
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

    public static void setCameraView(CameraView cameraView) {
        CameraViewManager.cameraView = cameraView;
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
        if (camera == null || cameraView == null  || cameraView.getHolder() == null) return;

        try {
            camera.stopPreview();
            camera.setPreviewDisplay(cameraView.getHolder());
            updateCameraSize();
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

    private static Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.1;
        double targetRatio=(double)h / w;
        if (sizes == null) return null;
        Camera.Size optimalSize = null;
        double minDiff = Double.MAX_VALUE;
        int targetHeight = h;
        for (Camera.Size size : sizes) {
            double ratio = (double) size.width / size.height;
            if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
            if (Math.abs(size.height - targetHeight) < minDiff) {
                optimalSize = size;
                minDiff = Math.abs(size.height - targetHeight);
            }
        }
        if (optimalSize == null) {
            minDiff = Double.MAX_VALUE;
            for (Camera.Size size : sizes) {
                if (Math.abs(size.height - targetHeight) < minDiff) {
                    optimalSize = size;
                    minDiff = Math.abs(size.height - targetHeight);
                }
            }
        }
        return optimalSize;
    }

    public static void updateCameraSize() {
        try {
            Camera camera = CameraViewManager.getCamera();
            if (camera == null || cameraView == null) return;
            List<Camera.Size> supportedPreviewSizes = camera.getParameters().getSupportedPreviewSizes();
            List<Camera.Size> supportedPictureSizes = camera.getParameters().getSupportedPictureSizes();
            Camera.Size optimalSize = getOptimalPreviewSize(supportedPreviewSizes, cameraView.getWidth(), cameraView.getHeight());
            Camera.Size optimalPictureSize = getOptimalPreviewSize(supportedPictureSizes, cameraView.getWidth(), cameraView.getHeight());
            Camera.Parameters parameters = camera.getParameters();
            parameters.setPreviewSize(optimalSize.width, optimalSize.height);
            parameters.setPictureSize(optimalPictureSize.width, optimalPictureSize.height);
            parameters.setFlashMode(CameraViewManager.getFlashMode());
            camera.setParameters(parameters);
            camera.startPreview();
        } catch (RuntimeException e) {
//            CameraViewManager.initCamera();
//            CameraViewManager.setCameraView(this);
//            updateCameraSize();
        }
    }
}
