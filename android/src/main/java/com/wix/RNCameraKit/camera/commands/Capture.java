package com.wix.RNCameraKit.camera.commands;

import android.content.Context;
import android.hardware.Camera;

import com.facebook.react.bridge.Promise;

import com.wix.RNCameraKit.camera.CameraViewManager;
import com.wix.RNCameraKit.SaveImageTask;

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
        CameraViewManager.getCamera().takePicture(null, null, new Camera.PictureCallback() {
            @Override
            public void onPictureTaken(byte[] data, Camera camera) {
                camera.stopPreview();
                new SaveImageTask(context, promise, saveToCameraRoll).execute(data);
            }
        });
    }
}
