package com.wix.RNCameraKit;

import android.content.ContentResolver;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.support.annotation.NonNull;
import android.util.Base64;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Date;

import javax.annotation.Nullable;

public class Utils {

    public final static String CONTENT_PREFIX = "content://";
    public final static String FILE_PREFIX = "file://";
    private static final int MAX_SAMPLE_SIZE = 8;



    public static String getBase64FromBitmap(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream .toByteArray();
        return Base64.encodeToString(byteArray, Base64.DEFAULT);
    }

    @Nullable
    public static String getStringSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getString(key);
        }
        return null;
    }

    public static @Nullable Integer getIntSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getInt(key);
        }
        return null;
    }

    public static @Nullable Boolean getBooleanSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getBoolean(key);
        }
        return null;
    }

    public static @NonNull ArrayList<String> readableArrayToList(ReadableArray items) {
        ArrayList<String> list = new ArrayList<>();
        for(int i = 0; i < items.size(); i++) {
            list.add(items.getString(i));
        }
        return list;
    }


    @NonNull
    public static WritableMap resizeImage(Context context, String imageName, String imageUrlString, int maxResolution, int compressionQuality) throws IOException {
        Bitmap sourceImage = null;
        sourceImage = Utils.loadBitmapFromFile(context, imageUrlString, maxResolution, maxResolution);

        if (sourceImage == null) {
            throw new IOException("Unable to load source image from path");
        }

        Bitmap scaledImage = Utils.resizeImage(sourceImage, maxResolution, maxResolution);
        if (sourceImage != scaledImage) {
            sourceImage.recycle();
        }

        // Save the resulting image
        File path = context.getCacheDir();
        String resizedImagePath = Utils.saveImage(scaledImage, path, Long.toString(new Date().getTime()), Bitmap.CompressFormat.JPEG, compressionQuality);

        // Clean up remaining image
        scaledImage.recycle();

        WritableMap ans = Arguments.createMap();
        ans.putString("uri", FILE_PREFIX+resizedImagePath);
        ans.putString("name", imageName);
        ans.putInt("size",  (int)new File(resizedImagePath).length());
        ans.putInt("width", scaledImage.getWidth());
        ans.putInt("height", scaledImage.getHeight());
        return ans;
    }


    /**
     * Resize the specified bitmap, keeping its aspect ratio.
     */
    public static Bitmap resizeImage(Bitmap image, int maxWidth, int maxHeight) {
        Bitmap newImage = null;
        if (image == null) {
            return null; // Can't load the image from the given path.
        }

        if (maxHeight > 0 && maxWidth > 0) {
            float width = image.getWidth();
            float height = image.getHeight();

            float ratio = Math.min((float)maxWidth / width, (float)maxHeight / height);

            int finalWidth = (int) (width * ratio);
            int finalHeight = (int) (height * ratio);
            newImage = Bitmap.createScaledBitmap(image, finalWidth, finalHeight, true);
        }

        return newImage;
    }


    /**
     * Compute the inSampleSize value to use to load a bitmap.
     * Adapted from https://developer.android.com/training/displaying-bitmaps/load-bitmap.html
     */
    public static int calculateInSampleSize(int width, int height, int reqWidth, int reqHeight) {

        if (reqHeight == 0 || reqWidth == 0) {
            return 1;
        }

        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {

            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            while (inSampleSize <= MAX_SAMPLE_SIZE
                    && (halfHeight / inSampleSize) >= reqHeight
                    && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }



    public static Bitmap loadBitmap(Context context, String imagePath, BitmapFactory.Options options) throws IOException {
        Bitmap sourceImage = null;
        if (!imagePath.startsWith(CONTENT_PREFIX)) {
            try {
                sourceImage = BitmapFactory.decodeFile(imagePath, options);
            } catch (Exception e) {
                e.printStackTrace();
                throw new IOException("Error decoding image file");
            }
        } else {
            ContentResolver cr = context.getContentResolver();
            InputStream input = cr.openInputStream(Uri.parse(imagePath));
            if (input != null) {
                sourceImage = BitmapFactory.decodeStream(input, null, options);
                input.close();
            }
        }
        return sourceImage;
    }

    /**
     * Loads the bitmap resource from the file specified in imagePath.
     */
    public static Bitmap loadBitmapFromFile(Context context, String imagePath, int newWidth,
                                            int newHeight) throws IOException  {
        // Decode the image bounds to find the size of the source image.
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        loadBitmap(context, imagePath, options);

        // Set a sample size according to the image size to lower memory usage.
        options.inSampleSize = calculateInSampleSize(options.outWidth, options.outHeight , newWidth, newHeight);
        options.inJustDecodeBounds = false;
        return loadBitmap(context, imagePath, options);
    }


    /**
     * Save the given bitmap in a directory. Extension is automatically generated using the bitmap format.
     */
    public static String saveImage(Bitmap bitmap, File saveDirectory, String fileName,
                                   Bitmap.CompressFormat compressFormat, int quality)
            throws IOException {
        if (bitmap == null) {
            throw new IOException("The bitmap couldn't be resized");
        }

        File newFile = new File(saveDirectory, fileName + "." + compressFormat.name());
        if(!newFile.createNewFile()) {
            throw new IOException("The file already exists");
        }

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        bitmap.compress(compressFormat, quality, outputStream);
        byte[] bitmapData = outputStream.toByteArray();

        outputStream.flush();
        outputStream.close();

        FileOutputStream fos = new FileOutputStream(newFile);
        fos.write(bitmapData);
        fos.flush();
        fos.close();

        return newFile.getAbsolutePath();
    }
}
