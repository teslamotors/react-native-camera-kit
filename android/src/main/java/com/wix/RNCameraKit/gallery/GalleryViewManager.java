package com.wix.RNCameraKit.gallery;

import android.graphics.drawable.Drawable;
import android.support.annotation.NonNull;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.ArrayList;
import java.util.Map;

import javax.annotation.Nullable;

public class GalleryViewManager extends SimpleViewManager<GalleryView> {

    private static final int COMMAND_REFRESH_GALLERY = 1;

    private final String UNSUPPORTED_IMAGE_KEY = "unsupportedImage";
    private final String UNSUPPORTED_TEXT_KEY = "unsupportedText";
    private final String UNSUPPORTED_TEXT_COLOR_KEY = "unsupportedTextColor";
    private final String SUPPORTED_TYPES_KEY = "supportedFileTypes";
    private final String UNSUPPORTED_OVERLAY_KEY = "unsupportedOverlayColor";
    private final String CUSTOM_BUTTON_IMAGE_KEY = "image";
    private final String CUSTOM_BUTTON_BCK_COLOR_KEY = "backgroundColor";

    private ThemedReactContext reactContext;

    @Override
    public String getName() {
        return "GalleryView";
    }

    @Override
    protected GalleryView createViewInstance(ThemedReactContext reactContext) {
        this.reactContext = reactContext;

        GalleryView view = new GalleryView(reactContext);
        view.setAdapter(new GalleryAdapter(view));
        return view;
    }

    @Override
    protected void onAfterUpdateTransaction(GalleryView view) {
        getViewAdapter(view).refreshData();
    }

    @ReactProp(name = "minimumInteritemSpacing")
    public void setItemSpacing(GalleryView view, int itemSpacing) {
        view.setItemSpacing(itemSpacing/2);
    }

    @ReactProp(name = "minimumLineSpacing")
    public void setLineSpacing(GalleryView view, int lineSpacing) {
        view.setLineSpacing(lineSpacing/2);
    }

    @ReactProp(name = "albumName")
    public void setAlbumName(GalleryView view, String albumName) {
        getViewAdapter(view).setAlbum(albumName);
    }

    @ReactProp(name = "columnCount")
    public void setColumnCount(GalleryView view, int columnCount) {
        view.setColumnCount(columnCount);
    }

    @ReactProp(name = "selectedImages")
    public void setSelectedUris(GalleryView view, ReadableArray uris) {
        getViewAdapter(view).setSelectedUris(readableArrayToList(uris));
    }

    @ReactProp(name = "dirtyImages")
    public void setDirtyImages(GalleryView view, final ReadableArray uris) {
        getViewAdapter(view).setDirtyUris(readableArrayToList(uris));
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
                        getViewAdapter(view).setSelectedDrawable(drawable);
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
                        getViewAdapter(view).setUnselectedDrawable(drawable);
                    }
                });
            }
        }).start();
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
                        getViewAdapter(view)
                                .setUnsupportedUIParams(
                                    unsupportedOverlayColor,
                                    unsupportedFinalImage,
                                    unsupportedText,
                                    unsupportedTextColor);
                        getViewAdapter(view).setSupportedFileTypes(supportedFileTypesList);
                    }
                });
            }
        }).start();
    }

    @ReactProp(name = "customButtonStyle")
    public void setCustomButton(final GalleryView view, final ReadableMap props) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                final String imageResource = getStringSafe(props, CUSTOM_BUTTON_IMAGE_KEY);
                final String backgroundColor = getStringSafe(props, CUSTOM_BUTTON_BCK_COLOR_KEY);
                final Drawable drawable = ResourceDrawableIdHelper.getIcon(view.getContext(), imageResource);
                reactContext.runOnUiQueueThread(new Runnable() {
                    @Override
                    public void run() {
                        getViewAdapter(view).setCustomButtonImage(drawable);
                        if (backgroundColor != null) {
                            getViewAdapter(view).setCustomButtonBackgroundColor(backgroundColor);
                        }
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
                .put("onCustomButtonPress", MapBuilder.of("registrationName", "onCustomButtonPress"))
                .build();
    }

    @Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        return MapBuilder.of("refreshGalleryView", COMMAND_REFRESH_GALLERY);
    }

    @Override
    public void receiveCommand(GalleryView view, int commandId, @Nullable ReadableArray args) {
        if (commandId == COMMAND_REFRESH_GALLERY) {
            getViewAdapter(view).refreshData();
        }
    }

    private @Nullable String getStringSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getString(key);
        }
        return null;
    }

    private @NonNull ArrayList<String> readableArrayToList(ReadableArray uris) {
        ArrayList<String> list = new ArrayList<>();
        for(int i = 0; i < uris.size(); i++) {
            list.add(uris.getString(i));
        }
        return list;
    }

    private GalleryAdapter getViewAdapter(GalleryView view) {
        return ((GalleryAdapter) view.getAdapter());
    }
}
