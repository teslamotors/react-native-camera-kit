package com.wix.RNCameraKit;

import android.content.Context;
import android.graphics.Rect;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.View;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.ArrayList;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryView extends RecyclerView {

    private GalleryAdapter adapter;
    private int itemSpacing;
    private int lineSpacing;

    public GalleryView(Context context) {
        super(context);
        setHasFixedSize(true);
        adapter = new GalleryAdapter(this);
        setAdapter(adapter);
    }

    private void updateDecorator() {
        addItemDecoration(new ItemDecoration() {
            @Override
            public void getItemOffsets(Rect outRect, View view, RecyclerView parent, State state) {
                outRect.top = lineSpacing;
                outRect.left = itemSpacing;
                outRect.right = itemSpacing;
                outRect.bottom = lineSpacing;
            }
        });
    }

    public void setAlbumName(String albumName) {
        adapter.setAlbum(albumName);
    }

    public void setItemSpacing(int itemSpacing) {
        this.itemSpacing = itemSpacing;
        updateDecorator();
    }

    public void setLineSpacing(int lineSpacing) {
        this.lineSpacing = lineSpacing;
        updateDecorator();
    }

    public void setColumnCount(int columnCount) {
        GridLayoutManager layoutManager = new GridLayoutManager(getContext(), columnCount);
        layoutManager.setOrientation(GridLayoutManager.VERTICAL);
        setLayoutManager(layoutManager);
    }

    public void onTapImage(String uri) {
        ReactContext reactContext = ((ReactContext)getContext());
        WritableMap event = Arguments.createMap();
        event.putString("uri", uri);
        event.putString("id", "onTapImage");
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onTapImage", event);
    }

    public void setSelectedUris(ArrayList<String> selectedUris) {
        adapter.setSelectedUris(selectedUris);
        adapter.notifyDataSetChanged();
        invalidate();
    }
}
