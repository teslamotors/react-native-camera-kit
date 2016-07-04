package com.wix.RNCameraKit.gallery;

import android.database.Cursor;
import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.support.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.wix.RNCameraKit.Utils;

import java.util.Collection;
import java.util.HashMap;

/**
 * Created by yedidyak on 29/06/2016.
 */
public class NativeGalleryModule extends ReactContextBaseJavaModule {

    public static final String[] ALBUMS_PROJECTION = new String[]{
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
    };

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
            albums.get(name).imageData = Utils.getBase64FromBitmap(thumbnail);
        }

        public boolean hasThumbnail(String name) {
            return albums.get(name).imageData != null;
        }

        public Collection<Album> getAlbums() {
            return albums.values();
        }
    }

    public NativeGalleryModule(ReactApplicationContext reactContext) {
        super(reactContext);
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
        map.putString("image", album.imageData);
        return map;
    }

    @NonNull
    private AlbumList getAlbumListFromCursor(Cursor imagesCursor) {
        AlbumList albums = new AlbumList();

        if (imagesCursor.moveToFirst()) {
            int bucketColumn = imagesCursor.getColumnIndex(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
            int thumbIdColumn = imagesCursor.getColumnIndex(MediaStore.Images.Media._ID);
            do {
                String name = imagesCursor.getString(bucketColumn);
                albums.addAlbum(name);
                if(!albums.hasThumbnail(name)) {
                    albums.setThumbnail(name, getThumbnail(imagesCursor.getInt(thumbIdColumn)));
                }
            } while (imagesCursor.moveToNext());
        }
        imagesCursor.close();
        return albums;
    }

    private Bitmap getThumbnail(int thumbId) {
        return MediaStore.Images.Thumbnails.getThumbnail(
            getCurrentActivity().getContentResolver(),
            thumbId,
            MediaStore.Images.Thumbnails.MINI_KIND,
            null);
    }

    @ReactMethod
    public void getAlbumsWithThumbnails(Promise promise) {

        Cursor imagesCursor = getCurrentActivity().getContentResolver().query(
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
}
