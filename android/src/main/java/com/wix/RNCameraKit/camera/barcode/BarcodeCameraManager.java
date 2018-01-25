package com.wix.RNCameraKit.camera.barcode;


import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;

import java.util.Map;

import javax.annotation.Nullable;

public class BarcodeCameraManager extends SimpleViewManager<BarcodeCameraView> {

    private static final int COMMAND_START_CAMERA = 1;
    private static final int COMMAND_STOP_CAMERA = 2;

    private BarcodeCameraView cameraView;

    @Override
    public String getName() {
        return "BarcodeCameraView";
    }

    @Override
    protected BarcodeCameraView createViewInstance(ThemedReactContext reactContext) {
        cameraView = new BarcodeCameraView(reactContext);
        return cameraView;
    }

    @Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        return MapBuilder.of(
                "startCamera", COMMAND_START_CAMERA,
                "stopCamera", COMMAND_STOP_CAMERA);
    }

    @Override
    public void receiveCommand(BarcodeCameraView root, int commandId, @Nullable ReadableArray args) {
        Log.i("NIGA", "command = " + commandId);
        switch (commandId) {
            case COMMAND_START_CAMERA:
                startCamera();
                setHandler(null);
                break;
            case COMMAND_STOP_CAMERA:
                stopCamera();
                break;
        }
    }

    private void startCamera() {
        cameraView.startCamera();
    }

    private void stopCamera() {
        cameraView.stopCamera();
    }

    private void setHandler(Promise promise) {
        cameraView.setHandler(promise);
    }
}
