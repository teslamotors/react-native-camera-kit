package com.wix.RNCameraKit.camera;

import android.app.Activity;
import android.content.Context;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.hardware.Camera;
import android.hardware.SensorManager;
import android.support.annotation.IntRange;
import android.util.Log;
import android.view.Display;
import android.view.OrientationEventListener;
import android.view.Surface;
import android.view.WindowManager;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.wix.RNCameraKit.DeviceUtils;
import com.wix.RNCameraKit.Utils;

import java.io.IOException;
import java.util.List;
import java.util.Stack;
import java.util.concurrent.atomic.AtomicBoolean;

@SuppressWarnings("deprecation MagicNumber") // We're still using Camera API 1, everything is deprecated
public class CameraViewManager extends SimpleViewManager<CameraView> {

    private static final int PORTRAIT_ROTATION = 90;
    private static Camera camera = null;
    private static int currentCamera = 0;
    private static String flashMode = Camera.Parameters.FLASH_MODE_AUTO;
    private static Stack<CameraView> cameraViews = new Stack<>();
    private static ThemedReactContext reactContext;
    private static OrientationEventListener orientationListener;
    private static int currentRotation = 0;
    private static AtomicBoolean cameraReleased = new AtomicBoolean(false);

    public static Camera getCamera() {
        return camera;
    }

    @Override
    public String getName() {
        return "CameraView";
    }

    @Override
    protected CameraView createViewInstance(ThemedReactContext reactContext) {
        CameraViewManager.reactContext = reactContext;
        return new CameraView(reactContext);
    }

    static void setCameraView(CameraView cameraView) {
        if(!cameraViews.isEmpty() && cameraViews.peek() == cameraView) return;
        CameraViewManager.cameraViews.push(cameraView);
        connectHolder();
        createOrientationListener();
    }

    private static void createOrientationListener() {
        if (orientationListener != null) return;
        orientationListener = new OrientationEventListener(reactContext, SensorManager.SENSOR_DELAY_NORMAL) {
             @Override
             public void onOrientationChanged(@IntRange(from = -1, to = 359) int angle) {
                 if (angle == OrientationEventListener.ORIENTATION_UNKNOWN) return;
                 setCameraRotation(359 - angle, false);
             }
         };
         orientationListener.enable();
    }

    static boolean setFlashMode(String mode) {
        if (camera == null) {
            return false;
        }
        Camera.Parameters parameters = camera.getParameters();
        List supportedModes = parameters.getSupportedFlashModes();
        if (supportedModes != null && supportedModes.contains(mode)) {
            flashMode = mode;
            parameters.setFlashMode(flashMode);
            camera.setParameters(parameters);
            camera.startPreview();
            return true;
        } else {
            return false;
        }
    }

    static boolean changeCamera() {
        if (Camera.getNumberOfCameras() == 1) {
            return false;
        }
        currentCamera++;
        currentCamera = currentCamera % Camera.getNumberOfCameras();
        initCamera();
        connectHolder();

        return true;
    }

    private static void initCamera() {
        if (camera != null) {
            releaseCamera();
        }
        try {
            camera = Camera.open(currentCamera);
            updateCameraSize();
            cameraReleased.set(false);
            setCameraRotation(currentRotation, true);
        } catch (RuntimeException e) {
            e.printStackTrace();
        }
    }

    private static void releaseCamera() {
        cameraReleased.set(true);
        camera.release();
    }

