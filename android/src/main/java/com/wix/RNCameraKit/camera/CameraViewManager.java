package com.wix.RNCameraKit.camera;

import android.content.Context;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.hardware.Camera;
import android.hardware.SensorManager;
import android.support.annotation.IntRange;
import android.view.Display;
import android.view.OrientationEventListener;
import android.view.WindowManager;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.wix.RNCameraKit.Utils;

import java.io.IOException;
import java.util.List;
import java.util.Stack;

public class CameraViewManager extends SimpleViewManager<CameraView> {

    private static final int INITIAL_ROTATION = 90;
    private static Camera camera = null;
    private static int currentCamera = 0;
    private static String flashMode = Camera.Parameters.FLASH_MODE_AUTO;
    private static Stack<CameraView> cameraViews = new Stack<>();
    private static ThemedReactContext reactContext;
    private static OrientationEventListener orientationListener;
    private static int currentRotation = -1;

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
        if (orientationListener == null) {
            orientationListener = createOrientationListener();
            orientationListener.enable();
        }
    }

    private static OrientationEventListener createOrientationListener() {
        return new OrientationEventListener(reactContext, SensorManager.SENSOR_DELAY_NORMAL) {
             @Override
             public void onOrientationChanged(@IntRange(from = -1, to = 359) int angle) {
                 if (angle == OrientationEventListener.ORIENTATION_UNKNOWN) return;
                 setCameraRotation(359 - angle);
             }
         };
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
            camera.release();
        }
        try {
            camera = Camera.open(currentCamera);
            setCameraRotation(INITIAL_ROTATION);
            updateCameraSize();
        } catch (RuntimeException e) {
            e.printStackTrace();
        }
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
                        } catch (IOException e) {
                            e.printStackTrace();
                        } catch (RuntimeException e) {
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
            camera.release();
            camera = null;
            clearOrientationListener();
        }
    }

    private static void clearOrientationListener() {
        if (orientationListener != null) {
            orientationListener.disable();
            orientationListener = null;
        }
    }

    private static void setCameraRotation(int rotation) {
        if (camera == null) return;
        int supportedRotation = getSupportedRotation(rotation);
        if (supportedRotation == currentRotation) return;
        currentRotation = supportedRotation;

        Camera.Parameters parameters = camera.getParameters();
        parameters.setRotation(supportedRotation); // Rotates camera
        parameters.setPictureFormat(PixelFormat.JPEG);
        camera.setDisplayOrientation(90); // Lock screen orientation vertically
        camera.setParameters(parameters);
    }

    public static Camera.CameraInfo getCameraInfo() {
        Camera.CameraInfo info = new Camera.CameraInfo();
        Camera.getCameraInfo(currentCamera, info);
        return info;
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

    private static int adaptBackCamera(int degrees) {
        return (getCameraInfo().orientation - degrees + 360) % 360;
    }

    private static int adaptFrontCamera(int degrees) {
        int result = (getCameraInfo().orientation + degrees) % 360;
        return (360 - result) % 360;  // compensate the mirror
    }

    private static boolean isFrontFacingCamera() {
        return getCameraInfo().facing == Camera.CameraInfo.CAMERA_FACING_FRONT;
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
        } catch (RuntimeException e) {}
    }

    public static void reconnect() {
        connectHolder();
    }
}
