package com.wix.RNCameraKit.camera;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.hardware.Camera;
import android.os.AsyncTask;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraModule extends ReactContextBaseJavaModule {

    public CameraModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "CameraModule";
    }

    @ReactMethod
    public void hasFrontCamera(Promise promise) {

        int numCameras = Camera.getNumberOfCameras();
        for (int i=0; i<numCameras; i++) {
            Camera.CameraInfo info = new Camera.CameraInfo();
            Camera.getCameraInfo(i, info);
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                promise.resolve(true);
                return;
            }
        }
        promise.resolve(false);
    }

    @ReactMethod
    public void hasFlashForCurrentCamera(Promise promise) {
        Camera camera = CameraView.instance.getCamera();
        promise.resolve(camera.getParameters().getSupportedFlashModes() != null);
    }

    @ReactMethod
    public void changeCamera(Promise promise) {
        promise.resolve(CameraView.instance.changeCamera());
    }

    @ReactMethod
    public void setFlashMode(String mode, Promise promise) {
        promise.resolve(CameraView.instance.setFlashMode(mode));
    }

    @ReactMethod
    public void getFlashMode(Promise promise) {
        Camera camera = CameraView.instance.getCamera();
        promise.resolve(camera.getParameters().getFlashMode());
    }

    @ReactMethod void capture(boolean saveToCameraRoll, final Promise promise) {
        Camera camera = CameraView.instance.getCamera();
        camera.takePicture(null, null, new Camera.PictureCallback(){

            @Override
            public void onPictureTaken(byte[] data, Camera camera) {
                new SaveImageTask(promise).execute(data);
            }
        });
    }

    private class SaveImageTask extends AsyncTask<byte[], Void, Void> {

        private final Promise promise;

        private SaveImageTask(Promise promise) {
            this.promise = promise;
        }

        @Override
        protected Void doInBackground(byte[]... data) {
            Bitmap image = BitmapFactory.decodeByteArray(data[0], 0, data[0].length);
            String fileUri = MediaStore.Images.Media.insertImage(getReactApplicationContext().getContentResolver(), image, System.currentTimeMillis() + "", "");
            Log.d("CameraKit", "Saved to: " + fileUri);
            if (fileUri == null) {
                promise.reject("CameraKit", "Failed to save image to mediastore");
            } else {
              promise.resolve(fileUri);
            }
            return null;
        }
    }
}
