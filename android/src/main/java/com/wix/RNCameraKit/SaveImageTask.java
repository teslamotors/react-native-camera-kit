package com.wix.RNCameraKit;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.hardware.Camera;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.support.annotation.Nullable;
import android.util.Log;
import android.util.Patterns;

import com.drew.imaging.ImageMetadataReader;
import com.drew.imaging.ImageProcessingException;
import com.drew.metadata.Metadata;
import com.drew.metadata.MetadataException;
import com.drew.metadata.exif.ExifIFD0Directory;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.wix.RNCameraKit.camera.CameraViewManager;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URL;

import static com.facebook.react.common.ReactConstants.TAG;

public class SaveImageTask extends AsyncTask<byte[], Void, Void> {

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

    private Bitmap getImageBitmapFromRemoteImageFile() {
        Bitmap image;
        try {
            URL url = new URL(bitmapUrl);
            image = BitmapFactory.decodeStream(url.openStream());
        } catch (IOException e) {
            image = null;
        }
        return image;
    }

    private Bitmap getImageBitmapFromLocalImageFile() {
        Bitmap image;
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
        return image;
    }

    private Bitmap getImageBitmap(byte[]... data) {
        Bitmap image;
        if (bitmapUrl != null) {
            if (Patterns.WEB_URL.matcher(bitmapUrl.toLowerCase()).matches()) {
                image = getImageBitmapFromRemoteImageFile();
            } else {
                image = getImageBitmapFromLocalImageFile();
            }
        }
        else {
            byte[] rawImageData = data[0];
            image = decodeAndRotateIfNeeded(rawImageData);
        }
        return image;
    }

    @Override
    protected Void doInBackground(byte[]... data) {
        Bitmap image = getImageBitmap(data);
        if (image == null) {
            promise.reject("CameraKit", "failed to get Bitmap image");
            return null;
        }

        WritableMap imageInfo = saveToCameraRoll ? saveToMediaStore(image) : saveTempImageFile(image);
        if (imageInfo == null)
            promise.reject("CameraKit", "failed to save image to MediaStore");
        else {
            promise.resolve(imageInfo);
            CameraViewManager.reconnect();
        }
        return null;
    }

    private WritableMap createImageInfo(String fileUri, String id, String fileName, long fileSize, int width, int height) {
        WritableMap imageInfo = Arguments.createMap();
        imageInfo.putString("uri",  fileUri);
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

            return createImageInfo(fileUri, filePath, fileName, fileSize, image.getWidth(), image.getHeight());
        } catch (Exception e) {
            return null;
        }
    }

    private Bitmap decodeAndRotateIfNeeded(byte[] rawImageData) {
        Matrix bitmapMatrix = getRotationMatrix(rawImageData);
        Bitmap image = BitmapFactory.decodeByteArray(rawImageData, 0, rawImageData.length);
        if (bitmapMatrix.isIdentity())
            return image;
        else
            return rotateImage(image, bitmapMatrix);
    }

    private Bitmap rotateImage(Bitmap image, Matrix bitmapMatrix) {
        return Bitmap.createBitmap(image, 0, 0, image.getWidth(), image.getHeight(), bitmapMatrix, false);
    }

    private Matrix getRotationMatrix(byte[] rawImageData) {
        try {
            return tryGetRotationMatrix(rawImageData);
        } catch (Exception e) {
            return new Matrix();
        }
    }

    private Matrix tryGetRotationMatrix(byte[] rawImageData) throws ImageProcessingException, IOException, MetadataException {
        Matrix matrix = new Matrix();
        Metadata metadata = readMetadata(rawImageData);
        final ExifIFD0Directory exifIFD0Directory = metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);
        boolean hasOrientation = exifIFD0Directory.containsTag(ExifIFD0Directory.TAG_ORIENTATION);
        if (hasOrientation) {
            final int exifOrientation = exifIFD0Directory.getInt(ExifIFD0Directory.TAG_ORIENTATION);
            boolean isFacingFront = CameraViewManager.getCameraInfo().facing == Camera.CameraInfo.CAMERA_FACING_FRONT;
            convertExifOrientationToMatrix(matrix, exifOrientation, isFacingFront);
        }
        return matrix;
    }

    private void convertExifOrientationToMatrix(Matrix matrix, int exifOrientation, boolean isCameraFacingFront) {
        switch (exifOrientation) {
            case 1:
                break;  // top left
            case 2:
                matrix.postScale(-1, 1);
                break;  // top right
            case 3:
                matrix.postRotate(180);
                break;  // bottom right
            case 4:
                matrix.postRotate(180);
                matrix.postScale(-1, 1);
                break;  // bottom left
            case 5:
                matrix.postRotate(90);
                matrix.postScale(-1, 1);
                break;  // left top
            case 6:
                matrix.postRotate(90);
                break;  // right top
            case 7:
                matrix.postRotate(270);
                matrix.postScale(-1, 1);
                break;  // right bottom
            case 8:
                matrix.postRotate(270);
                break;  // left bottom
            default:
                break;  // Unknown
        }
        if (isCameraFacingFront) {
            matrix.postRotate(180);
        }
    }

    private Metadata readMetadata(byte[] rawImageData) throws ImageProcessingException, IOException {
        Metadata metadata = null;
        ByteArrayInputStream inputStream = null;
        BufferedInputStream bufferedInputStream = null;
        try {
            inputStream = new ByteArrayInputStream(rawImageData);
            bufferedInputStream = new BufferedInputStream(inputStream);
            metadata = ImageMetadataReader.readMetadata(bufferedInputStream, rawImageData.length);
        } finally {
            if (bufferedInputStream != null) bufferedInputStream.close();
            if (inputStream != null) inputStream.close();
        }
        return metadata;
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
