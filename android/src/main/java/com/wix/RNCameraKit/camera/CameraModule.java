package com.wix.RNCameraKit.camera;

import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.hardware.Camera;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.ExifIFD0Directory;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
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
        for (int i = 0; i < numCameras; i++) {
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
        Camera camera = CameraViewManager.getCamera();
        promise.resolve(camera.getParameters().getSupportedFlashModes() != null);
    }

    @ReactMethod
    public void changeCamera(Promise promise) {
        promise.resolve(CameraViewManager.changeCamera());
    }

    @ReactMethod
    public void setFlashMode(String mode, Promise promise) {
        promise.resolve(CameraViewManager.setFlashMode(mode));
    }

    @ReactMethod
    public void getFlashMode(Promise promise) {
        Camera camera = CameraViewManager.getCamera();
        promise.resolve(camera.getParameters().getFlashMode());
    }

    @ReactMethod
    public void capture(boolean saveToCameraRoll, final Promise promise) {
        Camera camera = CameraViewManager.getCamera();
        camera.takePicture(null, null, new Camera.PictureCallback() {

            @Override
            public void onPictureTaken(byte[] data, Camera camera) {
                camera.stopPreview();
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

            try {
                Metadata metadata = ImageMetadataReader.readMetadata(new BufferedInputStream(new ByteArrayInputStream(data[0])), data[0].length);

                // Get the EXIF orientation.
                final ExifIFD0Directory exifIFD0Directory = metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);
                if (exifIFD0Directory.containsTag(ExifIFD0Directory.TAG_ORIENTATION)) {
                    final int exifOrientation = exifIFD0Directory.getInt(ExifIFD0Directory.TAG_ORIENTATION);

                    final Matrix bitmapMatrix = new Matrix();
                    switch (exifOrientation) {
                        case 1:
                            break;  // top left
                        case 2:
                            bitmapMatrix.postScale(-1, 1);
                            break;  // top right
                        case 3:
                            bitmapMatrix.postRotate(180);
                            break;  // bottom right
                        case 4:
                            bitmapMatrix.postRotate(180);
                            bitmapMatrix.postScale(-1, 1);
                            break;  // bottom left
                        case 5:
                            bitmapMatrix.postRotate(90);
                            bitmapMatrix.postScale(-1, 1);
                            break;  // left top
                        case 6:
                            bitmapMatrix.postRotate(90);
                            break;  // right top
                        case 7:
                            bitmapMatrix.postRotate(270);
                            bitmapMatrix.postScale(-1, 1);
                            break;  // right bottom
                        case 8:
                            bitmapMatrix.postRotate(270);
                            break;  // left bottom
                        default:
                            break;  // Unknown
                    }
                    // Create new bitmap.
                    image = Bitmap.createBitmap(image, 0, 0, image.getWidth(), image.getHeight(), bitmapMatrix, false);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }


            String fileUri = MediaStore.Images.Media.insertImage(getReactApplicationContext().getContentResolver(), image, System.currentTimeMillis() + "", "");

            if (fileUri == null) {
                promise.reject("CameraKit", "Failed to save image to mediastore");
            } else {

                Cursor cursor = getReactApplicationContext().getContentResolver().query(Uri.parse(fileUri), new String[]{MediaStore.Images.ImageColumns.DATA}, null, null, null);
                cursor.moveToFirst();
                String filePath = cursor.getString(0);
                cursor.close();

                promise.resolve(filePath);
                CameraViewManager.reconnect();
            }
            return null;
        }
    }
}
