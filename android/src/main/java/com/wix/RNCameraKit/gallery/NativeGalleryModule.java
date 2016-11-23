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
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.Collection;
import java.util.HashMap;

/**
 * Created by yedidyak on 29/06/2016.
 */
public class NativeGalleryModule extends ReactContextBaseJavaModule {

    public static final String[] ALBUMS_PROJECTION = new String[]{
        MediaStore.Images.Media.DATA,
        MediaStore.Images.Media.BUCKET_DISPLAY_NAME
    };
    public static final String[] IMAGES_PROJECTION = new String[]{
        MediaStore.Images.Media. _ID,
        MediaStore.Images.Media.SIZE,
        MediaStore.Images.Media.MIME_TYPE,
        MediaStore.Images.Media.TITLE,
        MediaStore.Images.Media.DATA
    };
    public static final String ALL_PHOTOS = "All Photos";

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
            }
            else {
                albums.get(name).count++;
            }
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
    public void getImagesForUris(ReadableArray uris, Promise promise) {

        StringBuilder builder = new StringBuilder();
        builder.append(MediaStore.Images.Media.DATA + " IN (");
        for (int i=0; i<uris.size(); i++) {
            builder.append("\"");
            builder.append(uris.getString(i));
            builder.append("\"");
            if(i != uris.size() -1) {
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
                do {
                    WritableMap map = Arguments.createMap();
                    map.putString("uri", "file://" + cursor.getString(dataIndex));
                    map.putInt("size", cursor.getInt(sizeIndex));
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
}
