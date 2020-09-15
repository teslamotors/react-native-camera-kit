package com.rncamerakit.gallery;

import android.database.Cursor;
import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.rncamerakit.SaveImageTask;
import com.rncamerakit.Utils;
import com.rncamerakit.gallery.permission.StoragePermission;

import java.io.File;
import java.io.IOException;
import java.util.Collection;
import java.util.HashMap;

import static com.rncamerakit.Utils.getStringSafe;

/**
 * Created by yedidyak on 29/06/2016.
 */
public class NativeGalleryModule extends ReactContextBaseJavaModule {


    private final String IMAGE_URI_KEY = "uri";
    private final String IMAGE_NAME_KEY = "name";

    private final int HIGHE_DIMANTION = 1200;
    private final int MEDIUM_DIMANTION = 800;
    private final int LOW_DIMANTION = 600;


    public static final int MEDIUM_COMPRESSION_QUALITY = 85;
    public static final int HIGH_COMPRESSION_QUALITY = 92;

    private final String HIGH_QUALITY = "high";
    private final String MEDIUM_QUALITY = "medium";
    private final String LOW_QUALITY = "low";


    public static final String[] ALBUMS_PROJECTION = new String[]{
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
    };
    public static final String[] IMAGES_PROJECTION = new String[]{
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.SIZE,
            MediaStore.Images.Media.MIME_TYPE,
            MediaStore.Images.Media.TITLE,
            MediaStore.Images.Media.WIDTH,
            MediaStore.Images.Media.HEIGHT,
            MediaStore.Images.Media.DATA
    };
    public static final String ALL_PHOTOS = "All Photos";
    private Promise checkPermissionStatusPromise;

    private class Album {
        String name;
        String imageUri = null;
        int count = 1;

        public Album(String name, String uri) {
            this.name = name;
            this.imageUri = uri;
        }
    }

    private class AlbumList {
        HashMap<String, Album> albums = new HashMap<>();

        public void addAlbum(String name, String uri) {
            if (!albums.containsKey(name)) {
                albums.put(name, new Album(name, uri));
            } else {
                albums.get(name).count++;
            }
        }

        public Collection<Album> getAlbums() {
            return albums.values();
        }
    }

    private final StoragePermission storagePermission;

    public NativeGalleryModule(ReactApplicationContext reactContext) {
        super(reactContext);
        storagePermission = new StoragePermission();
        checkPermissionWhenActivityIsAvailable();
    }

    private void checkPermissionWhenActivityIsAvailable() {
        getReactApplicationContext().addLifecycleEventListener(new LifecycleEventListener() {
            @Override
            public void onHostResume() {
                if (checkPermissionStatusPromise != null && getCurrentActivity() != null) {
                    getCurrentActivity().runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            checkPermissionStatusPromise.resolve(storagePermission.checkAuthorizationStatus(getCurrentActivity()));
                            checkPermissionStatusPromise = null;
                        }
                    });
                }
            }

            @Override
            public void onHostPause() {

            }

