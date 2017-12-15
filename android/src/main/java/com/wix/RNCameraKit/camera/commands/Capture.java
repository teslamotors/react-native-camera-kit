package com.wix.RNCameraKit.camera.commands;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;

import com.facebook.react.bridge.Promise;
import com.wix.RNCameraKit.SaveImageTask;
import com.wix.RNCameraKit.camera.CameraViewManager;

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
        final Camera camera = CameraViewManager.getCamera();
        Camera.ShutterCallback shutterCallback = new Camera.ShutterCallback() {
            @Override
            public void onShutter() {
                try {
                    camera.setPreviewCallback(null);
                    camera.setPreviewTexture(new SurfaceTexture(0));
                } catch (Exception e) {
                    // ignore
                }
            }
        };

        // Force portrait rotation
        Camera.Parameters params = camera.getParameters();
        params.setRotation(270);
        camera.setParameters(params);

        camera.takePicture(shutterCallback, null, new Camera.PictureCallback() {
            @Override
            public void onPictureTaken(byte[] data, Camera camera) {
                camera.stopPreview();
                new SaveImageTask(context, promise, saveToCameraRoll).execute(data);
            }
        });
    }
}
