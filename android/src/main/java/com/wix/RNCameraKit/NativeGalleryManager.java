package com.wix.RNCameraKit;

import android.database.Cursor;
import android.graphics.Bitmap;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Base64;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.io.ByteArrayOutputStream;
import java.util.Collection;
import java.util.HashMap;

/**
 * Created by yedidyak on 29/06/2016.
 */
public class NativeGalleryManager extends ReactContextBaseJavaModule {

    private class Album {
        String name;
        String imageData = null;
        int count = 1;

        public Album(String name) {
            this.name = name;
        }
    }

    private class AlbumList {
        HashMap<String, Album> albums = new HashMap<>();

        public void addAlbum(String name) {
            if (!albums.containsKey(name)) {
                albums.put(name, new Album(name));
            }
            else {
                albums.get(name).count++;
            }
        }

        public void setThumbnail(String name, Bitmap thumbnail) {

            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            thumbnail.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
            byte[] byteArray = byteArrayOutputStream .toByteArray();
            String encoded = Base64.encodeToString(byteArray, Base64.DEFAULT);

            albums.get(name).imageData = encoded;
        }

        public boolean hasThumbnail(String name) {
            return albums.get(name).imageData != null;
        }

        public Collection<Album> getAlbums() {
            return albums.values();
        }
    }

    public NativeGalleryManager(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "NativeGalleryManager";
    }

    @ReactMethod
    public void getAlbumsWithThumbnails(Promise promise) {

        String[] projection = new String[]{
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Images.Media._ID
        };

        Uri images = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        Cursor imagesCursor = getCurrentActivity().getContentResolver().query(images, projection, null, null, null);

        AlbumList albums = new AlbumList();

        if (imagesCursor.moveToFirst()) {
            int bucketColumn = imagesCursor.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
            int thumbIdColumn = imagesCursor.getColumnIndex(MediaStore.Images.Media._ID);
            do {
                String name = imagesCursor.getString(bucketColumn);
                albums.addAlbum(name);

                if(!albums.hasThumbnail(name)) {
                    int thumbId = imagesCursor.getInt(thumbIdColumn);
                    Bitmap thumb = MediaStore.Images.Thumbnails.getThumbnail(
                            getCurrentActivity().getContentResolver(),
                            thumbId,
                            MediaStore.Images.Thumbnails.MINI_KIND,
                            null);
                    albums.setThumbnail(name, thumb);
                }
            } while (imagesCursor.moveToNext());
        }

        WritableArray arr = Arguments.createArray();

        for (Album album : albums.getAlbums()) {
            WritableMap map = Arguments.createMap();
            map.putInt("imagesCount", album.count);
            map.putString("albumName", album.name);
            map.putString("image", album.imageData);
            arr.pushMap(map);
        }

        WritableMap ret = Arguments.createMap();
        ret.putArray("albums", arr);

        promise.resolve(ret);
    }

    @ReactMethod
    public void getPhotosForAlbum(String albumName, int numberOfPhotos, Promise promise) {

    }
}
