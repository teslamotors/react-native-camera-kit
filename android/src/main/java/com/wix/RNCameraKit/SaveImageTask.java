package com.wix.RNCameraKit;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import static com.facebook.react.common.ReactConstants.TAG;

public class SaveImageTask extends AsyncTask<Bitmap, Void, Void> {

    private final Context context;
    private final Promise promise;
    private boolean saveToCameraRoll;
    private String bitmapUrl = null;

    public SaveImageTask(Context context, Promise promise, boolean saveToCameraRoll) {
        this.context = context;
        this.promise = promise;
        this.saveToCameraRoll = saveToCameraRoll;
    }

    public SaveImageTask(String bitmapUrl, Context context, Promise promise, boolean saveToCameraRoll) {
        this(context, promise, saveToCameraRoll);
        this.bitmapUrl = bitmapUrl;
        if (this.bitmapUrl != null) {
            this.bitmapUrl = this.bitmapUrl.replace("file://","");
        }
    }

    private Bitmap getImageBitmap(Bitmap maybeImage) {
        Bitmap image;
        if (bitmapUrl != null) {
            FileInputStream fis;
            File imageFile = new File(bitmapUrl);
            try {
                fis = new FileInputStream(imageFile);
                image = BitmapFactory.decodeStream(fis);
                fis.close();
            } catch (IOException e) {
                e.printStackTrace();
                image = null;
            }

            if (imageFile.exists()) {
                imageFile.delete();
            }
        }
        else {
            image = maybeImage;
        }
        return image;
    }

    @Override
    protected Void doInBackground(Bitmap... maybeImage) {
        Bitmap image = getImageBitmap(maybeImage.length == 0 ? null : maybeImage[0]);
        if (image == null) {
            promise.reject("CameraKit", "failed to get Bitmap image");
            return null;
        }

        WritableMap imageInfo = saveToCameraRoll ? saveToMediaStore(image) : saveTempImageFile(image);
        if (imageInfo == null)
            promise.reject("CameraKit", "failed to save image to MediaStore");
        else {
            promise.resolve(imageInfo);
        }
        return null;
    }

    private WritableMap createImageInfo(String filePath, String id, String fileName, long fileSize, int width, int height) {
        WritableMap imageInfo = Arguments.createMap();
        imageInfo.putString("uri",  filePath);
        imageInfo.putString("id", id);
        imageInfo.putString("name", fileName);
        imageInfo.putInt("size", (int) fileSize);
        imageInfo.putInt("width", width);
        imageInfo.putInt("height", height);
        return imageInfo;
    }

    private WritableMap saveToMediaStore(Bitmap image) {
        try {
            String fileUri = MediaStore.Images.Media.insertImage(context.getContentResolver(), image, System.currentTimeMillis() + "", "");
            Cursor cursor = context.getContentResolver().query(Uri.parse(fileUri), new String[]{
                    MediaStore.Images.ImageColumns.DATA,
                    MediaStore.Images.ImageColumns.DISPLAY_NAME
            }, null, null, null);
            cursor.moveToFirst();
            int pathIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.DATA);
            int nameIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.DISPLAY_NAME);
            String filePath = cursor.getString(pathIndex);
            String fileName = cursor.getString(nameIndex);
            long fileSize = new File(filePath).length();
            cursor.close();

            return createImageInfo(filePath, filePath, fileName, fileSize, image.getWidth(), image.getHeight());
        } catch (Exception e) {
            return null;
        }
    }

    @Nullable
    private WritableMap saveTempImageFile(Bitmap image) {
        File imageFile;
        FileOutputStream outputStream;

        Long tsLong = System.currentTimeMillis()/1000;
        String fileName = "temp_Image_" + tsLong.toString() + ".jpg";

        try {
            imageFile = new File(context.getCacheDir(), fileName);
            if (imageFile.exists()) {
                imageFile.delete();
            }
            outputStream = new FileOutputStream(imageFile);
            image.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
            outputStream.close();
        } catch (IOException e) {
            Log.d(TAG, "Error accessing file: " + e.getMessage());
            imageFile = null;
        }
        return (imageFile != null) ? createImageInfo(Uri.fromFile(imageFile).toString(), imageFile.getAbsolutePath(), fileName, imageFile.length(), image.getWidth(), image.getHeight()) : null;
    }
}
