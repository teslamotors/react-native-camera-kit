package com.wix.RNCameraKit.camera;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.wix.RNCameraKit.camera.params.CameraParams;
import com.wonderkiln.camerakit.CameraKit;
import com.wonderkiln.camerakit.CameraKitEventCallback;
import com.wonderkiln.camerakit.CameraKitImage;

import java.util.Stack;


public class CameraViewManager extends SimpleViewManager<CameraView> {
    private static CameraViewManager instance;
    private final Stack<CameraView> cameras = new Stack<>();

    public static CameraViewManager instance() {
        if (instance == null) {
            instance = new CameraViewManager();
        }
        return instance;
    }

    private CameraViewManager() {
    }

    @Override
    public String getName() {
        return "CameraView";
    }

    @Override
    protected CameraView createViewInstance(ThemedReactContext reactContext) {
        stopCurrentCamera();
        final CameraView camera = CameraView.inflate(reactContext);
        cameras.push(camera);
        startCurrentCamera();
        return camera;
    }

    @Override
    public void onDropViewInstance(CameraView view) {
        stopAndPopCamera();
        startCurrentCamera();
        super.onDropViewInstance(view);
    }

    private void stopAndPopCamera() {
        if (cameras.isEmpty()) return;
        cameras.pop().stop();
    }

    private CameraView currentCamera() {
        return cameras.peek();
    }

    private void startCurrentCamera() {
        if (!cameras.isEmpty() && !currentCamera().isStarted()) {
            try {
                cameras.peek().start();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void stopCurrentCamera() {
        if (!cameras.isEmpty()) {
            cameras.peek().stop();
        }
    }

    void setFlashMode(@CameraParams.Flash int mode) {
        currentCamera().setFlash(mode);
    }

    boolean isFlashEnabled() {
        return currentCamera().getFlash() == CameraKit.Constants.FLASH_ON;
    }

    void changeCamera() {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                currentCamera().toggleFacing();
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    currentCamera().ensureToggleOnPreMarshmallow();
                }
            }
        });
    }

    public void captureImage(CameraKitEventCallback<CameraKitImage> cameraKitEventCallback) {
        currentCamera().captureImage(cameraKitEventCallback);
    }
}
