package com.wix.RNCameraKit.camera.commands;

import android.content.Context;

import com.facebook.react.bridge.Promise;
import com.wix.RNCameraKit.SaveImageTask;
import com.wix.RNCameraKit.camera.CameraViewManager;
import com.wonderkiln.camerakit.CameraKitEventCallback;
import com.wonderkiln.camerakit.CameraKitImage;

public class Capture implements Command {

    private final Context context;
    private boolean saveToCameraRoll;

    public Capture(Context context, boolean saveToCameraRoll) {
        this.context = context;
        this.saveToCameraRoll = saveToCameraRoll;
    }

    @Override
    public void execute(final Promise promise) {
        try {
            tryTakePicture(promise);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void tryTakePicture(final Promise promise) throws Exception {
        CameraViewManager.instance().captureImage(new CameraKitEventCallback<CameraKitImage>() {
            @Override
            public void callback(CameraKitImage cameraKitImage) {
                new SaveImageTask(context, promise, saveToCameraRoll).execute(cameraKitImage.getBitmap());
            }
        });
    }
}
