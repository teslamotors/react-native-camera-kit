package com.wix.RNCameraKit;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryViewManager extends SimpleViewManager<GalleryView> {

    @Override
    public String getName() {
        return "GalleryView";
    }

    @Override
    protected GalleryView createViewInstance(ThemedReactContext reactContext) {
        return new GalleryView(reactContext.getBaseContext());
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

}