            @Override
            public void onHostDestroy() {

            }
        });
    }

    @Override
    public String getName() {
        return "NativeGalleryModule";
    }

    @NonNull
    private WritableMap albumToMap(Album album) {
        WritableMap map = Arguments.createMap();
        map.putInt("imagesCount", album.count);
        map.putString("albumName", album.name);
        map.putString("thumbUri", album.imageUri);
        return map;
    }

    @NonNull
    private AlbumList getAlbumListFromCursor(Cursor imagesCursor) {
        AlbumList albums = new AlbumList();

        if (imagesCursor.moveToFirst()) {
            int bucketColumn = imagesCursor.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
            int uriColumn = imagesCursor.getColumnIndex(MediaStore.Images.Media.DATA);
            do {
                String name = imagesCursor.getString(bucketColumn);
                String uri = imagesCursor.getString(uriColumn);
                albums.addAlbum(name, uri);
                albums.addAlbum(ALL_PHOTOS, uri);
            } while (imagesCursor.moveToNext());
        }
        imagesCursor.close();
        return albums;
    }

    private Bitmap getThumbnail(int thumbId) {
        return MediaStore.Images.Thumbnails.getThumbnail(
                getReactApplicationContext().getContentResolver(),
                thumbId,
                MediaStore.Images.Thumbnails.MINI_KIND,
                null);
    }

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        storagePermission.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    @ReactMethod
    public void checkDeviceStorageAuthorizationStatus(final Promise promise) {
        if (getCurrentActivity() == null) {
            checkPermissionStatusPromise = promise;
        } else {
            getCurrentActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    promise.resolve(storagePermission.checkAuthorizationStatus(getCurrentActivity()));
                }
            });
        }
    }

    @ReactMethod
    public void requestDeviceStorageAuthorization(Promise promise) {
        storagePermission.requestAccess(getCurrentActivity(), promise);
    }

    @ReactMethod
    public void getAlbumsWithThumbnails(Promise promise) {
        Cursor imagesCursor = getReactApplicationContext().getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, ALBUMS_PROJECTION, null, null, null);
        AlbumList albums = getAlbumListFromCursor(imagesCursor);
        WritableArray arr = Arguments.createArray();

        for (Album album : albums.getAlbums()) {
            arr.pushMap(albumToMap(album));
        }

        WritableMap ret = Arguments.createMap();
        ret.putArray("albums", arr);

        promise.resolve(ret);
    }


    @ReactMethod
    public void resizeImage(ReadableMap image, String quality, Promise promise) throws IOException {
        try {
            String imageUrlString = getStringSafe(image, IMAGE_URI_KEY);
            if (imageUrlString.startsWith(Utils.FILE_PREFIX)) {
                imageUrlString = imageUrlString.replaceFirst(Utils.FILE_PREFIX, "");
            }

            // decide what is the wanted compression & resolution
            int maxResolution;
            int compressionQuality;
            switch(quality) {
                case HIGH_QUALITY:
                    maxResolution = HIGHE_DIMANTION;
                    compressionQuality = MEDIUM_COMPRESSION_QUALITY;
                    break;
                case MEDIUM_QUALITY:
                    maxResolution = MEDIUM_DIMANTION;
                    compressionQuality = MEDIUM_COMPRESSION_QUALITY;
                    break;
                case LOW_QUALITY:
                    maxResolution = LOW_DIMANTION;
                    compressionQuality = MEDIUM_COMPRESSION_QUALITY;
                    break;
                default:
                    maxResolution = HIGHE_DIMANTION;
                    compressionQuality = HIGH_COMPRESSION_QUALITY;
            }

            WritableMap ans = Utils.resizeImage(getReactApplicationContext(), image, imageUrlString, maxResolution, compressionQuality);

            promise.resolve(ans);
        } catch (IOException e) {
            Log.d("","Failed resize image e: "+e.getMessage());
        }
    }


    @ReactMethod
    public void getImagesForUris(ReadableArray uris, Promise promise) {
        StringBuilder builder = new StringBuilder();
        builder.append(MediaStore.Images.Media.DATA + " IN (");
        for (int i = 0; i < uris.size(); i++) {
            builder.append("\"");
            builder.append(uris.getString(i));
            builder.append("\"");
            if (i != uris.size() - 1) {
                builder.append(", ");
            }
        }
        builder.append(")");
        String selection = builder.toString();

        Cursor cursor = getReactApplicationContext().getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                IMAGES_PROJECTION,
                selection,
                null,
                null
        );

        WritableArray arr = Arguments.createArray();

        if (cursor != null) {
            if (cursor.moveToFirst()) {
                int dataIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATA);
                int sizeIndex = cursor.getColumnIndex(MediaStore.Images.Media.SIZE);
                int nameIndex = cursor.getColumnIndex(MediaStore.Images.Media.TITLE);
                int mimeIndex = cursor.getColumnIndex(MediaStore.Images.Media.MIME_TYPE);
                int widthIndex = cursor.getColumnIndex(MediaStore.Images.Media.WIDTH);
                int heightIndex = cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT);
                do {
                    WritableMap map = Arguments.createMap();
                    map.putString("uri", "file://" + cursor.getString(dataIndex));
                    map.putInt("size", cursor.getInt(sizeIndex));
                    map.putInt("width", cursor.getInt(widthIndex));
                    map.putInt("height", cursor.getInt(heightIndex));
                    map.putString("mime_type", cursor.getString(mimeIndex));
                    map.putString("name", cursor.getString(nameIndex));
                    arr.pushMap(map);
                } while (cursor.moveToNext());
            }
            cursor.close();
        }
        WritableMap ret = Arguments.createMap();
        ret.putArray("images", arr);
        promise.resolve(ret);
    }

    @ReactMethod
    public void saveImageURLToCameraRoll(String imageUrl, final Promise promise) {
        new SaveImageTask(imageUrl, getReactApplicationContext(), promise, true).execute();
    }

    @ReactMethod
    public void deleteTempImage(String imageUrl, final Promise promise) {
        boolean success = true;
        String imagePath = imageUrl.replace("file://", "");
        File imageFile = new File(imagePath);
        if (imageFile.exists()) {
            success = imageFile.delete();
        }

        if (promise != null) {
            WritableMap result = Arguments.createMap();
            result.putBoolean("success", success);
            promise.resolve(result);
        }
    }
}
