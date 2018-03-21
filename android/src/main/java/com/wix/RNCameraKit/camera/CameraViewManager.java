package com.wix.RNCameraKit.camera;

import android.content.Context;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.graphics.Rect;
import android.hardware.Camera;
import android.hardware.SensorManager;
import android.support.annotation.ColorInt;
import android.support.annotation.IntRange;
import android.view.Display;
import android.view.OrientationEventListener;
import android.view.WindowManager;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.google.zxing.Result;
import com.wix.RNCameraKit.Utils;
import com.wix.RNCameraKit.camera.barcode.BarcodeScanner;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Stack;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.annotation.Nullable;

import static com.wix.RNCameraKit.camera.Orientation.getSupportedRotation;

@SuppressWarnings("MagicNumber deprecation")
// We're still using Camera API 1, everything is deprecated
public class CameraViewManager extends SimpleViewManager<CameraView> {

    private static Camera camera = null;
    private static int currentCamera = 0;
    private static String flashMode = Camera.Parameters.FLASH_MODE_AUTO;
    private static Stack<CameraView> cameraViews = new Stack<>();
    private static ThemedReactContext reactContext;
    private static OrientationEventListener orientationListener;
    private static int currentRotation = 0;
    private static AtomicBoolean cameraReleased = new AtomicBoolean(false);

    private static boolean shouldScan = false;
    private static BarcodeScanner scanner;
    private static Camera.PreviewCallback previewCallback = new Camera.PreviewCallback() {
        @Override
        public void onPreviewFrame(final byte[] data, final Camera camera) {
            new Thread(() -> {
                if (scanner != null) {
                    scanner.onPreviewFrame(data, camera);
                }
            }).start();
        }
    };

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
        if (!cameraViews.isEmpty() && cameraViews.peek() == cameraView) return;
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
        setBarcodeScanner();
    }

    private static void releaseCamera() {
        camera.setOneShotPreviewCallback(null);
        cameraReleased.set(true);
        camera.release();
    }

    private static void connectHolder() {
        if (cameraViews.isEmpty() || cameraViews.peek().getHolder() == null) return;

        new Thread(new Runnable() {
            @Override
            public void run() {
                if (camera == null) {
                    initCamera();
                }

                if (cameraViews.isEmpty()) {
                    return;
                }

                cameraViews.peek().post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            camera.stopPreview();
                            camera.setPreviewDisplay(cameraViews.peek().getHolder());
                            camera.startPreview();
                            if (shouldScan) {
                                camera.setOneShotPreviewCallback(previewCallback);
                            }
                        } catch (IOException | RuntimeException e) {
                            e.printStackTrace();
                        }
                    }
                });
            }
        }).start();
    }

    static void removeCameraView() {
        if (!cameraViews.isEmpty()) {
            cameraViews.pop();
        }
        if (!cameraViews.isEmpty()) {
            connectHolder();
        } else if (camera != null) {
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
        camera.setDisplayOrientation(Orientation.getDeviceOrientation(reactContext.getCurrentActivity()));
        camera.setParameters(parameters);
    }

    public static Camera.CameraInfo getCameraInfo() {
        Camera.CameraInfo info = new Camera.CameraInfo();
        Camera.getCameraInfo(currentCamera, info);
        return info;
    }

    private static Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.15;
        double targetRatio = (double) h / w;
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
        } catch (RuntimeException ignored) {
        }
    }

    public static void reconnect() {
        connectHolder();
    }

    public static int getRotationCount() {
        return currentRotation / 90;
    }

    public static void setBarcodeScanner() {
        scanner = new BarcodeScanner(previewCallback);
        scanner.setResultHandler(new BarcodeScanner.ResultHandler() {
            @Override
            public void handleResult(Result rawResult) {
                WritableMap event = Arguments.createMap();
                event.putString("codeStringValue", rawResult.getText());
                if (!cameraViews.empty())
                    reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(cameraViews.peek().getId(), "onReadCode", event);
            }
        });
    }

    @Nullable
    @Override
    public Map<String, Object> getExportedCustomDirectEventTypeConstants() {
        return MapBuilder.<String, Object>builder()
                .put("onReadCode",
                        MapBuilder.of("registrationName", "onReadCode"))
                .build();
    }

    @ReactProp(name = "scanBarcode")
    public void setShouldScan(CameraView view, boolean scanBarcode) {
        shouldScan = scanBarcode;
        if (shouldScan && camera != null) {
            camera.setOneShotPreviewCallback(previewCallback);
        }
    }

    @ReactProp(name = "showFrame")
    public void setFrame(CameraView view, boolean show) {
        if (show) {
            view.showFrame();
        }
    }

    @ReactProp(name = "frameColor", defaultInt = Color.GREEN)
    public void setFrameColor(CameraView view, @ColorInt int color) {
        view.setFrameColor(color);
    }

    @ReactProp(name = "laserColor", defaultInt = Color.RED)
    public void setLaserColor(CameraView view, @ColorInt int color) {
        view.setLaserColor(color);
    }

    public static synchronized Rect getFramingRectInPreview(int previewWidth, int previewHeight) {
        return cameraViews.peek().getFramingRectInPreview(previewWidth, previewHeight);
    }
}