    private static void connectHolder() {
        if (cameraViews.isEmpty()  || cameraViews.peek().getHolder() == null) return;

        new Thread(new Runnable() {
            @Override
            public void run() {
                if(camera == null) {
                    initCamera();
                }

                if(cameraViews.isEmpty()) {
                    return;
                }

                cameraViews.peek().post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            camera.stopPreview();
                            camera.setPreviewDisplay(cameraViews.peek().getHolder());
                            camera.startPreview();
                        } catch (IOException | RuntimeException e) {
                            e.printStackTrace();
                        }
                    }
                });
            }
        }).start();
    }

    static void removeCameraView() {
        if(!cameraViews.isEmpty()) {
            cameraViews.pop();
        }
        if(!cameraViews.isEmpty()) {
            connectHolder();
        } else if(camera != null){
            releaseCamera();
            camera = null;
        }
        if (cameraViews.isEmpty()) {
            clearOrientationListener();
        }
    }

    private static void clearOrientationListener() {
        if (orientationListener != null) {
            orientationListener.disable();
            orientationListener = null;
        }
    }

    private static void setCameraRotation(int rotation, boolean force) {
        if (camera == null) return;
        int supportedRotation = getSupportedRotation(rotation);
        if (supportedRotation == currentRotation && !force) return;
        currentRotation = supportedRotation;

        if (cameraReleased.get()) return;
        Camera.Parameters parameters = camera.getParameters();
        parameters.setRotation(supportedRotation);
        parameters.setPictureFormat(PixelFormat.JPEG);
        camera.setDisplayOrientation(getDeviceOrientation());
        camera.setParameters(parameters);
    }

    private static int getDeviceOrientation() {
        Activity activity = reactContext.getCurrentActivity();
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

    private static int getSupportedRotation(int rotation) {
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

    public static Camera.CameraInfo getCameraInfo() {
        Camera.CameraInfo info = new Camera.CameraInfo();
        Camera.getCameraInfo(currentCamera, info);
        return info;
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
            Log.i("CameraViewManager", "adaptFrontCamera for google device: result: [" + result + "] degrees: [" + degrees + "]");
            return result;
        } else {
            // This works on all devices except nexus and pixel
            int result = (getCameraInfo().orientation + degrees + 180) % 360;
            result = (result) % 360;  // compensate the mirror
            Log.i("CameraViewManager", "adaptFrontCamera: result: [" + result + "] degrees: [" + degrees + "]");
            return result;
        }
    }

    private static Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.1;
        double targetRatio=(double)h / w;
        if (sizes == null) return null;
        Camera.Size optimalSize = null;
        double minDiff = Double.MAX_VALUE;
        for (Camera.Size size : sizes) {
            double ratio = (double) size.width / size.height;
            if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
            if (Math.abs(size.height - h) < minDiff) {
                optimalSize = size;
                minDiff = Math.abs(size.height - h);
            }
        }
        if (optimalSize == null) {
            minDiff = Double.MAX_VALUE;
            for (Camera.Size size : sizes) {
                if (Math.abs(size.height - h) < minDiff) {
                    optimalSize = size;
                    minDiff = Math.abs(size.height - h);
                }
            }
        }
        return optimalSize;
    }

    private static void updateCameraSize() {
        try {
            Camera camera = CameraViewManager.getCamera();

            WindowManager wm = (WindowManager) reactContext.getSystemService(Context.WINDOW_SERVICE);
            Display display = wm.getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            size.y = Utils.convertDeviceHeightToSupportedAspectRatio(size.x, size.y);
            if (camera == null) return;
            List<Camera.Size> supportedPreviewSizes = camera.getParameters().getSupportedPreviewSizes();
            List<Camera.Size> supportedPictureSizes = camera.getParameters().getSupportedPictureSizes();
            Camera.Size optimalSize = getOptimalPreviewSize(supportedPreviewSizes, size.x, size.y);
            Camera.Size optimalPictureSize = getOptimalPreviewSize(supportedPictureSizes, size.x, size.y);
            Camera.Parameters parameters = camera.getParameters();
            parameters.setPreviewSize(optimalSize.width, optimalSize.height);
            parameters.setPictureSize(optimalPictureSize.width, optimalPictureSize.height);
            parameters.setFlashMode(flashMode);
            camera.setParameters(parameters);
        } catch (RuntimeException ignored) {}
    }

    public static void reconnect() {
        connectHolder();
    }
}
