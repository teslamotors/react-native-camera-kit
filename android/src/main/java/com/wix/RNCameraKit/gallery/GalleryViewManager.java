package com.wix.RNCameraKit.gallery;

import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.ArrayList;
import java.util.Map;

import javax.annotation.Nullable;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryViewManager extends SimpleViewManager<GalleryView> {

    public static final int COMMAND_REFRESH_GALLERY = 1;
    private ThemedReactContext reactContext;

    @Override
    public String getName() {
        return "GalleryView";
    }

    @Override
    protected GalleryView createViewInstance(ThemedReactContext reactContext) {
        this.reactContext = reactContext;
        return new GalleryView(reactContext);
    }

    @ReactProp(name = "albumName")
    public void setAlbumName(GalleryView view, String albumName) {
        view.setAlbumName(albumName);
    }

    @ReactProp(name = "minimumInteritemSpacing")
    public void setItemSpacing(GalleryView view, int itemSpacing) {
        view.setItemSpacing(itemSpacing/2);
    }

    @ReactProp(name = "minimumLineSpacing")
    public void setLineSpacing(GalleryView view, int lineSpacing) {
        view.setLineSpacing(lineSpacing/2);
    }

    @ReactProp(name = "columnCount")
    public void setColumnCount(GalleryView view, int columnCount) {
        view.setColumnCount(columnCount);
    }

    @ReactProp(name = "selectedImages")
    public void setSelectedUris(GalleryView view, ReadableArray uris) {
        ArrayList<String> list = new ArrayList<>();
        for(int i = 0; i < uris.size(); i++) {
            list.add(uris.getString(i));
        }
        view.setSelectedUris(list);
    }

    @ReactProp(name = "selectedImageIcon")
    public void setSelectedImage(final GalleryView view, final String imageSource) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                final Drawable drawable = ResourceDrawableIdHelper.getIcon(view.getContext(), imageSource);
                reactContext.runOnUiQueueThread(new Runnable() {
                    @Override
                    public void run() {
                        view.setSelectedDrawable(drawable);
                    }
                });
            }
        }).start();
    }

    @ReactProp(name = "unSelectedImageIcon")
    public void setUnselectedImage(final GalleryView view, final String imageSource) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                final Drawable drawable = ResourceDrawableIdHelper.getIcon(view.getContext(), imageSource);
                reactContext.runOnUiQueueThread(new Runnable() {
                    @Override
                    public void run() {
                        view.setUnselectedDrawable(drawable);
                    }
                });
            }
        }).start();
    }

    @Nullable
    @Override
    public Map getExportedCustomDirectEventTypeConstants() {
        return MapBuilder.builder()
                .put("onTapImage", MapBuilder.of("registrationName", "onTapImage"))
                .build();
    }

    @Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        return MapBuilder.of("rereshGalleryView", COMMAND_REFRESH_GALLERY);
    }

    @Override
    public void receiveCommand(GalleryView root, int commandId, @Nullable ReadableArray args) {
        if (commandId == COMMAND_REFRESH_GALLERY) {
            root.refresh();
        }
    }
}
