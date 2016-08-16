package com.wix.RNCameraKit.gallery;

import android.graphics.Bitmap;
import android.graphics.Color;
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

//    fileTypeSupport={{
//        supportedFileTypes: ['image/jpeg', 'image/png'],
//        unsupportedOverlayColor: "#00000055",
//                unsupportedImage: require('./images/unsupportedImage.png'),
//                unsupportedText: 'Unsupported',
//                unsupportedTextColor: '#ffffff'
//    }}

    private final String UNSUPPORTED_IMAGE_KEY = "unsupportedImage";
    private final String UNSUPPORTED_TEXT_KEY = "unsupportedText";
    private final String UNSUPPORTED_TEXT_COLOR_KEY = "unsupportedTextColor";
    private final String SUPPORTED_TYPES_KEY = "supportedFileTypes";
    private final String UNSUPPORTED_OVERLAY_KEY = "unsupportedOverlayColor";

    private @Nullable String getStringSafe(ReadableMap map, String key) {
        if(map.hasKey(key)) {
            return map.getString(key);
        }
        return null;
    }

    @ReactProp(name = "fileTypeSupport")
    public void setFileTypeSupport(final GalleryView view, final ReadableMap fileTypeSupport) {
        final ReadableArray supportedFileTypes = fileTypeSupport.getArray(SUPPORTED_TYPES_KEY);
        final String unsupportedOverlayColor = getStringSafe(fileTypeSupport, UNSUPPORTED_OVERLAY_KEY);
        final String unsupportedImageSource = getStringSafe(fileTypeSupport, UNSUPPORTED_IMAGE_KEY);
        final String unsupportedText = getStringSafe(fileTypeSupport, UNSUPPORTED_TEXT_KEY);
        final String unsupportedTextColor = getStringSafe(fileTypeSupport, UNSUPPORTED_TEXT_COLOR_KEY);

        new Thread(new Runnable() {
            @Override
            public void run() {
                Drawable unsupportedImage = null;
                if(unsupportedImageSource != null) {
                    unsupportedImage = ResourceDrawableIdHelper.getIcon(view.getContext(), unsupportedImageSource);
                }
                final Drawable unsupportedFinalImage = unsupportedImage;
                final ArrayList<String> supportedFileTypesList = new ArrayList<String>();
                if(supportedFileTypes != null && supportedFileTypes.size() != 0) {
                    for (int i = 0; i < supportedFileTypes.size(); i++) {
                        supportedFileTypesList.add(supportedFileTypes.getString(i));
                    }
                }

                reactContext.runOnUiQueueThread(new Runnable() {
                    @Override
                    public void run() {
                        view.setUnsupportedUIParams(
                                unsupportedOverlayColor,
                                unsupportedFinalImage,
                                unsupportedText,
                                unsupportedTextColor);
                        view.setSupportedFileTypes(supportedFileTypesList);
                        view.refresh();
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
