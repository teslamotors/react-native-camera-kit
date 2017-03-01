package com.wix.RNCameraKit.gallery;

import android.graphics.drawable.Drawable;
import android.os.Handler;
import android.os.HandlerThread;
import android.support.annotation.NonNull;
import android.view.View;

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
    private final String SELECTION_SELECTED_IMAGE_KEY = "selectedImage";
    private final String SELECTION_UNSELECTED_IMAGE_KEY = "unselectedImage";
    private final String SELECTION_POSITION_KEY = "position";
    private final String SELECTION_SIZE_KEY = "size";

    /**
     * A handler is required in order to sync configurations made to the adapter - some must run off the UI thread (e.g. drawables
     * fetching), so that the finalizing call to refreshData() (from within {@link #onAfterUpdateTransaction(View)}) will be made
     * <u>strictly after all configurations have settled in</u>.
     *
     * <p>Note: It is not mandatory to invoke <b>all</b> config set-ups via the handler, but we do so anyway so as to avoid
     * races between multiple threads.</p>
     */
    private Handler adapterConfigHandler;

    @Override
    public String getName() {
        return "GalleryView";
    }

    @Override
    protected GalleryView createViewInstance(ThemedReactContext reactContext) {
        final HandlerThread handlerThread = new HandlerThread("GalleryViewManager.configThread");
        handlerThread.start();
        adapterConfigHandler = new Handler(handlerThread.getLooper());

        GalleryView view = new GalleryView(reactContext);
        view.setAdapter(new GalleryAdapter(view));
        return view;
    }

    @Override
    protected void onAfterUpdateTransaction(final GalleryView view) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                getViewAdapter(view).refreshData();
            }
        });
        super.onAfterUpdateTransaction(view);
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
    public void setAlbumName(final GalleryView view, final String albumName) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                getViewAdapter(view).setAlbum(albumName);
            }
        });
    }

    @ReactProp(name = "columnCount")
    public void setColumnCount(GalleryView view, int columnCount) {
        view.setColumnCount(columnCount);
    }

    @ReactProp(name = "selectedImages")
    public void setSelectedUris(final GalleryView view, final ReadableArray uris) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                getViewAdapter(view).setSelectedUris(readableArrayToList(uris));
            }
        });
    }

    @ReactProp(name = "dirtyImages")
    public void setDirtyImages(final GalleryView view, final ReadableArray uris) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                getViewAdapter(view).setDirtyUris(readableArrayToList(uris));
            }
        });
    }

    @ReactProp(name = "selectedImageIcon")
    public void setSelectedImage(final GalleryView view, final String imageSource) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                final Drawable drawable = ResourceDrawableIdHelper.getIcon(view.getContext(), imageSource);
                getViewAdapter(view).setSelectedDrawable(drawable);
            }
        });
    }

    @ReactProp(name = "unSelectedImageIcon")
    public void setUnselectedImage(final GalleryView view, final String imageSource) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                final Drawable drawable = ResourceDrawableIdHelper.getIcon(view.getContext(), imageSource);
                getViewAdapter(view).setUnselectedDrawable(drawable);
            }
        });
    }

    @ReactProp(name = "selection")
    public void setSelectionProperties(final GalleryView view, final ReadableMap selectionProps) {
        final String selectedImage = getStringSafe(selectionProps, SELECTION_SELECTED_IMAGE_KEY);
        final String unselectedImage = getStringSafe(selectionProps, SELECTION_UNSELECTED_IMAGE_KEY);
        final Integer position = getIntSafe(selectionProps, SELECTION_POSITION_KEY);
        final String size = getStringSafe(selectionProps, SELECTION_SIZE_KEY);
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                final GalleryAdapter viewAdapter = getViewAdapter(view);

                if (selectedImage != null) {
                    final Drawable selectedDrawable = ResourceDrawableIdHelper.getIcon(view.getContext(), selectedImage);
                    viewAdapter.setSelectedDrawable(selectedDrawable);
                }

                if (unselectedImage != null) {
                    final Drawable unselectedDrawable = ResourceDrawableIdHelper.getIcon(view.getContext(), unselectedImage);
                    viewAdapter.setUnselectedDrawable(unselectedDrawable);
                }

                if (position != null) {
                    viewAdapter.setSelectionDrawablePosition(position);
                }

                if (size != null) {
                    final int sizeCode = size.equalsIgnoreCase("large") ? GalleryAdapter.SELECTED_IMAGE_SIZE_LARGE : GalleryAdapter.SELECTED_IMAGE_SIZE_NORMAL;
                    viewAdapter.setSelectedDrawableSize(sizeCode);
                }
            }
        });
    }

    @ReactProp(name = "fileTypeSupport")
    public void setFileTypeSupport(final GalleryView view, final ReadableMap fileTypeSupport) {
        final ReadableArray supportedFileTypes = fileTypeSupport.getArray(SUPPORTED_TYPES_KEY);
        final String unsupportedOverlayColor = getStringSafe(fileTypeSupport, UNSUPPORTED_OVERLAY_KEY);
        final String unsupportedImageSource = getStringSafe(fileTypeSupport, UNSUPPORTED_IMAGE_KEY);
        final String unsupportedText = getStringSafe(fileTypeSupport, UNSUPPORTED_TEXT_KEY);
        final String unsupportedTextColor = getStringSafe(fileTypeSupport, UNSUPPORTED_TEXT_COLOR_KEY);

        dispatchOnConfigJobQueue(new Runnable() {
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

    @ReactProp(name = "customButtonStyle")
    public void setCustomButton(final GalleryView view, final ReadableMap props) {
        dispatchOnConfigJobQueue(new Runnable() {
            @Override
            public void run() {
                final String imageResource = getStringSafe(props, CUSTOM_BUTTON_IMAGE_KEY);
                final String backgroundColor = getStringSafe(props, CUSTOM_BUTTON_BCK_COLOR_KEY);
                final Drawable drawable = ResourceDrawableIdHelper.getIcon(view.getContext(), imageResource);

                getViewAdapter(view).setCustomButtonImage(drawable);
                if (backgroundColor != null) {
                    getViewAdapter(view).setCustomButtonBackgroundColor(backgroundColor);
                }
            }
        });
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

    private void dispatchOnConfigJobQueue(Runnable runnable) {
        adapterConfigHandler.post(runnable);
    }

    private @Nullable String getStringSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getString(key);
        }
        return null;
    }

    private @Nullable Integer getIntSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getInt(key);
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
